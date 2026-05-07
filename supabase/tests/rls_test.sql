-- ============================================================================
-- Test: rls_test
-- Stream A / A2-TEST: adversarial tests for row-level security policies
--
-- Strategy:
--   * Wrap the whole script in BEGIN / ROLLBACK.
--   * Seed data as the current (service_role, MCP default) session, which
--     bypasses RLS. Four auth.users + four players, five games covering all
--     combinations of (security x game_state), memberships so we have
--     at-least-one-of-each-kind, two orders with one execution in G1, and
--     one command per member for visibility tests.
--   * Then, for each authenticated user persona, SET LOCAL ROLE authenticated
--     + set request.jwt.claim.sub/claims so auth.uid() returns that user's
--     id, and run SELECT counts + INSERT/UPDATE attempts. Between personas,
--     RESET ROLE to re-enter service_role.
--
-- Personas:
--   A  — admin of G1 (public/created) and G4 (public/trading_started)
--   B  — member of G1, admin of G2 (private/created)
--   C  — member of G2, admin of G3 (public/trading_ended)
--   D  — admin of G5 (public/game_finalised)
--   E  — authenticated but not a member of anything (random uuid)
--   anon — unauthenticated role, no policy should match
--
-- Each persona's DO block asserts counts for players/games/games_players/
-- orders/executions/commands and tries at least one denied INSERT/UPDATE.
--
-- Deterministic UUIDs used so the persona blocks can reference them cleanly.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Seed data (runs as service_role — bypasses RLS)
-- ----------------------------------------------------------------------------

-- Auth users
INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'a@rls.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@rls.test'),
  ('33333333-3333-3333-3333-333333333333', 'c@rls.test'),
  ('44444444-4444-4444-4444-444444444444', 'd@rls.test');

-- Players
INSERT INTO players (player_id, username, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'alice', 'alice@rls.test'),
  ('22222222-2222-2222-2222-222222222222', 'bob',   'bob@rls.test'),
  ('33333333-3333-3333-3333-333333333333', 'carol', 'carol@rls.test'),
  ('44444444-4444-4444-4444-444444444444', 'dan',   'dan@rls.test');

-- Games (explicit uuids so assertions are predictable)
--   G1 public  / created         - A admin, B joined
--   G2 private / created         - B admin, C joined
--   G3 public  / trading_ended   - C admin
--   G4 public  / trading_started - A admin
--   G5 public  / game_finalised  - D admin
INSERT INTO games (game_id, game_name, game_security, is_ranked, game_max_players, joining_code, end_condition, admin_player_id, game_state) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'G1 PubCreated',      'public',  'casual', 4, 'G1PUB', 'endless', '11111111-1111-1111-1111-111111111111', 'created'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000002', 'G2 PrivCreated',     'private', 'casual', 4, 'G2PRI', 'endless', '22222222-2222-2222-2222-222222222222', 'created'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000003', 'G3 PubTradeEnded',   'public',  'casual', 4, 'G3END', 'endless', '33333333-3333-3333-3333-333333333333', 'trading_ended'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000004', 'G4 PubTrading',      'public',  'casual', 4, 'G4TRD', 'endless', '11111111-1111-1111-1111-111111111111', 'trading_started'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000005', 'G5 PubFinalised',    'public',  'casual', 4, 'G5FIN', 'endless', '44444444-4444-4444-4444-444444444444', 'game_finalised');

-- Games players memberships
INSERT INTO games_players (map_game_id, map_player_id, is_admin) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '11111111-1111-1111-1111-111111111111', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '22222222-2222-2222-2222-222222222222', false),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000002', '22222222-2222-2222-2222-222222222222', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000002', '33333333-3333-3333-3333-333333333333', false),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000003', '33333333-3333-3333-3333-333333333333', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000004', '11111111-1111-1111-1111-111111111111', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000005', '44444444-4444-4444-4444-444444444444', true);

-- Two orders in G1 so we can create one execution linking them
INSERT INTO orders (order_id, created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status) VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'limit_buy',  5, 5, 100, 'order_resting'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-000000000002', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'limit_sell', 5, 5, 100, 'order_resting');

INSERT INTO executions (executions_game_id, buy_order_id, sell_order_id, quantity, execution_price) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-000000000002', 1, 100);

-- One command per member. A's command is in G1, B's in G2, C's in G3.
INSERT INTO commands (command_game_id, player_id, command_type, payload) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '11111111-1111-1111-1111-111111111111', 'create_order',       '{}'::jsonb),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000002', '22222222-2222-2222-2222-222222222222', 'start_game',         '{}'::jsonb),
  ('aaaaaaaa-aaaa-aaaa-aaaa-000000000003', '33333333-3333-3333-3333-333333333333', 'set_envelope_price', '{"price":10}'::jsonb);

-- ----------------------------------------------------------------------------
-- Persona A (admin of G1, G4)
-- ----------------------------------------------------------------------------
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
SET LOCAL ROLE authenticated;

