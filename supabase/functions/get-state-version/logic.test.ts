import { assertEquals } from "jsr:@std/assert";

import {
  gameVersionRedisKeys,
  handleGetStateVersion,
  MAX_GAME_IDS,
  parseGameIdsPayload,
  versionsFromMget,
} from "./logic.ts";

Deno.test("parseGameIdsPayload: rejects empty array", () => {
  const r = parseGameIdsPayload({ game_ids: [] });
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.status, 400);
});

Deno.test("parseGameIdsPayload: rejects too many ids", () => {
  const ids = Array.from(
    { length: MAX_GAME_IDS + 1 },
    (_, i) => `00000000-0000-4000-8000-${String(i).padStart(12, "0")}`,
  );
  const r = parseGameIdsPayload({ game_ids: ids });
  assertEquals(r.ok, false);
});

Deno.test("parseGameIdsPayload: dedupes duplicate uuids", () => {
  const id = "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee";
  const r = parseGameIdsPayload({ game_ids: [id, id, `  ${id}  `] });
  assertEquals(r.ok, true);
  if (r.ok) assertEquals(r.ids, [id]);
});

Deno.test("parseGameIdsPayload: rejects non-string id", () => {
  const r = parseGameIdsPayload({ game_ids: ["aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee", 1] });
  assertEquals(r.ok, false);
});

Deno.test("parseGameIdsPayload: rejects invalid uuid", () => {
  const r = parseGameIdsPayload({ game_ids: ["not-a-uuid"] });
  assertEquals(r.ok, false);
});

Deno.test("gameVersionRedisKeys", () => {
  assertEquals(
    gameVersionRedisKeys(["aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee"]),
    ["game_version:aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee"],
  );
});

Deno.test("versionsFromMget: mix found, missing, bad string", () => {
  const ids = [
    "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee",
    "bbbbbbbb-bbbb-4ccc-dddd-eeeeeeeeeeee",
    "cccccccc-cccc-4ccc-dddd-eeeeeeeeeeee",
  ];
  const v = versionsFromMget(ids, ["7", null, "nope"]);
  assertEquals(v[ids[0]], 7);
  assertEquals(v[ids[1]], null);
  assertEquals(v[ids[2]], null);
});

Deno.test("handleGetStateVersion: OPTIONS → 204 + CORS", async () => {
  const r = await handleGetStateVersion(
    new Request("http://x", { method: "OPTIONS" }),
    {
      verifyJwt: async () => ({ ok: true }),
      fetchVersions: async () => ({}),
    },
  );
  assertEquals(r.status, 204);
});

Deno.test("handleGetStateVersion: GET → 405", async () => {
  const r = await handleGetStateVersion(
    new Request("http://x", { method: "GET" }),
    {
      verifyJwt: async () => ({ ok: true }),
      fetchVersions: async () => ({}),
    },
  );
  assertEquals(r.status, 405);
});

Deno.test("handleGetStateVersion: bad json", async () => {
  const r = await handleGetStateVersion(
    new Request("http://x", {
      method: "POST",
      body: "not-json{{{",
      headers: { "Content-Type": "application/json" },
    }),
    {
      verifyJwt: async () => ({ ok: true }),
      fetchVersions: async () => ({}),
    },
  );
  assertEquals(r.status, 400);
});

Deno.test("handleGetStateVersion: verifyJwt receives null when no Authorization header", async () => {
  const id = "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee";
  let sawAuth: string | null = "unset";
  const r = await handleGetStateVersion(
    new Request("http://x", {
      method: "POST",
      body: JSON.stringify({ game_ids: [id] }),
      headers: { "Content-Type": "application/json" },
    }),
    {
      verifyJwt: async (authorization) => {
        sawAuth = authorization;
        return {
          ok: false,
          status: 401,
          body: { error: "missing_authorization" },
        };
      },
      fetchVersions: async () => ({ [id]: 1 }),
    },
  );
  assertEquals(sawAuth, null);
  assertEquals(r.status, 401);
});

Deno.test("handleGetStateVersion: invalid jwt path", async () => {
  const id = "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee";
  const r = await handleGetStateVersion(
    new Request("http://x", {
      method: "POST",
      body: JSON.stringify({ game_ids: [id] }),
      headers: { "Content-Type": "application/json" },
    }),
    {
      verifyJwt: async () => ({
        ok: false,
        status: 401,
        body: { error: "invalid_token" },
      }),
      fetchVersions: async () => ({ [id]: 1 }),
    },
  );
  assertEquals(r.status, 401);
  const j = await r.json();
  assertEquals(j.error, "invalid_token");
});

Deno.test("handleGetStateVersion: happy path batch", async () => {
  const a = "aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee";
  const b = "bbbbbbbb-bbbb-4ccc-dddd-eeeeeeeeeeee";
  const r = await handleGetStateVersion(
    new Request("http://x", {
      method: "POST",
      body: JSON.stringify({ game_ids: [a, b] }),
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer x",
      },
    }),
    {
      verifyJwt: async () => ({ ok: true }),
      fetchVersions: async (ids) => {
        assertEquals(ids, [a, b]);
        return { [a]: 3, [b]: null };
      },
    },
  );
  assertEquals(r.status, 200);
  const j = await r.json() as { versions: Record<string, number | null> };
  assertEquals(j.versions[a], 3);
  assertEquals(j.versions[b], null);
});
