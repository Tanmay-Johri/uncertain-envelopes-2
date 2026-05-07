/** Max game_ids per request (abuse guard). */
export const MAX_GAME_IDS = 50;

/** Loose UUID shape check (Postgres `uuid` text form). */
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(s: string): boolean {
  return UUID_RE.test(s);
}

/** Build Redis keys in the same order as `gameIds`. */
export function gameVersionRedisKeys(gameIds: string[]): string[] {
  return gameIds.map((id) => `game_version:${id}`);
}

/**
 * Parse Upstash/Redis MGET `result` array into per-game versions.
 * Missing keys come back as `null` from Redis; non-numeric strings → null.
 */
export function versionsFromMget(
  gameIds: string[],
  mgetValues: unknown[],
): Record<string, number | null> {
  const out: Record<string, number | null> = {};
  for (let i = 0; i < gameIds.length; i++) {
    const id = gameIds[i];
    const raw = mgetValues[i];
    if (raw === null || raw === undefined) {
      out[id] = null;
      continue;
    }
    if (typeof raw !== "string") {
      out[id] = null;
      continue;
    }
    const n = Number(raw);
    out[id] = Number.isFinite(n) ? n : null;
  }
  return out;
}

export type ParsedGameIds =
  | { ok: true; ids: string[] }
  | { ok: false; status: number; body: Record<string, unknown> };

export function parseGameIdsPayload(body: unknown): ParsedGameIds {
  if (body === null || typeof body !== "object") {
    return {
      ok: false,
      status: 400,
      body: { error: "expected_json_object" },
    };
  }
  const raw = (body as Record<string, unknown>).game_ids;
  if (!Array.isArray(raw)) {
    return {
      ok: false,
      status: 400,
      body: { error: "game_ids_must_be_array" },
    };
  }
  if (raw.length === 0) {
    return {
      ok: false,
      status: 400,
      body: { error: "game_ids_non_empty_required" },
    };
  }
  if (raw.length > MAX_GAME_IDS) {
    return {
      ok: false,
      status: 400,
      body: { error: "game_ids_too_many", max: MAX_GAME_IDS },
    };
  }
  const ids: string[] = [];
  const seen = new Set<string>();
  for (const x of raw) {
    if (typeof x !== "string") {
      return {
        ok: false,
        status: 400,
        body: { error: "game_id_must_be_string" },
      };
    }
    const id = x.trim();
    if (!id) {
      return {
        ok: false,
        status: 400,
        body: { error: "game_id_empty" },
      };
    }
    if (!isUuid(id)) {
      return {
        ok: false,
        status: 400,
        body: { error: "game_id_invalid_uuid" },
      };
    }
    if (seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
  }
  if (ids.length === 0) {
    return {
      ok: false,
      status: 400,
      body: { error: "game_ids_non_empty_required" },
    };
  }
  return { ok: true, ids };
}

export type JwtVerifyResult =
  | { ok: true }
  | { ok: false; status: number; body: Record<string, unknown> };

export type GetStateVersionDeps = {
  verifyJwt: (authorization: string | null) => Promise<JwtVerifyResult>;
  /** Read `game_version:{id}` for each id; fail-open → all nulls on transport errors. */
  fetchVersions: (gameIds: string[]) => Promise<Record<string, number | null>>;
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
};

export async function handleGetStateVersion(
  req: Request,
  deps: GetStateVersionDeps,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        ...jsonHeaders,
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "bad_json" }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const parsed = parseGameIdsPayload(body);
  if (!parsed.ok) {
    return new Response(JSON.stringify(parsed.body), {
      status: parsed.status,
      headers: jsonHeaders,
    });
  }

  const jwt = await deps.verifyJwt(req.headers.get("authorization"));
  if (!jwt.ok) {
    return new Response(JSON.stringify(jwt.body), {
      status: jwt.status,
      headers: jsonHeaders,
    });
  }

  const versions = await deps.fetchVersions(parsed.ids);
  return new Response(JSON.stringify({ versions }), {
    status: 200,
    headers: jsonHeaders,
  });
}
