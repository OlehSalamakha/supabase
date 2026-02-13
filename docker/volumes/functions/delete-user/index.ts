import { serve } from "https://deno.land/std@0.177.1/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Recursively list and delete all objects under a storage folder.
// Returns an error message string on failure, or null on success.
async function deleteFolder(
  storage: ReturnType<ReturnType<typeof createClient>["storage"]["from"]>,
  bucket: string,
  folder: string,
): Promise<string | null> {
  const { data: items, error } = await storage.from(bucket).list(folder);
  if (error) return error.message;
  if (!items || items.length === 0) return null;

  // Items with an id are files; items without are virtual folders.
  const files = items.filter((i: { id: string | null }) => i.id !== null);
  const subfolders = items.filter((i: { id: string | null }) => i.id === null);

  if (files.length > 0) {
    const paths = files.map((f: { name: string }) => `${folder}/${f.name}`);
    const { error: removeError } = await storage.from(bucket).remove(paths);
    if (removeError) return removeError.message;
  }

  for (const sub of subfolders) {
    const err = await deleteFolder(storage, bucket, `${folder}/${sub.name}`);
    if (err) return err;
  }

  return null;
}

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

  // Recursively delete all storage objects in the user's folder
  const storageError = await deleteFolder(
    supabaseAdmin.storage as any,
    "memozen",
    userId,
  );
  if (storageError) {
    return new Response(
      JSON.stringify({ error: `Failed to delete storage files: ${storageError}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
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
