-- ============================================================================
-- Migration: 001_create_tables
-- Stream A / A1: full base schema for Uncertain Envelopes v2
--
-- Covers:
--   1. All gameplay enums (game_state, order_status, command_type, etc.)
--   2. The 6 tables from the PRD: players, games, games_players, orders,
--      executions, commands
--   3. Check / unique / foreign-key constraints
--   4. Indexes for the command processor, sweeper, order matching, and
--      chart / history reads
--   5. updated_at triggers for games and orders
--
-- Design decisions (confirmed with user before writing):
--   - players.player_id is PK and FK to auth.users(id) ON DELETE RESTRICT.
--     Account deletion is an explicit application workflow; no cascading
--     deletion of trading / game history.
--   - All cross-entity FKs use ON DELETE RESTRICT for the same reason.
--   - joining_code uniqueness is enforced only while the game is non-terminal
--     (game_state IN ('created','trading_started','trading_ended')), via a
--     partial unique index.
--   - Money-like fields are numeric (arbitrary precision).
--   - Quantities and delta_envelopes are integer.
--   - Enum-like domains use native Postgres ENUMs.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Enum types
-- ---------------------------------------------------------------------------
CREATE TYPE game_security AS ENUM ('public', 'private');

CREATE TYPE game_ranked AS ENUM ('ranked', 'casual');

CREATE TYPE end_condition AS ENUM ('timed', 'endless');

CREATE TYPE game_state AS ENUM (
  'created',
  'trading_started',
  'trading_ended',
  'game_finalised',
  'discarded'
);

CREATE TYPE lobby_status AS ENUM ('playing', 'finished');

CREATE TYPE order_type AS ENUM (
  'limit_buy',
  'limit_sell',
  'market_buy',
  'market_sell'
);

CREATE TYPE order_status AS ENUM (
  'in_queue',
  'being_processed',
  'order_resting',
  'order_closed',
  'cancelled',
  'game_ended'
);

CREATE TYPE command_type AS ENUM (
  'create_game',
  'join_game',
  'leave_game',
  'kick_player',
  'start_game',
  'create_order',
  'cancel_order',
  'end_trading',
  'set_envelope_price',
  'finalise_game',
  'discard_game',
  'add_time'
);

CREATE TYPE command_status AS ENUM (
  'pending',
  'claimed',
  'processed',
  'failed',
  'rejected'
);

-- ---------------------------------------------------------------------------
-- Generic updated_at trigger functions
--
-- We use clock_timestamp() (wall clock) rather than now() because now() /
-- transaction_timestamp() is frozen for the duration of a transaction. If a
-- stored procedure (e.g. match_order) writes a row and then updates it inside
-- the same transaction, the trigger needs to record an actual wall-clock
-- delta so callers / tests can order writes within the transaction.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_games_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := clock_timestamp();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION set_orders_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.order_updated_at := clock_timestamp();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- players
-- ---------------------------------------------------------------------------
CREATE TABLE players (
  player_id   UUID        PRIMARY KEY
              REFERENCES auth.users (id) ON DELETE RESTRICT,
  username    TEXT        NOT NULL UNIQUE,
  email       TEXT        NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT players_username_length
    CHECK (char_length(username) BETWEEN 3 AND 32),
  CONSTRAINT players_username_lowercase
    CHECK (username = lower(username)),
  CONSTRAINT players_email_format
    CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);

