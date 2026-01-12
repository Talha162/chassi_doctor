-- ============================================================================
-- ADMIN ADJUSTMENTS MODULE
-- Stores admin-configured adjustments that Gemini will rank and filter
-- ============================================================================

-- Main table: admin_adjustments
-- Stores the core adjustment records with single symptom reference
CREATE TABLE IF NOT EXISTS admin_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Single symptom reference (one adjustment group per symptom)
  symptom_id UUID NOT NULL REFERENCES chassis_symptom(id) ON DELETE CASCADE,
  
  -- Additional metadata
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);

-- Junction table: admin_adjustments_track_configs
-- Maps admin adjustments to applicable track configurations
CREATE TABLE IF NOT EXISTS admin_adjustments_track_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_adjustment_id UUID NOT NULL REFERENCES admin_adjustments(id) ON DELETE CASCADE,
  track_config_id UUID NOT NULL REFERENCES track_configuration(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(admin_adjustment_id, track_config_id)
);

-- Junction table: admin_adjustments_issues
-- Maps admin adjustments to applicable chassis issues
CREATE TABLE IF NOT EXISTS admin_adjustments_issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_adjustment_id UUID NOT NULL REFERENCES admin_adjustments(id) ON DELETE CASCADE,
  issue_id UUID NOT NULL REFERENCES chassis_issue_option(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(admin_adjustment_id, issue_id)
);

-- Main table: admin_adjustment_recommendations
-- Stores individual adjustment recommendations with ranking capability
CREATE TABLE IF NOT EXISTS admin_adjustment_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_adjustment_id UUID NOT NULL REFERENCES admin_adjustments(id) ON DELETE CASCADE,
  
  -- Recommendation details
  title TEXT NOT NULL,
  details TEXT NOT NULL,
  category TEXT,
  
  -- Ranking fields for Gemini to use
  base_rank INTEGER DEFAULT 0,
  gemini_score NUMERIC(3, 2) DEFAULT NULL,
  final_rank INTEGER DEFAULT NULL,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- admin_adjustments indexes
CREATE INDEX IF NOT EXISTS idx_admin_adjustments_symptom_id 
  ON admin_adjustments(symptom_id);
CREATE INDEX IF NOT EXISTS idx_admin_adjustments_created_at 
  ON admin_adjustments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_adjustments_is_active 
  ON admin_adjustments(is_active);

-- admin_adjustments_track_configs indexes
CREATE INDEX IF NOT EXISTS idx_admin_adj_track_adj_id 
  ON admin_adjustments_track_configs(admin_adjustment_id);
CREATE INDEX IF NOT EXISTS idx_admin_adj_track_config_id 
  ON admin_adjustments_track_configs(track_config_id);

-- admin_adjustments_issues indexes
CREATE INDEX IF NOT EXISTS idx_admin_adj_issues_adj_id 
  ON admin_adjustments_issues(admin_adjustment_id);
CREATE INDEX IF NOT EXISTS idx_admin_adj_issues_issue_id 
  ON admin_adjustments_issues(issue_id);

-- admin_adjustment_recommendations indexes
CREATE INDEX IF NOT EXISTS idx_admin_rec_adj_id 
  ON admin_adjustment_recommendations(admin_adjustment_id);
CREATE INDEX IF NOT EXISTS idx_admin_rec_final_rank 
  ON admin_adjustment_recommendations(final_rank);
CREATE INDEX IF NOT EXISTS idx_admin_rec_is_active 
  ON admin_adjustment_recommendations(is_active);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_admin_adj_symptom_active 
  ON admin_adjustments(symptom_id, is_active);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE admin_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_adjustments_track_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_adjustments_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_adjustment_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_adjustments
CREATE POLICY "Allow authenticated users to view admin_adjustments"
  ON admin_adjustments FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to insert admin_adjustments"
  ON admin_adjustments FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to update admin_adjustments"
  ON admin_adjustments FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to delete admin_adjustments"
  ON admin_adjustments FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS Policies for admin_adjustments_track_configs
CREATE POLICY "Allow authenticated users to view track configs"
  ON admin_adjustments_track_configs FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to manage track configs"
  ON admin_adjustments_track_configs FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to delete track configs"
  ON admin_adjustments_track_configs FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS Policies for admin_adjustments_issues
CREATE POLICY "Allow authenticated users to view issues"
  ON admin_adjustments_issues FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to manage issues"
  ON admin_adjustments_issues FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to delete issues"
  ON admin_adjustments_issues FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS Policies for admin_adjustment_recommendations
CREATE POLICY "Allow authenticated users to view recommendations"
  ON admin_adjustment_recommendations FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to insert recommendations"
  ON admin_adjustment_recommendations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to update recommendations"
  ON admin_adjustment_recommendations FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to delete recommendations"
  ON admin_adjustment_recommendations FOR DELETE
  USING (auth.role() = 'authenticated');

-- ============================================================================
-- USEFUL VIEWS FOR QUERIES
-- ============================================================================

-- View to get adjustments with all related data (for listing in admin panel)
CREATE OR REPLACE VIEW admin_adjustments_with_details AS
SELECT 
  aa.id,
  aa.symptom_id,
  cs.title as symptom_title,
  aa.created_at,
  aa.is_active,
  JSON_AGG(DISTINCT jsonb_build_object(
    'id', tc.id,
    'track_type', tc.track_type,
    'surface_type', tc.surface_type,
    'weather_condition', tc.weather_condition
  )) FILTER (WHERE tc.id IS NOT NULL) as track_configs,
  JSON_AGG(DISTINCT jsonb_build_object(
    'id', cio.id,
    'title', cio.title,
    'description', cio.description
  )) FILTER (WHERE cio.id IS NOT NULL) as issues
FROM admin_adjustments aa
LEFT JOIN chassis_symptom cs ON aa.symptom_id = cs.id
LEFT JOIN admin_adjustments_track_configs aatc ON aa.id = aatc.admin_adjustment_id
LEFT JOIN track_configuration tc ON aatc.track_config_id = tc.id
LEFT JOIN admin_adjustments_issues aai ON aa.id = aai.admin_adjustment_id
LEFT JOIN chassis_issue_option cio ON aai.issue_id = cio.id
GROUP BY aa.id, aa.symptom_id, cs.title, aa.created_at, aa.is_active;

-- View to get top recommendations for a given symptom (for user display)
-- Filters to show only top 3-4 with highest final_rank
CREATE OR REPLACE VIEW top_recommendations_by_symptom AS
SELECT 
  aa.symptom_id,
  aar.id,
  aar.title,
  aar.details,
  aar.category,
  aar.final_rank,
  aar.gemini_score,
  ROW_NUMBER() OVER (PARTITION BY aa.symptom_id ORDER BY aar.final_rank ASC NULLS LAST, aar.base_rank DESC) as rank_position
FROM admin_adjustments aa
JOIN admin_adjustment_recommendations aar ON aa.id = aar.admin_adjustment_id
WHERE aa.is_active = TRUE AND aar.is_active = TRUE
ORDER BY aa.symptom_id, aar.final_rank ASC NULLS LAST;
