-- Recipe App Database Migration Script - Updated Version
-- This script includes all original tables plus account deletion functionality

-- ------------------------------
-- Schema Creation
-- ------------------------------
CREATE SCHEMA IF NOT EXISTS api;
CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS util;
CREATE SCHEMA IF NOT EXISTS stripe;

-- ------------------------------
-- Domain Types for Common Patterns
-- ------------------------------
CREATE DOMAIN util.url AS text
CHECK (VALUE ~ '^https?://[^\s/$.?#].[^\s]*$');

CREATE DOMAIN util.email AS text
CHECK (VALUE ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');

-- ------------------------------
-- Enums
-- ------------------------------

-- Create dietary tag enum
CREATE TYPE reference.dietary_tag_type AS ENUM (
    'vegetarian', 'vegan', 'gluten-free', 'dairy-free', 'nut-free', 
    'low-carb', 'keto', 'paleo', 'pescatarian', 'whole30', 
    'sugar-free', 'low-sodium', 'high-protein', 'low-fat',
    'mediterranean', 'halal', 'kosher'
);

CREATE TYPE reference.cuisine_type AS ENUM (
    'american', 'italian', 'mexican', 'french', 'chinese', 'japanese', 
    'indian', 'thai', 'mediterranean', 'middle_eastern', 'korean', 
    'vietnamese', 'greek', 'spanish', 'german', 'brazilian', 
    'caribbean', 'british', 'irish', 'african', 'turkish', 'moroccan', 
    'swedish', 'russian', 'hungarian', 'peruvian', 'ethiopian', 
    'lebanese', 'filipino', 'malaysian', 'other'
);

CREATE TYPE reference.course_type AS ENUM (
    'appetizer', 'breakfast', 'lunch', 'dinner', 'dessert', 
    'snack', 'side', 'beverage', 'brunch', 'salad', 'soup', 'other'
);

-- New enums for updated features
CREATE TYPE reference.social_platform_type AS ENUM (
    'website', 'instagram', 'facebook', 'twitter', 'pinterest',
    'youtube', 'tiktok', 'linkedin', 'other'
);

CREATE TYPE reference.potluck_slot_type AS ENUM (
    'appetizer', 'main', 'side', 'dessert', 'drink', 'other'
);

CREATE TYPE reference.potluck_participant_role AS ENUM (
    'host', 'cohost', 'participant', 'guest'
);

CREATE TYPE reference.ai_feature_type AS ENUM (
    'url_extraction', 'text_extraction', 'image_recognition', 
    'recipe_image_generation', 'conversation'
);

CREATE TYPE reference.subscription_tier AS ENUM (
    'free', 'pro'
);

CREATE TYPE reference.subscription_status AS ENUM (
    'active', 'inactive', 'canceled', 'past_due',
    'trialing', 'incomplete', 'incomplete_expired', 'unpaid', 'paused'
);

CREATE TYPE reference.guest_conversion_status AS ENUM (
    'pending', 'converted', 'declined'
);

-- ------------------------------
-- Stripe Specific Types
-- ------------------------------

CREATE TYPE stripe.pricing_type AS ENUM ('one_time', 'recurring');
CREATE TYPE stripe.pricing_plan_interval AS ENUM ('day', 'week', 'month', 'year');

-- ------------------------------
-- Functions & Utilities
-- ------------------------------

-- Function to update the modified timestamp automatically
CREATE OR REPLACE FUNCTION util.update_modified_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION util.update_modified_column IS 'Generic trigger function to automatically update the updated_at timestamp';

-- Function to create a profile when a new user registers
CREATE OR REPLACE FUNCTION api.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  username_base TEXT;
  new_username TEXT;
  uuid_last_part TEXT;
BEGIN
  -- Extract last 4 characters of UUID
  uuid_last_part := substring(new.id::text from (length(new.id::text) - 3));
  
  -- Create base username from email if no names available
  IF new.raw_user_meta_data->>'first_name' IS NULL OR new.raw_user_meta_data->>'last_name' IS NULL THEN
    username_base := split_part(new.email, '@', 1);
  ELSE
    username_base := concat(
      lower(regexp_replace(coalesce(new.raw_user_meta_data->>'first_name', ''), '[^a-zA-Z0-9]', '', 'g')), 
      '-',
      lower(regexp_replace(coalesce(new.raw_user_meta_data->>'last_name', ''), '[^a-zA-Z0-9]', '', 'g'))
    );
  END IF;
  
  -- Combine base with UUID suffix
  new_username := concat(username_base, '-', uuid_last_part);
  
  -- Insert new profile
  INSERT INTO api.profiles (
    id, 
    first_name, 
    last_name, 
    username
  )
  VALUES (
    new.id, 
    coalesce(new.raw_user_meta_data->>'first_name', ''), 
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    new_username
  );
  
  -- Set default subscription tier to free
  INSERT INTO api.user_subscriptions (
    user_id,
    subscription_tier,
    status
  )
  VALUES (
    new.id,
    'free',
    'active'
  );
  
  RETURN new;
END;
$$;

COMMENT ON FUNCTION api.handle_new_user IS 'Creates a user profile in the api.profiles table when a new user signs up';

-- Generate a slug from recipe name
CREATE OR REPLACE FUNCTION util.generate_recipe_slug(name text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN lower(regexp_replace(name, '[^a-zA-Z0-9]', '-', 'g'));
END;
$$;

COMMENT ON FUNCTION util.generate_recipe_slug IS 'Creates a URL-friendly slug from a recipe name';

-- Transaction function to create a complete recipe with ingredients and instructions
CREATE OR REPLACE FUNCTION api.create_complete_recipe(
  recipe_data jsonb,
  ingredients_data jsonb,
  instructions_data jsonb
) 
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_recipe_id uuid;
  forked_from_id uuid := recipe_data->>'forked_from_id';
  is_fork boolean := false;
BEGIN
  -- Start transaction
  BEGIN
    -- Set is_fork flag if we have a forked_from_id
    IF forked_from_id IS NOT NULL THEN
      is_fork := true;
    END IF;
    
    -- Insert recipe
    INSERT INTO api.recipes (
      name,
      description,
      prep_time,
      cook_time,
      total_time,
      servings,
      cuisine,
      course,
      dietary_tags,
      source_url,
      image_url,
      user_id,
      forked_from_id,
      is_fork
    )
    VALUES (
      recipe_data->>'name',
      recipe_data->>'description',
      recipe_data->>'prep_time',
      recipe_data->>'cook_time',
      recipe_data->>'total_time',
      recipe_data->>'servings',
      (recipe_data->>'cuisine')::reference.cuisine_type,
      (recipe_data->>'course')::reference.course_type,
      (recipe_data->>'dietary_tags')::reference.dietary_tag_type[],
      (recipe_data->>'source_url')::util.url,
      recipe_data->>'image_url',
      auth.uid(),
      forked_from_id,
      is_fork
    )
    RETURNING id INTO new_recipe_id;
    
    -- Insert ingredients
    INSERT INTO api.ingredients (recipe_id, name, quantity, notes, sort_order)
    SELECT 
      new_recipe_id,
      ing->>'name',
      ing->>'quantity',
      ing->>'notes',
      (ing->>'sort_order')::int
    FROM jsonb_array_elements(ingredients_data) AS ing;
    
    -- Insert instructions
    INSERT INTO api.instructions (recipe_id, step_number, instruction)
    SELECT 
      new_recipe_id,
      (ins->>'step_number')::int,
      ins->>'instruction'
    FROM jsonb_array_elements(instructions_data) AS ins;
    
    -- Track AI usage if applicable
    IF recipe_data->>'ai_extraction_type' IS NOT NULL THEN
      INSERT INTO api.ai_feature_usage (
        user_id,
        feature_type,
        recipe_id
      )
      VALUES (
        auth.uid(),
        (recipe_data->>'ai_extraction_type')::reference.ai_feature_type,
        new_recipe_id
      );
    END IF;
    
    RETURN new_recipe_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Roll back the transaction if any part fails
      RAISE;
  END;
END;
$$;

COMMENT ON FUNCTION api.create_complete_recipe IS 'Creates a complete recipe with ingredients and instructions in a single transaction';

-- Function to check if user has reached free tier AI usage limits
CREATE OR REPLACE FUNCTION api.check_ai_usage_limits(user_id uuid, feature_type reference.ai_feature_type)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  subscription_tier reference.subscription_tier;
  usage_count int;
  free_tier_limit int := 10;
BEGIN
  -- Get user's subscription tier
  SELECT us.subscription_tier INTO subscription_tier
  FROM api.user_subscriptions us
  WHERE us.user_id = check_ai_usage_limits.user_id
  AND us.status = 'active'
  LIMIT 1;
  
  -- Pro users have unlimited usage
  IF subscription_tier = 'pro' THEN
    RETURN true;
  END IF;
  
  -- For free tier users, check limits
  SELECT COUNT(*) INTO usage_count
  FROM api.ai_feature_usage
  WHERE user_id = check_ai_usage_limits.user_id;
  
  -- Return true if under limit, false if at or over limit
  RETURN usage_count < free_tier_limit;
END;
$$;

COMMENT ON FUNCTION api.check_ai_usage_limits IS 'Checks if a user has reached their AI feature usage limits based on subscription tier';

-- Create a potluck event with slots
CREATE OR REPLACE FUNCTION api.create_potluck_event(
  event_data jsonb,
  slots_data jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_event_id uuid;
  new_slug text;
  host_id uuid := auth.uid();
BEGIN
  -- Start transaction
  BEGIN
    -- Generate a slug if not provided
    IF event_data->>'slug' IS NULL OR event_data->>'slug' = '' THEN
      new_slug := lower(regexp_replace(event_data->>'name', '[^a-zA-Z0-9]', '-', 'g')) || '-' || 
                  substring(extensions.uuid_generate_v4()::text, 1, 8);
    ELSE
      new_slug := event_data->>'slug';
    END IF;
    
    -- Insert the potluck event
    INSERT INTO api.potluck_events (
      name,
      slug,
      description,
      location,
      event_date,
      event_time,
      allow_custom_slots,
      custom_slots_when_full
    )
    VALUES (
      event_data->>'name',
      new_slug,
      event_data->>'description',
      event_data->>'location',
      (event_data->>'event_date')::date,
      (event_data->>'event_time')::time,
      coalesce((event_data->>'allow_custom_slots')::boolean, false),
      coalesce((event_data->>'custom_slots_when_full')::boolean, false)
    )
    RETURNING id INTO new_event_id;
    
    -- Add the host as a participant with host role
    INSERT INTO api.potluck_participants (
      event_id,
      user_id,
      role
    )
    VALUES (
      new_event_id,
      host_id,
      'host'
    );
    
    -- Insert the predefined slots
    INSERT INTO api.potluck_slots (
      event_id,
      slot_type,
      name,
      description,
      custom_slot,
      sort_order
    )
    SELECT 
      new_event_id,
      (slot->>'slot_type')::reference.potluck_slot_type,
      slot->>'name',
      slot->>'description',
      false,
      (slot->>'sort_order')::int
    FROM jsonb_array_elements(slots_data) AS slot;
    
    RETURN new_event_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Roll back the transaction if any part fails
      RAISE;
  END;
END;
$$;

COMMENT ON FUNCTION api.create_potluck_event IS 'Creates a complete potluck event with predefined slots';

-- Claim a potluck slot
CREATE OR REPLACE FUNCTION api.claim_potluck_slot(
  event_id uuid,
  slot_id uuid,
  participant_data jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_participant_id uuid;
  user_id uuid := auth.uid();
  is_guest boolean := participant_data->>'guest_email' IS NOT NULL;
  guest_id uuid;
BEGIN
  -- Check if slot is already claimed
  IF EXISTS (
    SELECT 1 FROM api.potluck_slots 
    WHERE id = slot_id AND claimed = true
  ) THEN
    RAISE EXCEPTION 'This slot has already been claimed';
  END IF;
  
  -- Start transaction
  BEGIN
    -- For guest users, create a guest record
    IF is_guest THEN
      INSERT INTO api.guest_users (
        name,
        email,
        conversion_status
      )
      VALUES (
        participant_data->>'guest_name',
        participant_data->>'guest_email',
        'pending'
      )
      RETURNING id INTO guest_id;
      
      -- Insert participant with guest info
      INSERT INTO api.potluck_participants (
        event_id,
        slot_id,
        guest_id,
        guest_name,
        guest_email,
        recipe_id,
        custom_dish_name,
        dish_description,
        dietary_info,
        comments,
        role
      )
      VALUES (
        event_id,
        slot_id,
        guest_id,
        participant_data->>'guest_name',
        participant_data->>'guest_email',
        (participant_data->>'recipe_id')::uuid,
        participant_data->>'custom_dish_name',
        participant_data->>'dish_description',
        participant_data->>'dietary_info',
        participant_data->>'comments',
        'guest'
      )
      RETURNING id INTO new_participant_id;
    ELSE
      -- Insert participant with user account
      INSERT INTO api.potluck_participants (
        event_id,
        slot_id,
        user_id,
        recipe_id,
        custom_dish_name,
        dish_description,
        dietary_info,
        comments,
        role
      )
      VALUES (
        event_id,
        slot_id,
        user_id,
        (participant_data->>'recipe_id')::uuid,
        participant_data->>'custom_dish_name',
        participant_data->>'dish_description',
        participant_data->>'dietary_info',
        participant_data->>'comments',
        'participant'
      )
      RETURNING id INTO new_participant_id;
    END IF;
    
    -- Mark the slot as claimed
    UPDATE api.potluck_slots
    SET claimed = true
    WHERE id = slot_id;
    
    RETURN new_participant_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Roll back the transaction if any part fails
      RAISE;
  END;
END;
$$;

COMMENT ON FUNCTION api.claim_potluck_slot IS 'Claims a potluck slot for a user or guest';

-- ------------------------------
-- Account Deletion Functions
-- ------------------------------

-- Export user data function
CREATE OR REPLACE FUNCTION api.export_user_data(user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    export_data jsonb;
BEGIN
    SELECT jsonb_build_object(
        'user_profile', (SELECT row_to_json(p) FROM api.profiles p WHERE p.id = user_id),
        'recipes', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'recipe', r,
                    'ingredients', (
                        SELECT jsonb_agg(row_to_json(i))
                        FROM api.ingredients i
                        WHERE i.recipe_id = r.id
                    ),
                    'instructions', (
                        SELECT jsonb_agg(row_to_json(ins) ORDER BY ins.step_number)
                        FROM api.instructions ins
                        WHERE ins.recipe_id = r.id
                    ),
                    'nutritional_info', (
                        SELECT row_to_json(n)
                        FROM api.nutritional_info n
                        WHERE n.recipe_id = r.id
                    )
                )
            )
            FROM api.recipes r
            WHERE r.user_id = export_user_data.user_id
              AND r.deleted_at IS NULL
        ),
        'shopping_lists', (
            SELECT jsonb_agg(row_to_json(sl))
            FROM api.shopping_list_items sl
            WHERE sl.user_id = export_user_data.user_id
        ),
        'meal_plans', (
            SELECT jsonb_agg(row_to_json(mp))
            FROM api.meal_plan mp
            WHERE mp.user_id = export_user_data.user_id
        ),
        'favorites', (
            SELECT jsonb_agg(row_to_json(f))
            FROM api.user_favorites f
            WHERE f.user_id = export_user_data.user_id
        )
    ) INTO export_data;
    
    RETURN export_data;
END;
$$;

COMMENT ON FUNCTION api.export_user_data IS 'Exports all user data in a structured format for data portability';

-- Account deletion function
CREATE OR REPLACE FUNCTION api.delete_user_account(
    user_id uuid,
    deletion_reason text DEFAULT NULL,
    export_data boolean DEFAULT false
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_email text;
    had_subscription boolean;
    stripe_customer_id text;
BEGIN
    -- Get user email for deletion record
    SELECT email INTO user_email FROM auth.users WHERE id = user_id;
    
    -- Check if user had an active subscription
    SELECT EXISTS (
        SELECT 1 FROM api.user_subscriptions 
        WHERE user_id = delete_user_account.user_id AND status = 'active'
    ) INTO had_subscription;
    
    -- Get Stripe customer ID if exists
    SELECT stripe_customer_id INTO stripe_customer_id 
    FROM stripe.customers 
    WHERE id = user_id;
    
    -- Record the deletion for analytics (without maintaining user reference)
    INSERT INTO api.account_deletions (
        email,
        reason,
        requested_data_export,
        subscription_cancelled
    ) VALUES (
        user_email,
        deletion_reason,
        export_data,
        had_subscription
    );
    
    -- Cancel Stripe subscription if exists
    IF had_subscription THEN
        -- Update subscription status in our database
        UPDATE api.user_subscriptions
        SET 
            status = 'canceled',
            cancelled_at = NOW()
        WHERE user_id = delete_user_account.user_id AND status = 'active';
        
        -- Note: In an actual implementation, you would make an API call to Stripe
        -- to cancel the subscription on their side as well
    END IF;
    
    -- Delete Stripe customer data if exists
    IF stripe_customer_id IS NOT NULL THEN
        DELETE FROM stripe.customer_billing WHERE user_id = delete_user_account.user_id;
        DELETE FROM stripe.customers WHERE id = delete_user_account.user_id;
        -- Note: You would also want to delete this customer in Stripe via API
    END IF;
    
    -- Delete all user data - most tables should cascade automatically
    -- due to your ON DELETE CASCADE constraints, but we'll explicitly
    -- handle the main tables to ensure complete deletion
    
    -- Delete user social links
    DELETE FROM api.user_social_links WHERE user_id = delete_user_account.user_id;
    
    -- Delete shopping list items
    DELETE FROM api.shopping_list_items WHERE user_id = delete_user_account.user_id;
    
    -- Delete meal plans
    DELETE FROM api.meal_plan WHERE user_id = delete_user_account.user_id;
    
    -- Delete potluck participants where user is the participant
    DELETE FROM api.potluck_participants WHERE user_id = delete_user_account.user_id;
    
    -- Delete potluck events hosted by the user
    -- This will cascade delete slots and participants
    DELETE FROM api.potluck_events 
    WHERE id IN (
        SELECT event_id FROM api.potluck_participants 
        WHERE user_id = delete_user_account.user_id AND role = 'host'
    );
    
    -- Delete AI conversations and related data
    DELETE FROM api.ai_conversations WHERE user_id = delete_user_account.user_id;
    DELETE FROM api.ai_feature_usage WHERE user_id = delete_user_account.user_id;
    
    -- Delete user API keys
    DELETE FROM api.user_api_keys WHERE user_id = delete_user_account.user_id;
    
    -- Delete follows
    DELETE FROM api.user_follows WHERE follower_id = delete_user_account.user_id OR followed_id = delete_user_account.user_id;
    
    -- Delete favorites
    DELETE FROM api.user_favorites WHERE user_id = delete_user_account.user_id;
    
    -- Delete recipe likes
    DELETE FROM api.recipe_likes WHERE user_id = delete_user_account.user_id;
    
    -- Delete pinned recipes
    DELETE FROM api.pinned_recipes WHERE user_id = delete_user_account.user_id;
    
    -- Delete user role mappings
    DELETE FROM api.user_role_mappings WHERE user_id = delete_user_account.user_id;
    
    -- Delete all user recipes and their components
    -- This will cascade delete ingredients, instructions, nutritional info
    DELETE FROM api.recipes WHERE user_id = delete_user_account.user_id;
    
    -- Delete user profile
    DELETE FROM api.profiles WHERE id = delete_user_account.user_id;
    
    -- Finally, delete the user from auth.users
    -- Note: In Supabase, you would typically use auth.api.delete_user() for this
    -- This is a placeholder for that call
    -- DELETE FROM auth.users WHERE id = delete_user_account.user_id;
    
    -- Return success
    RETURN true;
END;
$$;

COMMENT ON FUNCTION api.delete_user_account IS 'Completely deletes all user data from the system';

-- ------------------------------
-- Stripe Integration Functions
-- ------------------------------

-- Function to sync Stripe subscription to user_subscriptions
CREATE OR REPLACE FUNCTION stripe.sync_subscription_to_app()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert or update the user_subscriptions record
  INSERT INTO api.user_subscriptions(
    user_id,
    subscription_tier,
    status,
    payment_provider,
    subscription_id,
    stripe_subscription_id,
    stripe_price_id,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    cancelled_at
  )
  SELECT 
    sc.id, -- user_id from stripe.customers
    CASE 
      WHEN sp.metadata->>'tier' = 'pro' THEN 'pro'::reference.subscription_tier
      ELSE 'free'::reference.subscription_tier
    END,
    NEW.status,
    'stripe',
    NEW.id,
    NEW.id,
    NEW.price_id,
    NEW.current_period_start,
    NEW.current_period_end,
    NEW.cancel_at_period_end,
    NEW.canceled_at
  FROM stripe.customers sc
  LEFT JOIN stripe.prices sp ON sp.id = NEW.price_id
  WHERE sc.stripe_customer_id = (NEW.metadata->>'stripe_customer_id')
  ON CONFLICT (user_id) DO UPDATE SET
    subscription_tier = CASE 
      WHEN EXCLUDED.stripe_price_id IN (SELECT id FROM stripe.prices WHERE metadata->>'tier' = 'pro') 
      THEN 'pro'::reference.subscription_tier
      ELSE 'free'::reference.subscription_tier
    END,
    status = EXCLUDED.status,
    stripe_subscription_id = EXCLUDED.stripe_subscription_id,
    stripe_price_id = EXCLUDED.stripe_price_id,
    current_period_start = EXCLUDED.current_period_start,
    current_period_end = EXCLUDED.current_period_end,
    cancel_at_period_end = EXCLUDED.cancel_at_period_end,
    cancelled_at = EXCLUDED.cancelled_at,
    metadata = EXCLUDED.metadata,
    updated_at = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION stripe.sync_subscription_to_app IS 'Syncs Stripe subscription changes to the app subscription table';

-- Function to process Stripe webhook events
CREATE OR REPLACE FUNCTION stripe.handle_webhook_event()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle different event types
  IF NEW.event_type = 'customer.subscription.created' OR 
     NEW.event_type = 'customer.subscription.updated' THEN
    -- Extract subscription data and insert/update in subscriptions table
    INSERT INTO stripe.subscriptions (
      id,
      user_id,
      status,
      metadata,
      price_id,
      quantity,
      cancel_at_period_end,
      current_period_start,
      current_period_end,
      cancel_at,
      canceled_at
    )
    SELECT
      (NEW.data->'object'->>'id'),
      (SELECT id FROM stripe.customers WHERE stripe_customer_id = (NEW.data->'object'->>'customer')),
      (NEW.data->'object'->>'status')::reference.subscription_status,
      (NEW.data->'object'->'metadata'),
      (NEW.data->'object'->'items'->'data'->0->>'price'),
      (NEW.data->'object'->'items'->'data'->0->>'quantity')::integer,
      (NEW.data->'object'->>'cancel_at_period_end')::boolean,
      to_timestamp((NEW.data->'object'->>'current_period_start')::integer),
      to_timestamp((NEW.data->'object'->>'current_period_end')::integer),
      CASE WHEN NEW.data->'object'->>'cancel_at' IS NOT NULL 
           THEN to_timestamp((NEW.data->'object'->>'cancel_at')::integer) 
           ELSE NULL END,
      CASE WHEN NEW.data->'object'->>'canceled_at' IS NOT NULL 
           THEN to_timestamp((NEW.data->'object'->>'canceled_at')::integer) 
           ELSE NULL END
    ON CONFLICT (id) DO UPDATE SET
      status = EXCLUDED.status,
      metadata = EXCLUDED.metadata,
      price_id = EXCLUDED.price_id,
      quantity = EXCLUDED.quantity,
      cancel_at_period_end = EXCLUDED.cancel_at_period_end,
      current_period_start = EXCLUDED.current_period_start,
      current_period_end = EXCLUDED.current_period_end,
      cancel_at = EXCLUDED.cancel_at,
      canceled_at = EXCLUDED.canceled_at;
  
  ELSIF NEW.event_type = 'product.created' OR NEW.event_type = 'product.updated' THEN
    -- Handle product events
    INSERT INTO stripe.products (
      id,
      active,
      name,
      description,
      image,
      metadata
    )
    SELECT
      (NEW.data->'object'->>'id'),
      (NEW.data->'object'->>'active')::boolean,
      (NEW.data->'object'->>'name'),
      (NEW.data->'object'->>'description'),
      (NEW.data->'object'->>'images'->0),
      (NEW.data->'object'->'metadata')
    ON CONFLICT (id) DO UPDATE SET
      active = EXCLUDED.active,
      name = EXCLUDED.name,
      description = EXCLUDED.description,
      image = EXCLUDED.image,
      metadata = EXCLUDED.metadata,
      updated_at = now();
      
  ELSIF NEW.event_type = 'price.created' OR NEW.event_type = 'price.updated' THEN
    -- Handle price events
    INSERT INTO stripe.prices (
      id,
      product_id,
      active,
      description,
      unit_amount,
      currency,
      type,
      interval,
      interval_count,
      metadata
    )
    SELECT
      (NEW.data->'object'->>'id'),
      (NEW.data->'object'->>'product'),
      (NEW.data->'object'->>'active')::boolean,
      (NEW.data->'object'->>'nickname'),
      (NEW.data->'object'->>'unit_amount')::bigint,
      (NEW.data->'object'->>'currency'),
      CASE 
        WHEN NEW.data->'object'->>'type' = 'recurring' THEN 'recurring'::stripe.pricing_type
        ELSE 'one_time'::stripe.pricing_type
      END,
      CASE 
        WHEN NEW.data->'object'->'recurring'->>'interval' = 'month' THEN 'month'::stripe.pricing_plan_interval
        WHEN NEW.data->'object'->'recurring'->>'interval' = 'year' THEN 'year'::stripe.pricing_plan_interval
        WHEN NEW.data->'object'->'recurring'->>'interval' = 'week' THEN 'week'::stripe.pricing_plan_interval
        WHEN NEW.data->'object'->'recurring'->>'interval' = 'day' THEN 'day'::stripe.pricing_plan_interval
        ELSE NULL
      END,
      (NEW.data->'object'->'recurring'->>'interval_count')::integer,
      (NEW.data->'object'->'metadata')
    ON CONFLICT (id) DO UPDATE SET
      product_id = EXCLUDED.product_id,
      active = EXCLUDED.active,
      description = EXCLUDED.description,
      unit_amount = EXCLUDED.unit_amount,
      currency = EXCLUDED.currency,
      type = EXCLUDED.type,
      interval = EXCLUDED.interval,
      interval_count = EXCLUDED.interval_count,
      metadata = EXCLUDED.metadata,
      updated_at = now();
  
  ELSIF NEW.event_type = 'customer.created' OR NEW.event_type = 'customer.updated' THEN
    -- Handle customer events
    INSERT INTO stripe.customers (
      id,
      stripe_customer_id
    )
    SELECT
      (SELECT id FROM auth.users WHERE email = (NEW.data->'object'->>'email')),
      (NEW.data->'object'->>'id')
    ON CONFLICT (id) DO UPDATE SET
      stripe_customer_id = EXCLUDED.stripe_customer_id;
  END IF;
  
  -- Mark the webhook event as processed
  UPDATE stripe.webhook_events
  SET processed = true
  WHERE id = NEW.id;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and mark as failed
    UPDATE stripe.webhook_events
    SET 
      processed = true,
      processing_error = SQLERRM
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION stripe.handle_webhook_event IS 'Processes incoming Stripe webhook events';

-- ------------------------------
-- Core Tables
-- ------------------------------

-- User roles table
CREATE TABLE api.user_roles (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.user_roles IS 'Defines user roles for permission management';

-- Insert default roles
INSERT INTO api.user_roles (name, description) VALUES
('admin', 'Administrator with full system access'),
('user', 'Regular user with standard permissions')
ON CONFLICT DO NOTHING;

-- User roles mapping
CREATE TABLE api.user_role_mappings (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role_id uuid REFERENCES api.user_roles(id) ON DELETE CASCADE NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, role_id)
);

COMMENT ON TABLE api.user_role_mappings IS 'Maps users to their assigned roles';

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION util.is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM api.user_role_mappings urm
    JOIN api.user_roles ur ON urm.role_id = ur.id
    WHERE urm.user_id = user_id AND ur.name = 'admin'
  );
$$;

COMMENT ON FUNCTION util.is_admin IS 'Checks if a user has the admin role';

-- Helper function for RLS policy to check recipe ownership or admin status
CREATE OR REPLACE FUNCTION util.can_modify_recipe(recipe_owner_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (auth.uid() = recipe_owner_id OR util.is_admin(auth.uid()));
END;
$$;

COMMENT ON FUNCTION util.can_modify_recipe IS 'Checks if the current user can modify a recipe (owner or admin)';

-- Helper function for RLS policy to check user record ownership or admin status
CREATE OR REPLACE FUNCTION util.can_modify_user_record(record_owner_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (auth.uid() = record_owner_id OR util.is_admin(auth.uid()));
END;
$$;

COMMENT ON FUNCTION util.can_modify_user_record IS 'Checks if the current user can modify a user-owned record (owner or admin)';

-- User profiles table - extends auth.users
CREATE TABLE api.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username text UNIQUE NOT NULL,
    first_name text,
    last_name text,
    bio text,
    location text,
    website_url util.url,
    profile_picture text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

COMMENT ON TABLE api.profiles IS 'Extended user profile information linked to auth.users';
COMMENT ON COLUMN api.profiles.username IS 'Unique username for the user, used in URLs and mentions';
COMMENT ON COLUMN api.profiles.deleted_at IS 'Timestamp for soft deletion, NULL for active profiles';

-- Account deletions tracking table
CREATE TABLE api.account_deletions (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    email text NOT NULL,
    reason text,
    deletion_date timestamp with time zone DEFAULT now() NOT NULL,
    requested_data_export boolean DEFAULT false NOT NULL,
    subscription_cancelled boolean DEFAULT false NOT NULL
);

COMMENT ON TABLE api.account_deletions IS 'Tracks user account deletions for analytics and compliance, without maintaining user_id references';

-- New: User social links
CREATE TABLE api.user_social_links (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    platform_type reference.social_platform_type NOT NULL,
    url util.url NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.user_social_links IS 'Social media and website links for user profiles';

-- Primary recipes table
CREATE TABLE api.recipes (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL CHECK (char_length(name) >= 3 AND char_length(name) <= 100),
    slug text UNIQUE,
    description text,
    prep_time text NOT NULL,
    cook_time text NOT NULL,
    total_time text,
    servings text NOT NULL,
    cuisine reference.cuisine_type,
    course reference.course_type NOT NULL,
    dietary_tags reference.dietary_tag_type[] DEFAULT '{}',
    source_url util.url,
    image_url text,
    likes_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    -- New fields for recipe forking
    forked_from_id uuid REFERENCES api.recipes(id) ON DELETE SET NULL,
    is_fork boolean DEFAULT false NOT NULL
);

COMMENT ON TABLE api.recipes IS 'Main recipes table containing recipe metadata and user ownership';
COMMENT ON COLUMN api.recipes.slug IS 'URL-friendly identifier for the recipe';
COMMENT ON COLUMN api.recipes.deleted_at IS 'Timestamp for soft deletion, NULL for active recipes';
COMMENT ON COLUMN api.recipes.dietary_tags IS 'Array of dietary preference tags applicable to this recipe';
COMMENT ON COLUMN api.recipes.forked_from_id IS 'Original recipe ID if this is a forked/copied recipe';
COMMENT ON COLUMN api.recipes.is_fork IS 'Indicates if this recipe is a fork of another recipe';

-- Trigger to generate slug if not provided
CREATE OR REPLACE FUNCTION api.generate_recipe_slug_if_needed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    -- Extract last 4 characters of UUID
    NEW.slug := util.generate_recipe_slug(NEW.name) || '-' || 
                substring(NEW.id::text, (length(NEW.id::text) - 3));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_recipe_slug
BEFORE INSERT OR UPDATE ON api.recipes
FOR EACH ROW EXECUTE FUNCTION api.generate_recipe_slug_if_needed();

-- Recipe components

-- Ingredients for recipes
CREATE TABLE api.ingredients (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE CASCADE NOT NULL,
    name text NOT NULL CHECK (char_length(name) >= 1),
    quantity text,
    notes text,
    sort_order integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.ingredients IS 'Ingredients used in recipes';
COMMENT ON COLUMN api.ingredients.sort_order IS 'Order in which ingredients should be displayed';

-- Step-by-step cooking instructions
CREATE TABLE api.instructions (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE CASCADE NOT NULL,
    step_number integer NOT NULL CHECK (step_number > 0),
    instruction text NOT NULL CHECK (char_length(instruction) >= 5),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.instructions IS 'Step-by-step cooking instructions for recipes';

-- Simplified nutritional information
CREATE TABLE api.nutritional_info (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE CASCADE NOT NULL,
    calories text,
    protein text,
    total_fat text,
    saturated_fat text,
    cholesterol text,
    sodium text,
    total_carbohydrates text,
    dietary_fiber text,
    total_sugars text,
    vitamin_c text,
    calcium text,
    iron text,
    potassium text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.nutritional_info IS 'Nutritional information for recipes';

-- ------------------------------
-- User Interaction Tables
-- ------------------------------

-- User favorites (saved recipes)
CREATE TABLE api.user_favorites (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id uuid NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, recipe_id)
);

COMMENT ON TABLE api.user_favorites IS 'Tracks which recipes users have saved as favorites';

-- User follows (social connections)
CREATE TABLE api.user_follows (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    follower_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    followed_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE CHECK (followed_id != follower_id),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(follower_id, followed_id)
);

COMMENT ON TABLE api.user_follows IS 'Tracks social follow relationships between users';

-- Recipe likes
CREATE TABLE api.recipe_likes (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    recipe_id uuid NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, recipe_id)
);

COMMENT ON TABLE api.recipe_likes IS 'Tracks which recipes users have liked';

-- Pinned recipes (limit 3 per user)
CREATE TABLE api.pinned_recipes (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id uuid NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, recipe_id)
);

COMMENT ON TABLE api.pinned_recipes IS 'User-pinned recipes (limited to 3 per user) for quick access';

-- Create a constraint function to limit pinned recipes
CREATE OR REPLACE FUNCTION api.check_pinned_recipe_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM api.pinned_recipes WHERE user_id = NEW.user_id) >= 3 THEN
    RAISE EXCEPTION 'Users can only pin up to 3 recipes';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add the constraint trigger
CREATE TRIGGER enforce_pinned_recipe_limit
BEFORE INSERT ON api.pinned_recipes
FOR EACH ROW EXECUTE FUNCTION api.check_pinned_recipe_limit();

-- Slot-based meal planning
CREATE TABLE api.meal_plan (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE CASCADE NOT NULL,
    cooking_date date NOT NULL CHECK (cooking_date >= CURRENT_DATE),
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, cooking_date, recipe_id)
);

COMMENT ON TABLE api.meal_plan IS 'User meal planning calendar';

-- Shopping list
CREATE TABLE api.shopping_list_items (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name text NOT NULL CHECK (char_length(name) >= 2),
    quantity text,
    recipe_quantity text,
    checked boolean DEFAULT false NOT NULL,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE SET NULL,
    recipe_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sort_order integer
);

COMMENT ON TABLE api.shopping_list_items IS 'User shopping list items, optionally linked to recipes';

-- User API keys with UUID generation
CREATE TABLE api.user_api_keys (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL CHECK (char_length(name) >= 3),
    api_key uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);

COMMENT ON TABLE api.user_api_keys IS 'API keys generated for users to access the API programmatically';

-- ------------------------------
-- Feature and Subscription Tables
-- ------------------------------

-- User subscriptions
CREATE TABLE api.user_subscriptions (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_tier reference.subscription_tier NOT NULL DEFAULT 'free',
    status reference.subscription_status NOT NULL DEFAULT 'active',
    payment_provider text,
    subscription_id text,
    -- New Stripe-specific fields
    stripe_subscription_id text,
    stripe_price_id text,
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    cancel_at_period_end boolean DEFAULT false,
    cancelled_at timestamp with time zone,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id)
);

COMMENT ON TABLE api.user_subscriptions IS 'Tracks user subscription status and details';

-- AI feature usage tracking
CREATE TABLE api.ai_feature_usage (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feature_type reference.ai_feature_type NOT NULL,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE SET NULL,
    conversation_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.ai_feature_usage IS 'Tracks AI feature usage for free tier limits';

-- AI conversations 
CREATE TABLE api.ai_conversations (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL DEFAULT 'New Conversation',
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.ai_conversations IS 'Stores Recipe Assistant conversation sessions';

-- AI conversation messages
CREATE TABLE api.ai_conversation_messages (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES api.ai_conversations(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content text NOT NULL,
    image_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.ai_conversation_messages IS 'Individual messages in Recipe Assistant conversations';

-- AI-generated recipes mapping
CREATE TABLE api.ai_generated_recipes (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES api.ai_conversations(id) ON DELETE CASCADE,
    recipe_id uuid NOT NULL REFERENCES api.recipes(id) ON DELETE CASCADE,
    prompt_used text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.ai_generated_recipes IS 'Maps AI conversations to recipes generated from them';

-- Guest users (for potluck without account)
CREATE TABLE api.guest_users (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL,
    email util.email NOT NULL,
    conversion_status reference.guest_conversion_status NOT NULL DEFAULT 'pending',
    converted_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.guest_users IS 'Temporary guest users for potluck events before account creation';

-- Potluck events
CREATE TABLE api.potluck_events (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL CHECK (char_length(name) >= 3),
    slug text UNIQUE NOT NULL,
    description text,
    location text,
    event_date date NOT NULL CHECK (event_date >= CURRENT_DATE),
    event_time time,
    allow_custom_slots boolean DEFAULT false NOT NULL,
    custom_slots_when_full boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.potluck_events IS 'Potluck events for shared meal planning';
COMMENT ON COLUMN api.potluck_events.allow_custom_slots IS 'Whether guests can create custom slots not defined by host';
COMMENT ON COLUMN api.potluck_events.custom_slots_when_full IS 'Whether guests can create custom slots only when defined slots are full';

-- Potluck slots
CREATE TABLE api.potluck_slots (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES api.potluck_events(id) ON DELETE CASCADE,
    slot_type reference.potluck_slot_type NOT NULL,
    name text NOT NULL,
    description text,
    custom_slot boolean DEFAULT false NOT NULL,
    claimed boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE api.potluck_slots IS 'Defines what dish slots are available for a potluck event';
COMMENT ON COLUMN api.potluck_slots.custom_slot IS 'Whether this slot was created by a guest rather than the host';

-- Potluck participants
CREATE TABLE api.potluck_participants (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES api.potluck_events(id) ON DELETE CASCADE,
    slot_id uuid REFERENCES api.potluck_slots(id) ON DELETE SET NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    guest_id uuid REFERENCES api.guest_users(id) ON DELETE SET NULL,
    guest_name text,
    guest_email util.email,
    recipe_id uuid REFERENCES api.recipes(id) ON DELETE SET NULL,
    custom_dish_name text,
    dish_description text,
    dietary_info text,
    comments text,
    role reference.potluck_participant_role NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CHECK ((user_id IS NOT NULL AND guest_id IS NULL) OR (user_id IS NULL AND guest_id IS NOT NULL))
);

COMMENT ON TABLE api.potluck_participants IS 'People attending potluck events, including hosts, cohosts, and guests';
COMMENT ON COLUMN api.potluck_participants.role IS 'Role of the participant (host, cohost, participant, guest)';

-- ------------------------------
-- Stripe Schema Tables
-- ------------------------------

-- Map Supabase users to Stripe customers
CREATE TABLE stripe.customers (
    id uuid REFERENCES auth.users(id) NOT NULL PRIMARY KEY,
    stripe_customer_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE stripe.customers IS 'Maps Supabase users to Stripe customer IDs';

-- Stripe products
CREATE TABLE stripe.products (
    id text PRIMARY KEY,
    active boolean,
    name text,
    description text,
    image text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE stripe.products IS 'Products synchronized from Stripe';

-- Stripe prices
CREATE TABLE stripe.prices (
    id text PRIMARY KEY,
    product_id text REFERENCES stripe.products,
    active boolean,
    description text,
    unit_amount bigint,
    currency text CHECK (char_length(currency) = 3),
    type stripe.pricing_type,
    interval stripe.pricing_plan_interval,
    interval_count integer,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE stripe.prices IS 'Prices synchronized from Stripe';

-- Stripe subscriptions
CREATE TABLE stripe.subscriptions (
    id text PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) NOT NULL,
    status reference.subscription_status,
    metadata jsonb,
    price_id text REFERENCES stripe.prices,
    quantity integer,
    cancel_at_period_end boolean,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    current_period_start timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    current_period_end timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    ended_at timestamp with time zone,
    cancel_at timestamp with time zone,
    canceled_at timestamp with time zone
);

COMMENT ON TABLE stripe.subscriptions IS 'Subscriptions synchronized from Stripe';

-- Customer billing details
CREATE TABLE stripe.customer_billing (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    billing_address jsonb,
    payment_method jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE stripe.customer_billing IS 'Stores customer billing addresses and payment methods';

-- Stripe webhook events
CREATE TABLE stripe.webhook_events (
    id text PRIMARY KEY,
    event_type text NOT NULL,
    api_version text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb,
    processed boolean DEFAULT false,
    processing_error text
);

COMMENT ON TABLE stripe.webhook_events IS 'Records Stripe webhook events for processing';

-- Check constraint function for custom slots
CREATE OR REPLACE FUNCTION api.check_custom_slot_allowed()
RETURNS TRIGGER AS $$
DECLARE
  allow_custom boolean;
  custom_when_full boolean;
  all_slots_filled boolean;
BEGIN
  -- Get the potluck event settings
  SELECT 
    pe.allow_custom_slots,
    pe.custom_slots_when_full
  INTO
    allow_custom,
    custom_when_full
  FROM api.potluck_events pe
  WHERE pe.id = NEW.event_id;
  
  -- If this is a custom slot, check if it's allowed
  IF NEW.custom_slot = true THEN
    -- If custom slots are always allowed, we're good
    IF allow_custom = true THEN
      RETURN NEW;
    END IF;
    
    -- If custom slots are allowed when all other slots are filled
    IF custom_when_full = true THEN
      -- Check if all non-custom slots are claimed
      SELECT COUNT(*) = 0 INTO all_slots_filled
      FROM api.potluck_slots ps
      WHERE ps.event_id = NEW.event_id
      AND ps.custom_slot = false
      AND ps.claimed = false;
      
      IF all_slots_filled THEN
        RETURN NEW;
      ELSE
        RAISE EXCEPTION 'Custom slots are only allowed when all predefined slots are filled';
      END IF;
    END IF;
    
    -- If we get here, custom slots aren't allowed
    RAISE EXCEPTION 'Custom slots are not allowed for this potluck event';
  END IF;
  
  -- For non-custom slots, always allow
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce custom slot rules
CREATE TRIGGER enforce_custom_slot_rules
BEFORE INSERT ON api.potluck_slots
FOR EACH ROW EXECUTE FUNCTION api.check_custom_slot_allowed();

-- ------------------------------
-- Reference Data
-- ------------------------------

-- Create daily value reference table
CREATE TABLE reference.daily_nutritional_values (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    nutrient_name text NOT NULL,
    daily_value text NOT NULL,
    unit text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(nutrient_name)
);

COMMENT ON TABLE reference.daily_nutritional_values IS 'Reference data for recommended daily nutritional values';

-- ------------------------------
-- Storage bucket setup
-- ------------------------------

-- Recipe images storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('recipe-images', 'Recipe Images', true)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE storage.objects IS '
Storage organization:
- recipe-images bucket: 
  - /{user_id}/{recipe_id}/{filename} - Primary recipe images
  - /{user_id}/temp/{unique_id}-{filename} - Temporary uploads before association

- profile-images bucket:
  - /{user_id}/avatar.{jpg|png} - User profile pictures
  - /{user_id}/header.{jpg|png} - User profile header images

- ai-uploads bucket:
  - /{user_id}/conversation/{conversation_id}/{message_id}-{filename} - Images uploaded in Recipe Assistant conversations
';

-- User profile images storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'Profile Images', true)
ON CONFLICT DO NOTHING;

-- AI conversation uploads bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('ai-uploads', 'AI Assistant Uploads', true)
ON CONFLICT DO NOTHING;

-- ------------------------------
-- Views
-- ------------------------------

-- Optimized recipe details view
CREATE VIEW api.recipe_details AS
WITH recipe_ingredients AS (
  SELECT 
    recipe_id, 
    jsonb_agg(
      jsonb_build_object(
        'id', id, 
        'name', name, 
        'quantity', quantity, 
        'notes', notes
      ) ORDER BY sort_order
    ) AS ingredients
  FROM api.ingredients
  GROUP BY recipe_id
),
recipe_instructions AS (
  SELECT 
    recipe_id, 
    jsonb_agg(
      jsonb_build_object(
        'id', id, 
        'step_number', step_number, 
        'instruction', instruction
      ) ORDER BY step_number
    ) AS instructions
  FROM api.instructions
  GROUP BY recipe_id
)
SELECT 
    r.id,
    r.name,
    r.slug,
    r.description,
    r.prep_time,
    r.cook_time,
    r.total_time,
    r.servings,
    r.cuisine,
    r.course,
    r.dietary_tags,
    r.source_url,
    r.image_url,
    r.likes_count,
    r.created_at,
    r.updated_at,
    r.user_id,
    r.forked_from_id,
    r.is_fork,
    p.username AS added_by_username,
    ((p.first_name || ' '::text) || p.last_name) AS added_by_name,
    EXISTS(SELECT 1 FROM api.pinned_recipes pr WHERE pr.recipe_id = r.id AND pr.user_id = auth.uid()) AS is_pinned,
    COALESCE(ri.ingredients, '[]'::jsonb) AS ingredients,
    COALESCE(rn.instructions, '[]'::jsonb) AS instructions,
    jsonb_build_object(
        'calories', ni.calories, 
        'protein', ni.protein, 
        'total_fat', ni.total_fat, 
        'saturated_fat', ni.saturated_fat, 
        'cholesterol', ni.cholesterol, 
        'sodium', ni.sodium, 
        'total_carbohydrates', ni.total_carbohydrates, 
        'dietary_fiber', ni.dietary_fiber, 
        'total_sugars', ni.total_sugars,
        'vitamin_c', ni.vitamin_c, 
        'calcium', ni.calcium, 
        'iron', ni.iron, 
        'potassium', ni.potassium
    ) AS nutritional_info,
    CASE
      WHEN r.forked_from_id IS NOT NULL THEN
        (SELECT p2.username FROM api.recipes r2 JOIN api.profiles p2 ON r2.user_id = p2.id WHERE r2.id = r.forked_from_id)
      ELSE NULL
    END AS forked_from_username,
    (SELECT COUNT(*) FROM api.recipes WHERE forked_from_id = r.id) AS fork_count
FROM 
    api.recipes r
    LEFT JOIN api.profiles p ON r.user_id = p.id
    LEFT JOIN api.nutritional_info ni ON r.id = ni.recipe_id
    LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
    LEFT JOIN recipe_instructions rn ON r.id = rn.recipe_id
WHERE 
    r.deleted_at IS NULL;

COMMENT ON VIEW api.recipe_details IS 'Comprehensive view of recipes with related ingredients, instructions, and nutritional info';

-- User's favorite recipes view
CREATE VIEW api.user_favorite_recipes AS
SELECT 
    f.id AS favorite_id,
    f.user_id,
    r.id AS recipe_id,
    r.name,
    r.slug,
    r.description,
    r.image_url,
    r.cook_time,
    r.prep_time,
    r.cuisine,
    r.course,
    f.created_at AS favorited_at
FROM 
    api.user_favorites f
JOIN 
    api.recipes r ON f.recipe_id = r.id
WHERE 
    r.deleted_at IS NULL;

COMMENT ON VIEW api.user_favorite_recipes IS 'User-favorited recipes with essential recipe information';

-- User's pinned recipes view
CREATE VIEW api.user_pinned_recipes AS
SELECT 
    pr.id AS pin_id,
    pr.user_id,
    r.id AS recipe_id,
    r.name,
    r.slug,
    r.description,
    r.image_url,
    r.cook_time,
    r.prep_time,
    r.cuisine,
    r.course,
    pr.created_at AS pinned_at
FROM 
    api.pinned_recipes pr
JOIN 
    api.recipes r ON pr.recipe_id = r.id
WHERE 
    r.deleted_at IS NULL;

COMMENT ON VIEW api.user_pinned_recipes IS 'User-pinned recipes (limited to 3) with essential recipe information';

-- User with roles view
CREATE VIEW api.users_with_roles AS
SELECT 
    p.id,
    p.username,
    p.first_name,
    p.last_name,
    p.profile_picture,
    array_agg(r.name) AS roles
FROM 
    api.profiles p
LEFT JOIN 
    api.user_role_mappings m ON p.id = m.user_id
LEFT JOIN 
    api.user_roles r ON m.role_id = r.id
WHERE 
    p.deleted_at IS NULL
GROUP BY 
    p.id, p.username, p.first_name, p.last_name, p.profile_picture;

COMMENT ON VIEW api.users_with_roles IS 'User profiles with their assigned roles';

-- Forked recipes view
CREATE VIEW api.forked_recipes AS
SELECT 
    r.id,
    r.name,
    r.slug,
    r.description,
    r.user_id,
    p.username AS added_by_username,
    r.created_at,
    r.forked_from_id,
    r.is_fork,
    r2.name AS original_recipe_name,
    r2.slug AS original_recipe_slug,
    p2.username AS original_recipe_username,
    p2.id AS original_recipe_user_id
FROM 
    api.recipes r
JOIN 
    api.profiles p ON r.user_id = p.id
LEFT JOIN 
    api.recipes r2 ON r.forked_from_id = r2.id
LEFT JOIN 
    api.profiles p2 ON r2.user_id = p2.id
WHERE 
    r.is_fork = true
    AND r.deleted_at IS NULL;

COMMENT ON VIEW api.forked_recipes IS 'Shows recipe fork relationships with original recipe details';

-- User potluck events view
CREATE VIEW api.user_potluck_events AS
SELECT 
    pe.id,
    pe.name,
    pe.slug,
    pe.description,
    pe.location,
    pe.event_date,
    pe.event_time,
    pe.created_at,
    pp.user_id,
    pp.role,
    CASE 
        WHEN pp.role = 'host' THEN true
        WHEN pp.role = 'cohost' THEN true
        ELSE false
    END AS can_edit,
    (SELECT COUNT(*) FROM api.potluck_slots ps WHERE ps.event_id = pe.id) AS slot_count,
    (SELECT COUNT(*) FROM api.potluck_slots ps WHERE ps.event_id = pe.id AND ps.claimed = true) AS filled_slot_count
FROM 
    api.potluck_events pe
JOIN 
    api.potluck_participants pp ON pe.id = pp.event_id
WHERE 
    pp.user_id IS NOT NULL;

COMMENT ON VIEW api.user_potluck_events IS 'Shows potluck events where the user is a host, cohost, or participant';

-- User subscription details view
CREATE VIEW api.user_subscription_details AS
SELECT 
    us.id,
    us.user_id,
    us.subscription_tier,
    us.status,
    us.payment_provider,
    us.current_period_start,
    us.current_period_end,
    us.cancel_at_period_end,
    CASE 
        WHEN us.subscription_tier = 'free' THEN 0
        WHEN us.status = 'active' AND us.subscription_tier = 'pro' THEN
            CASE 
                WHEN sp.interval = 'month' THEN sp.unit_amount / 100
                WHEN sp.interval = 'year' THEN (sp.unit_amount / 100) / 12
                ELSE 0
            END
        ELSE 0
    END AS monthly_cost,
    sp.currency,
    sp.interval as billing_interval,
    p.name as product_name,
    p.description as product_description
FROM 
    api.user_subscriptions us
LEFT JOIN 
    stripe.prices sp ON us.stripe_price_id = sp.id
LEFT JOIN 
    stripe.products p ON sp.product_id = p.id;

COMMENT ON VIEW api.user_subscription_details IS 'User subscription details with pricing information';

-- ------------------------------
-- Indexes
-- ------------------------------

-- Performance indexes
CREATE INDEX idx_ingredients_recipe_id ON api.ingredients(recipe_id);
CREATE INDEX idx_instructions_recipe_id ON api.instructions(recipe_id);
CREATE INDEX idx_meal_plan_date ON api.meal_plan(cooking_date);
CREATE INDEX idx_meal_plan_user_id ON api.meal_plan(user_id);
CREATE INDEX idx_recipes_course ON api.recipes(course);
CREATE INDEX idx_recipes_cuisine ON api.recipes(cuisine);
CREATE INDEX idx_recipes_user_id ON api.recipes(user_id);
CREATE INDEX idx_recipes_deleted_at ON api.recipes(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_recipes_slug ON api.recipes(slug);
CREATE INDEX idx_shopping_list_user_id ON api.shopping_list_items(user_id);
CREATE INDEX idx_user_follows_followed_id ON api.user_follows(followed_id);
CREATE INDEX idx_user_follows_follower_id ON api.user_follows(follower_id);
CREATE INDEX idx_recipe_likes_recipe_id ON api.recipe_likes(recipe_id);
CREATE INDEX idx_recipe_likes_user_id ON api.recipe_likes(user_id);
CREATE INDEX idx_user_api_keys_user_id ON api.user_api_keys(user_id);
CREATE INDEX idx_pinned_recipes_user_id ON api.pinned_recipes(user_id);
CREATE INDEX idx_pinned_recipes_recipe_id ON api.pinned_recipes(recipe_id);

-- New indexes for added tables
CREATE INDEX idx_user_social_links_user_id ON api.user_social_links(user_id);
CREATE INDEX idx_user_subscriptions_user_id ON api.user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_stripe_id ON api.user_subscriptions(stripe_subscription_id);
CREATE INDEX idx_ai_feature_usage_user_id ON api.ai_feature_usage(user_id);
CREATE INDEX idx_ai_conversations_user_id ON api.ai_conversations(user_id);
CREATE INDEX idx_ai_conversation_messages_conversation_id ON api.ai_conversation_messages(conversation_id);
CREATE INDEX idx_ai_generated_recipes_conversation_id ON api.ai_generated_recipes(conversation_id);
CREATE INDEX idx_ai_generated_recipes_recipe_id ON api.ai_generated_recipes(recipe_id);
CREATE INDEX idx_potluck_events_event_date ON api.potluck_events(event_date);
CREATE INDEX idx_potluck_slots_event_id ON api.potluck_slots(event_id);
CREATE INDEX idx_potluck_slots_claimed ON api.potluck_slots(claimed);
CREATE INDEX idx_potluck_participants_event_id ON api.potluck_participants(event_id);
CREATE INDEX idx_potluck_participants_user_id ON api.potluck_participants(user_id);
CREATE INDEX idx_potluck_participants_guest_id ON api.potluck_participants(guest_id);
CREATE INDEX idx_guest_users_email ON api.guest_users(email);
CREATE INDEX idx_recipes_forked_from_id ON api.recipes(forked_from_id) WHERE forked_from_id IS NOT NULL;
CREATE INDEX idx_account_deletions_email ON api.account_deletions(email);

-- Stripe indexes
CREATE INDEX idx_stripe_customers_customer_id ON stripe.customers(stripe_customer_id);
CREATE INDEX idx_stripe_prices_product_id ON stripe.prices(product_id);
CREATE INDEX idx_stripe_subscriptions_user_id ON stripe.subscriptions(user_id);
CREATE INDEX idx_stripe_webhook_events_processed ON stripe.webhook_events(processed);
CREATE INDEX idx_stripe_webhook_events_type ON stripe.webhook_events(event_type);
CREATE INDEX idx_stripe_customer_billing_user_id ON stripe.customer_billing(user_id);

-- Full text search indexing
CREATE INDEX idx_recipes_fts ON api.recipes 
  USING gin(to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, '')));

CREATE INDEX idx_potluck_events_fts ON api.potluck_events
  USING gin(to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(location, '')));

-- Array indexes
CREATE INDEX idx_recipes_dietary_tags ON api.recipes USING gin(dietary_tags);

-- Partial indexes for frequently filtered conditions
CREATE INDEX idx_active_recipes ON api.recipes(user_id, created_at)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_recent_recipes ON api.recipes(created_at)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_popular_recipes ON api.recipes(likes_count)
  WHERE deleted_at IS NULL AND likes_count > 10;

CREATE INDEX idx_shopping_checked_items ON api.shopping_list_items(user_id, checked)
  WHERE checked = true;

CREATE INDEX idx_forked_recipes ON api.recipes(user_id)
  WHERE is_fork = true;

CREATE INDEX idx_upcoming_potlucks ON api.potluck_events(event_date);

CREATE INDEX idx_active_subscriptions ON api.user_subscriptions(user_id)
  WHERE status = 'active';

-- ------------------------------
-- Triggers
-- ------------------------------

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION api.handle_new_user();

-- Triggers to maintain updated_at timestamps
CREATE TRIGGER update_profiles_modtime
  BEFORE UPDATE ON api.profiles
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_user_social_links_modtime
  BEFORE UPDATE ON api.user_social_links
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_recipes_modtime
  BEFORE UPDATE ON api.recipes
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_meal_plan_modtime
  BEFORE UPDATE ON api.meal_plan
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_shopping_list_modtime
  BEFORE UPDATE ON api.shopping_list_items
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_ingredients_modtime
  BEFORE UPDATE ON api.ingredients
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_instructions_modtime
  BEFORE UPDATE ON api.instructions
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_user_api_keys_modtime
  BEFORE UPDATE ON api.user_api_keys
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_pinned_recipes_modtime
  BEFORE UPDATE ON api.pinned_recipes
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_user_subscriptions_modtime
  BEFORE UPDATE ON api.user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_ai_conversations_modtime
  BEFORE UPDATE ON api.ai_conversations
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_potluck_events_modtime
  BEFORE UPDATE ON api.potluck_events
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_potluck_slots_modtime
  BEFORE UPDATE ON api.potluck_slots
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_potluck_participants_modtime
  BEFORE UPDATE ON api.potluck_participants
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_stripe_products_modtime
  BEFORE UPDATE ON stripe.products
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_stripe_prices_modtime
  BEFORE UPDATE ON stripe.prices
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

CREATE TRIGGER update_stripe_customer_billing_modtime
  BEFORE UPDATE ON stripe.customer_billing
  FOR EACH ROW EXECUTE FUNCTION util.update_modified_column();

-- Trigger to update recipe likes counter
CREATE OR REPLACE FUNCTION api.update_recipe_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE api.recipes 
    SET likes_count = likes_count + 1
    WHERE id = NEW.recipe_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE api.recipes 
    SET likes_count = greatest(0, likes_count - 1)
    WHERE id = OLD.recipe_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_recipe_likes_count
AFTER INSERT OR DELETE ON api.recipe_likes
FOR EACH ROW EXECUTE FUNCTION api.update_recipe_likes_count();

-- Track AI usage
CREATE OR REPLACE FUNCTION api.track_ai_conversation_usage()
RETURNS TRIGGER AS $$
BEGIN
  -- Only track user messages (not system or assistant)
  IF NEW.role = 'user' THEN
    INSERT INTO api.ai_feature_usage (
      user_id,
      feature_type,
      conversation_id
    )
    SELECT 
      user_id,
      'conversation',
      NEW.conversation_id
    FROM api.ai_conversations
    WHERE id = NEW.conversation_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_ai_conversation_usage
AFTER INSERT ON api.ai_conversation_messages
FOR EACH ROW EXECUTE FUNCTION api.track_ai_conversation_usage();

-- Enforce AI usage limits for free tier
CREATE OR REPLACE FUNCTION api.enforce_ai_usage_limits()
RETURNS TRIGGER AS $$
DECLARE
  can_use boolean;
BEGIN
  -- Check if user can use this AI feature
  SELECT api.check_ai_usage_limits(NEW.user_id, NEW.feature_type) INTO can_use;
  
  IF NOT can_use THEN
    RAISE EXCEPTION 'You have reached your AI usage limit. Please upgrade to Pro for unlimited AI features.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_ai_usage_limits
BEFORE INSERT ON api.ai_feature_usage
FOR EACH ROW EXECUTE FUNCTION api.enforce_ai_usage_limits();

-- Stripe webhook processing trigger
CREATE TRIGGER process_stripe_webhook_event
AFTER INSERT ON stripe.webhook_events
FOR EACH ROW EXECUTE FUNCTION stripe.handle_webhook_event();

-- Sync Stripe subscription changes to app
CREATE TRIGGER on_stripe_subscription_change
AFTER INSERT OR UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION stripe.sync_subscription_to_app();

-- ------------------------------
-- Row Level Security
-- ------------------------------

-- Enable RLS on all tables
ALTER TABLE api.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.instructions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.meal_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.nutritional_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.shopping_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_role_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.recipe_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.pinned_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reference.daily_nutritional_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.account_deletions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on feature tables
ALTER TABLE api.user_social_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.ai_feature_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.ai_conversation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.ai_generated_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.guest_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potluck_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potluck_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.potluck_participants ENABLE ROW LEVEL SECURITY;

-- Enable RLS on Stripe tables
ALTER TABLE stripe.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.customer_billing ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.webhook_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------
-- RLS Policies
-- ------------------------------

-- Public tables: viewable by everyone but editable by owner or admin

-- Profiles policies
CREATE POLICY "Profiles are viewable by anyone" ON api.profiles
  FOR SELECT USING (true);

CREATE POLICY "Profiles can be updated by owner" ON api.profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Profiles are insertable by owner" ON api.profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- Account deletions policies
CREATE POLICY "Account deletions viewable by admin" ON api.account_deletions
  FOR SELECT USING (util.is_admin(auth.uid()));

CREATE POLICY "Account deletions insertable by calling function" ON api.account_deletions
  FOR INSERT WITH CHECK (true);

-- User social links policies
CREATE POLICY "Social links are viewable by anyone" ON api.user_social_links
  FOR SELECT USING (true);

CREATE POLICY "Social links are insertable by owner" ON api.user_social_links
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Social links are updatable by owner" ON api.user_social_links
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Social links are deletable by owner" ON api.user_social_links
  FOR DELETE USING (user_id = auth.uid());

-- Recipe policies
CREATE POLICY "Recipes are viewable by anyone" ON api.recipes
  FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Recipes are insertable by authenticated users" ON api.recipes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND user_id = auth.uid());

CREATE POLICY "Recipes are updatable by owner or admin" ON api.recipes
  FOR UPDATE USING (util.can_modify_recipe(user_id));

CREATE POLICY "Recipes are deletable by owner or admin" ON api.recipes
  FOR DELETE USING (util.can_modify_recipe(user_id));

-- Ingredients policies
CREATE POLICY "Ingredients are viewable by anyone" ON api.ingredients
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM api.recipes 
      WHERE id = recipe_id 
      AND deleted_at IS NULL
    )
  );

CREATE POLICY "Ingredients are insertable by recipe owner" ON api.ingredients
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND user_id = auth.uid()
  ));

CREATE POLICY "Ingredients are updatable by recipe owner or admin" ON api.ingredients
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND util.can_modify_recipe(user_id)
  ));

CREATE POLICY "Ingredients are deletable by recipe owner or admin" ON api.ingredients
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND util.can_modify_recipe(user_id)
  ));

-- Instructions policies
CREATE POLICY "Instructions are viewable by anyone" ON api.instructions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM api.recipes 
      WHERE id = recipe_id 
      AND deleted_at IS NULL
    )
  );

