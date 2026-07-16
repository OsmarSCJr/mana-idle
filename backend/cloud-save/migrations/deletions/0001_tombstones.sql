CREATE TABLE deletion_tombstones (
  player_hmac TEXT PRIMARY KEY,
  status TEXT NOT NULL CHECK(status IN ('pending', 'completed')),
  requested_at INTEGER NOT NULL,
  completed_at INTEGER,
  expires_at INTEGER NOT NULL,
  last_error_code TEXT,
  last_reconciled_at INTEGER
) STRICT;

CREATE INDEX deletion_tombstones_pending_idx ON deletion_tombstones(status, requested_at);
CREATE INDEX deletion_tombstones_expiry_idx ON deletion_tombstones(expires_at);
CREATE INDEX deletion_tombstones_reconcile_idx ON deletion_tombstones(last_reconciled_at, expires_at);
