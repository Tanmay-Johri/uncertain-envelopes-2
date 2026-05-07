import { assertEquals } from "jsr:@std/assert";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

import {
  redisSyncAfterSuccess,
  reloadGamePartition,
  type RedisGameVersionPort,
} from "./redis-sync.ts";

const gameId = "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee";

function makeSupabaseStub(
  opts: {
    commandGameId: string | null;
    gameRow: { game_state: string; state_version: number } | null;
    gameError?: unknown;
  },
) {
  return {
    from(table: string) {
      if (table === "commands") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: opts.commandGameId === null
                  ? null
                  : { command_game_id: opts.commandGameId },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === "games") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: opts.gameRow,
                error: opts.gameError ?? null,
              }),
            }),
          }),
        };
      }
      throw new Error("unknown table " + table);
    },
  };
}

function captureRedis(): RedisGameVersionPort & {
  setCalls: [string, number, number][];
  delCalls: string[];
} {
  const setCalls: [string, number, number][] = [];
  const delCalls: string[] = [];
  return {
    setCalls,
    delCalls,
    set: async (g, v, t) => {
      setCalls.push([g, v, t]);
    },
    del: async (g) => {
      delCalls.push(g);
    },
  };
}

Deno.test("redisSyncAfterSuccess: game_finalised → del only", async () => {
  const redis = captureRedis();
  const sb = makeSupabaseStub({
    commandGameId: gameId,
    gameRow: { game_state: "game_finalised", state_version: 9 },
  });
  await redisSyncAfterSuccess(sb as unknown as SupabaseClient, {
    out_command_id: "cmd1",
    out_command_game_id: gameId,
  }, redis);
  assertEquals(redis.delCalls, [gameId]);
  assertEquals(redis.setCalls.length, 0);
});

Deno.test("redisSyncAfterSuccess: discarded → del only", async () => {
  const redis = captureRedis();
  const sb = makeSupabaseStub({
    commandGameId: gameId,
    gameRow: { game_state: "discarded", state_version: 2 },
  });
  await redisSyncAfterSuccess(sb as unknown as SupabaseClient, {
    out_command_id: "cmd1",
    out_command_game_id: gameId,
  }, redis);
  assertEquals(redis.delCalls, [gameId]);
  assertEquals(redis.setCalls.length, 0);
});

Deno.test("redisSyncAfterSuccess: trading_started → set with ttl 3600", async () => {
  const redis = captureRedis();
  const sb = makeSupabaseStub({
    commandGameId: gameId,
    gameRow: { game_state: "trading_started", state_version: 11 },
  });
  await redisSyncAfterSuccess(sb as unknown as SupabaseClient, {
    out_command_id: "cmd1",
    out_command_game_id: gameId,
  }, redis);
  assertEquals(redis.delCalls.length, 0);
  assertEquals(redis.setCalls, [[gameId, 11, 3600]]);
});

Deno.test("redisSyncAfterSuccess: no command_game_id after reload → no redis", async () => {
  const redis = captureRedis();
  const sb = makeSupabaseStub({
    commandGameId: null,
    gameRow: { game_state: "trading_started", state_version: 1 },
  });
  await redisSyncAfterSuccess(sb as unknown as SupabaseClient, {
    out_command_id: "cmd1",
    out_command_game_id: null,
  }, redis);
  assertEquals(redis.setCalls.length, 0);
  assertEquals(redis.delCalls.length, 0);
});

Deno.test("redisSyncAfterSuccess: games row missing → no redis", async () => {
  const redis = captureRedis();
  const sb = makeSupabaseStub({
    commandGameId: gameId,
    gameRow: null,
  });
  await redisSyncAfterSuccess(sb as unknown as SupabaseClient, {
    out_command_id: "cmd1",
    out_command_game_id: gameId,
  }, redis);
  assertEquals(redis.setCalls.length, 0);
  assertEquals(redis.delCalls.length, 0);
});

Deno.test("reloadGamePartition: returns new game id from commands row", async () => {
  const sb = makeSupabaseStub({
    commandGameId: gameId,
    gameRow: { game_state: "created", state_version: 1 },
  });
  const gid = await reloadGamePartition(
    sb as unknown as SupabaseClient,
    "cmd1",
    null,
  );
  assertEquals(gid, gameId);
});
