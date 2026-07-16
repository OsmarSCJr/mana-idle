PRAGMA foreign_keys = ON;

CREATE TABLE wallets (
  player_id TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  free_balance INTEGER NOT NULL DEFAULT 0 CHECK(free_balance >= 0),
  paid_balance INTEGER NOT NULL DEFAULT 0 CHECK(paid_balance = 0),
  revision INTEGER NOT NULL DEFAULT 0 CHECK(revision >= 0),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
) STRICT;

CREATE TABLE wallet_entries (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  operation_id TEXT NOT NULL,
  grant_key TEXT,
  bucket TEXT NOT NULL DEFAULT 'free' CHECK(bucket = 'free'),
  amount INTEGER NOT NULL CHECK(amount != 0),
  reason TEXT NOT NULL CHECK(reason IN ('migration', 'daily', 'entitlement')),
  source_ref TEXT,
  balance_after INTEGER NOT NULL CHECK(balance_after >= 0),
  wallet_revision INTEGER NOT NULL CHECK(wallet_revision > 0),
  created_at INTEGER NOT NULL,
  UNIQUE(player_id, operation_id)
) STRICT;

CREATE UNIQUE INDEX wallet_grant_unique
  ON wallet_entries(player_id, grant_key)
  WHERE grant_key IS NOT NULL;
CREATE INDEX wallet_entries_player_created_idx ON wallet_entries(player_id, created_at DESC);

CREATE TABLE entitlements (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  sku TEXT NOT NULL CHECK(sku IN ('boost_fervor', 'boost_passo_ligeiro', 'study_slot')),
  operation_id TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
  granted_at INTEGER NOT NULL,
  UNIQUE(player_id, operation_id)
) STRICT;

CREATE INDEX entitlements_player_idx ON entitlements(player_id, granted_at DESC);
