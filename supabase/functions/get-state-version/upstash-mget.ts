/**
 * Upstash Redis REST: MGET for keys `game_version:{uuid}`.
 * Fail-open: on any error, returns all-null map for the requested game ids.
 */

export async function redisMgetValues(
  gameIds: string[],
  keys: string[],
  fetchFn: typeof fetch,
  restUrl: string,
  restToken: string,
): Promise<unknown[]> {
  if (keys.length === 0) return [];
  try {
    const res = await fetchFn(restUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${restToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(["MGET", ...keys]),
    });
    if (!res.ok) {
      console.warn("redisMgetValues: non-OK", res.status);
      return gameIds.map(() => null);
    }
    const json = (await res.json()) as { result?: unknown };
    const arr = json.result;
    if (!Array.isArray(arr) || arr.length !== keys.length) {
      console.warn("redisMgetValues: unexpected result shape");
      return gameIds.map(() => null);
    }
    return arr;
  } catch (e) {
    console.warn("redisMgetValues: fetch failed (fail-open)", e);
    return gameIds.map(() => null);
  }
}
