ALTER TABLE neighborhoods ENABLE ROW LEVEL SECURITY;

-- Read-only for everyone (public listing OK)
DROP POLICY IF EXISTS "Public can view neighborhood data" ON neighborhoods;
CREATE POLICY "Public can view neighborhood data"
ON neighborhoods
FOR SELECT
USING (true);

-- (Optional) lock down writes unless you have an admin flow
DROP POLICY IF EXISTS "Neighborhoods: no public writes" ON neighborhoods;
CREATE POLICY "Neighborhoods: no public writes"
ON neighborhoods
FOR INSERT TO public
WITH CHECK (false);

CREATE POLICY "Neighborhoods: no public updates"
ON neighborhoods
FOR UPDATE TO public
USING (false)
WITH CHECK (false);

CREATE POLICY "Neighborhoods: no public deletes"
ON neighborhoods
FOR DELETE TO public
USING (false);

-- Note: Supabase's service_role bypasses RLS automatically.

-- ================================
-- PROPERTIES (public under price cap,
--             authenticated see all)
-- ================================
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

-- 1) Public can view only “affordable” listings
DROP POLICY IF EXISTS "Public can view affordable properties" ON properties;
CREATE POLICY "Public can view affordable properties"
ON properties
FOR SELECT TO anon, authenticated
USING (COALESCE(price, 1e15) < 500000);

-- 2) Authenticated users can view all
DROP POLICY IF EXISTS "Authenticated users can view all properties" ON properties;
CREATE POLICY "Authenticated users can view all properties"
ON properties
FOR SELECT TO authenticated
USING (auth.role() = 'authenticated');

-- (Optional) Ownership-based writes for authenticated listers
-- Assumes properties.owner_id (uuid) exists
DROP POLICY IF EXISTS "Owners can insert their properties" ON properties;
CREATE POLICY "Owners can insert their properties"
ON properties
FOR INSERT TO authenticated
WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can update their properties" ON properties;
CREATE POLICY "Owners can update their properties"
ON properties
FOR UPDATE TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can delete their properties" ON properties;
CREATE POLICY "Owners can delete their properties"
ON properties
FOR DELETE TO authenticated
USING (owner_id = auth.uid());

-- ================================
-- USER PREFERENCES (private per user)
-- ================================
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Read own prefs
DROP POLICY IF EXISTS "Users can read own preferences" ON user_preferences;
CREATE POLICY "Users can read own preferences"
ON user_preferences
FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- Create own prefs
DROP POLICY IF EXISTS "Users can insert own preferences" ON user_preferences;
CREATE POLICY "Users can insert own preferences"
ON user_preferences
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Update only own prefs
DROP POLICY IF EXISTS "Users can update own preferences" ON user_preferences;
CREATE POLICY "Users can update own preferences"
ON user_preferences
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Delete only own prefs
DROP POLICY IF EXISTS "Users can delete own preferences" ON user_preferences;
CREATE POLICY "Users can delete own preferences"
ON user_preferences
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ================================
-- RECOMMENDED INDEXES for RLS filters
-- ================================
CREATE INDEX IF NOT EXISTS idx_properties_price ON properties (price);
CREATE INDEX IF NOT EXISTS idx_properties_owner ON properties (owner_id);
CREATE INDEX IF NOT EXISTS idx_user_prefs_user ON user_preferences (user_id);
