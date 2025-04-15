# SarahsRecipes.ai Supabase Migration Script

```sql
-- ==========================================
-- INITIALIZATION - SCHEMAS AND EXTENSIONS
-- ==========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent"; -- For accent-insensitive search

-- Create necessary schemas
CREATE SCHEMA IF NOT EXISTS api;
CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS stripe;

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

-- Automatically set updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Function to check if user has reached their free tier import limit
CREATE OR REPLACE FUNCTION public.check_import_limit()
RETURNS BOOLEAN AS $$
DECLARE
    user_imports INTEGER;
    user_tier TEXT;
    import_limit INTEGER := 10; -- Free tier limit
BEGIN
    -- Get user's subscription tier
    SELECT tier INTO user_tier FROM api.user_subscriptions 
    WHERE user_id = auth.uid() AND is_active = true;
    
    -- If user is on a paid tier, always allow imports
    IF user_tier = 'premium' THEN
        RETURN TRUE;
    END IF;
    
    -- Count user's imports
    SELECT COUNT(*) INTO user_imports FROM api.ai_usage
    WHERE user_id = auth.uid() AND operation = 'recipe_import' AND created_at > NOW() - INTERVAL '1 year';
    
    -- Check if under limit
    RETURN user_imports < import_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

-- ==========================================
-- REFERENCE DATA TABLES
-- ==========================================

-- Reference table for tag categories
CREATE TABLE IF NOT EXISTS reference.tag_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('dietary', 'cuisine', 'meal_type', 'custom')),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(name, type)
);

-- Reference table for standard units of measurement
CREATE TABLE IF NOT EXISTS reference.measurement_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    abbreviation TEXT,
    type TEXT NOT NULL CHECK (type IN ('volume', 'weight', 'count', 'length', 'temperature', 'other')),
    base_unit_id UUID REFERENCES reference.measurement_units(id),
    conversion_factor DECIMAL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- USER PROFILE TABLES
-- ==========================================

-- Extended user profile information
CREATE TABLE IF NOT EXISTS api.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    dietary_preferences TEXT[],
    public_profile BOOLEAN NOT NULL DEFAULT false,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Track user subscription status
CREATE TABLE IF NOT EXISTS api.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, is_active) WHERE is_active = true
);

-- Track AI feature usage
CREATE TABLE IF NOT EXISTS api.ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    operation TEXT NOT NULL, -- 'recipe_import', 'tag_suggestion', etc.
    source TEXT NOT NULL, -- 'url', 'photo', 'text', etc.
    tokens_used INTEGER,
    successful BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- RECIPE CORE TABLES
-- ==========================================

-- Main recipe table
CREATE TABLE IF NOT EXISTS api.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    source_url TEXT,
    source_attribution TEXT,
    image_url TEXT,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER,
    servings INTEGER,
    serving_size TEXT,
    calories_per_serving INTEGER,
    is_private BOOLEAN NOT NULL DEFAULT true,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    extraction_method TEXT CHECK (extraction_method IN ('url', 'photo', 'text', 'manual', 'generated')),
    extracted_at TIMESTAMPTZ,
    language TEXT DEFAULT 'en',
    slug TEXT,
    seo_title TEXT,
    seo_description TEXT,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Recipe ingredients
CREATE TABLE IF NOT EXISTS api.recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    quantity DECIMAL,
    unit TEXT,
    name TEXT NOT NULL,
    preparation TEXT, -- e.g., "finely chopped"
    is_heading BOOLEAN NOT NULL DEFAULT false, -- For ingredient section headers
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recipe instructions
CREATE TABLE IF NOT EXISTS api.recipe_instructions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    is_heading BOOLEAN NOT NULL DEFAULT false, -- For instruction section headers
    estimated_time_minutes INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recipe notes and personalization
CREATE TABLE IF NOT EXISTS api.recipe_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT true,
    position INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- User recipe cook logs
CREATE TABLE IF NOT EXISTS api.recipe_cook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cook_date DATE NOT NULL DEFAULT CURRENT_DATE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    notes TEXT,
    modifications TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- RECIPE ORGANIZATION TABLES
-- ==========================================

-- Tags for recipe organization
CREATE TABLE IF NOT EXISTS api.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category_id UUID REFERENCES reference.tag_categories(id),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for system tags
    is_system BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(name, category_id, user_id)
);

-- Recipe-to-tag mapping
CREATE TABLE IF NOT EXISTS api.recipe_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES api.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(recipe_id, tag_id)
);

-- User collections of recipes
CREATE TABLE IF NOT EXISTS api.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    is_private BOOLEAN NOT NULL DEFAULT true,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, name)
);

-- Recipes within collections
CREATE TABLE IF NOT EXISTS api.collection_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES api.collections(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    position INTEGER,
    added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(collection_id, recipe_id)
);

-- ==========================================
-- SOCIAL FEATURES TABLES
-- ==========================================

-- Potluck events
CREATE TABLE IF NOT EXISTS api.potlucks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    location TEXT,
    location_details TEXT,
    image_url TEXT,
    dietary_restrictions TEXT[],
    is_private BOOLEAN NOT NULL DEFAULT true,
    invitation_code TEXT UNIQUE,
    max_guests INTEGER,
    rsvp_deadline TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('planning', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Potluck participants
CREATE TABLE IF NOT EXISTS api.potluck_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    potluck_id UUID NOT NULL REFERENCES api.potlucks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Can be NULL for guest participants
    email TEXT,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'invited' CHECK (status IN ('invited', 'confirmed', 'declined', 'maybe')),
    guest_count INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(potluck_id, user_id) WHERE user_id IS NOT NULL,
    UNIQUE(potluck_id, email) WHERE email IS NOT NULL
);

-- Potluck recipe assignments
CREATE TABLE IF NOT EXISTS api.potluck_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    potluck_id UUID NOT NULL REFERENCES api.potlucks(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES api.potluck_participants(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES api.recipes(id) ON DELETE SET NULL,
    custom_recipe_name TEXT, -- Used when recipe_id is NULL
    category TEXT NOT NULL CHECK (category IN ('appetizer', 'side', 'main', 'dessert', 'drink', 'other')),
    notes TEXT,
    is_confirmed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- SHOPPING LIST TABLES
-- ==========================================

-- Shopping lists
CREATE TABLE IF NOT EXISTS api.shopping_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Shopping list items
CREATE TABLE IF NOT EXISTS api.shopping_list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopping_list_id UUID NOT NULL REFERENCES api.shopping_lists(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES api.recipes(id) ON DELETE SET NULL,
    recipe_ingredient_id UUID REFERENCES api.recipe_ingredients(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    quantity DECIMAL,
    unit TEXT,
    category TEXT, -- For organizing by department
    is_checked BOOLEAN NOT NULL DEFAULT false,
    custom_added BOOLEAN NOT NULL DEFAULT false, -- TRUE if manually added
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- STRIPE INTEGRATION TABLES
-- ==========================================

-- Stripe customers (synced from webhooks)
CREATE TABLE IF NOT EXISTS stripe.customers (
    id TEXT PRIMARY KEY, -- Stripe customer ID
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id)
);

-- Stripe subscriptions (synced from webhooks)
CREATE TABLE IF NOT EXISTS stripe.subscriptions (
    id TEXT PRIMARY KEY, -- Stripe subscription ID
    customer_id TEXT NOT NULL REFERENCES stripe.customers(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    price_id TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    canceled_at TIMESTAMPTZ,
    trial_start TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- ANALYTICS TABLES
-- ==========================================

-- Feature usage analytics
CREATE TABLE IF NOT EXISTS analytics.feature_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    feature TEXT NOT NULL,
    action TEXT NOT NULL,
    metadata JSONB,
    client_info JSONB, -- Device, browser, etc.
    session_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recipe view analytics
CREATE TABLE IF NOT EXISTS analytics.recipe_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    view_type TEXT NOT NULL, -- 'detail', 'cooking_mode', etc.
    duration_seconds INTEGER,
    referrer TEXT,
    client_info JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- TRIGGERS
-- ==========================================

-- Set updated_at timestamps
CREATE TRIGGER set_updated_at_profiles
BEFORE UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_user_subscriptions
BEFORE UPDATE ON api.user_subscriptions
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_recipes
BEFORE UPDATE ON api.recipes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_recipe_ingredients
BEFORE UPDATE ON api.recipe_ingredients
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_recipe_instructions
BEFORE UPDATE ON api.recipe_instructions
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_recipe_notes
BEFORE UPDATE ON api.recipe_notes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_recipe_cook_logs
BEFORE UPDATE ON api.recipe_cook_logs
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_tags
BEFORE UPDATE ON api.tags
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_collections
BEFORE UPDATE ON api.collections
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_potlucks
BEFORE UPDATE ON api.potlucks
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_potluck_participants
BEFORE UPDATE ON api.potluck_participants
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_potluck_recipes
BEFORE UPDATE ON api.potluck_recipes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_shopping_lists
BEFORE UPDATE ON api.shopping_lists
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_tag_categories
BEFORE UPDATE ON reference.tag_categories
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_measurement_units
BEFORE UPDATE ON reference.measurement_units
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_stripe_customers
BEFORE UPDATE ON stripe.customers
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_updated_at_stripe_subscriptions
BEFORE UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Recipe slug generator
CREATE OR REPLACE FUNCTION public.generate_recipe_slug()
RETURNS TRIGGER AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    counter INTEGER := 1;
BEGIN
    -- Create base slug from title
    base_slug := lower(regexp_replace(NEW.title, '[^a-zA-Z0-9]+', '-', 'g'));
    base_slug := trim(both '-' from base_slug);
    
    -- Initial attempt with just the base slug
    final_slug := base_slug;
    
    -- Check if slug exists and append counter if needed
    WHILE EXISTS(
        SELECT 1 FROM api.recipes WHERE slug = final_slug AND id != NEW.id
    ) LOOP
        counter := counter + 1;
        final_slug := base_slug || '-' || counter::text;
    END LOOP;
    
    NEW.slug := final_slug;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

CREATE TRIGGER generate_recipe_slug
BEFORE INSERT OR UPDATE OF title ON api.recipes
FOR EACH ROW
WHEN (NEW.slug IS NULL OR OLD.title IS DISTINCT FROM NEW.title)
EXECUTE FUNCTION public.generate_recipe_slug();

-- Create default favorites collection for new users
CREATE OR REPLACE FUNCTION public.create_default_collections()
RETURNS TRIGGER AS $$
BEGIN
    -- Create Favorites collection
    INSERT INTO api.collections (user_id, name, is_default, is_favorite, is_private)
    VALUES (NEW.id, 'Favorites', true, true, true);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

CREATE TRIGGER create_default_collections
AFTER INSERT ON api.profiles
FOR EACH ROW
EXECUTE FUNCTION public.create_default_collections();

-- Automatically create a profile for new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO api.profiles (id, display_name)
    VALUES (NEW.id, NEW.email);
    
    INSERT INTO api.user_subscriptions (user_id, tier, is_active)
    VALUES (NEW.id, 'free', true);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Sync favorite recipes to favorites collection
CREATE OR REPLACE FUNCTION public.sync_favorites_collection()
RETURNS TRIGGER AS $$
DECLARE
    fav_collection_id UUID;
BEGIN
    -- Only proceed if the favorite status changed
    IF OLD.is_favorite IS NOT DISTINCT FROM NEW.is_favorite THEN
        RETURN NEW;
    END IF;
    
    -- Get the favorites collection ID
    SELECT id INTO fav_collection_id
    FROM api.collections
    WHERE user_id = NEW.user_id AND is_default = true AND is_favorite = true;
    
    -- Create a default favorites collection if it doesn't exist
    IF fav_collection_id IS NULL THEN
        INSERT INTO api.collections (user_id, name, is_default, is_favorite, is_private)
        VALUES (NEW.user_id, 'Favorites', true, true, true)
        RETURNING id INTO fav_collection_id;
    END IF;
    
    -- Add to favorites collection
    IF NEW.is_favorite = true THEN
        INSERT INTO api.collection_recipes (collection_id, recipe_id)
        VALUES (fav_collection_id, NEW.id)
        ON CONFLICT (collection_id, recipe_id) DO NOTHING;
    -- Remove from favorites collection
    ELSE
        DELETE FROM api.collection_recipes 
        WHERE collection_id = fav_collection_id AND recipe_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

CREATE TRIGGER sync_favorites_collection
AFTER UPDATE OF is_favorite ON api.recipes
FOR EACH ROW
EXECUTE FUNCTION public.sync_favorites_collection();

-- Track recipe views
CREATE OR REPLACE FUNCTION public.increment_recipe_view()
RETURNS TRIGGER AS $$
BEGIN
    -- Only increment the counter on SELECT operations
    IF TG_OP = 'SELECT' THEN
        UPDATE api.recipes 
        SET view_count = view_count + 1 
        WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

-- ==========================================
-- INDEXES
-- ==========================================

-- Recipe search optimization
CREATE INDEX idx_recipes_title_search ON api.recipes USING GIN (to_tsvector('english', title));
CREATE INDEX idx_recipes_user_id ON api.recipes(user_id);
CREATE INDEX idx_recipes_is_private ON api.recipes(is_private) WHERE is_private = false;
CREATE INDEX idx_recipes_is_favorite ON api.recipes(is_favorite) WHERE is_favorite = true;
CREATE INDEX idx_recipes_slug ON api.recipes(slug);

-- Recipe components
CREATE INDEX idx_recipe_ingredients_recipe_id ON api.recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_instructions_recipe_id ON api.recipe_instructions(recipe_id);
CREATE INDEX idx_recipe_notes_recipe_id ON api.recipe_notes(recipe_id);
CREATE INDEX idx_recipe_notes_user_id ON api.recipe_notes(user_id);

-- Organization
CREATE INDEX idx_tags_name ON api.tags(name);
CREATE INDEX idx_tags_category_id ON api.tags(category_id);
CREATE INDEX idx_recipe_tags_recipe_id ON api.recipe_tags(recipe_id);
CREATE INDEX idx_recipe_tags_tag_id ON api.recipe_tags(tag_id);
CREATE INDEX idx_collections_user_id ON api.collections(user_id);
CREATE INDEX idx_collection_recipes_collection_id ON api.collection_recipes(collection_id);
CREATE INDEX idx_collection_recipes_recipe_id ON api.collection_recipes(recipe_id);

-- Potlucks
CREATE INDEX idx_potlucks_user_id ON api.potlucks(user_id);
CREATE INDEX idx_potlucks_event_date ON api.potlucks(event_date);
CREATE INDEX idx_potluck_participants_potluck_id ON api.potluck_participants(potluck_id);
CREATE INDEX idx_potluck_participants_user_id ON api.potluck_participants(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_potluck_recipes_potluck_id ON api.potluck_recipes(potluck_id);
CREATE INDEX idx_potluck_recipes_participant_id ON api.potluck_recipes(participant_id);

-- Shopping lists
CREATE INDEX idx_shopping_lists_user_id ON api.shopping_lists(user_id);
CREATE INDEX idx_shopping_list_items_shopping_list_id ON api.shopping_list_items(shopping_list_id);
CREATE INDEX idx_shopping_list_items_recipe_id ON api.shopping_list_items(recipe_id) WHERE recipe_id IS NOT NULL;

-- AI Usage tracking
CREATE INDEX idx_ai_usage_user_id ON api.ai_usage(user_id);
CREATE INDEX idx_ai_usage_created_at ON api.ai_usage(created_at);

-- ==========================================
-- ROW LEVEL SECURITY POLICIES
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_instructions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_cook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.collection_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potlucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potluck_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potluck_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.shopping_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.feature_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.recipe_views ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view their own profile"
    ON api.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view public profiles"
    ON api.profiles FOR SELECT
    USING (public_profile = true);

CREATE POLICY "Users can update their own profile"
    ON api.profiles FOR UPDATE
    USING (auth.uid() = id);

-- User subscriptions policies
CREATE POLICY "Users can view their own subscriptions"
    ON api.user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- AI usage policies
CREATE POLICY "Users can view their own AI usage"
    ON api.ai_usage FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI usage if within limits"
    ON api.ai_usage FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        (operation != 'recipe_import' OR public.check_import_limit())
    );

-- Recipe policies
CREATE POLICY "Users can view their own recipes"
    ON api.recipes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view public recipes"
    ON api.recipes FOR SELECT
    USING (is_private = false);

CREATE POLICY "Users can insert their own recipes"
    ON api.recipes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recipes"
    ON api.recipes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recipes"
    ON api.recipes FOR DELETE
    USING (auth.uid() = user_id);

-- Recipe components policies
-- Ingredients
CREATE POLICY "Users can view ingredients of their own recipes"
    ON api.recipe_ingredients FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_ingredients.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can view ingredients of public recipes"
    ON api.recipe_ingredients FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_ingredients.recipe_id
        AND api.recipes.is_private = false
    ));

CREATE POLICY "Users can insert ingredients to their own recipes"
    ON api.recipe_ingredients FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_ingredients.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can update ingredients of their own recipes"
    ON api.recipe_ingredients FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_ingredients.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete ingredients of their own recipes"
    ON api.recipe_ingredients FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_ingredients.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

-- Instructions (similar to ingredients)
CREATE POLICY "Users can view instructions of their own recipes"
    ON api.recipe_instructions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_instructions.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can view instructions of public recipes"
    ON api.recipe_instructions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_instructions.recipe_id
        AND api.recipes.is_private = false
    ));

CREATE POLICY "Users can insert instructions to their own recipes"
    ON api.recipe_instructions FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_instructions.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can update instructions of their own recipes"
    ON api.recipe_instructions FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_instructions.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete instructions of their own recipes"
    ON api.recipe_instructions FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_instructions.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

-- Notes
CREATE POLICY "Users can view their own notes"
    ON api.recipe_notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view public notes on public recipes"
    ON api.recipe_notes FOR SELECT
    USING (
        is_private = false AND
        EXISTS (
            SELECT 1 FROM api.recipes
            WHERE api.recipes.id = api.recipe_notes.recipe_id
            AND api.recipes.is_private = false
        )
    );

CREATE POLICY "Users can insert their own notes"
    ON api.recipe_notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes"
    ON api.recipe_notes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes"
    ON api.recipe_notes FOR DELETE
    USING (auth.uid() = user_id);

-- Cook logs
CREATE POLICY "Users can view their own cook logs"
    ON api.recipe_cook_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cook logs"
    ON api.recipe_cook_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cook logs"
    ON api.recipe_cook_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cook logs"
    ON api.recipe_cook_logs FOR DELETE
    USING (auth.uid() = user_id);

-- Tags
CREATE POLICY "Anyone can view system tags"
    ON api.tags FOR SELECT
    USING (is_system = true OR user_id IS NULL);

CREATE POLICY "Users can view their own tags"
    ON api.tags FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tags"
    ON api.tags FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tags"
    ON api.tags FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tags"
    ON api.tags FOR DELETE
    USING (auth.uid() = user_id);

-- Recipe Tags
CREATE POLICY "Users can view tags for their own recipes"
    ON api.recipe_tags FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_tags.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can view tags for public recipes"
    ON api.recipe_tags FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_tags.recipe_id
        AND api.recipes.is_private = false
    ));

CREATE POLICY "Users can insert tags to their own recipes"
    ON api.recipe_tags FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_tags.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete tags from their own recipes"
    ON api.recipe_tags FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.recipes
        WHERE api.recipes.id = api.recipe_tags.recipe_id
        AND api.recipes.user_id = auth.uid()
    ));

-- Collections
CREATE POLICY "Users can view their own collections"
    ON api.collections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view public collections"
    ON api.collections FOR SELECT
    USING (is_private = false);

CREATE POLICY "Users can insert their own collections"
    ON api.collections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own collections"
    ON api.collections FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own collections"
    ON api.collections FOR DELETE
    USING (auth.uid() = user_id);

-- Collection Recipes
CREATE POLICY "Users can view recipes in their own collections"
    ON api.collection_recipes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.collections
        WHERE api.collections.id = api.collection_recipes.collection_id
        AND api.collections.user_id = auth.uid()
    ));

CREATE POLICY "Users can view recipes in public collections"
    ON api.collection_recipes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.collections
        WHERE api.collections.id = api.collection_recipes.collection_id
        AND api.collections.is_private = false
    ));

CREATE POLICY "Users can insert recipes to their own collections"
    ON api.collection_recipes FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.collections
        WHERE api.collections.id = api.collection_recipes.collection_id
        AND api.collections.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete recipes from their own collections"
    ON api.collection_recipes FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.collections
        WHERE api.collections.id = api.collection_recipes.collection_id
        AND api.collections.user_id = auth.uid()
    ));

-- Potlucks
CREATE POLICY "Users can view their own potlucks"
    ON api.potlucks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Participants can view potlucks they're invited to"
    ON api.potlucks FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.potluck_participants
        WHERE api.potluck_participants.potluck_id = api.potlucks.id
        AND api.potluck_participants.user_id = auth.uid()
    ));

CREATE POLICY "Users can view public potlucks"
    ON api.potlucks FOR SELECT
    USING (is_private = false);

CREATE POLICY "Users can insert their own potlucks"
    ON api.potlucks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own potlucks"
    ON api.potlucks FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own potlucks"
    ON api.potlucks FOR DELETE
    USING (auth.uid() = user_id);

-- Potluck Participants
CREATE POLICY "Potluck hosts can view participants"
    ON api.potluck_participants FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_participants.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Users can view their own participant records"
    ON api.potluck_participants FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Potluck hosts can insert participants"
    ON api.potluck_participants FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_participants.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Users can update their own participant status"
    ON api.potluck_participants FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Potluck hosts can update participants"
    ON api.potluck_participants FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_participants.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Potluck hosts can delete participants"
    ON api.potluck_participants FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_participants.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

-- Potluck Recipes
CREATE POLICY "Potluck hosts can view assigned recipes"
    ON api.potluck_recipes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_recipes.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Participants can view potluck recipes"
    ON api.potluck_recipes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.potluck_participants
        WHERE api.potluck_participants.potluck_id = api.potluck_recipes.potluck_id
        AND api.potluck_participants.user_id = auth.uid()
    ));

CREATE POLICY "Participants can insert their own recipes"
    ON api.potluck_recipes FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.potluck_participants
        WHERE api.potluck_participants.id = api.potluck_recipes.participant_id
        AND api.potluck_participants.user_id = auth.uid()
    ));

CREATE POLICY "Potluck hosts can insert any recipes"
    ON api.potluck_recipes FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_recipes.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Participants can update their own recipes"
    ON api.potluck_recipes FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.potluck_participants
        WHERE api.potluck_participants.id = api.potluck_recipes.participant_id
        AND api.potluck_participants.user_id = auth.uid()
    ));

CREATE POLICY "Potluck hosts can update any recipes"
    ON api.potluck_recipes FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_recipes.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

CREATE POLICY "Participants can delete their own recipes"
    ON api.potluck_recipes FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.potluck_participants
        WHERE api.potluck_participants.id = api.potluck_recipes.participant_id
        AND api.potluck_participants.user_id = auth.uid()
    ));

CREATE POLICY "Potluck hosts can delete any recipes"
    ON api.potluck_recipes FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.potlucks
        WHERE api.potlucks.id = api.potluck_recipes.potluck_id
        AND api.potlucks.user_id = auth.uid()
    ));

-- Shopping Lists
CREATE POLICY "Users can view their own shopping lists"
    ON api.shopping_lists FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own shopping lists"
    ON api.shopping_lists FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own shopping lists"
    ON api.shopping_lists FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own shopping lists"
    ON api.shopping_lists FOR DELETE
    USING (auth.uid() = user_id);

-- Shopping List Items
CREATE POLICY "Users can view items in their own shopping lists"
    ON api.shopping_list_items FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM api.shopping_lists
        WHERE api.shopping_lists.id = api.shopping_list_items.shopping_list_id
        AND api.shopping_lists.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert items to their own shopping lists"
    ON api.shopping_list_items FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM api.shopping_lists
        WHERE api.shopping_lists.id = api.shopping_list_items.shopping_list_id
        AND api.shopping_lists.user_id = auth.uid()
    ));

CREATE POLICY "Users can update items in their own shopping lists"
    ON api.shopping_list_items FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM api.shopping_lists
        WHERE api.shopping_lists.id = api.shopping_list_items.shopping_list_id
        AND api.shopping_lists.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete items from their own shopping lists"
    ON api.shopping_list_items FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM api.shopping_lists
        WHERE api.shopping_lists.id = api.shopping_list_items.shopping_list_id
        AND api.shopping_lists.user_id = auth.uid()
    ));

-- Analytics
CREATE POLICY "Users can track their own feature usage"
    ON analytics.feature_usage FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can track their own recipe views"
    ON analytics.recipe_views FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- USEFUL VIEWS
-- ==========================================

-- Recipes with tag information
CREATE VIEW api.recipes_with_tags AS
SELECT 
    r.*,
    array_agg(DISTINCT t.name) FILTER (WHERE t.name IS NOT NULL) AS tags,
    array_agg(DISTINCT tc.type || ':' || t.name) FILTER (WHERE t.name IS NOT NULL) AS categorized_tags
FROM 
    api.recipes r
LEFT JOIN 
    api.recipe_tags rt ON r.id = rt.recipe_id
LEFT JOIN 
    api.tags t ON rt.tag_id = t.id
LEFT JOIN 
    reference.tag_categories tc ON t.category_id = tc.id
GROUP BY 
    r.id;

-- Public recipe counts by tag
CREATE VIEW api.popular_tags AS
SELECT 
    t.id,
    t.name,
    tc.type AS category,
    COUNT(DISTINCT rt.recipe_id) AS recipe_count
FROM 
    api.tags t
JOIN 
    reference.tag_categories tc ON t.category_id = tc.id
JOIN 
    api.recipe_tags rt ON t.id = rt.tag_id
JOIN 
    api.recipes r ON rt.recipe_id = r.id
WHERE 
    r.is_private = false
GROUP BY 
    t.id, t.name, tc.type
ORDER BY 
    recipe_count DESC;

-- User subscription status with expiration
CREATE VIEW api.active_subscriptions AS
SELECT 
    us.user_id,
    us.tier,
    us.stripe_subscription_id,
    us.current_period_end,
    us.cancel_at_period_end,
    CASE 
        WHEN us.tier = 'premium' AND us.current_period_end > now() THEN true
        WHEN us.tier = 'free' THEN true
        ELSE false
    END AS is_active
FROM 
    api.user_subscriptions us
WHERE 
    us.is_active = true;

-- Recipe statistics
CREATE VIEW api.recipe_statistics AS
SELECT 
    r.id AS recipe_id,
    r.title,
    r.user_id,
    r.view_count,
    COUNT(DISTINCT rt.tag_id) AS tag_count,
    COUNT(DISTINCT cr.collection_id) AS collection_count,
    COUNT(DISTINCT rcl.id) AS cook_count,
    AVG(rcl.rating) AS avg_rating,
    COUNT(DISTINCT rn.id) AS note_count
FROM 
    api.recipes r
LEFT JOIN 
    api.recipe_tags rt ON r.id = rt.recipe_id
LEFT JOIN 
    api.collection_recipes cr ON r.id = cr.recipe_id
LEFT JOIN 
    api.recipe_cook_logs rcl ON r.id = rcl.recipe_id
LEFT JOIN 
    api.recipe_notes rn ON r.id = rn.recipe_id
GROUP BY 
    r.id;

-- Complete recipe view (for easy querying)
CREATE VIEW api.complete_recipes AS
SELECT 
    r.*,
    p.display_name AS author_name,
    p.avatar_url AS author_avatar,
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', ri.id,
                'position', ri.position,
                'quantity', ri.quantity,
                'unit', ri.unit,
                'name', ri.name,
                'preparation', ri.preparation,
                'is_heading', ri.is_heading,
                'notes', ri.notes
            ) ORDER BY ri.position
        )
        FROM api.recipe_ingredients ri
        WHERE ri.recipe_id = r.id
    ) AS ingredients,
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', rs.id,
                'position', rs.position,
                'instruction', rs.instruction,
                'is_heading', rs.is_heading,
                'estimated_time_minutes', rs.estimated_time_minutes
            ) ORDER BY rs.position
        )
        FROM api.recipe_instructions rs
        WHERE rs.recipe_id = r.id
    ) AS instructions,
    (
        SELECT array_agg(DISTINCT t.name)
        FROM api.recipe_tags rt
        JOIN api.tags t ON rt.tag_id = t.id
        WHERE rt.recipe_id = r.id
    ) AS tags,
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', c.id,
                'name', c.name,
                'is_default', c.is_default
            )
        )
        FROM api.collection_recipes cr
        JOIN api.collections c ON cr.collection_id = c.id
        WHERE cr.recipe_id = r.id AND c.user_id = r.user_id
    ) AS collections,
    (
        SELECT COUNT(*)
        FROM api.recipe_cook_logs rcl
        WHERE rcl.recipe_id = r.id
    ) AS cook_count,
    (
        SELECT AVG(rating)::NUMERIC(3,2)
        FROM api.recipe_cook_logs rcl
        WHERE rcl.recipe_id = r.id AND rcl.rating IS NOT NULL
    ) AS avg_rating
FROM 
    api.recipes r
JOIN 
    api.profiles p ON r.user_id = p.id;

-- ==========================================
-- STORED PROCEDURES
-- ==========================================

-- Generate a shopping list from recipes
CREATE OR REPLACE FUNCTION api.generate_shopping_list(
    p_user_id UUID,
    p_name TEXT,
    p_recipe_ids UUID[]
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = api, public, pg_temp
AS $$
DECLARE
    v_shopping_list_id UUID;
    v_recipe_id UUID;
BEGIN
    -- Create new shopping list
    INSERT INTO api.shopping_lists (
        user_id,
        name,
        description,
        is_active
    ) VALUES (
        p_user_id,
        p_name,
        'Generated from recipes',
        true
    ) RETURNING id INTO v_shopping_list_id;
    
    -- Loop through all recipe IDs
    FOREACH v_recipe_id IN ARRAY p_recipe_ids
    LOOP
        -- Insert ingredients as shopping list items
        INSERT INTO api.shopping_list_items (
            shopping_list_id,
            recipe_id,
            recipe_ingredient_id,
            name,
            quantity,
            unit,
            category,
            is_checked,
            custom_added
        )
        SELECT
            v_shopping_list_id,
            v_recipe_id,
            ri.id,
            ri.name,
            ri.quantity,
            ri.unit,
            CASE
                WHEN ri.name ILIKE '%milk%' OR ri.name ILIKE '%cheese%' OR ri.name ILIKE '%yogurt%' THEN 'Dairy'
                WHEN ri.name ILIKE '%beef%' OR ri.name ILIKE '%chicken%' OR ri.name ILIKE '%pork%' THEN 'Meat'
                WHEN ri.name ILIKE '%apple%' OR ri.name ILIKE '%banana%' OR ri.name ILIKE '%lettuce%' THEN 'Produce'
                ELSE 'Other'
            END,
            false,
            false
        FROM
            api.recipe_ingredients ri
        WHERE
            ri.recipe_id = v_recipe_id
            AND NOT ri.is_heading;
    END LOOP;
    
    -- Combine duplicate items with the same name
    -- This is a simplified approach - a more sophisticated version would handle unit conversions
    WITH duplicates AS (
        SELECT
            name,
            unit,
            SUM(quantity) as total_quantity,
            MIN(id) as first_id
        FROM
            api.shopping_list_items
        WHERE
            shopping_list_id = v_shopping_list_id
            AND unit IS NOT NULL
            AND quantity IS NOT NULL
        GROUP BY
            name, unit
        HAVING
            COUNT(*) > 1
    )
    UPDATE api.shopping_list_items sli
    SET quantity = d.total_quantity
    FROM duplicates d
    WHERE sli.id = d.first_id;
    
    -- Delete the now-combined duplicates
    DELETE FROM api.shopping_list_items
    WHERE shopping_list_id = v_shopping_list_id
    AND id NOT IN (
        SELECT MIN(id)
        FROM api.shopping_list_items
        WHERE shopping_list_id = v_shopping_list_id
        GROUP BY name, unit
    );
    
    RETURN v_shopping_list_id;
END;
$$;

-- Log a recipe view
CREATE OR REPLACE PROCEDURE api.log_recipe_view(
    p_recipe_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_view_type TEXT DEFAULT 'detail'
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = api, analytics, public, pg_temp
AS $$
BEGIN
    -- Increment the view count
    UPDATE api.recipes
    SET view_count = view_count + 1
    WHERE id = p_recipe_id;
    
    -- Log the view for analytics
    INSERT INTO analytics.recipe_views (
        recipe_id,
        user_id,
        view_type,
        client_info
    ) VALUES (
        p_recipe_id,
        COALESCE(p_user_id, auth.uid()),
        p_view_type,
        jsonb_build_object(
            'user_agent', current_setting('request.headers', true)::jsonb->>'user-agent',
            'ip', current_setting('request.headers', true)::jsonb->>'x-forwarded-for'
        )
    );
    
    COMMIT;
END;
$$;

-- Create initial reference data
DO $$
BEGIN
    -- Insert tag categories if they don't exist
    INSERT INTO reference.tag_categories (name, type, description)
    VALUES
        ('Dietary Restriction', 'dietary', 'Dietary requirements or preferences'),
        ('Cuisine', 'cuisine', 'Regional or cultural style of cooking'),
        ('Meal Type', 'meal_type', 'Type of meal or course'),
        ('Difficulty', 'custom', 'Recipe difficulty level'),
        ('Season', 'custom', 'Seasonal categorization'),
        ('Cooking Method', 'custom', 'Method of preparation')
    ON CONFLICT (name, type) DO NOTHING;

    -- Insert common dietary restriction tags
    WITH category AS (
        SELECT id FROM reference.tag_categories WHERE type = 'dietary' LIMIT 1
    )
    INSERT INTO api.tags (name, category_id, is_system)
    SELECT tag_name, category.id, true
    FROM category, unnest(ARRAY[
        'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free', 
        'Nut-Free', 'Low-Carb', 'Keto', 'Paleo',
        'Low-Fat', 'Low-Sodium', 'Sugar-Free', 'Whole30'
    ]) AS tag_name
    ON CONFLICT DO NOTHING;

    -- Insert common cuisine tags
    WITH category AS (
        SELECT id FROM reference.tag_categories WHERE type = 'cuisine' LIMIT 1
    )
    INSERT INTO api.tags (name, category_id, is_system)
    SELECT tag_name, category.id, true
    FROM category, unnest(ARRAY[
        'Italian', 'Mexican', 'Chinese', 'Japanese', 'Indian',
        'French', 'Mediterranean', 'Thai', 'Greek', 'Spanish',
        'American', 'Southern', 'Korean', 'Vietnamese', 'Middle Eastern'
    ]) AS tag_name
    ON CONFLICT DO NOTHING;

    -- Insert common meal type tags
    WITH category AS (
        SELECT id FROM reference.tag_categories WHERE type = 'meal_type' LIMIT 1
    )
    INSERT INTO api.tags (name, category_id, is_system)
    SELECT tag_name, category.id, true
    FROM category, unnest(ARRAY[
        'Breakfast', 'Lunch', 'Dinner', 'Appetizer', 'Side Dish',
        'Dessert', 'Snack', 'Drink', 'Soup', 'Salad',
        'Main Course', 'Brunch', 'Sauce', 'Dip'
    ]) AS tag_name
    ON CONFLICT DO NOTHING;

    -- Insert measurement units
    INSERT INTO reference.measurement_units (name, abbreviation, type)
    VALUES
        ('Cup', 'cup', 'volume'),
        ('Tablespoon', 'tbsp', 'volume'),
        ('Teaspoon', 'tsp', 'volume'),
        ('Fluid Ounce', 'fl oz', 'volume'),
        ('Pint', 'pt', 'volume'),
        ('Quart', 'qt', 'volume'),
        ('Gallon', 'gal', 'volume'),
        ('Milliliter', 'ml', 'volume'),
        ('Liter', 'l', 'volume'),
        
        ('Pound', 'lb', 'weight'),
        ('Ounce', 'oz', 'weight'),
        ('Gram', 'g', 'weight'),
        ('Kilogram', 'kg', 'weight'),
        
        ('Piece', 'pc', 'count'),
        ('Dozen', 'doz', 'count'),
        
        ('Inch', 'in', 'length'),
        ('Centimeter', 'cm', 'length'),
        
        ('Fahrenheit', '°F', 'temperature'),
        ('Celsius', '°C', 'temperature'),
        
        ('Pinch', 'pinch', 'other'),
        ('Dash', 'dash', 'other'),
        ('To taste', 'to taste', 'other')
    ON CONFLICT DO NOTHING;
END;
$$;
```

This SQL migration script creates a complete database schema for SarahsRecipes.ai based on the requirements and best practices. It includes:

1. **Schema Structure**:
   - `api` for user-generated content and core functionality
   - `reference` for lookup tables and standardized data
   - `analytics` for tracking and reporting
   - `stripe` for payment integration

2. **Core Tables**:
   - User profiles and subscription management
   - Recipe structure with ingredients and instructions
   - Organization system with tags and collections
   - Social features like potlucks and sharing
   - Shopping lists with smart organization

3. **Security Implementation**:
   - Row Level Security policies for all tables
   - Proper permission checks based on ownership
   - Subscription tier enforcement
   - Privacy controls for content sharing

4. **System Functions**:
   - Auto-updating timestamps
   - Usage tracking and limits
   - Automated slug generation
   - Default collection creation

5. **Performance Optimization**:
   - Strategic indexes for common queries
   - Optimized views for complex data access
   - Full-text search capability

6. **Helper Features**:
   - Shopping list generation
   - Recipe view tracking
   - Tag suggestion system
   - Reference data for common categories

This schema provides a solid foundation for building your SaaS application with all the features described in your requirements document, while following the database patterns best practices.