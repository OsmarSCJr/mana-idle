PRAGMA foreign_keys = ON;

CREATE TABLE save_mutations (
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  mutation_id TEXT NOT NULL,
  base_revision INTEGER NOT NULL CHECK(base_revision >= 0),
  resulting_revision INTEGER NOT NULL CHECK(resulting_revision > 0),
  payload_sha256 TEXT NOT NULL,
  device_id TEXT NOT NULL,
  server_updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY(player_id, mutation_id)
) STRICT, WITHOUT ROWID;

CREATE INDEX save_mutations_created_idx ON save_mutations(created_at);

CREATE TABLE save_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  revision INTEGER NOT NULL CHECK(revision >= 0),
  reason TEXT NOT NULL CHECK(length(reason) BETWEEN 1 AND 40),
  schema_version INTEGER NOT NULL,
  payload_json TEXT NOT NULL CHECK(json_valid(payload_json)),
  payload_sha256 TEXT NOT NULL,
  payload_bytes INTEGER NOT NULL CHECK(payload_bytes BETWEEN 1 AND 65536),
  created_at INTEGER NOT NULL,
  UNIQUE(player_id, revision, reason)
) STRICT;

CREATE INDEX save_snapshots_player_created_idx ON save_snapshots(player_id, created_at DESC);