DO $persona_a$
DECLARE c integer;
BEGIN
  SELECT count(*) INTO c FROM players;
  ASSERT c = 4, format('persona A: players visible expected 4 got %s', c);

  SELECT count(*) INTO c FROM games;
  ASSERT c = 2, format('persona A: games visible (G1 member, G4 member) expected 2 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  ASSERT c = 2, format('persona A: G1 members visible expected 2 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000002';
  ASSERT c = 0, format('persona A: G2 (private, not member) members must be hidden, got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000003';
  ASSERT c = 0, format('persona A: G3 (public trading_ended, not member) members must be hidden, got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000005';
  ASSERT c = 0, format('persona A: G5 (finalised, not member) members must be hidden, got %s', c);

  SELECT count(*) INTO c FROM orders WHERE game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  ASSERT c = 2, format('persona A: G1 orders visible expected 2 got %s', c);

  SELECT count(*) INTO c FROM orders WHERE game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000002';
  ASSERT c = 0, format('persona A: G2 orders must be hidden, got %s', c);

  SELECT count(*) INTO c FROM executions;
  ASSERT c = 1, format('persona A: exec visible expected 1 got %s', c);

  SELECT count(*) INTO c FROM commands;
  ASSERT c = 1, format('persona A: commands visible (own only) expected 1 got %s', c);

  SELECT count(*) INTO c FROM commands WHERE player_id = '22222222-2222-2222-2222-222222222222';
  ASSERT c = 0, format('persona A: others commands must be hidden, got %s', c);

  -- Denied: INSERT player with someone else's id
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES ('55555555-5555-5555-5555-555555555555', 'mallory', 'mallory@rls.test');
    RAISE EXCEPTION 'FAIL: persona A inserted player row for another uuid';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Denied: INSERT command as someone else
  BEGIN
    INSERT INTO commands (command_game_id, player_id, command_type)
      VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '22222222-2222-2222-2222-222222222222', 'leave_game');
    RAISE EXCEPTION 'FAIL: persona A inserted command as other player';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Allowed: INSERT command as self
  INSERT INTO commands (command_game_id, player_id, command_type)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '11111111-1111-1111-1111-111111111111', 'leave_game');

  -- Denied: INSERT games (no policy at all for authenticated INSERT)
  BEGIN
    INSERT INTO games (game_id, game_name, game_security, is_ranked, game_max_players, joining_code, end_condition, admin_player_id)
      VALUES (gen_random_uuid(), 'Hax', 'public', 'casual', 4, 'HACK1', 'endless', '11111111-1111-1111-1111-111111111111');
    RAISE EXCEPTION 'FAIL: persona A inserted a games row directly';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Denied: INSERT games_players (no policy)
  BEGIN
    INSERT INTO games_players (map_game_id, map_player_id)
      VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-000000000002', '11111111-1111-1111-1111-111111111111');
    RAISE EXCEPTION 'FAIL: persona A inserted games_players directly';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Denied: INSERT orders (no policy)
  BEGIN
    INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock)
      VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'limit_buy', 1, 1, 100);
    RAISE EXCEPTION 'FAIL: persona A inserted orders directly';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Denied: INSERT executions (no policy)
  BEGIN
    INSERT INTO executions (executions_game_id, buy_order_id, sell_order_id, quantity, execution_price)
      VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-000000000002', 1, 200);
    RAISE EXCEPTION 'FAIL: persona A inserted executions directly';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- UPDATE / DELETE with no matching policy: silently affect 0 rows, not error.
  -- Assert the target row did NOT change.
  UPDATE games SET game_name = 'Hax' WHERE game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  SELECT count(*) INTO c FROM games
    WHERE game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001' AND game_name = 'Hax';
  ASSERT c = 0, 'persona A: UPDATE games leaked through RLS';

  UPDATE orders SET status = 'cancelled' WHERE order_id = 'bbbbbbbb-bbbb-bbbb-bbbb-000000000001';
  SELECT count(*) INTO c FROM orders
    WHERE order_id = 'bbbbbbbb-bbbb-bbbb-bbbb-000000000001' AND status = 'cancelled';
  ASSERT c = 0, 'persona A: UPDATE orders leaked through RLS';

  DELETE FROM games_players WHERE map_player_id = '22222222-2222-2222-2222-222222222222';
  SELECT count(*) INTO c FROM games_players WHERE map_player_id = '22222222-2222-2222-2222-222222222222';
  ASSERT c >= 1, 'persona A: DELETE games_players leaked through RLS';

  -- UPDATE another player's row must silently affect 0
  UPDATE players SET username = 'hacked' WHERE player_id = '22222222-2222-2222-2222-222222222222';
  SELECT count(*) INTO c FROM players
    WHERE player_id = '22222222-2222-2222-2222-222222222222' AND username = 'hacked';
  ASSERT c = 0, 'persona A: UPDATE another players row leaked';

  -- UPDATE own players row must succeed (and is visible)
  UPDATE players SET username = 'alice2' WHERE player_id = '11111111-1111-1111-1111-111111111111';
  SELECT count(*) INTO c FROM players
    WHERE player_id = '11111111-1111-1111-1111-111111111111' AND username = 'alice2';
  ASSERT c = 1, 'persona A: UPDATE own players row did not persist';

  RAISE NOTICE 'persona A: all assertions passed';