-- ---------------------------------------------------------------------------
-- games
-- ---------------------------------------------------------------------------
CREATE TABLE games (
  game_id                         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  game_name                       TEXT          NOT NULL,
  game_description                TEXT,
  game_created_at                 TIMESTAMPTZ   NOT NULL DEFAULT now(),
  game_security                   game_security NOT NULL,
  is_ranked                       game_ranked   NOT NULL,
  game_max_players                INTEGER       NOT NULL,
  joining_code                    TEXT          NOT NULL,
  end_condition                   end_condition NOT NULL,
  total_decided_duration_seconds  INTEGER,
  end_time_decided                TIMESTAMPTZ,
  start_time                      TIMESTAMPTZ,
  end_time_actual                 TIMESTAMPTZ,
  game_state                      game_state    NOT NULL DEFAULT 'created',
  admin_player_id                 UUID          NOT NULL
                                  REFERENCES players (player_id) ON DELETE RESTRICT,
  last_traded_price               NUMERIC,
  envelope_price                  NUMERIC,
  state_version                   INTEGER       NOT NULL DEFAULT 1,
  updated_at                      TIMESTAMPTZ   NOT NULL DEFAULT clock_timestamp(),

  CONSTRAINT games_game_name_length
    CHECK (char_length(game_name) BETWEEN 1 AND 32),
  CONSTRAINT games_description_length
    CHECK (game_description IS NULL OR char_length(game_description) <= 256),
  CONSTRAINT games_max_players_range
    CHECK (game_max_players BETWEEN 1 AND 100),
  CONSTRAINT games_joining_code_format
    CHECK (joining_code ~ '^[A-Z0-9]{5}$'),
  CONSTRAINT games_duration_matches_end_condition
    CHECK (
      (end_condition = 'timed'
        AND total_decided_duration_seconds IS NOT NULL
        AND total_decided_duration_seconds > 0)
      OR
      (end_condition = 'endless'
        AND total_decided_duration_seconds IS NULL)
    ),
  CONSTRAINT games_end_time_decided_matches_end_condition
    CHECK (end_condition = 'timed' OR end_time_decided IS NULL),
  CONSTRAINT games_state_version_positive
    CHECK (state_version >= 1)
);

-- Joining code is unique only while the game is non-terminal. This lets old
-- finalised / discarded games keep their historical codes without blocking
-- code reuse for new games.
CREATE UNIQUE INDEX games_joining_code_active_unique
  ON games (joining_code)
  WHERE game_state IN ('created', 'trading_started', 'trading_ended');

CREATE INDEX games_game_state_idx        ON games (game_state);
CREATE INDEX games_admin_player_id_idx   ON games (admin_player_id);

CREATE TRIGGER games_set_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW
  EXECUTE FUNCTION set_games_updated_at();

-- ---------------------------------------------------------------------------
-- games_players
-- ---------------------------------------------------------------------------
CREATE TABLE games_players (
  games_players_row_id  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  map_game_id           UUID          NOT NULL
                        REFERENCES games (game_id)   ON DELETE RESTRICT,
  map_player_id         UUID          NOT NULL
                        REFERENCES players (player_id) ON DELETE RESTRICT,
  lobby_status          lobby_status  NOT NULL DEFAULT 'playing',
  joined_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
  is_admin              BOOLEAN       NOT NULL DEFAULT false,
  delta_cash            NUMERIC       NOT NULL DEFAULT 0,
  delta_envelopes       INTEGER       NOT NULL DEFAULT 0,
  pnl                   NUMERIC       NOT NULL DEFAULT 0,

  CONSTRAINT games_players_unique_membership UNIQUE (map_game_id, map_player_id)
);

CREATE INDEX games_players_map_player_id_idx ON games_players (map_player_id);

-- Exactly one admin per game (the admin row is the row created with is_admin=true
-- by process_create_game; we never hand out a second admin for the same game).
CREATE UNIQUE INDEX games_players_one_admin_per_game
  ON games_players (map_game_id)
  WHERE is_admin = true;

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
  order_id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by_player_id  UUID          NOT NULL
                        REFERENCES players (player_id) ON DELETE RESTRICT,
  game_id               UUID          NOT NULL
                        REFERENCES games (game_id)   ON DELETE RESTRICT,
  type                  order_type    NOT NULL,
  quantity_initial      INTEGER       NOT NULL,
  quantity_current      INTEGER       NOT NULL,
  price_per_stock       NUMERIC,
  status                order_status  NOT NULL DEFAULT 'being_processed',
  order_created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
  order_updated_at      TIMESTAMPTZ   NOT NULL DEFAULT clock_timestamp(),

  CONSTRAINT orders_quantity_initial_positive
    CHECK (quantity_initial > 0),
  CONSTRAINT orders_quantity_current_range
    CHECK (quantity_current >= 0 AND quantity_current <= quantity_initial),
  CONSTRAINT orders_price_per_stock_matches_type
    CHECK (
      (type IN ('limit_buy', 'limit_sell')
        AND price_per_stock IS NOT NULL
        AND price_per_stock > 0)
      OR
      (type IN ('market_buy', 'market_sell')
        AND price_per_stock IS NULL)
    )
);

