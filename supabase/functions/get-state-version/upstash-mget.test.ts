import { assertEquals } from "jsr:@std/assert";

import { redisMgetValues } from "./upstash-mget.ts";

Deno.test("redisMgetValues: OK maps result array", async () => {
  const fetchFn: typeof fetch = async (url, init) => {
    const r = new Request(url!.toString(), init);
    const body = (await r.json()) as unknown[];
    assertEquals(body[0], "MGET");
    return new Response(JSON.stringify({ result: ["1", null, "42"] }), {
      status: 200,
    });
  };
  const keys = ["game_version:a", "game_version:b", "game_version:c"];
  const gameIds = ["a", "b", "c"];
  const out = await redisMgetValues(gameIds, keys, fetchFn, "https://x", "tok");
  assertEquals(out, ["1", null, "42"]);
});

Deno.test("redisMgetValues: non-OK → nulls", async () => {
  const fetchFn: typeof fetch = async () =>
    new Response("", { status: 503 });
  const gameIds = ["a", "b"];
  const out = await redisMgetValues(gameIds, ["k1", "k2"], fetchFn, "u", "t");
  assertEquals(out, [null, null]);
});

Deno.test("redisMgetValues: network throw → nulls", async () => {
  const fetchFn: typeof fetch = async () => {
    throw new Error("boom");
  };
  const gameIds = ["x"];
  const out = await redisMgetValues(gameIds, ["k"], fetchFn, "u", "t");
  assertEquals(out, [null]);
});

Deno.test("redisMgetValues: wrong result length → nulls", async () => {
  const fetchFn: typeof fetch = async () =>
    new Response(JSON.stringify({ result: ["1"] }), { status: 200 });
  const gameIds = ["a", "b"];
  const out = await redisMgetValues(gameIds, ["k1", "k2"], fetchFn, "u", "t");
  assertEquals(out, [null, null]);
});
