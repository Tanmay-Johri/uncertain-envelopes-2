import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  gameVersionRedisKeys,
  handleGetStateVersion,
  type GetStateVersionDeps,
  versionsFromMget,
} from "./logic.ts";
import { redisMgetValues } from "./upstash-mget.ts";

async function verifyJwt(authorization: string | null) {
  if (!authorization || !authorization.toLowerCase().startsWith("bearer ")) {
    return {
      ok: false as const,
      status: 401,
      body: { error: "missing_authorization" },
    };
  }
  const jwt = authorization.slice(7).trim();
  if (!jwt) {
    return {
      ok: false as const,
      status: 401,
      body: { error: "missing_authorization" },
    };
  }

  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anon) {
    console.error("get-state-version: SUPABASE_URL / SUPABASE_ANON_KEY not set");
    return {
      ok: false as const,
      status: 500,
      body: { error: "misconfigured_server" },
    };
  }

  const sb = createClient(url, anon);
  const { data: { user }, error } = await sb.auth.getUser(jwt);
  if (error || !user) {
    return {
      ok: false as const,
      status: 401,
      body: { error: "invalid_token" },
    };
  }
  return { ok: true as const };
}

function makeDeps(): GetStateVersionDeps {
  return {
    verifyJwt,
    fetchVersions: async (gameIds: string[]) => {
      const restUrl = Deno.env.get("UPSTASH_REDIS_REST_URL");
      const restToken = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");
      if (!restUrl || !restToken) {
        console.warn("get-state-version: Redis env not set — returning nulls");
        return Object.fromEntries(gameIds.map((id) => [id, null]));
      }
      const keys = gameVersionRedisKeys(gameIds);
      const raw = await redisMgetValues(gameIds, keys, fetch, restUrl, restToken);
      return versionsFromMget(gameIds, raw);
    },
  };
}

Deno.serve(async (req: Request) => {
  try {
    return await handleGetStateVersion(req, makeDeps());
  } catch (e) {
    console.error("get-state-version:", e);
    return new Response(JSON.stringify({ error: "internal_error" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
