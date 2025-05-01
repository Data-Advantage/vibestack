-- seed.sql
-- This file populates reference tables with essential data for LaunchWeek.ai
-- Only includes lookup data - no user data or user-generated content

-- Clean and reload reference data (safely - only if the tables exist)
DO $$
BEGIN
    -- Note: We're not truncating enum types since they can't be truncated
    -- We only truncate actual tables with data

    -- Drop stripe.subscription_benefits if it exists (deprecated - using config.subscription_benefits instead)
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'stripe' AND table_name = 'subscription_benefits') THEN
        DROP TABLE stripe.subscription_benefits CASCADE;
    END IF;
    
    -- Clear config.subscription_benefits if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'config' AND table_name = 'subscription_benefits') THEN
        TRUNCATE config.subscription_benefits CASCADE;
    END IF;
    
    -- Clear config.credit_packages if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'config' AND table_name = 'credit_packages') THEN
        TRUNCATE config.credit_packages CASCADE;
    END IF;
END
$$;

-- =========================================================
-- Credit Packages
-- =========================================================

-- Initialize default credit packages
INSERT INTO config.credit_packages (name, credits, price_cents, is_active)
VALUES 
  ('3-Pack', 3, 5000, true),
  ('10-Pack', 10, 12500, true);

-- =========================================================
-- Stripe Product and Subscription Data
-- =========================================================

-- Products for our credit packs and access tiers
INSERT INTO stripe.products (id, name, description, active, created_at, updated_at) VALUES
('prod_launchweek_free', 'LaunchWeek Free', 'Basic access with 1 free project credit', TRUE, NOW(), NOW()),
('prod_launchweek_3pack', 'LaunchWeek 3-Pack', 'Three additional project credits', TRUE, NOW(), NOW()),
('prod_launchweek_10pack', 'LaunchWeek 10-Pack', 'Ten additional project credits with discount', TRUE, NOW(), NOW());

-- Prices for our credit packs
INSERT INTO stripe.prices (id, product_id, active, currency, unit_amount, type, interval, created_at, updated_at) VALUES
-- Free tier has no price
('price_free_0', 'prod_launchweek_free', TRUE, 'usd', 0, 'one_time', NULL, NOW(), NOW()),
-- 3-Pack credit purchase ($50)
('price_3pack_50', 'prod_launchweek_3pack', TRUE, 'usd', 5000, 'one_time', NULL, NOW(), NOW()),
-- 10-Pack credit purchase ($125)
('price_10pack_125', 'prod_launchweek_10pack', TRUE, 'usd', 12500, 'one_time', NULL, NOW(), NOW());

-- Subscription benefits - defines what each tier provides
INSERT INTO config.subscription_benefits (id, tier_name, monthly_price, yearly_price, max_projects, max_ai_conversations, has_priority_support, has_advanced_features, features, created_at, updated_at) VALUES
-- Free tier: Unlimited PRDs, 1 free project credit
(gen_random_uuid(), 'Free', 0, 0, NULL, NULL, FALSE, FALSE, 
 '{"unlimited_prds": true, "free_project_credit": 1}', NOW(), NOW()),
-- Premium features are enabled by purchasing credit packs
(gen_random_uuid(), 'Credit User', NULL, NULL, NULL, NULL, TRUE, TRUE, 
 '{"unlimited_prds": true, "feedback_collection": true, "prototype_sharing": true}', NOW(), NOW());

-- =========================================================
-- Framework Definitions and Implementation Guides
-- =========================================================

-- This table would store structured data about each framework day  
-- Currently not implemented as its own table, but we could add it in the future
-- For now, this content would be hardcoded in the application

-- =========================================================
-- Initial Admin User Setup
-- =========================================================

-- Note: Admin users should be created through the Supabase Dashboard UI
-- or via an initial signup and role assignment, not in seed.sql.
-- This is just a reminder comment.

-- =========================================================
-- Analytics Setup Data (initial empty materialized views)
-- =========================================================

-- Refresh materialized views to ensure they're initialized
SELECT analytics.refresh_all_materialized_views();