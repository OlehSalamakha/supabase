import { serve } from "https://deno.land/std@0.177.1/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  // Extract JWT from Authorization header
  const authHeader = req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid authorization header" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const token = authHeader.replace("Bearer ", "");

  // Decode JWT payload to extract user ID (JWT already verified by main)
  let userId: string;
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    userId = payload.sub;
    if (!userId) throw new Error("No sub claim");
  } catch (_) {
    return new Response(
      JSON.stringify({ error: "Invalid JWT payload" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  // Use admin client (server-side only) to delete the user
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Delete all storage objects in the user's folder before deleting the user
  const { data: files, error: listError } = await supabaseAdmin.storage
    .from("memozen")
    .list(userId);

  if (listError) {
    return new Response(
      JSON.stringify({ error: `Failed to list storage files: ${listError.message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  if (files && files.length > 0) {
    const paths = files.map((f) => `${userId}/${f.name}`);
    const { error: deleteStorageError } = await supabaseAdmin.storage
      .from("memozen")
      .remove(paths);

    if (deleteStorageError) {
      return new Response(
        JSON.stringify({ error: `Failed to delete storage files: ${deleteStorageError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }
  }

  const { error } = await supabaseAdmin.auth.admin.deleteUser(userId);

  if (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ message: "User deleted successfully" }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