CREATE POLICY "Instructions are insertable by recipe owner" ON api.instructions
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND user_id = auth.uid()
  ));

CREATE POLICY "Instructions are updatable by recipe owner or admin" ON api.instructions
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND util.can_modify_recipe(user_id)
  ));

CREATE POLICY "Instructions are deletable by recipe owner or admin" ON api.instructions
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND util.can_modify_recipe(user_id)
  ));

-- Nutritional info policies
CREATE POLICY "Nutritional info is viewable by anyone" ON api.nutritional_info
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM api.recipes 
      WHERE id = recipe_id 
      AND deleted_at IS NULL
    )
  );

CREATE POLICY "Nutritional info is insertable by recipe owner" ON api.nutritional_info
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND user_id = auth.uid()
  ));

CREATE POLICY "Nutritional info is updatable by recipe owner or admin" ON api.nutritional_info
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM api.recipes WHERE id = recipe_id AND util.can_modify_recipe(user_id)
  ));

-- User follows policies
CREATE POLICY "User follows are viewable by anyone" ON api.user_follows
  FOR SELECT USING (true);

CREATE POLICY "Follows are insertable by follower" ON api.user_follows
  FOR INSERT WITH CHECK (follower_id = auth.uid());

CREATE POLICY "Follows are deletable by follower" ON api.user_follows
  FOR DELETE USING (follower_id = auth.uid());

