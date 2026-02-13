-- Add ON DELETE CASCADE to FK constraints that reference auth.users(id)
-- so that admin.deleteUser() can succeed without foreign key violations.

-- notes.user_id → auth.users(id)
ALTER TABLE public.notes
  DROP CONSTRAINT notes_user_id_fkey,
  ADD CONSTRAINT notes_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- note_embeddings.note_id → notes(id)
-- Must also cascade so that deleting notes rows doesn't get blocked.
ALTER TABLE public.note_embeddings
  DROP CONSTRAINT note_embeddings_note_id_fkey,
  ADD CONSTRAINT note_embeddings_note_id_fkey
    FOREIGN KEY (note_id) REFERENCES public.notes(id) ON DELETE CASCADE;

-- subscription_events.user_id → auth.users(id)
ALTER TABLE public.subscription_events
  DROP CONSTRAINT subscription_events_user_id_fkey,
  ADD CONSTRAINT subscription_events_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
