/**
 * Thin Upstash Redis REST helpers (fail-open — logs only).
 * Env: UPSTASH_REDIS_REST_URL (e.g. https://xxxx.upstash.io)
 *      UPSTASH_REDIS_REST_TOKEN
 */

async function redisCommand(
  body: unknown,
): Promise<{ ok: boolean; status: number }> {
  const url = Deno.env.get("UPSTASH_REDIS_REST_URL");
  const token = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");
  if (!url || !token) {
    console.warn("redisCommand: Redis env vars not set — skipping");
    return { ok: false, status: 0 };
  }
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    return { ok: res.ok, status: res.status };
  } catch (e) {
    console.warn("redisCommand: fetch failed (fail-open):", e);
    return { ok: false, status: 0 };
  }
}

/**
 * SET key → value with EX ttl seconds.
 * Each successful write uses Redis SET with EX: the TTL is **reset** from
 * zero on every call (standard Redis semantics), so active games keep a fresh
 * 1-hour window while trading continues.
 */
export async function redisSetGameVersion(
  gameId: string,
  stateVersion: number,
  ttlSeconds: number,
): Promise<void> {
  const key = `game_version:${gameId}`;
  const r = await redisCommand(["SET", key, String(stateVersion), "EX", ttlSeconds]);
  if (!r.ok) {
    console.warn(
      `redisSetGameVersion: non-OK response status=${r.status} key=${key}`,
    );
  }
}

/** DEL game_version:{game_id} — ignore errors */
export async function redisDelGameVersion(gameId: string): Promise<void> {
  const key = `game_version:${gameId}`;
  const r = await redisCommand(["DEL", key]);
  if (!r.ok) {
    console.warn(
      `redisDelGameVersion: non-OK response status=${r.status} key=${key}`,
    );
  }
}
