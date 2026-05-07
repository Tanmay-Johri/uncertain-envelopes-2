import { assertEquals } from "jsr:@std/assert";

import { extractUeCode } from "./classification.ts";

Deno.test("extractUeCode: structured code UE001 / UE002 (case insensitive)", () => {
  assertEquals(extractUeCode({ code: "ue001" }), "UE001");
  assertEquals(extractUeCode({ code: "UE002" }), "UE002");
});

Deno.test("extractUeCode: Postgres-style message text", () => {
  assertEquals(
    extractUeCode({ message: "invalid state transition (UE002)" }),
    "UE002",
  );
});

Deno.test("extractUeCode: serialized JSON substring", () => {
  assertEquals(
    extractUeCode({ nested: "prefix UE001 suffix", code: null }),
    "UE001",
  );
});

Deno.test("extractUeCode: unrelated errors → null", () => {
  assertEquals(extractUeCode({ code: "23503", message: "fk violation" }), null);
  assertEquals(extractUeCode(null), null);
});
