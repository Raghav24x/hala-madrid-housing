CREATE OR REPLACE FUNCTION match_properties(
  p_user_id uuid,
  p_max_budget numeric,
  p_preferred_districts text[],
  p_price_weight numeric DEFAULT 0.5,     -- tweak weights if you like
  p_district_weight numeric DEFAULT 0.5,
  p_limit integer DEFAULT 10
)
RETURNS TABLE (
  property_id bigint,
  match_score numeric
)
LANGUAGE sql
AS $$
  WITH prefs AS (
    SELECT ARRAY_REMOVE(p_preferred_districts, NULL) AS districts
  ),
  priced AS (
    SELECT
      p.id AS property_id,
      -- Price closeness: 1 when price == budget, 0 when price == 0 or price == 2*budget (or worse).
      -- We clamp and only consider properties <= budget.
      GREATEST(
        0,
        LEAST(
          1,
          1 - (ABS(p.price - p_max_budget) / NULLIF(p_max_budget, 0))
        )
      ) AS price_score,
      p.neighborhood_id
    FROM properties p
    WHERE
      p.price IS NOT NULL
      AND p.price >= 0
      AND (p_max_budget IS NULL OR p.price <= p_max_budget)
  ),
  district_fit AS (
    SELECT
      pr.property_id,
      CASE
        WHEN prefs.districts IS NULL OR CARDINALITY(prefs.districts) = 0 THEN 0
        WHEN n.name = ANY(prefs.districts) THEN 1
        ELSE 0
      END AS district_score
    FROM priced pr
    LEFT JOIN neighborhoods n ON n.id = pr.neighborhood_id
    CROSS JOIN prefs
  )
  SELECT
    pr.property_id,
    ROUND(
      (pr.price_score * p_price_weight) +
      (df.district_score * p_district_weight),
      4
    ) AS match_score
  FROM priced pr
  JOIN district_fit df USING (property_id)
  ORDER BY match_score DESC, pr.property_id
  LIMIT COALESCE(p_limit, 10)
$$;

-- ============================================
-- NEIGHBORHOOD RECOMMENDER
-- - Normalizes to [0,1] if your columns aren't already 0–1
-- - Uses COALESCE to handle NULLs
-- - Weights are tunable
-- ============================================

CREATE OR REPLACE FUNCTION recommend_neighborhoods(
  p_user_id uuid,
  p_safety_weight numeric DEFAULT 0.3,
  p_metro_weight  numeric DEFAULT 0.2,
  p_walk_weight   numeric DEFAULT 0.5,
  p_limit integer DEFAULT 5
)
RETURNS TABLE (
  neighborhood_name text,
  recommendation_score numeric
)
LANGUAGE sql
AS $$
  WITH base AS (
    SELECT
      n.name,
      -- If your indices are already 0..1, these COALESCEs are fine.
      -- If not, replace with min-max normalization over your data.
      COALESCE(n.safety_index, 0)     AS safety_norm,
      CASE WHEN COALESCE(n.metro_proximity, false) THEN 1 ELSE 0 END AS metro_norm,
      COALESCE(n.walkability_score, 0) AS walk_norm
    FROM neighborhoods n
  )
  SELECT
    b.name AS neighborhood_name,
    ROUND(
      (b.safety_norm * p_safety_weight) +
      (b.metro_norm  * p_metro_weight)  +
      (b.walk_norm   * p_walk_weight),
      4
    ) AS recommendation_score
  FROM base b
  ORDER BY recommendation_score DESC, neighborhood_name
  LIMIT COALESCE(p_limit, 5)
$$;

-- ============================================
-- RECOMMENDED INDEXES
-- ============================================

-- Fast price filtering + neighborhood joins
CREATE INDEX IF NOT EXISTS idx_properties_price ON properties (price);
CREATE INDEX IF NOT EXISTS idx_properties_neighborhood ON properties (neighborhood_id);

-- Fast district lookups by name
CREATE INDEX IF NOT EXISTS idx_neighborhoods_name ON neighborhoods (name);

-- (Optional) If you frequently filter by safety/walkability thresholds:
-- CREATE INDEX IF NOT EXISTS idx_neighborhoods_scores ON neighborhoods (safety_index, walkability_score);
