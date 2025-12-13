-- Add raw_text column to notes table
-- This column will store the raw transcription text before any processing
ALTER TABLE notes
ADD COLUMN raw_text TEXT DEFAULT '';
