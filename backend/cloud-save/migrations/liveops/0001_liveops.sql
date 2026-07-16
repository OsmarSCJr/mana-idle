PRAGMA foreign_keys = ON;

CREATE TABLE balance_versions (
  id TEXT PRIMARY KEY CHECK(length(id) BETWEEN 1 AND 64),
  schema_version INTEGER NOT NULL DEFAULT 1 CHECK(schema_version = 1),
  status TEXT NOT NULL CHECK(status IN ('draft', 'published', 'superseded')),
  config_json TEXT NOT NULL CHECK(json_valid(config_json)),
  config_sha256 TEXT NOT NULL CHECK(length(config_sha256) = 64),
  created_by TEXT NOT NULL CHECK(length(created_by) BETWEEN 1 AND 254),
  created_at INTEGER NOT NULL,
  published_by TEXT CHECK(published_by IS NULL OR length(published_by) BETWEEN 1 AND 254),
  published_at INTEGER,
  rollback_of_version_id TEXT REFERENCES balance_versions(id),
  CHECK((published_by IS NULL) = (published_at IS NULL))
) STRICT;

CREATE INDEX balance_versions_created_idx ON balance_versions(created_at DESC, id DESC);

CREATE TRIGGER balance_versions_payload_immutable
BEFORE UPDATE OF schema_version, config_json, config_sha256, created_by, created_at, rollback_of_version_id
ON balance_versions
BEGIN
  SELECT RAISE(ABORT, 'balance version payload is immutable');
END;

CREATE TABLE liveops_state (
  id INTEGER PRIMARY KEY CHECK(id = 1),
  revision INTEGER NOT NULL CHECK(revision >= 1),
  active_balance_version_id TEXT NOT NULL REFERENCES balance_versions(id),
  published_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
) STRICT;

CREATE TABLE campaigns (
  id TEXT PRIMARY KEY CHECK(length(id) BETWEEN 1 AND 64),
  campaign_key TEXT NOT NULL UNIQUE CHECK(length(campaign_key) BETWEEN 1 AND 64),
  active_version_id TEXT,
  latest_version_number INTEGER NOT NULL CHECK(latest_version_number >= 1),
  created_by TEXT NOT NULL CHECK(length(created_by) BETWEEN 1 AND 254),
  created_at INTEGER NOT NULL
) STRICT;

CREATE TABLE campaign_versions (
  id TEXT PRIMARY KEY CHECK(length(id) BETWEEN 1 AND 64),
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE RESTRICT,
  version_number INTEGER NOT NULL CHECK(version_number >= 1),
  status TEXT NOT NULL CHECK(status IN ('draft', 'published', 'superseded', 'cancelled')),
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 80),
  starts_at INTEGER NOT NULL,
  ends_at INTEGER NOT NULL CHECK(ends_at > starts_at),
  effects_json TEXT NOT NULL CHECK(json_valid(effects_json)),
  payload_sha256 TEXT NOT NULL CHECK(length(payload_sha256) = 64),
  created_by TEXT NOT NULL CHECK(length(created_by) BETWEEN 1 AND 254),
  created_at INTEGER NOT NULL,
  published_by TEXT CHECK(published_by IS NULL OR length(published_by) BETWEEN 1 AND 254),
  published_at INTEGER,
  retired_at INTEGER,
  rollback_of_version_id TEXT REFERENCES campaign_versions(id),
  cancelled_by TEXT CHECK(cancelled_by IS NULL OR length(cancelled_by) BETWEEN 1 AND 254),
  cancelled_at INTEGER,
  UNIQUE(campaign_id, version_number),
  CHECK((published_by IS NULL) = (published_at IS NULL)),
  CHECK(retired_at IS NULL OR published_at IS NOT NULL),
  CHECK((cancelled_by IS NULL) = (cancelled_at IS NULL))
) STRICT;

CREATE INDEX campaign_versions_campaign_idx
  ON campaign_versions(campaign_id, version_number DESC);
CREATE INDEX campaign_versions_public_idx
  ON campaign_versions(published_at, retired_at, ends_at, starts_at);

CREATE TRIGGER campaign_versions_payload_immutable
BEFORE UPDATE OF campaign_id, version_number, name, starts_at, ends_at, effects_json,
                 payload_sha256, created_by, created_at, rollback_of_version_id
ON campaign_versions
BEGIN
  SELECT RAISE(ABORT, 'campaign version payload is immutable');
END;

CREATE TABLE liveops_audit (
  id TEXT PRIMARY KEY CHECK(length(id) BETWEEN 1 AND 64),
  actor TEXT NOT NULL CHECK(length(actor) BETWEEN 1 AND 254),
  action TEXT NOT NULL CHECK(length(action) BETWEEN 1 AND 80),
  target_type TEXT NOT NULL CHECK(length(target_type) BETWEEN 1 AND 40),
  target_id TEXT NOT NULL CHECK(length(target_id) BETWEEN 1 AND 64),
  before_hash TEXT NOT NULL CHECK(length(before_hash) = 64),
  after_hash TEXT NOT NULL CHECK(length(after_hash) = 64),
  reason TEXT NOT NULL CHECK(length(reason) BETWEEN 3 AND 300),
  request_id TEXT NOT NULL CHECK(length(request_id) BETWEEN 1 AND 128),
  metadata_json TEXT NOT NULL CHECK(json_valid(metadata_json)),
  created_at INTEGER NOT NULL
) STRICT;

CREATE INDEX liveops_audit_created_idx ON liveops_audit(created_at DESC, id DESC);

INSERT INTO balance_versions (
  id, schema_version, status, config_json, config_sha256,
  created_by, created_at, published_by, published_at
) VALUES (
  'balance-baseline-v1',
  1,
  'published',
  '{"boosts":{"fervorProductionMultiplier":2,"harvestSeconds":7200,"holyHandsManualMultiplier":10,"pentecostProductionMultiplier":5,"swiftStepTimeMultiplier":0.5},"economy":{"growthRate":1.11,"milestones":[{"multiplier":1,"quantity":25},{"multiplier":2,"quantity":50},{"multiplier":2,"quantity":100},{"multiplier":2,"quantity":200},{"multiplier":2,"quantity":300},{"multiplier":2,"quantity":400}],"offlineCapSeconds":28800,"prestigeDivisor":2000000000000,"prophetCostMultiplier":20,"prophetUnlockQuantity":25,"saintBonus":0.06},"rewards":{"offlineTripleGemCost":3,"videoGems":5}}',
  'b8c9531becf66d33593850ae272e8c80146d97abde4476c6a48d9f1e6a008925',
  'system-migration',
  unixepoch(),
  'system-migration',
  unixepoch()
);

INSERT INTO liveops_state (
  id, revision, active_balance_version_id, published_at, updated_at
) VALUES (1, 1, 'balance-baseline-v1', unixepoch(), unixepoch());