CREATE INDEX orders_game_status_idx
  ON orders (game_id, status);

-- Matching engine lookup: for a given game, resting orders of a given type,
-- sorted by price then time. Indexing all of this speeds up match_order().
CREATE INDEX orders_game_type_status_price_time_idx
  ON orders (game_id, type, status, price_per_stock, order_created_at);

CREATE INDEX orders_created_by_player_id_idx
  ON orders (created_by_player_id);

CREATE TRIGGER orders_set_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION set_orders_updated_at();

-- ---------------------------------------------------------------------------
-- executions
-- ---------------------------------------------------------------------------
CREATE TABLE executions (
  executions_id       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  executions_game_id  UUID         NOT NULL
                      REFERENCES games (game_id)  ON DELETE RESTRICT,
  buy_order_id        UUID         NOT NULL
                      REFERENCES orders (order_id) ON DELETE RESTRICT,
  sell_order_id       UUID         NOT NULL
                      REFERENCES orders (order_id) ON DELETE RESTRICT,
  quantity            INTEGER      NOT NULL,
  execution_price     NUMERIC      NOT NULL,
  executed_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT executions_quantity_positive   CHECK (quantity > 0),
  CONSTRAINT executions_price_positive      CHECK (execution_price > 0),
  CONSTRAINT executions_distinct_orders     CHECK (buy_order_id <> sell_order_id)
);

CREATE INDEX executions_game_time_idx
  ON executions (executions_game_id, executed_at);
CREATE INDEX executions_buy_order_id_idx
  ON executions (buy_order_id);
CREATE INDEX executions_sell_order_id_idx
  ON executions (sell_order_id);

-- ---------------------------------------------------------------------------
-- commands
-- ---------------------------------------------------------------------------
CREATE TABLE commands (
  command_id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
  -- command_game_id is nullable ONLY for create_game commands (the game
  -- doesn't exist yet at submission time). process_create_game() backfills
  -- it after inserting the games row. The partial CHECK below enforces this.
  command_game_id     UUID            REFERENCES games (game_id)    ON DELETE RESTRICT,
  command_created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
  -- player_id is nullable for system-triggered commands (e.g. the sweeper
  -- posting an end_trading command when a timed game hits its deadline).
  player_id           UUID            REFERENCES players (player_id) ON DELETE RESTRICT,
  command_type        command_type    NOT NULL,
  payload             JSONB           NOT NULL DEFAULT '{}'::jsonb,
  command_status      command_status  NOT NULL DEFAULT 'pending',
  claim_token         UUID,
  claimed_at          TIMESTAMPTZ,
  attempt_count       INTEGER         NOT NULL DEFAULT 0,
  finished_at         TIMESTAMPTZ,

  CONSTRAINT commands_attempt_count_range
    CHECK (attempt_count >= 0 AND attempt_count <= 3),
  CONSTRAINT commands_game_id_required_for_non_create
    CHECK (command_type = 'create_game' OR command_game_id IS NOT NULL)
);

-- Processor lookup: claim the oldest pending/failed command for a given game.
CREATE INDEX commands_processor_idx
  ON commands (command_game_id, command_status, command_created_at);

-- Sweeper lookup: find stale `claimed` commands (claimed_at < now() - 30s).
CREATE INDEX commands_sweeper_claimed_idx
  ON commands (claimed_at)
  WHERE command_status = 'claimed';

CREATE INDEX commands_player_id_idx ON commands (player_id);
