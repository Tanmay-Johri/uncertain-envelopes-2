/**
 * Dedicated module for UE classification unit tests (`classification.test.ts`).
 * Production code inlines this logic in index.ts — keep both in sync.
 */

/** UE001 / UE002 surfaced by stored procs (A-GAP-7). */

export function extractUeCode(error: unknown): "UE001" | "UE002" | null {
  if (!error || typeof error !== "object") return null;
  const e = error as Record<string, unknown>;

  const direct = typeof e.code === "string" ? e.code.toUpperCase() : null;
  if (direct === "UE001" || direct === "UE002") return direct;

  const msg = `${e.message ?? ""} ${e.details ?? ""} ${e.hint ?? ""}`;
  if (msg.includes("UE001")) return "UE001";
  if (msg.includes("UE002")) return "UE002";

  const js = JSON.stringify(error);
  if (js.includes("UE001")) return "UE001";
  if (js.includes("UE002")) return "UE002";

  return null;
}