-- Pinned recipes policies
CREATE POLICY "Pinned recipes are viewable by anyone" ON api.pinned_recipes
  FOR SELECT USING (true);

CREATE POLICY "Pinned recipes are insertable by owner" ON api.pinned_recipes
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Pinned recipes are updatable by owner" ON api.pinned_recipes
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Pinned recipes are deletable by owner" ON api.pinned_recipes
  FOR DELETE USING (user_id = auth.uid());

-- Potluck events policies
CREATE POLICY "Potluck events are viewable by anyone" ON api.potluck_events
  FOR SELECT USING (true);

CREATE POLICY "Potluck events are insertable by authenticated users" ON api.potluck_events
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Potluck events are updatable by hosts or admin" ON api.potluck_events
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    ) OR util.is_admin(auth.uid())
  );

CREATE POLICY "Potluck events are deletable by hosts or admin" ON api.potluck_events
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = id
      AND user_id = auth.uid()
      AND role = 'host'
    ) OR util.is_admin(auth.uid())
  );

-- Potluck slots policies
CREATE POLICY "Potluck slots are viewable by anyone" ON api.potluck_slots
  FOR SELECT USING (true);

CREATE POLICY "Potluck slots are insertable by hosts or participants based on rules" ON api.potluck_slots
  FOR INSERT WITH CHECK (
    -- Hosts and cohosts can always add slots
    EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
    -- For custom slots by participants, rules are enforced by trigger
    OR (
      NEW.custom_slot = true
      AND EXISTS (
        SELECT 1 FROM api.potluck_events
        WHERE id = NEW.event_id
        AND (allow_custom_slots = true OR custom_slots_when_full = true)
      )
    )
  );

