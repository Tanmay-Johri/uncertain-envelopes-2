import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { redisDelGameVersion, redisSetGameVersion } from "./redis.ts";

export type RedisSyncClaimRow = {
  out_command_id: string;
  out_command_game_id: string | null;
};

export type RedisGameVersionPort = {
  set: (
    gameId: string,
    stateVersion: number,
    ttlSeconds: number,
  ) => Promise<void>;
  del: (gameId: string) => Promise<void>;
};

const defaultRedis: RedisGameVersionPort = {
  set: redisSetGameVersion,
  del: redisDelGameVersion,
};

/** Reload command_game_id after any command completes (critical for create_game). */
export async function reloadGamePartition(
  sb: SupabaseClient,
  commandId: string,
  prev: string | null,
): Promise<string | null> {
  const { data, error } = await sb
    .from("commands")
    .select("command_game_id")
    .eq("command_id", commandId)
    .maybeSingle();
  if (error) {
    console.warn("reloadGamePartition:", error);
    return prev;
  }
  const gid = data?.command_game_id;
  return typeof gid === "string" ? gid : prev;
}

/**
 * After a command is marked processed: sync `state_version` to Redis, or delete
 * the cache key when the game reaches a terminal state.
 */
export async function redisSyncAfterSuccess(
  sb: SupabaseClient,
  cmd: RedisSyncClaimRow,
  redis: RedisGameVersionPort = defaultRedis,
): Promise<void> {
  const gameId = await reloadGamePartition(
    sb,
    cmd.out_command_id,
    cmd.out_command_game_id,
  );

  if (!gameId) {
    console.warn("redisSync: no command_game_id yet — skipping");
    return;
  }

  const { data: game, error } = await sb
    .from("games")
    .select("state_version, game_state")
    .eq("game_id", gameId)
    .maybeSingle();
  if (error || !game) {
    console.warn("redisSync: load games failed:", error);
    return;
  }

  const st = String(game.game_state);
  if (st === "game_finalised" || st === "discarded") {
    await redis.del(gameId);
    return;
  }

  await redis.set(gameId, Number(game.state_version), 3600);
}
