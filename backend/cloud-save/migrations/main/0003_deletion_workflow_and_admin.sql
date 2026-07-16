PRAGMA foreign_keys = ON;

CREATE TABLE security_actions (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('recovery_reset', 'account_delete')),
  status TEXT NOT NULL CHECK(status IN ('pending', 'cancelled', 'completed')),
  requested_by_device_id TEXT NOT NULL,
  execute_after INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  cancelled_at INTEGER,
  completed_at INTEGER
) STRICT;

CREATE INDEX security_actions_due_idx ON security_actions(status, execute_after);
CREATE INDEX security_actions_player_idx ON security_actions(player_id, created_at DESC);
CREATE UNIQUE INDEX security_actions_one_pending_idx
  ON security_actions(player_id, kind)
  WHERE status = 'pending';

CREATE TABLE system_settings (
  id INTEGER PRIMARY KEY CHECK(id = 1),
  maintenance_mode INTEGER NOT NULL DEFAULT 0 CHECK(maintenance_mode IN (0, 1)),
  read_only_uploads INTEGER NOT NULL DEFAULT 0 CHECK(read_only_uploads IN (0, 1)),
  allow_new_accounts INTEGER NOT NULL DEFAULT 1 CHECK(allow_new_accounts IN (0, 1)),
  min_client_version TEXT,
  updated_at INTEGER NOT NULL
) STRICT;

INSERT INTO system_settings (id, updated_at) VALUES (1, unixepoch());

CREATE TABLE admin_audit (
  id TEXT PRIMARY KEY,
  actor TEXT NOT NULL CHECK(length(actor) BETWEEN 1 AND 254),
  action TEXT NOT NULL CHECK(length(action) BETWEEN 1 AND 80),
  target_type TEXT NOT NULL CHECK(length(target_type) BETWEEN 1 AND 40),
  target_id_hash TEXT,
  reason TEXT NOT NULL CHECK(length(reason) BETWEEN 3 AND 300),
  request_id TEXT NOT NULL,
  created_at INTEGER NOT NULL
) STRICT;

CREATE INDEX admin_audit_created_idx ON admin_audit(created_at DESC, id DESC);