CREATE POLICY "Potluck slots are updatable by hosts or cohosts" ON api.potluck_slots
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
  );

CREATE POLICY "Potluck slots are deletable by hosts or cohosts" ON api.potluck_slots
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
  );

-- Potluck participants policies
CREATE POLICY "Potluck participants are viewable by anyone" ON api.potluck_participants
  FOR SELECT USING (true);

CREATE POLICY "Participants can be added by hosts or self" ON api.potluck_participants
  FOR INSERT WITH CHECK (
    -- Adding self
    user_id = auth.uid()
    -- Adding as host/cohost
    OR EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
  );

CREATE POLICY "Participants can be updated by self or hosts" ON api.potluck_participants
  FOR UPDATE USING (
    -- Self
    user_id = auth.uid()
    -- Host/cohost
    OR EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
  );

CREATE POLICY "Participants can be deleted by self or hosts" ON api.potluck_participants
  FOR DELETE USING (
    -- Self
    user_id = auth.uid()
    -- Host/cohost
    OR EXISTS (
      SELECT 1 FROM api.potluck_participants
      WHERE event_id = event_id
      AND user_id = auth.uid()
      AND role IN ('host', 'cohost')
    )
  );

-- Reference data policies
CREATE POLICY "Nutritional reference data is viewable by anyone" ON reference.daily_nutritional_values
  FOR SELECT USING (true);

