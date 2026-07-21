-- ──────────────────────────────────────────────────────────────────────────
-- Append-only audit log for `quotation_stock_checks` updates.
-- Run in the Supabase SQL editor on both prod and test.
--
-- Powers two warehouse-app features:
--   • B2: "Show history" bottom sheet in the Stock Check screen
--   • B3: Per-item shortage history sheet (long-press a stock item card)
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS quotation_stock_check_logs (
  id              BIGSERIAL    PRIMARY KEY,
  quotation_id    BIGINT       NOT NULL REFERENCES quotations(id) ON DELETE CASCADE,
  quotation_item_id BIGINT     NOT NULL,
  supplier_code   TEXT         NOT NULL DEFAULT '',
  product_name    TEXT         NOT NULL DEFAULT '',
  changed_by      UUID         REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_name TEXT         NOT NULL DEFAULT '',
  changed_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  before_status   TEXT,
  after_status    TEXT,
  before_qty      NUMERIC,
  after_qty       NUMERIC,
  shortage_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_sclogs_quotation
  ON quotation_stock_check_logs (quotation_id, changed_at DESC);

CREATE INDEX IF NOT EXISTS idx_sclogs_supplier_recent
  ON quotation_stock_check_logs (supplier_code, changed_at DESC);

-- Trigger: append a log row whenever a stock_check row is inserted, or
-- updated with an actual status / qty / reason change. SECURITY DEFINER so
-- it can write to a table whose RLS forbids direct inserts.
CREATE OR REPLACE FUNCTION public.log_stock_check_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_name TEXT := '';
  v_before_status TEXT := NULL;
  v_before_qty NUMERIC := NULL;
BEGIN
  IF NEW.checked_by IS NOT NULL THEN
    SELECT COALESCE(full_name, '') INTO v_name
    FROM profiles WHERE id = NEW.checked_by;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF OLD.status IS NOT DISTINCT FROM NEW.status
       AND OLD.quantity_available IS NOT DISTINCT FROM NEW.quantity_available
       AND OLD.shortage_reason IS NOT DISTINCT FROM NEW.shortage_reason THEN
      RETURN NEW;
    END IF;
    v_before_status := OLD.status;
    v_before_qty := OLD.quantity_available;
  END IF;

  INSERT INTO quotation_stock_check_logs (
    quotation_id, quotation_item_id, supplier_code, product_name,
    changed_by, changed_by_name, changed_at,
    before_status, after_status, before_qty, after_qty,
    shortage_reason
  ) VALUES (
    NEW.quotation_id, NEW.quotation_item_id,
    COALESCE(NEW.supplier_code, ''), COALESCE(NEW.product_name, ''),
    NEW.checked_by, COALESCE(v_name, ''), COALESCE(NEW.checked_at, NOW()),
    v_before_status, NEW.status, v_before_qty, NEW.quantity_available,
    NEW.shortage_reason
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_stock_check_change ON quotation_stock_checks;
CREATE TRIGGER trg_log_stock_check_change
AFTER INSERT OR UPDATE ON quotation_stock_checks
FOR EACH ROW EXECUTE FUNCTION public.log_stock_check_change();

-- RLS: warehouse_manager + admin can read. No INSERT/UPDATE/DELETE policy →
-- direct writes are blocked; only the SECURITY DEFINER trigger can insert.
ALTER TABLE quotation_stock_check_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sclogs_select" ON quotation_stock_check_logs;
CREATE POLICY "sclogs_select" ON quotation_stock_check_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('warehouse_manager', 'admin')
    )
  );

GRANT SELECT ON quotation_stock_check_logs TO authenticated;
