-- Neighborhoods Table
CREATE TABLE neighborhoods (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  district text,
  avg_property_price numeric(10,2),
  safety_index numeric(5,2),
  metro_proximity boolean,
  walkability_score integer
);

-- Properties Table
CREATE TABLE properties (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title text NOT NULL,
  neighborhood_id bigint REFERENCES neighborhoods(id),
  property_type text CHECK (
    property_type IN ('apartment', 'house', 'duplex', 'studio')
  ),
  price numeric(10,2),
  area_sqm numeric(8,2),
  bedrooms integer,
  bathrooms integer,
  amenities text[],
  energy_efficiency text,
  created_at timestamp with time zone DEFAULT now()
);

-- User Preferences Table
CREATE TABLE user_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  preferred_districts text[],
  max_budget numeric(10,2),
  min_bedrooms integer,
  preferred_amenities text[],
  language text DEFAULT 'es'
);
