PRAGMA foreign_keys = ON;

CREATE TABLE players (
  id TEXT PRIMARY KEY,
  recovery_hash TEXT NOT NULL UNIQUE,
  recovery_key_version INTEGER NOT NULL DEFAULT 1,
  deletion_hmac TEXT NOT NULL UNIQUE,
  deletion_key_version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'deleting')),
  created_at INTEGER NOT NULL,
  recovery_rotated_at INTEGER,
  deletion_requested_at INTEGER
) STRICT;

CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  installation_id TEXT NOT NULL,
  label TEXT,
  client_version TEXT,
  kind TEXT NOT NULL DEFAULT 'game' CHECK(kind IN ('game', 'web_deletion')),
  created_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  revoked_at INTEGER,
  UNIQUE(player_id, installation_id)
) STRICT;

CREATE INDEX devices_player_idx ON devices(player_id, revoked_at);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  token_key_version INTEGER NOT NULL DEFAULT 1,
  purpose TEXT NOT NULL DEFAULT 'game' CHECK(purpose IN ('game', 'account_deletion')),
  created_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  idle_expires_at INTEGER NOT NULL,
  absolute_expires_at INTEGER NOT NULL,
  revoked_at INTEGER
) STRICT;

CREATE INDEX sessions_player_active_idx
  ON sessions(player_id, revoked_at, idle_expires_at, absolute_expires_at);
CREATE INDEX sessions_device_idx ON sessions(device_id, revoked_at);

CREATE TABLE cloud_saves (
  player_id TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  revision INTEGER NOT NULL DEFAULT 0 CHECK(revision >= 0),
  schema_version INTEGER,
  payload_json TEXT CHECK(payload_json IS NULL OR json_valid(payload_json)),
  payload_sha256 TEXT,
  payload_bytes INTEGER CHECK(payload_bytes IS NULL OR payload_bytes BETWEEN 1 AND 65536),
  previous_revision INTEGER,
  previous_schema_version INTEGER,
  previous_payload_json TEXT CHECK(previous_payload_json IS NULL OR json_valid(previous_payload_json)),
  previous_payload_sha256 TEXT,
  previous_payload_bytes INTEGER CHECK(previous_payload_bytes IS NULL OR previous_payload_bytes BETWEEN 1 AND 65536),
  previous_updated_at INTEGER,
  last_mutation_id TEXT,
  last_device_id TEXT,
  client_saved_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
) STRICT;

CREATE INDEX cloud_saves_updated_idx ON cloud_saves(updated_at);
