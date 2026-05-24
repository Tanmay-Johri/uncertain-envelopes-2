import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { redisSyncAfterSuccess, reloadGamePartition } from "./redis-sync.ts";

// -----------------------------------------------------------------------------
// UE001 / UE002 (mirrors classification.ts — keep classification tests passing)
// -----------------------------------------------------------------------------

function extractUeCode(error: unknown): "UE001" | "UE002" | null {
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

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

type ClaimRow = {
  out_command_id: string;
  out_claim_token: string;
  out_command_type: string;
  out_attempt_count: number;
  out_player_id: string | null;
  out_command_game_id: string | null;
};

// -----------------------------------------------------------------------------
// Webhook authentication (vault → Authorization: Bearer ...)
// -----------------------------------------------------------------------------

function requireWebhookAuth(req: Request): Response | null {
  const expected = Deno.env.get("COMMAND_PROCESSOR_WEBHOOK_SECRET");
  if (!expected) {
    console.error("COMMAND_PROCESSOR_WEBHOOK_SECRET is not configured");
    return new Response(JSON.stringify({ error: "misconfigured server" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  const got = req.headers.get("authorization");
  const want = `Bearer ${expected}`;
  if (got !== want) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  return null;
}

function requireEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`missing required env ${name}`);
  return v;
}

// -----------------------------------------------------------------------------

function rpcNameFor(commandType: string): string {
  const MAP: Record<string, string> = {
    create_game: "process_create_game",
    join_game: "process_join_game",
    leave_game: "process_leave_game",
    kick_player: "process_kick_player",
    start_game: "process_start_game",
    create_order: "process_create_order",
    cancel_order: "process_cancel_order",
    partial_cancel_order: "process_partial_cancel_order",
    end_trading: "process_end_trading",
    set_envelope_price: "process_set_envelope_price",
    finalise_game: "process_finalise_game",
    discard_game: "process_discard_game",
    add_time: "process_add_time",
  };
  const n = MAP[commandType];
  if (!n) throw new Error(`unknown command_type: ${commandType}`);
  return n;
}

async function dispatchCommand(
  sb: SupabaseClient,
  row: ClaimRow,
): Promise<void> {
  let fn: string;
  try {
    fn = rpcNameFor(row.out_command_type);
  } catch (_e) {
    throw Object.assign(new Error(`unknown command_type:${row.out_command_type}`), {
      code: "UE001",
    });
  }
  const { error } = await sb.rpc(fn, { p_command_id: row.out_command_id });
  if (error) throw error;
}

// -----------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  const authErr = requireWebhookAuth(req);
  if (authErr) return authErr;

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let payload: { command_id?: string; command_game_id?: string | null };
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "bad json" }), { status: 400 });
  }

  if (!payload.command_id || typeof payload.command_id !== "string") {
    return new Response(JSON.stringify({ error: "command_id required" }), {
      status: 400,
    });
  }

  const SUPABASE_URL = requireEnv("SUPABASE_URL");
  const SERVICE_KEY = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
  const sb = createClient(SUPABASE_URL, SERVICE_KEY);

  let partition: string | null =
    typeof payload.command_game_id === "string"
      ? payload.command_game_id
      : null;

  // ----- entry mutex (non-null game only — create_game path skips this) -----
  if (partition) {
    const { data: busy, error } = await sb.rpc(
      "command_processor_has_recent_claim",
      { p_game_id: partition },
    );
    if (error) console.warn("entry mutex RPC warn:", error);
    else if (busy === true) {
      return new Response(JSON.stringify({ skipped: true, reason: "mutex" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  // ----- drain loop -----
  let safetyCounter = 0;
  while (safetyCounter < 500) {
    safetyCounter += 1;

    if (partition) {
      const { data: busy, error } = await sb.rpc(
        "command_processor_has_recent_claim",
        { p_game_id: partition },
      );
      if (error) console.warn("loop mutex RPC warn:", error);
      else if (busy === true) break;
    }

    const {
      data: claimed,
      error: cErr,
    } = await sb.rpc("command_processor_claim_next", { p_game_id: partition }) as {
      data: ClaimRow[] | null;
      error: { message?: string } | null;
    };

    if (cErr) {
      console.error("claim_next error:", cErr);
      return new Response(JSON.stringify({ error: "claim_failed" }), {
        status: 500,
      });
    }

    if (!claimed || claimed.length === 0) break;
    const row = claimed[0];

    try {
      await dispatchCommand(sb, row);
    } catch (err) {
      const ue = extractUeCode(err);
      const att = Number(row.out_attempt_count);
      console.error("dispatch failed:", err, { ue, att });

      const terminal = ue !== null || att >= 3;
      const fn = terminal
        ? "command_processor_mark_rejected"
        : "command_processor_mark_failed";

      const { error: markErr } = await sb.rpc(fn, {
        p_command_id: row.out_command_id,
        p_claim_token: row.out_claim_token,
      });
      if (markErr) console.error(`${fn}:`, markErr);

      partition = await reloadGamePartition(sb, row.out_command_id, partition);
      continue;
    }

    const { data: ok, error: finErr } = await sb.rpc(
      "command_processor_mark_processed",
      {
        p_command_id: row.out_command_id,
        p_claim_token: row.out_claim_token,
      },
    ) as {
      data: boolean | null;
      error: { message?: string } | null;
    };

    if (finErr) {
      console.error("mark_processed RPC error:", finErr);
      return new Response(JSON.stringify({ error: "finalize_failed" }), {
        status: 500,
      });
    }

    if (ok !== true) {
      console.warn(
        "mark_processed stole token — another worker won race; exiting drain early",
      );
      break;
    }

    await redisSyncAfterSuccess(sb, row);

    partition = await reloadGamePartition(sb, row.out_command_id, partition);
  }

  if (safetyCounter >= 500) {
    console.warn("command-processor safety cap reached (500 iterations)");
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
