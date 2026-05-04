-- ============================================================================
-- Migration: 005_create_lifecycle_functions
-- Stream A / A5: game lifecycle stored procedures
--
-- Procedures (all SECURITY DEFINER, callable only by service_role):
--
--   process_start_game(p_command_id)
--       Admin starts trading. Requires game_state='created'. Sets start_time
--       and (for timed games) end_time_decided. Bumps state_version.
--
--   process_end_trading(p_command_id)
--       Admin OR system (sweeper) ends trading. Requires game_state=
--       'trading_started'. Flips all active orders to 'game_ended'. Sets
--       end_time_actual. Bumps state_version.
--
--   process_set_envelope_price(p_command_id)
--       Admin sets or re-edits the envelope value. Only valid in
--       game_state='trading_ended'. payload: { "envelope_price": <numeric> }.
--       Bumps state_version.
--
--   process_finalise_game(p_command_id)
--       Admin finalises the game. Requires game_state='trading_ended' AND
--       envelope_price IS NOT NULL. Computes PnL for all players as
--       round(delta_cash + envelope_price * delta_envelopes, 5), sets
--       lobby_status='finished' for all rows, moves game to 'game_finalised'.
--       Bumps state_version.
--
--   process_discard_game(p_command_id)
--       Admin abandons the game. Allowed from game_state IN ('created',
--       'trading_ended'). Sets all lobby_status='finished' (symmetry with
--       finalise). Moves game to 'discarded'. Bumps state_version.
--
--   process_add_time(p_command_id)
--       Admin extends a running timed game. Requires game_state=
--       'trading_started' AND end_condition='timed'. payload:
--       { "additional_seconds": <positive integer> }. Rejected (UE002) if
--       end_time_decided has already passed. Bumps state_version.
--
-- Locked design decisions (planning session):
--   Q1  start_game min players  : >= 1 (admin alone is sufficient)
--   Q2  end_trading system auth  : null player_id requires end_condition=
--       'timed' AND end_time_decided <= clock_timestamp() — defense-in-depth
--   Q3  envelope_price range     : >= 0; UE001 if negative
--   Q4  PnL precision            : round(..., 5) — hard 5-dp cap on write
--   Q5  discard lobby_status     : flip all rows to 'finished'
--   Q6  add_time past deadline   : UE002 if end_time_decided <= clock_timestamp()
--
-- Error classes (inherited from 003 / 004):
--   UE001 — non-retriable validation: command not found, wrong command_type,
--           required field null, missing or malformed payload
--   UE002 — non-retriable business-rule violation: wrong game_state,
--           non-admin caller, end_condition mismatch, deadline already passed,
--           envelope_price null at finalise time
--
-- clock_timestamp() is used throughout (not now() / transaction_timestamp())
-- so that comparisons against end_time_decided are wall-clock accurate even
-- inside long-running transactions.
-- ============================================================================


