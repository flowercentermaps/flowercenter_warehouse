-- ─────────────────────────────────────────────────────────────────────────────
-- Migration 002: Multi-store stock allocations
-- Run in Supabase Dashboard → SQL Editor
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Add store_allocations column (JSONB array of {store, qty} objects)
ALTER TABLE quotation_stock_checks
  ADD COLUMN IF NOT EXISTS store_allocations JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 2. GIN index for future queries on allocation data
CREATE INDEX IF NOT EXISTS idx_stock_checks_store_allocs
  ON quotation_stock_checks USING gin (store_allocations);

-- ─────────────────────────────────────────────────────────────────────────────
-- Example of what the column holds:
-- [
--   {"store": "Showroom",     "qty": 50},
--   {"store": "Hamsat Store", "qty": 50}
-- ]
--
-- The existing warehouse_location TEXT column is kept for backwards
-- compatibility and is now written as a comma-joined list of store names.
-- ─────────────────────────────────────────────────────────────────────────────
