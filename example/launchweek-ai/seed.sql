-- seed.sql
-- This file populates reference tables with essential data for LaunchWeek.ai
-- Only includes lookup data - no user data or user-generated content

-- Clean and reload reference data (safely - only if the tables exist)
DO $$
BEGIN
    -- Note: We're not truncating enum types since they can't be truncated
    -- We only truncate actual tables with data

    -- Clear stripe.subscription_benefits if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'stripe' AND table_name = 'subscription_benefits') THEN
        TRUNCATE stripe.subscription_benefits CASCADE;
    END IF;
END
$$;

-- =========================================================
-- Stripe Product and Subscription Data
-- =========================================================

-- Products for our subscription tiers
INSERT INTO stripe.products (id, name, description, active, created_at, updated_at) VALUES
('prod_launchweek_free', 'LaunchWeek Free', 'Basic access with limited credits', TRUE, NOW(), NOW()),
('prod_launchweek_monthly', 'LaunchWeek Pro Monthly', 'Full access with monthly credits', TRUE, NOW(), NOW()),
('prod_launchweek_yearly', 'LaunchWeek Pro Yearly', 'Full access with yearly billing', TRUE, NOW(), NOW()),
('prod_launchweek_credits', 'LaunchWeek Credits', 'One-time credit purchase', TRUE, NOW(), NOW());

-- Prices for our subscription plans
INSERT INTO stripe.prices (id, product_id, active, currency, unit_amount, type, interval, created_at, updated_at) VALUES
-- Free tier has no price
('price_free_0', 'prod_launchweek_free', TRUE, 'usd', 0, 'recurring', 'month', NOW(), NOW()),
-- Monthly subscription ($7/month)
('price_monthly_7', 'prod_launchweek_monthly', TRUE, 'usd', 700, 'recurring', 'month', NOW(), NOW()),
-- Yearly subscription ($70/year)
('price_yearly_70', 'prod_launchweek_yearly', TRUE, 'usd', 7000, 'recurring', 'year', NOW(), NOW()),
-- One-time credit purchase ($50)
('price_credits_50', 'prod_launchweek_credits', TRUE, 'usd', 5000, 'one_time', NULL, NOW(), NOW());

-- Subscription benefits - defines what each tier provides
INSERT INTO stripe.subscription_benefits (id, product_id, monthly_credits, max_projects, has_priority_support, has_advanced_features, created_at, updated_at) VALUES
-- Free tier: 2 credits only at signup, no monthly refill
(gen_random_uuid(), 'prod_launchweek_free', 0, 2, FALSE, FALSE, NOW(), NOW()),
-- Monthly tier: 50 credits per month, refills monthly, cap at 50 projects  
(gen_random_uuid(), 'prod_launchweek_monthly', 50, 50, TRUE, FALSE, NOW(), NOW()),
-- Yearly tier: 50 credits per month (600/year), refills monthly, cap at 100 projects
(gen_random_uuid(), 'prod_launchweek_yearly', 50, 100, TRUE, TRUE, NOW(), NOW()),
-- Credit pack: This is a one-time purchase of 3 credits, not a subscription (no benefit record needed)
(gen_random_uuid(), 'prod_launchweek_credits', 3, NULL, FALSE, FALSE, NOW(), NOW());

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