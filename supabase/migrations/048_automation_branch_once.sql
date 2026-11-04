-- ============================================================
-- 048_automation_branch_once.sql
--
-- State for condition steps whose OTHER (`no`) branch is configured
-- to run "once per contact" (ConditionStepConfig.else_once_per_contact).
--
-- A row is claimed BEFORE the branch runs (and before any configured
-- delay is scheduled), so repeated triggers for the same contact are
-- skipped. The UNIQUE constraint makes the claim atomic under
-- concurrent webhook deliveries: exactly one insert wins, the rest
-- hit a 23505 conflict and skip.
--
-- `branch_key` is `no` (the OTHER branch). It is intentionally not tied
-- to a step id: the builder recreates step rows on save, so ids are not
-- stable. The guard therefore means "this automation's OTHER branch has
-- already run for this contact", and survives edits.
--
-- Service-role only — the engine writes/reads it, never the browser.
-- Idempotent — safe to run multiple times.
-- ============================================================

CREATE TABLE IF NOT EXISTS automation_branch_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  automation_id UUID NOT NULL REFERENCES automations(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  branch_key TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (automation_id, contact_id, branch_key)
);

CREATE INDEX IF NOT EXISTS idx_automation_branch_runs_lookup
  ON automation_branch_runs(automation_id, contact_id, branch_key);

ALTER TABLE automation_branch_runs ENABLE ROW LEVEL SECURITY;
-- No policies: all access is server-side via the service-role key.
