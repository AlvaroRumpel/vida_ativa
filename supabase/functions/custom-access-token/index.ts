// supabase/functions/custom-access-token/index.ts
// Custom Access Token Hook — injeta tenant_id e role em app_metadata
//
// Tipo de hook: Custom Access Token (roda em todo login + refresh)
// Supabase Auto-injects: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// SECURITY NOTES:
// - CVE-2025-48757: SEMPRE usar app_metadata (server-set), NUNCA user_metadata
// - Service role key via Deno.env.get() — nunca hardcoded
// - Spread completo de claims existentes para não perder iss/aud/exp/sub
//
// Payload recebido DO Supabase Auth:
//   { user_id: string, claims: object, authentication_method: string }
// Payload retornado PARA Supabase Auth:
//   { claims: { ...original_claims, app_metadata: { tenant_id, role } } }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38";

serve(async (req: Request) => {
  // Auth Hooks only accept POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Validate required environment variables before any logic
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("FATAL: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set");
    return new Response(
      JSON.stringify({ error: "Auth hook misconfigured — missing env vars" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    // Parse Auth Hook payload from Supabase Auth server
    const event = await req.json();
    const user_id: string = event.user_id;
    const claims: Record<string, unknown> = event.claims ?? {};

    if (!user_id) {
      console.error("Auth Hook payload missing user_id");
      return new Response(JSON.stringify({ claims }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Initialize Supabase Admin client with service role key
    // This bypasses RLS — needed to query memberships for any user
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    // Query memberships to get tenant_id + role for this user
    // Uses .maybeSingle() instead of .single() to avoid error when no membership
    const { data: membership, error } = await supabaseAdmin
      .from("memberships")
      .select("tenant_id, role")
      .eq("user_id", user_id)
      .maybeSingle();

    if (error) {
      console.error(`Membership query error for user ${user_id}:`, error.message);
      // Return claims unchanged — RLS will deny access (defense-in-depth)
      return new Response(JSON.stringify({ claims }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!membership) {
      // User has no membership — not part of any tenant
      // Return claims unchanged; RLS policies will deny access to tenant data
      console.warn(`No membership found for user ${user_id} — returning claims unchanged`);
      return new Response(JSON.stringify({ claims }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // CR-01: Validate tenant_id consistency — prevent silent overwrite on refresh
    // If user already has a tenant_id in claims, it must match the membership record.
    // Mismatch suggests a session hijack attempt or misconfigured membership data.
    const existingTenantId = (claims.app_metadata as Record<string, unknown>)?.tenant_id;
    if (existingTenantId && existingTenantId !== membership.tenant_id) {
      console.warn(
        `Auth Hook: tenant_id mismatch for user ${user_id}. ` +
        `Existing: ${existingTenantId}, Membership: ${membership.tenant_id}. ` +
        `Returning claims unchanged (potential session hijack attempt).`
      );
      return new Response(JSON.stringify({ claims }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Inject tenant_id and role into app_metadata
    // CRITICAL: spread existing claims first to preserve iss, aud, exp, sub, role, etc.
    // CRITICAL: app_metadata only (NOT user_metadata) — CVE-2025-48757
    const modifiedClaims = {
      ...claims,
      app_metadata: {
        ...((claims.app_metadata as Record<string, unknown>) ?? {}),
        tenant_id: membership.tenant_id,
        role: membership.role,
      },
    };

    console.log(
      `Auth Hook: injected tenant_id=${membership.tenant_id} role=${membership.role} for user ${user_id}`
    );

    return new Response(JSON.stringify({ claims: modifiedClaims }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    // WR-01: Differentiate JSON parse errors (400) from unexpected errors (500)
    if (err instanceof SyntaxError) {
      console.error("Auth Hook JSON parse error:", err.message);
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    console.error("Auth Hook unexpected error:", err);
    // Return 500 — Supabase Auth will fail login (safer than issuing unmodified token)
    return new Response(
      JSON.stringify({ error: "Internal server error in auth hook" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
