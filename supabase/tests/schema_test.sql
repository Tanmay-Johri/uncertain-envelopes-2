-- ============================================================================
-- Test: schema_test
-- Stream A / A1-TEST: adversarial tests for the base schema
--
-- Everything runs inside one outer transaction that rolls back at the end, so
-- nothing persists even on partial success. Within the DO block, each failing
-- "expected error" test is wrapped in a sub-block with its own EXCEPTION
-- handler (PL/pgSQL's implicit savepoint semantics) so a caught constraint
-- violation does not poison the rest of the run.
--
-- Test strategy:
--   - Happy-path insert for every table
--   - FK violations for every FK
--   - Unique / partial-unique index violations (including joining_code scope
--     and one-admin-per-game)
--   - Every CHECK constraint (name length, description length, max_players
--     range, joining_code format, duration/end_condition consistency,
--     end_time_decided/end_condition, username length + lowercase, email
--     format, order quantity_initial > 0, quantity_current range,
--     price/type consistency, execution quantity/price positive, execution
--     distinct orders, command attempt_count range, command game_id
--     required for non-create_game)
--   - Enum label rejection (invalid enum string)
--   - Cascade-RESTRICT: deleting a player/game with dependents fails
--   - Default values (state_version=1, game_state='created', attempt_count=0,
--     command_status='pending', is_admin=false, delta_cash=0,
--     delta_envelopes=0, pnl=0, lobby_status='playing', status='being_processed')
--   - updated_at trigger on games
--   - order_updated_at trigger on orders
-- ============================================================================

BEGIN;

DO $schema_test$
DECLARE
  v_auth_a  uuid := gen_random_uuid();
  v_auth_b  uuid := gen_random_uuid();
  v_auth_c  uuid := gen_random_uuid();
  v_auth_d  uuid := gen_random_uuid();
  v_missing uuid := gen_random_uuid();
  v_game_id       uuid;
  v_game_id_b     uuid;
  v_game_id_old   uuid;
  v_order_buy_id  uuid;
  v_order_sell_id uuid;
  v_ts_before     timestamptz;
  v_ts_after      timestamptz;
  v_default_state game_state;
  v_default_cs    command_status;
  v_default_ac    integer;
  v_default_is_adm boolean;
  v_default_dc    numeric;
  v_default_de    integer;
  v_default_pnl   numeric;
  v_default_lbs   lobby_status;
  v_default_status order_status;
  v_default_sv    integer;
BEGIN
  -- --------------------------------------------------------------------------
  -- Setup: four auth.users rows so we have valid player_id targets
  -- --------------------------------------------------------------------------
  INSERT INTO auth.users (id, email) VALUES (v_auth_a, 'a@test.local');
  INSERT INTO auth.users (id, email) VALUES (v_auth_b, 'b@test.local');
  INSERT INTO auth.users (id, email) VALUES (v_auth_c, 'c@test.local');
  INSERT INTO auth.users (id, email) VALUES (v_auth_d, 'd@test.local');

  -- --------------------------------------------------------------------------
  -- players
  -- --------------------------------------------------------------------------

  -- happy path
  INSERT INTO players (player_id, username, email)
    VALUES (v_auth_a, 'alice', 'alice@test.local');
  ASSERT (SELECT count(*) FROM players WHERE player_id = v_auth_a) = 1,
    'players happy-path insert missing';

  -- FK violation: player_id not in auth.users
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_missing, 'nobody', 'nobody@test.local');
    RAISE EXCEPTION 'FAIL: players FK to auth.users did not reject unknown uuid';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- unique username (straight duplicate)
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, 'alice', 'alice2@test.local');
    RAISE EXCEPTION 'FAIL: duplicate username accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- unique email
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, 'bob', 'alice@test.local');
    RAISE EXCEPTION 'FAIL: duplicate email accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- username must be lowercase
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, 'Alice', 'a2@test.local');
    RAISE EXCEPTION 'FAIL: non-lowercase username accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- username length < 3
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, 'al', 'a3@test.local');
    RAISE EXCEPTION 'FAIL: 2-char username accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- username length > 32
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, repeat('a', 33), 'a4@test.local');
    RAISE EXCEPTION 'FAIL: 33-char username accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- email format
  BEGIN
    INSERT INTO players (player_id, username, email)
      VALUES (v_auth_b, 'bob1', 'not-an-email');
    RAISE EXCEPTION 'FAIL: malformed email accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- finish populating players for later tests
  INSERT INTO players (player_id, username, email)
    VALUES (v_auth_b, 'bob', 'bob@test.local');
  INSERT INTO players (player_id, username, email)
    VALUES (v_auth_c, 'carol', 'carol@test.local');
  INSERT INTO players (player_id, username, email)
    VALUES (v_auth_d, 'dan', 'dan@test.local');

  -- --------------------------------------------------------------------------
  -- games: defaults + constraints
  -- --------------------------------------------------------------------------

  -- happy path (timed, public, ranked)
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, total_decided_duration_seconds,
    admin_player_id
  ) VALUES (
    'Test Game', 'public', 'ranked', 4,
    'ABC12', 'timed', 600, v_auth_a
  ) RETURNING game_id INTO v_game_id;

  -- default state_version / game_state
  SELECT state_version, game_state INTO v_default_sv, v_default_state
    FROM games WHERE game_id = v_game_id;
  ASSERT v_default_sv = 1, 'default state_version must be 1';
  ASSERT v_default_state = 'created', 'default game_state must be created';

  -- admin FK to players
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      'Bad Admin', 'public', 'casual', 4,
      'BAD01', 'endless', v_missing
    );
    RAISE EXCEPTION 'FAIL: games admin_player_id FK did not reject unknown player';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- game_name empty
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      '', 'public', 'casual', 4, 'CODE0', 'endless', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: empty game_name accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- game_name too long (33 chars)
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      repeat('g', 33), 'public', 'casual', 4, 'CODE1', 'endless', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: 33-char game_name accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- description boundary: empty string allowed
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id, game_description
  ) VALUES (
    'Desc Empty', 'public', 'casual', 4, 'DESC0', 'endless', v_auth_a, ''
  );

  -- description 256 chars allowed, 257 rejected
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id, game_description
  ) VALUES (
    'Desc Max', 'public', 'casual', 4, 'DESC1', 'endless', v_auth_a, repeat('x', 256)
  );
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id, game_description
    ) VALUES (
      'Desc Over', 'public', 'casual', 4, 'DESC2', 'endless', v_auth_a, repeat('x', 257)
    );
    RAISE EXCEPTION 'FAIL: 257-char description accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- max_players boundaries
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      'Max 0', 'public', 'casual', 0, 'MAX00', 'endless', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: max_players=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      'Max 101', 'public', 'casual', 101, 'MAX01', 'endless', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: max_players=101 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- joining_code format (lowercase rejected, 4-char rejected, 6-char rejected,
  -- symbols rejected)
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES ('Lower', 'public', 'casual', 4, 'abc12', 'endless', v_auth_a);
    RAISE EXCEPTION 'FAIL: lowercase joining_code accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES ('Short', 'public', 'casual', 4, 'ABC1', 'endless', v_auth_a);
    RAISE EXCEPTION 'FAIL: 4-char joining_code accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES ('Long', 'public', 'casual', 4, 'ABC123', 'endless', v_auth_a);
    RAISE EXCEPTION 'FAIL: 6-char joining_code accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES ('Sym', 'public', 'casual', 4, 'ABC-1', 'endless', v_auth_a);
    RAISE EXCEPTION 'FAIL: symbol in joining_code accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- end_condition = 'endless' must have NULL duration
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, total_decided_duration_seconds,
      admin_player_id
    ) VALUES (
      'Endless+Dur', 'public', 'casual', 4, 'ENDL1', 'endless', 600, v_auth_a
    );
    RAISE EXCEPTION 'FAIL: endless game with duration accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- end_condition = 'timed' must have non-null positive duration
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES ('TimedNull', 'public', 'casual', 4, 'TIM01', 'timed', v_auth_a);
    RAISE EXCEPTION 'FAIL: timed game with NULL duration accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, total_decided_duration_seconds,
      admin_player_id
    ) VALUES ('TimedZero', 'public', 'casual', 4, 'TIM02', 'timed', 0, v_auth_a);
    RAISE EXCEPTION 'FAIL: timed game with duration=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- endless game cannot have end_time_decided
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, end_time_decided, admin_player_id
    ) VALUES (
      'EndlessDeadline', 'public', 'casual', 4,
      'ENDL2', 'endless', now() + interval '1 hour', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: endless game with end_time_decided accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- state_version < 1 rejected
  BEGIN
    UPDATE games SET state_version = 0 WHERE game_id = v_game_id;
    RAISE EXCEPTION 'FAIL: state_version=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- enum rejection: invalid game_security string
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      'BadEnum', 'hidden'::game_security, 'casual', 4,
      'BAD99', 'endless', v_auth_a
    );
    RAISE EXCEPTION 'FAIL: invalid game_security enum value accepted';
  EXCEPTION WHEN invalid_text_representation THEN NULL;
  END;

  -- --------------------------------------------------------------------------
  -- joining_code partial unique index
  -- --------------------------------------------------------------------------

  -- create a second game also in 'created' state sharing a different code
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id
  ) VALUES (
    'Second', 'public', 'casual', 4, 'XXX11', 'endless', v_auth_b
  ) RETURNING game_id INTO v_game_id_b;

  -- collision in active state rejected
  BEGIN
    INSERT INTO games (
      game_name, game_security, is_ranked, game_max_players,
      joining_code, end_condition, admin_player_id
    ) VALUES (
      'Collide', 'public', 'casual', 4, 'XXX11', 'endless', v_auth_c
    );
    RAISE EXCEPTION 'FAIL: duplicate joining_code in active states accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- terminal-state game can hold same code without blocking
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id, game_state
  ) VALUES (
    'OldFinalised', 'public', 'casual', 4,
    'REUSE', 'endless', v_auth_a, 'game_finalised'
  ) RETURNING game_id INTO v_game_id_old;

  -- another active game with same code 'REUSE' should succeed because the
  -- finalised one is not in the partial index
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id
  ) VALUES (
    'ReusedCode', 'public', 'casual', 4, 'REUSE', 'endless', v_auth_b
  );

  -- but two discarded games sharing the same code is also fine
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id, game_state
  ) VALUES (
    'DiscA', 'public', 'casual', 4, 'DROPX', 'endless', v_auth_c, 'discarded'
  );
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, admin_player_id, game_state
  ) VALUES (
    'DiscB', 'public', 'casual', 4, 'DROPX', 'endless', v_auth_d, 'discarded'
  );

  -- --------------------------------------------------------------------------
  -- games.updated_at trigger
  -- --------------------------------------------------------------------------
  SELECT updated_at INTO v_ts_before FROM games WHERE game_id = v_game_id;
  PERFORM pg_sleep(0.02);
  UPDATE games SET game_name = 'Test Game v2' WHERE game_id = v_game_id;
  SELECT updated_at INTO v_ts_after FROM games WHERE game_id = v_game_id;
  ASSERT v_ts_after > v_ts_before,
    'games.updated_at trigger did not bump on UPDATE';

  -- --------------------------------------------------------------------------
  -- games_players
  -- --------------------------------------------------------------------------

  -- admin row for v_game_id
  INSERT INTO games_players (map_game_id, map_player_id, is_admin)
    VALUES (v_game_id, v_auth_a, true);

  -- defaults landing correctly
  SELECT lobby_status, is_admin, delta_cash, delta_envelopes, pnl
    INTO v_default_lbs, v_default_is_adm, v_default_dc, v_default_de, v_default_pnl
    FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_auth_a;
  ASSERT v_default_lbs = 'playing',        'default lobby_status must be playing';
  ASSERT v_default_is_adm = true,          'admin row is_admin wrong';
  ASSERT v_default_dc = 0,                 'default delta_cash must be 0';
  ASSERT v_default_de = 0,                 'default delta_envelopes must be 0';
  ASSERT v_default_pnl = 0,                'default pnl must be 0';

  -- insert a non-admin player with defaults
  INSERT INTO games_players (map_game_id, map_player_id)
    VALUES (v_game_id, v_auth_b);
  SELECT is_admin INTO v_default_is_adm
    FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_auth_b;
  ASSERT v_default_is_adm = false, 'default is_admin must be false';

  -- FK violations
  BEGIN
    INSERT INTO games_players (map_game_id, map_player_id)
      VALUES (gen_random_uuid(), v_auth_a);
    RAISE EXCEPTION 'FAIL: games_players bad map_game_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO games_players (map_game_id, map_player_id)
      VALUES (v_game_id, v_missing);
    RAISE EXCEPTION 'FAIL: games_players bad map_player_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- duplicate (game, player) rejected
  BEGIN
    INSERT INTO games_players (map_game_id, map_player_id)
      VALUES (v_game_id, v_auth_a);
    RAISE EXCEPTION 'FAIL: duplicate games_players membership accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- only one admin per game
  BEGIN
    INSERT INTO games_players (map_game_id, map_player_id, is_admin)
      VALUES (v_game_id, v_auth_c, true);
    RAISE EXCEPTION 'FAIL: second admin for same game accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  -- but a second game can have its own admin
  INSERT INTO games_players (map_game_id, map_player_id, is_admin)
    VALUES (v_game_id_b, v_auth_b, true);

  -- --------------------------------------------------------------------------
  -- orders
  -- --------------------------------------------------------------------------

  -- limit_buy happy path
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock
  ) VALUES (
    v_auth_a, v_game_id, 'limit_buy', 10, 10, 100
  ) RETURNING order_id INTO v_order_buy_id;
  SELECT status INTO v_default_status FROM orders WHERE order_id = v_order_buy_id;
  ASSERT v_default_status = 'being_processed',
    'default orders.status must be being_processed';

  -- limit_sell happy path
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_auth_b, v_game_id, 'limit_sell', 5, 5, 120, 'order_resting'
  ) RETURNING order_id INTO v_order_sell_id;

  -- market_buy must have null price
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial, quantity_current
  ) VALUES (v_auth_a, v_game_id, 'market_buy', 3, 3);

  -- market order with non-null price rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, v_game_id, 'market_buy', 3, 3, 100);
    RAISE EXCEPTION 'FAIL: market order with price accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- limit order with null price rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial, quantity_current
    ) VALUES (v_auth_a, v_game_id, 'limit_buy', 3, 3);
    RAISE EXCEPTION 'FAIL: limit order with null price accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- limit order with zero/negative price rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, v_game_id, 'limit_buy', 3, 3, 0);
    RAISE EXCEPTION 'FAIL: limit order with price=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- quantity_initial 0 rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, v_game_id, 'limit_buy', 0, 0, 10);
    RAISE EXCEPTION 'FAIL: quantity_initial=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- quantity_current > quantity_initial rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, v_game_id, 'limit_buy', 5, 10, 10);
    RAISE EXCEPTION 'FAIL: quantity_current > quantity_initial accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- quantity_current < 0 rejected
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, v_game_id, 'limit_buy', 5, -1, 10);
    RAISE EXCEPTION 'FAIL: quantity_current < 0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- orders.FK game_id
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_auth_a, gen_random_uuid(), 'limit_buy', 1, 1, 10);
    RAISE EXCEPTION 'FAIL: orders bad game_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- orders.FK created_by_player_id
  BEGIN
    INSERT INTO orders (
      created_by_player_id, game_id, type, quantity_initial,
      quantity_current, price_per_stock
    ) VALUES (v_missing, v_game_id, 'limit_buy', 1, 1, 10);
    RAISE EXCEPTION 'FAIL: orders bad created_by_player_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- orders.order_updated_at trigger
  SELECT order_updated_at INTO v_ts_before FROM orders WHERE order_id = v_order_buy_id;
  PERFORM pg_sleep(0.02);
  UPDATE orders SET quantity_current = 9 WHERE order_id = v_order_buy_id;
  SELECT order_updated_at INTO v_ts_after FROM orders WHERE order_id = v_order_buy_id;
  ASSERT v_ts_after > v_ts_before,
    'orders.order_updated_at trigger did not bump on UPDATE';

  -- --------------------------------------------------------------------------
  -- executions
  -- --------------------------------------------------------------------------

  -- happy path
  INSERT INTO executions (
    executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
  ) VALUES (v_game_id, v_order_buy_id, v_order_sell_id, 1, 120);

  -- quantity > 0
  BEGIN
    INSERT INTO executions (
      executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
    ) VALUES (v_game_id, v_order_buy_id, v_order_sell_id, 0, 120);
    RAISE EXCEPTION 'FAIL: execution quantity=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- price > 0
  BEGIN
    INSERT INTO executions (
      executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
    ) VALUES (v_game_id, v_order_buy_id, v_order_sell_id, 1, 0);
    RAISE EXCEPTION 'FAIL: execution price=0 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- buy != sell
  BEGIN
    INSERT INTO executions (
      executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
    ) VALUES (v_game_id, v_order_buy_id, v_order_buy_id, 1, 120);
    RAISE EXCEPTION 'FAIL: execution with buy=sell accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- FK violations
  BEGIN
    INSERT INTO executions (
      executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
    ) VALUES (gen_random_uuid(), v_order_buy_id, v_order_sell_id, 1, 120);
    RAISE EXCEPTION 'FAIL: execution bad game_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO executions (
      executions_game_id, buy_order_id, sell_order_id, quantity, execution_price
    ) VALUES (v_game_id, gen_random_uuid(), v_order_sell_id, 1, 120);
    RAISE EXCEPTION 'FAIL: execution bad buy_order_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- --------------------------------------------------------------------------
  -- commands
  -- --------------------------------------------------------------------------

  -- create_game command may have null command_game_id
  INSERT INTO commands (command_type, player_id, payload)
    VALUES ('create_game', v_auth_a, '{"name":"X"}'::jsonb);

  -- default values on commands
  SELECT command_status, attempt_count
    INTO v_default_cs, v_default_ac
    FROM commands
    WHERE command_type = 'create_game' AND player_id = v_auth_a
    ORDER BY command_created_at DESC LIMIT 1;
  ASSERT v_default_cs = 'pending', 'default command_status must be pending';
  ASSERT v_default_ac = 0,         'default attempt_count must be 0';

  -- non-create_game command requires game_id
  BEGIN
    INSERT INTO commands (command_type, player_id)
      VALUES ('join_game', v_auth_b);
    RAISE EXCEPTION 'FAIL: join_game with null game_id accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO commands (command_type, player_id)
      VALUES ('create_order', v_auth_b);
    RAISE EXCEPTION 'FAIL: create_order with null game_id accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- system command: player_id may be null (sweeper-triggered end_trading)
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'end_trading', NULL);

  -- attempt_count range 0..3
  BEGIN
    INSERT INTO commands (command_game_id, command_type, player_id, attempt_count)
      VALUES (v_game_id, 'join_game', v_auth_b, -1);
    RAISE EXCEPTION 'FAIL: attempt_count=-1 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO commands (command_game_id, command_type, player_id, attempt_count)
      VALUES (v_game_id, 'join_game', v_auth_b, 4);
    RAISE EXCEPTION 'FAIL: attempt_count=4 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- FK validation on commands
  BEGIN
    INSERT INTO commands (command_game_id, command_type, player_id)
      VALUES (gen_random_uuid(), 'join_game', v_auth_b);
    RAISE EXCEPTION 'FAIL: commands bad game_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO commands (command_game_id, command_type, player_id)
      VALUES (v_game_id, 'join_game', v_missing);
    RAISE EXCEPTION 'FAIL: commands bad player_id accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- --------------------------------------------------------------------------
  -- RESTRICT cascade behavior: deletes blocked when dependents exist
  -- --------------------------------------------------------------------------

  -- v_auth_a is admin of v_game_id and referenced by games.admin_player_id,
  -- games_players, orders, commands. Deleting from players must fail.
  BEGIN
    DELETE FROM players WHERE player_id = v_auth_a;
    RAISE EXCEPTION 'FAIL: deleting a player with dependents succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- v_game_id has games_players / orders / executions / commands — delete must fail
  BEGIN
    DELETE FROM games WHERE game_id = v_game_id;
    RAISE EXCEPTION 'FAIL: deleting a game with dependents succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- deleting an order referenced by an execution must fail
  BEGIN
    DELETE FROM orders WHERE order_id = v_order_sell_id;
    RAISE EXCEPTION 'FAIL: deleting an order referenced by execution succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- --------------------------------------------------------------------------
  -- FK RESTRICT for auth.users: deleting auth user with a player row blocked
  -- --------------------------------------------------------------------------
  BEGIN
    DELETE FROM auth.users WHERE id = v_auth_a;
    RAISE EXCEPTION 'FAIL: deleting an auth user with a player row succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  RAISE NOTICE 'schema_test: all schema assertions passed';
END;
$schema_test$;

ROLLBACK;