-- Guest users policies
CREATE POLICY "Guest users are viewable by anyone" ON api.guest_users
  FOR SELECT USING (true);

CREATE POLICY "Guest users are insertable by anyone" ON api.guest_users
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Guest users are updatable by admin" ON api.guest_users
  FOR UPDATE USING (util.is_admin(auth.uid()));

-- User subscriptions policies
CREATE POLICY "User subscriptions viewable by self" ON api.user_subscriptions
  FOR SELECT USING (user_id = auth.uid() OR util.is_admin(auth.uid()));

CREATE POLICY "User subscriptions updatable by admin" ON api.user_subscriptions
  FOR UPDATE USING (util.is_admin(auth.uid()));

-- Stripe table policies
CREATE POLICY "Stripe products viewable by anyone" ON stripe.products
  FOR SELECT USING (true);

CREATE POLICY "Stripe prices viewable by anyone" ON stripe.prices
  FOR SELECT USING (true);

CREATE POLICY "Stripe subscriptions viewable by self" ON stripe.subscriptions
  FOR SELECT USING (user_id = auth.uid() OR util.is_admin(auth.uid()));

CREATE POLICY "Stripe customer billing viewable by self" ON stripe.customer_billing
  FOR SELECT USING (user_id = auth.uid() OR util.is_admin(auth.uid()));

CREATE POLICY "Stripe customer billing updatable by self" ON stripe.customer_billing
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Stripe customer billing insertable by self" ON stripe.customer_billing
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- No direct access to customers or webhook events (managed by backend only)

-- ------------------------------
-- Realtime Publications
-- ------------------------------

-- Drop existing publication if needed
DROP PUBLICATION IF EXISTS supabase_realtime;
DROP PUBLICATION IF EXISTS stripe_realtime;

-- Create publications for realtime updates
CREATE PUBLICATION supabase_realtime FOR TABLE 
  api.recipes,
  api.profiles,
  api.potluck_events,
  api.potluck_slots,
  api.potluck_participants;

CREATE PUBLICATION stripe_realtime FOR TABLE 
  stripe.products, 
  stripe.prices,
  stripe.subscriptions,
  api.user_subscriptions;