END;
$persona_a$;

RESET ROLE;

-- ----------------------------------------------------------------------------
-- Persona D (member of G5 only, finalised game)
-- ----------------------------------------------------------------------------
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
SELECT set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);
SET LOCAL ROLE authenticated;

DO $persona_d$
DECLARE c integer;
BEGIN
  SELECT count(*) INTO c FROM games;
  ASSERT c = 3, format('persona D: games visible (G1, G4, G5) expected 3 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  ASSERT c = 2, format('persona D: G1 members via public-active expected 2 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000005';
  ASSERT c = 1, format('persona D: G5 members via membership expected 1 got %s', c);

  -- D can see G1 in games (public-active) but MUST NOT see G1 orders
  SELECT count(*) INTO c FROM orders WHERE game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  ASSERT c = 0, format('persona D: G1 orders must be hidden (not a member) got %s', c);

  SELECT count(*) INTO c FROM executions;
  ASSERT c = 0, format('persona D: executions visible expected 0 got %s', c);

  SELECT count(*) INTO c FROM commands;
  ASSERT c = 0, format('persona D: commands visible expected 0 got %s', c);

  RAISE NOTICE 'persona D: all assertions passed';
END;
$persona_d$;

RESET ROLE;

-- ----------------------------------------------------------------------------
-- Persona E (authenticated but not a member of any game)
-- ----------------------------------------------------------------------------
SELECT set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
SET LOCAL ROLE authenticated;

DO $persona_e$
DECLARE c integer;
BEGIN
  SELECT count(*) INTO c FROM players;
  ASSERT c = 4, format('persona E: players visible expected 4 got %s', c);

  SELECT count(*) INTO c FROM games;
  ASSERT c = 2, format('persona E: games visible (G1, G4 public-active) expected 2 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000001';
  ASSERT c = 2, format('persona E: G1 public-active members expected 2 got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000002';
  ASSERT c = 0, format('persona E: G2 private members hidden, got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000003';
  ASSERT c = 0, format('persona E: G3 non-active members hidden, got %s', c);

  SELECT count(*) INTO c FROM games_players WHERE map_game_id = 'aaaaaaaa-aaaa-aaaa-aaaa-000000000005';
  ASSERT c = 0, format('persona E: G5 finalised members hidden, got %s', c);

  SELECT count(*) INTO c FROM orders;
  ASSERT c = 0, format('persona E: orders hidden expected 0 got %s', c);

  SELECT count(*) INTO c FROM executions;
  ASSERT c = 0, format('persona E: executions hidden expected 0 got %s', c);

  SELECT count(*) INTO c FROM commands;
  ASSERT c = 0, format('persona E: commands hidden expected 0 got %s', c);

  -- E cannot insert a command as any other real player
  BEGIN
    INSERT INTO commands (command_game_id, player_id, command_type)
      VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-000000000001', '11111111-1111-1111-1111-111111111111', 'leave_game');
    RAISE EXCEPTION 'FAIL: persona E inserted command as another player';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  RAISE NOTICE 'persona E: all assertions passed';
END;
$persona_e$;

RESET ROLE;

-- ----------------------------------------------------------------------------
-- Anonymous (anon role, no JWT claims)
-- ----------------------------------------------------------------------------
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '', true);
SET LOCAL ROLE anon;

DO $persona_anon$
DECLARE c integer;
BEGIN
  SELECT count(*) INTO c FROM players;
  ASSERT c = 0, format('anon: players must be hidden, got %s', c);

  SELECT count(*) INTO c FROM games;
  ASSERT c = 0, format('anon: games must be hidden, got %s', c);

  SELECT count(*) INTO c FROM games_players;
  ASSERT c = 0, format('anon: games_players must be hidden, got %s', c);

  SELECT count(*) INTO c FROM orders;
  ASSERT c = 0, format('anon: orders must be hidden, got %s', c);

  SELECT count(*) INTO c FROM executions;
  ASSERT c = 0, format('anon: executions must be hidden, got %s', c);

  SELECT count(*) INTO c FROM commands;
  ASSERT c = 0, format('anon: commands must be hidden, got %s', c);

  -- Anon cannot insert anything
  BEGIN
    INSERT INTO players (player_id, username, email) VALUES (gen_random_uuid(), 'x', 'x@x.co');
    RAISE EXCEPTION 'FAIL: anon inserted into players';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  RAISE NOTICE 'anon: all assertions passed';
END;
$persona_anon$;

RESET ROLE;

ROLLBACK;