-- ============================================================================
-- process_start_game
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_start_game(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd         commands%ROWTYPE;
  v_game        games%ROWTYPE;
  v_caller_row  games_players%ROWTYPE;
  v_start_time  timestamptz;
BEGIN
  -- ---- Prologue: validate command row ------------------------------------ --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_start_game: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'start_game' THEN
    RAISE EXCEPTION 'process_start_game: command % has type % (expected start_game)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_start_game: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_start_game: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_start_game: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check ------------------------------------------------------- --
  IF v_game.game_state <> 'created' THEN
    RAISE EXCEPTION 'process_start_game: game_state % does not allow starting (expected created)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Admin check ------------------------------------------------------- --
  -- Q1: minimum players is 1 (admin alone is sufficient), so no count gate here.
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_start_game: caller % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_start_game: caller % is not admin of game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Mutate ------------------------------------------------------------ --
  v_start_time := clock_timestamp();

  UPDATE games
  SET
    game_state       = 'trading_started',
    start_time       = v_start_time,
    -- Timed: compute wall-clock deadline. Endless: leave end_time_decided NULL.
    end_time_decided = CASE
      WHEN end_condition = 'timed'
      THEN v_start_time + (total_decided_duration_seconds * interval '1 second')
      ELSE NULL
    END,
    state_version    = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_start_game(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_start_game(uuid) TO service_role;


-- ============================================================================
-- process_end_trading
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_end_trading(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd         commands%ROWTYPE;
  v_game        games%ROWTYPE;
  v_caller_row  games_players%ROWTYPE;
BEGIN
  -- ---- Prologue ---------------------------------------------------------- --
  -- NOTE: player_id MAY be null here (system/sweeper-triggered auto-end).
  -- We do NOT raise UE001 for null player_id; authorisation is handled below.
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_end_trading: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'end_trading' THEN
    RAISE EXCEPTION 'process_end_trading: command % has type % (expected end_trading)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_end_trading: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_end_trading: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check ------------------------------------------------------- --
  IF v_game.game_state <> 'trading_started' THEN
    RAISE EXCEPTION 'process_end_trading: game_state % does not allow ending (expected trading_started)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Authorisation: human admin vs system ------------------------------ --
  IF v_cmd.player_id IS NOT NULL THEN
    -- Human admin path: caller must be a member and have is_admin = true.
    SELECT * INTO v_caller_row
    FROM games_players
    WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'process_end_trading: caller % not in game %',
        v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
    END IF;
    IF NOT v_caller_row.is_admin THEN
      RAISE EXCEPTION 'process_end_trading: caller % is not admin of game %',
        v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
    END IF;
  ELSE
    -- System / sweeper path (Q2): defense-in-depth — reject unless the
    -- game is timed AND the deadline has genuinely passed.
    IF v_game.end_condition <> 'timed' THEN
      RAISE EXCEPTION 'process_end_trading: system-triggered end is only valid for timed games (game end_condition is %)',
        v_game.end_condition USING ERRCODE = 'UE002';
    END IF;
    IF v_game.end_time_decided IS NULL OR v_game.end_time_decided > clock_timestamp() THEN
      RAISE EXCEPTION 'process_end_trading: system end rejected — timer has not expired yet (end_time_decided = %)',
        v_game.end_time_decided USING ERRCODE = 'UE002';
    END IF;
  END IF;

  -- ---- Flip active orders to game_ended ---------------------------------- --
  UPDATE orders
  SET status = 'game_ended'
  WHERE game_id = v_cmd.command_game_id
    AND status IN ('in_queue', 'being_processed', 'order_resting');

  -- ---- Mutate game row (single state_version bump) ----------------------- --
  UPDATE games
  SET
    game_state      = 'trading_ended',
    end_time_actual = clock_timestamp(),
    state_version   = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_end_trading(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_end_trading(uuid) TO service_role;


-- ============================================================================
-- process_set_envelope_price
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_set_envelope_price(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd         commands%ROWTYPE;
  v_game        games%ROWTYPE;
  v_caller_row  games_players%ROWTYPE;
  v_price_raw   text;
  v_price       numeric;
BEGIN
  -- ---- Prologue ---------------------------------------------------------- --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_set_envelope_price: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'set_envelope_price' THEN
    RAISE EXCEPTION 'process_set_envelope_price: command % has type % (expected set_envelope_price)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_set_envelope_price: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_set_envelope_price: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Validate payload -------------------------------------------------- --
  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_set_envelope_price: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;
  v_price_raw := v_cmd.payload ->> 'envelope_price';
  IF v_price_raw IS NULL THEN
    RAISE EXCEPTION 'process_set_envelope_price: payload.envelope_price required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_price := v_price_raw::numeric;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_set_envelope_price: payload.envelope_price is not numeric (got %)',
      v_price_raw USING ERRCODE = 'UE001';
  END;
  IF v_price < 0 THEN
    RAISE EXCEPTION 'process_set_envelope_price: envelope_price must be >= 0 (got %)',
      v_price USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_set_envelope_price: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check ------------------------------------------------------- --
  IF v_game.game_state <> 'trading_ended' THEN
    RAISE EXCEPTION 'process_set_envelope_price: game_state % does not allow setting price (expected trading_ended)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Admin check ------------------------------------------------------- --
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_set_envelope_price: caller % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_set_envelope_price: caller % is not admin of game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Mutate ------------------------------------------------------------ --
  UPDATE games
  SET
    envelope_price = v_price,
    state_version  = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_set_envelope_price(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_set_envelope_price(uuid) TO service_role;


-- ============================================================================
-- process_finalise_game
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_finalise_game(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd         commands%ROWTYPE;
  v_game        games%ROWTYPE;
  v_caller_row  games_players%ROWTYPE;
BEGIN
  -- ---- Prologue ---------------------------------------------------------- --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_finalise_game: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'finalise_game' THEN
    RAISE EXCEPTION 'process_finalise_game: command % has type % (expected finalise_game)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_finalise_game: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_finalise_game: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_finalise_game: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check ------------------------------------------------------- --
  IF v_game.game_state <> 'trading_ended' THEN
    RAISE EXCEPTION 'process_finalise_game: game_state % does not allow finalising (expected trading_ended)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Envelope price guard --------------------------------------------- --
  IF v_game.envelope_price IS NULL THEN
    RAISE EXCEPTION 'process_finalise_game: envelope_price must be set before finalising'
      USING ERRCODE = 'UE002';
  END IF;

  -- ---- Admin check ------------------------------------------------------- --
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_finalise_game: caller % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_finalise_game: caller % is not admin of game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Compute and write PnL for every player (Q4: round to 5 dp) ------- --
  UPDATE games_players
  SET
    pnl          = round(delta_cash + v_game.envelope_price * delta_envelopes, 5),
    lobby_status = 'finished'
  WHERE map_game_id = v_cmd.command_game_id;

  -- ---- Transition game state --------------------------------------------- --
  UPDATE games
  SET
    game_state    = 'game_finalised',
    state_version = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_finalise_game(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_finalise_game(uuid) TO service_role;


-- ============================================================================
-- process_discard_game
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_discard_game(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd         commands%ROWTYPE;
  v_game        games%ROWTYPE;
  v_caller_row  games_players%ROWTYPE;
BEGIN
  -- ---- Prologue ---------------------------------------------------------- --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_discard_game: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'discard_game' THEN
    RAISE EXCEPTION 'process_discard_game: command % has type % (expected discard_game)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_discard_game: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_discard_game: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_discard_game: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check ------------------------------------------------------- --
  IF v_game.game_state NOT IN ('created', 'trading_ended') THEN
    RAISE EXCEPTION 'process_discard_game: game_state % does not allow discarding (expected created or trading_ended)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Admin check ------------------------------------------------------- --
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_discard_game: caller % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_discard_game: caller % is not admin of game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Flip all player rows to finished (Q5: symmetry with finalise) ----- --
  UPDATE games_players
  SET lobby_status = 'finished'
  WHERE map_game_id = v_cmd.command_game_id;

  -- ---- Transition game state --------------------------------------------- --
  UPDATE games
  SET
    game_state    = 'discarded',
    state_version = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_discard_game(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_discard_game(uuid) TO service_role;


-- ============================================================================
-- process_add_time
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_add_time(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd          commands%ROWTYPE;
  v_game         games%ROWTYPE;
  v_caller_row   games_players%ROWTYPE;
  v_seconds_raw  text;
  v_seconds      integer;
BEGIN
  -- ---- Prologue ---------------------------------------------------------- --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_add_time: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'add_time' THEN
    RAISE EXCEPTION 'process_add_time: command % has type % (expected add_time)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_add_time: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_add_time: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Validate payload before touching the game row --------------------- --
  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_add_time: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;
  v_seconds_raw := v_cmd.payload ->> 'additional_seconds';
  IF v_seconds_raw IS NULL THEN
    RAISE EXCEPTION 'process_add_time: payload.additional_seconds required'
      USING ERRCODE = 'UE001';
  END IF;
  -- Cast to integer; reject non-integer strings (e.g. "60.5", "abc")
  BEGIN
    v_seconds := v_seconds_raw::integer;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_add_time: payload.additional_seconds is not an integer (got %)',
      v_seconds_raw USING ERRCODE = 'UE001';
  END;
  IF v_seconds <= 0 THEN
    RAISE EXCEPTION 'process_add_time: payload.additional_seconds must be > 0 (got %)',
      v_seconds USING ERRCODE = 'UE001';
  END IF;

  -- ---- Lock game row ----------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_add_time: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State and config checks ------------------------------------------- --
  IF v_game.game_state <> 'trading_started' THEN
    RAISE EXCEPTION 'process_add_time: game_state % does not allow adding time (expected trading_started)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;
  IF v_game.end_condition <> 'timed' THEN
    RAISE EXCEPTION 'process_add_time: add_time is only valid for timed games (game end_condition is %)',
      v_game.end_condition USING ERRCODE = 'UE002';
  END IF;

  -- Q6: reject if deadline already passed (sweeper should handle this instead)
  IF v_game.end_time_decided <= clock_timestamp() THEN
    RAISE EXCEPTION 'process_add_time: deadline has already passed (end_time_decided = %); use end_trading instead',
      v_game.end_time_decided USING ERRCODE = 'UE002';
  END IF;

  -- ---- Admin check ------------------------------------------------------- --
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_add_time: caller % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_add_time: caller % is not admin of game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Mutate ------------------------------------------------------------ --
  UPDATE games
  SET
    total_decided_duration_seconds = total_decided_duration_seconds + v_seconds,
    end_time_decided               = end_time_decided + (v_seconds * interval '1 second'),
    state_version                  = state_version + 1
  WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_add_time(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_add_time(uuid) TO service_role;
