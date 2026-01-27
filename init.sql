-- API Keys Platform Database Schema
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    permission_mode VARCHAR(20) NOT NULL DEFAULT 'union'
        CHECK (permission_mode IN ('union', 'overrides_only')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- API Keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key_hash VARCHAR(255) NOT NULL,
    key_prefix VARCHAR(12) NOT NULL,
    name VARCHAR(255),
    description TEXT,
    tier VARCHAR(50) DEFAULT 'basic' CHECK (tier IN ('basic', 'pro', 'enterprise', 'ultimate')),
    rate_limit INTEGER DEFAULT 1000,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    granted_modules TEXT[] DEFAULT '{}',
    granted_module_groups TEXT[] DEFAULT '{}',
    allowed_ips INET[],
    allowed_domains TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT unique_key_hash UNIQUE (key_hash)
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Validation logs table (for analytics)
CREATE TABLE IF NOT EXISTS validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE SET NULL,
    is_valid BOOLEAN NOT NULL,
    reason VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    response_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_is_active ON api_keys(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_validations_api_key_id ON validations(api_key_id);
CREATE INDEX IF NOT EXISTS idx_validations_created_at ON validations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_granted_modules ON api_keys USING GIN(granted_modules);
CREATE INDEX IF NOT EXISTS idx_api_keys_granted_module_groups ON api_keys USING GIN(granted_module_groups);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS module_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS module_group_modules (
    module_group_id UUID NOT NULL REFERENCES module_groups(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    PRIMARY KEY (module_group_id, module_id)
);

CREATE TABLE IF NOT EXISTS perm_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS perm_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(20) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO perm_actions (key) VALUES
    ('create'),
    ('read'),
    ('update'),
    ('delete')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS perm_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID NOT NULL REFERENCES perm_modules(id) ON DELETE CASCADE,
    action_id UUID NOT NULL REFERENCES perm_actions(id) ON DELETE RESTRICT,
    perm_key VARCHAR(150) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_perm_module_action UNIQUE (module_id, action_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_permissions_module_id ON perm_permissions(module_id);
CREATE INDEX IF NOT EXISTS idx_perm_permissions_action_id ON perm_permissions(action_id);

CREATE TABLE IF NOT EXISTS perm_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS perm_variant_rules (
    variant_id UUID NOT NULL REFERENCES perm_variants(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES perm_permissions(id) ON DELETE CASCADE,
    effect VARCHAR(10) NOT NULL CHECK (effect IN ('allow', 'deny')),
    PRIMARY KEY (variant_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_variant_rules_permission_id ON perm_variant_rules(permission_id);

CREATE TABLE IF NOT EXISTS perm_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS perm_group_variants (
    group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    variant_id UUID NOT NULL REFERENCES perm_variants(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, variant_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_group_variants_variant_id ON perm_group_variants(variant_id);

-- Direct group-permission assignments (simplified matrix)
CREATE TABLE IF NOT EXISTS perm_group_permissions (
    group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES perm_permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (group_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_group_permissions_permission_id ON perm_group_permissions(permission_id);

CREATE TABLE IF NOT EXISTS perm_group_edges (
    parent_group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    child_group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (parent_group_id, child_group_id),
    CONSTRAINT perm_group_edges_no_self CHECK (parent_group_id <> child_group_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_group_edges_child ON perm_group_edges(child_group_id);

CREATE TABLE IF NOT EXISTS perm_group_closure (
    ancestor_group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    descendant_group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    depth INTEGER NOT NULL,
    PRIMARY KEY (ancestor_group_id, descendant_group_id),
    CONSTRAINT perm_group_closure_depth_nonneg CHECK (depth >= 0)
);

CREATE INDEX IF NOT EXISTS idx_perm_group_closure_descendant ON perm_group_closure(descendant_group_id);

CREATE TABLE IF NOT EXISTS perm_user_groups (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES perm_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_perm_user_groups_group_id ON perm_user_groups(group_id);

CREATE TABLE IF NOT EXISTS perm_user_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES perm_permissions(id) ON DELETE CASCADE,
    effect VARCHAR(10) NOT NULL CHECK (effect IN ('allow', 'deny')),
    reason TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_perm_user_overrides_user_id ON perm_user_overrides(user_id);
CREATE INDEX IF NOT EXISTS idx_perm_user_overrides_permission_id ON perm_user_overrides(permission_id);
CREATE INDEX IF NOT EXISTS idx_perm_user_overrides_expires_at ON perm_user_overrides(expires_at);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_perm_user_overrides_no_expiry
  ON perm_user_overrides(user_id, permission_id)
  WHERE expires_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_perm_user_overrides_with_expiry
  ON perm_user_overrides(user_id, permission_id, expires_at)
  WHERE expires_at IS NOT NULL;

-- Seed default admin user (password: admin123 - CHANGE IN PRODUCTION!)
-- Password hash for 'admin123' using bcrypt
INSERT INTO users (email, name, password_hash, role)
VALUES (
    'admin@licenseguard.local',
    'Administrator',
    '$2b$12$ZYdwbsHsIOtl5KIlrZxIuOyDKwqBOEMnOWQozMGN.Vs0qPoExZ0Ka',
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- Menu items table for dynamic menu management
CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
    module_key VARCHAR(100) NOT NULL,
    label_key VARCHAR(100) NOT NULL,
    label_default VARCHAR(255) NOT NULL,
    href VARCHAR(500),  -- NULL for group headers
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    required_permission JSONB,  -- e.g. {"moduleKey": "admin.users", "action": "read"}
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for menu_items
CREATE INDEX IF NOT EXISTS idx_menu_items_parent ON menu_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_active ON menu_items(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_module_key ON menu_items(module_key);

-- Unique constraint on module_key + href (except NULL hrefs)
CREATE UNIQUE INDEX IF NOT EXISTS idx_menu_items_unique_href
    ON menu_items(module_key, href)
    WHERE href IS NOT NULL;

-- Trigger for menu_items updated_at
CREATE OR REPLACE FUNCTION update_menu_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS menu_items_updated_at ON menu_items;
CREATE TRIGGER menu_items_updated_at
    BEFORE UPDATE ON menu_items
    FOR EACH ROW
    EXECUTE FUNCTION update_menu_items_updated_at();

-- Table for user-specific menu sorting and aliases
CREATE TABLE IF NOT EXISTS user_menu_preferences (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
    custom_sort_order INTEGER NOT NULL,
    custom_label VARCHAR(255),
    PRIMARY KEY (user_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS idx_user_menu_preferences_user ON user_menu_preferences(user_id);

-- Seed default menu items
-- Hierarchical Menu Structure with proper UUIDs
-- Parent items (group headers with no href, collapsible sections)
INSERT INTO menu_items (id, parent_id, module_key, label_key, label_default, href, icon, sort_order, is_active) VALUES
  ('10000000-0000-0000-0000-000000000001', NULL, 'user', 'menu.user.title', 'User Admin', NULL, 'users', 10, true),
  ('20000000-0000-0000-0000-000000000001', NULL, 'permissions', 'menu.permissions.title', 'Permissions', NULL, 'shield', 20, true),
  ('40000000-0000-0000-0000-000000000001', NULL, 'tour', 'menu.tour.title', 'Tour', NULL, 'map', 25, true),
  ('30000000-0000-0000-0000-000000000001', NULL, 'apikeys', 'menu.apikeys.title', 'API Keys', NULL, 'key', 30, true)
ON CONFLICT (id) DO UPDATE SET
    label_default = EXCLUDED.label_default,
    href = EXCLUDED.href,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order,
    parent_id = EXCLUDED.parent_id;

-- User Admin children
INSERT INTO menu_items (id, parent_id, module_key, label_key, label_default, href, icon, sort_order, is_active) VALUES
  ('10000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000001', 'user', 'menu.user.dashboard', 'Dashboard', '/admin/user/dashboard', 'layout-dashboard', 10, true),
  ('10000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000001', 'user', 'menu.user.users', 'Benutzer', '/admin/user/users', 'users', 20, true)
ON CONFLICT (id) DO UPDATE SET
    label_default = EXCLUDED.label_default,
    href = EXCLUDED.href,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order,
    parent_id = EXCLUDED.parent_id;

-- Permissions Admin children (RBAC) - sinnvoll sortiert
INSERT INTO menu_items (id, parent_id, module_key, label_key, label_default, href, icon, sort_order, is_active) VALUES
  ('20000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.dashboard', 'Dashboard', '/admin/permissions/dashboard', 'layout-dashboard', 10, true),
  ('20000000-0000-0000-0000-000000000011', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.roles', 'Rollen', '/admin/permissions/roles', 'user-cog', 20, true),
  ('20000000-0000-0000-0000-000000000016', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.groups', 'Gruppen', '/admin/permissions/groups', 'users-round', 30, true),
  ('20000000-0000-0000-0000-000000000017', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.orgunits', 'Org. Einheiten', '/admin/permissions/org-units', 'building', 40, true),
  ('20000000-0000-0000-0000-000000000012', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.permissions', 'Berechtigungen', '/admin/permissions/permissions', 'shield-check', 50, true),
  ('20000000-0000-0000-0000-000000000013', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.modules', 'Module', '/admin/permissions/modules', 'package', 60, true),
  ('20000000-0000-0000-0000-000000000014', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.resources', 'Ressourcen', '/admin/permissions/resources', 'database', 70, true),
  ('20000000-0000-0000-0000-000000000015', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.variants', 'Varianten', '/admin/permissions/variants', 'layers', 80, true),
  ('20000000-0000-0000-0000-000000000018', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.matrix', 'Matrix', '/admin/permissions/matrix', 'grid-2x2', 90, true),
  ('20000000-0000-0000-0000-000000000019', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.effective', 'Effektive Rechte', '/admin/permissions/effective-permissions', 'check-circle', 100, true),
  ('20000000-0000-0000-0000-00000000001a', '20000000-0000-0000-0000-000000000001', 'permissions', 'menu.permissions.rbacguide', 'RBAC Guide', '/admin/permissions/rbac-guide', 'book-open', 110, true)
ON CONFLICT (id) DO UPDATE SET
    label_default = EXCLUDED.label_default,
    href = EXCLUDED.href,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order,
    parent_id = EXCLUDED.parent_id;

-- Tour children
INSERT INTO menu_items (id, parent_id, module_key, label_key, label_default, href, icon, sort_order, is_active) VALUES
  ('40000000-0000-0000-0000-000000000010', '40000000-0000-0000-0000-000000000001', 'tour', 'menu.tour.dashboard', 'Dashboard', '/admin/tour/dashboard', 'layout-dashboard', 10, true),
  ('40000000-0000-0000-0000-000000000011', '40000000-0000-0000-0000-000000000001', 'tour', 'menu.tour.tours', 'Touren', '/admin/tour/tours', 'route', 20, true),
  ('40000000-0000-0000-0000-000000000012', '40000000-0000-0000-0000-000000000001', 'tour', 'menu.tour.steps', 'Schritte', '/admin/tour/steps', 'footprints', 30, true)
ON CONFLICT (id) DO UPDATE SET
    label_default = EXCLUDED.label_default,
    href = EXCLUDED.href,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order,
    parent_id = EXCLUDED.parent_id;

-- API Keys children
INSERT INTO menu_items (id, parent_id, module_key, label_key, label_default, href, icon, sort_order, is_active) VALUES
  ('30000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000001', 'apikeys', 'menu.apikeys.dashboard', 'Dashboard', '/admin/api-keys/dashboard', 'layout-dashboard', 10, true),
  ('30000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000001', 'apikeys', 'menu.apikeys.keys', 'API-Schlüssel', '/admin/api-keys/api-keys', 'key', 20, true)
ON CONFLICT (id) DO UPDATE SET
    label_default = EXCLUDED.label_default,
    href = EXCLUDED.href,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order,
    parent_id = EXCLUDED.parent_id;

-- ============================================================================
-- TOUR SYSTEM TABLES & SEED DATA
-- ============================================================================

-- Form Registry Table
CREATE TABLE IF NOT EXISTS form_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id VARCHAR(255) UNIQUE NOT NULL,
  form_name VARCHAR(255) NOT NULL,
  form_alias VARCHAR(255),
  form_path VARCHAR(500),
  module VARCHAR(100),
  description TEXT,
  available_fields JSONB DEFAULT '[]',
  is_valid BOOLEAN DEFAULT true,
  last_scanned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_form_registry_form_id ON form_registry(form_id);
CREATE INDEX IF NOT EXISTS idx_form_registry_module ON form_registry(module);

-- Tours Table
CREATE TABLE IF NOT EXISTS tours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id VARCHAR(255) NOT NULL REFERENCES form_registry(form_id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN ('valid', 'invalid', 'warning', 'pending')),
  validation_message TEXT,
  last_validated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(form_id)
);

CREATE INDEX IF NOT EXISTS idx_tours_form_id ON tours(form_id);
CREATE INDEX IF NOT EXISTS idx_tours_active ON tours(is_active) WHERE is_active = true;

-- Tour Steps Table
CREATE TABLE IF NOT EXISTS tour_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL DEFAULT 1,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  icon VARCHAR(100),
  field_selector VARCHAR(500),
  field_label VARCHAR(255),
  side VARCHAR(20) DEFAULT 'bottom' CHECK (side IN ('top', 'bottom', 'left', 'right', 'top-left', 'top-right', 'bottom-left', 'bottom-right')),
  show_controls BOOLEAN DEFAULT true,
  show_skip BOOLEAN DEFAULT true,
  validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN ('valid', 'invalid', 'pending')),
  validation_message TEXT,
  last_validated_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tour_id, step_order)
);

CREATE INDEX IF NOT EXISTS idx_tour_steps_tour_id ON tour_steps(tour_id);
CREATE INDEX IF NOT EXISTS idx_tour_steps_order ON tour_steps(tour_id, step_order);

-- Triggers for tour tables
DROP TRIGGER IF EXISTS form_registry_updated_at ON form_registry;
CREATE TRIGGER form_registry_updated_at
  BEFORE UPDATE ON form_registry
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS tours_updated_at ON tours;
CREATE TRIGGER tours_updated_at
  BEFORE UPDATE ON tours
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS tour_steps_updated_at ON tour_steps;
CREATE TRIGGER tour_steps_updated_at
  BEFORE UPDATE ON tour_steps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed: Form Registry (Admin Pages)
INSERT INTO form_registry (form_id, form_name, form_alias, form_path, module, description, available_fields) VALUES
  ('admin.user.dashboard', 'User Dashboard', 'Dashboard', '/user/dashboard', 'user', 'Übersicht des User-Moduls', '[]'),
  ('admin.user.users', 'Benutzerverwaltung', 'Users', '/user/users', 'user', 'Benutzer anlegen, bearbeiten und löschen', '["input[name=\"email\"]", "input[name=\"name\"]", "select[name=\"role\"]"]'),
  ('admin.permissions.dashboard', 'Permissions Dashboard', 'Dashboard', '/permissions/dashboard', 'permissions', 'Übersicht des Berechtigungssystems', '[]'),
  ('admin.permissions.roles', 'Rollenverwaltung', 'Roles', '/permissions/roles', 'permissions', 'Rollen definieren und verwalten', '["input[name=\"key\"]", "input[name=\"displayName\"]", "textarea[name=\"description\"]"]'),
  ('admin.permissions.groups', 'Gruppenverwaltung', 'Groups', '/permissions/groups', 'permissions', 'Benutzergruppen verwalten', '["input[name=\"key\"]", "input[name=\"displayName\"]"]'),
  ('admin.permissions.org-units', 'Organisationseinheiten', 'OrgUnits', '/permissions/org-units', 'permissions', 'MLM-Hierarchie verwalten', '["select[name=\"orgUnitTypeId\"]", "input[name=\"key\"]", "input[name=\"displayName\"]"]'),
  ('admin.permissions.permissions', 'Berechtigungen', 'Permissions', '/permissions/permissions', 'permissions', 'Einzelberechtigungen verwalten', '[]'),
  ('admin.permissions.modules', 'Module', 'Modules', '/permissions/modules', 'permissions', 'RBAC-Module verwalten', '["input[name=\"key\"]", "input[name=\"displayName\"]"]'),
  ('admin.permissions.resources', 'Ressourcen', 'Resources', '/permissions/resources', 'permissions', 'Geschützte Ressourcen definieren', '["input[name=\"key\"]", "input[name=\"displayName\"]"]'),
  ('admin.permissions.variants', 'Varianten', 'Variants', '/permissions/variants', 'permissions', 'Berechtigungsvarianten konfigurieren', '[]'),
  ('admin.permissions.matrix', 'Berechtigungsmatrix', 'Matrix', '/permissions/matrix', 'permissions', 'Übersicht aller Berechtigungen', '[]'),
  ('admin.permissions.effective', 'Effektive Rechte', 'Effective', '/permissions/effective-permissions', 'permissions', 'Berechnete Berechtigungen', '[]'),
  ('admin.apikeys.dashboard', 'API Keys Dashboard', 'Dashboard', '/api-keys/dashboard', 'apikeys', 'Übersicht der API-Schlüssel', '[]'),
  ('admin.apikeys.keys', 'API-Schlüssel', 'Keys', '/api-keys/api-keys', 'apikeys', 'API-Schlüssel verwalten', '["select[name=\"userId\"]", "input[name=\"name\"]", "select[name=\"tier\"]"]'),
  ('admin.tour.dashboard', 'Tour Dashboard', 'Dashboard', '/tour/dashboard', 'tour', 'Übersicht der Guided Tours', '[]'),
  ('admin.tour.tours', 'Touren verwalten', 'Tours', '/tour/tours', 'tour', 'Onboarding-Touren erstellen', '["select[name=\"formId\"]", "input[name=\"name\"]", "textarea[name=\"description\"]"]'),
  ('admin.tour.steps', 'Tour-Schritte', 'Steps', '/tour/steps', 'tour', 'Tour-Schritte konfigurieren', '["input[name=\"title\"]", "textarea[name=\"content\"]", "input[name=\"targetSelector\"]"]')
ON CONFLICT (form_id) DO UPDATE SET
  form_name = EXCLUDED.form_name,
  form_path = EXCLUDED.form_path,
  module = EXCLUDED.module;

-- Seed: All Tours (32 tours)
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  -- User Module
  ('50000000-0000-0000-0001-000000000001', 'admin.user.users', 'Benutzerverwaltung Tour', 'Lernen Sie, wie Sie Benutzer anlegen und verwalten', true, 'valid'),
  ('ff9dfbe2-8945-474b-b805-f2ddf6e2e131', 'admin.user.users.create', 'Benutzer erstellen', 'Anleitung zum Erstellen eines neuen Benutzers', true, 'valid'),
  ('50000000-0000-0000-0001-000000000003', 'admin.user.users.edit', 'Benutzer bearbeiten', 'Anleitung zum Bearbeiten eines Benutzers', true, 'valid'),
  ('50000000-0000-0000-0001-000000000010', 'admin.user.dashboard', 'Benutzer-Dashboard', 'Überblick über das Benutzer-Dashboard', true, 'valid'),
  -- Permissions Module
  ('50000000-0000-0000-0002-000000000001', 'admin.permissions.roles', 'Rollen erstellen', 'Schritt-für-Schritt Anleitung zur Rollenerstellung', true, 'valid'),
  ('50000000-0000-0000-0002-000000000002', 'admin.permissions.groups', 'Gruppen verwalten', 'Anleitung zur Gruppenverwaltung', true, 'valid'),
  ('50000000-0000-0000-0002-000000000003', 'admin.permissions.org-units', 'Organisationseinheiten', 'MLM-Hierarchie verstehen', true, 'valid'),
  ('50000000-0000-0000-0002-000000000004', 'admin.permissions.matrix', 'Berechtigungsmatrix', 'Die Matrix-Ansicht nutzen', true, 'valid'),
  ('50000000-0000-0000-0002-000000000005', 'admin.permissions.permissions', 'Berechtigungen verwalten', 'Lernen Sie, wie Sie Berechtigungen anzeigen und verwalten', true, 'valid'),
  ('50000000-0000-0000-0002-000000000006', 'admin.permissions.modules', 'Module verwalten', 'Lernen Sie, wie Sie Module anlegen und verwalten', true, 'valid'),
  ('50000000-0000-0000-0002-000000000007', 'admin.permissions.variants', 'Varianten verwalten', 'Lernen Sie, wie Sie Berechtigungsvarianten erstellen', true, 'valid'),
  ('50000000-0000-0000-0002-000000000008', 'admin.permissions.resources', 'Ressourcen verwalten', 'Lernen Sie, wie Sie Ressourcen erstellen und verwalten', true, 'valid'),
  ('50000000-0000-0000-0002-000000000009', 'admin.permissions.effective', 'Permission Calculator', 'Berechnen Sie effektive Berechtigungen für einen Benutzer', true, 'valid'),
  ('50000000-0000-0000-0002-000000000010', 'admin.permissions.dashboard', 'Berechtigungs-Dashboard', 'Überblick über das Berechtigungssystem', true, 'valid'),
  ('50000000-0000-0000-0002-000000000011', 'admin.permissions.roles.create', 'Rolle erstellen', 'Anleitung zum Erstellen einer neuen Rolle', true, 'valid'),
  ('50000000-0000-0000-0002-000000000012', 'admin.permissions.groups.create', 'Gruppe erstellen', 'Anleitung zum Erstellen einer neuen Gruppe', true, 'valid'),
  ('50000000-0000-0000-0002-000000000013', 'admin.permissions.permissions.create', 'Berechtigung erstellen', 'Anleitung zum Erstellen einer neuen Berechtigung', true, 'valid'),
  ('50000000-0000-0000-0002-000000000014', 'admin.permissions.modules.create', 'Modul erstellen', 'Anleitung zum Erstellen eines neuen Moduls', true, 'valid'),
  ('50000000-0000-0000-0002-000000000015', 'admin.permissions.groups.edit', 'Gruppe bearbeiten', 'Anleitung zum Bearbeiten einer Gruppe', true, 'valid'),
  ('50000000-0000-0000-0002-000000000016', 'admin.permissions.modules.edit', 'Modul bearbeiten', 'Anleitung zum Bearbeiten eines Moduls', true, 'valid'),
  -- API Keys Module
  ('50000000-0000-0000-0003-000000000001', 'admin.apikeys.keys', 'API-Schlüssel erstellen', 'Anleitung zur API-Key-Erstellung', true, 'valid'),
  ('50000000-0000-0000-0003-000000000010', 'admin.apikeys.dashboard', 'API-Keys Dashboard', 'Überblick über das API-Key Dashboard', true, 'valid'),
  -- Tour Module
  ('50000000-0000-0000-0004-000000000001', 'admin.tour.tours', 'Touren verwalten', 'Eigene Onboarding-Touren erstellen', true, 'valid'),
  ('50000000-0000-0000-0004-000000000002', 'admin.tour.steps', 'Tour-Schritte konfigurieren', 'Detaillierte Schritt-Konfiguration', true, 'valid'),
  ('50000000-0000-0000-0004-000000000003', 'admin.tour.tours.create', 'Tour erstellen', 'Anleitung zum Erstellen einer neuen Tour', true, 'valid'),
  ('50000000-0000-0000-0004-000000000004', 'admin.tour.tours.edit', 'Tour bearbeiten', 'Anleitung zum Bearbeiten einer Tour', true, 'valid'),
  ('50000000-0000-0000-0004-000000000005', 'admin.tour.steps.create', 'Tour-Schritt erstellen', 'Anleitung zum Erstellen eines neuen Tour-Schritts', true, 'valid'),
  ('50000000-0000-0000-0004-000000000006', 'admin.tour.steps.edit', 'Tour-Schritt bearbeiten', 'Anleitung zum Bearbeiten eines Tour-Schritts', true, 'valid'),
  ('50000000-0000-0000-0004-000000000010', 'admin.tour.dashboard', 'Tour-Dashboard', 'Überblick über das Tour-System Dashboard', true, 'valid'),
  -- Shell Module
  ('50000000-0000-0000-0005-000000000001', 'admin.shell.menu-settings', 'Menu-Einstellungen', 'Lernen Sie, wie Sie das Navigationsmenü konfigurieren', true, 'valid'),
  ('50000000-0000-0000-0005-000000000002', 'admin.shell.menu.create', 'Menu-Eintrag erstellen', 'Anleitung zum Erstellen eines neuen Menü-Eintrags', true, 'valid'),
  ('50000000-0000-0000-0005-000000000003', 'admin.shell.menu.edit', 'Menu-Eintrag bearbeiten', 'Anleitung zum Bearbeiten eines Menü-Eintrags', true, 'valid')
ON CONFLICT (form_id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

-- Seed: Tour Steps - User Module
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- admin.user.users (page tour)
  ('50000000-0000-0000-0001-000000000001', 1, 'Willkommen', 'In dieser Tour lernen Sie die Benutzerverwaltung kennen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 2, 'Benutzer anlegen', 'Klicken Sie hier, um einen neuen Benutzer zu erstellen.', '➕', '#btn-add-user', 'Neuer Benutzer Button', 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 3, 'Benutzer suchen', 'Hier können Sie nach Benutzern suchen.', '📧', '#users-search', 'Suche', 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 4, 'Ihre Benutzer', 'Hier sehen Sie alle Benutzer. Klicken Sie auf einen Benutzer um ihn zu bearbeiten.', '👤', '#users-table', 'Benutzerliste', 'bottom'),
  -- admin.user.users.create (modal tour)
  ('ff9dfbe2-8945-474b-b805-f2ddf6e2e131', 1, 'Name eingeben', 'Geben Sie den vollständigen Namen des Benutzers ein.', NULL, 'input[name="name"]', 'Name', 'bottom'),
  ('ff9dfbe2-8945-474b-b805-f2ddf6e2e131', 2, 'E-Mail eingeben', 'Die E-Mail-Adresse wird für die Anmeldung verwendet.', NULL, 'input[name="email"]', 'E-Mail', 'bottom'),
  ('ff9dfbe2-8945-474b-b805-f2ddf6e2e131', 3, 'Passwort setzen', 'Mindestens 8 Zeichen für ein sicheres Passwort.', NULL, 'input[name="password"]', 'Passwort', 'bottom'),
  ('ff9dfbe2-8945-474b-b805-f2ddf6e2e131', 4, 'Rolle auswählen', 'Admins haben erweiterte Berechtigungen.', NULL, 'select[name="role"]', 'Rolle', 'bottom'),
  -- admin.user.users.edit (modal tour)
  ('50000000-0000-0000-0001-000000000003', 1, 'Benutzer bearbeiten', 'Bearbeiten Sie die Eigenschaften dieses Benutzers.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 2, 'Name', 'Ändern Sie den Anzeigenamen des Benutzers.', '📝', 'input[name="name"]', 'Name', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 3, 'E-Mail', 'Ändern Sie die E-Mail-Adresse. Diese dient gleichzeitig als Login-Name.', '📧', 'input[name="email"]', 'E-Mail', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 4, 'Passwort', 'Setzen Sie ein neues Passwort. Leer lassen, um das bestehende Passwort beizubehalten.', '🔐', 'input[name="password"]', 'Passwort', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 5, 'Rolle', 'Ändern Sie die Rolle des Benutzers (z.B. Admin, User).', '👤', 'select[name="role"]', 'Rolle', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 6, 'Status', 'Aktivieren oder deaktivieren Sie den Benutzer. Deaktivierte Benutzer können sich nicht anmelden.', '✅', 'select[name="isActive"]', 'Status', 'bottom'),
  -- admin.user.dashboard
  ('50000000-0000-0000-0001-000000000010', 1, 'Benutzer-Dashboard', 'Willkommen im Benutzer-Dashboard. Hier sehen Sie eine Übersicht über alle registrierten Benutzer und deren Status.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000010', 2, 'Statistiken', 'Das Dashboard zeigt Ihnen wichtige Kennzahlen wie die Anzahl aktiver Benutzer, neue Registrierungen und Login-Aktivitäten.', '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, icon = EXCLUDED.icon, field_selector = EXCLUDED.field_selector, field_label = EXCLUDED.field_label;

-- Seed: Tour Steps - Permissions Module
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- admin.permissions.roles (page tour)
  ('50000000-0000-0000-0002-000000000001', 1, 'Rollenverwaltung', 'Rollen sind Vorlagen für Berechtigungen.', '🎭', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000001', 2, 'Rolle erstellen', 'Klicken Sie hier, um eine neue Rolle zu erstellen.', '🔑', '#btn-add-role', 'Neue Rolle Button', 'bottom'),
  ('50000000-0000-0000-0002-000000000001', 3, 'Ihre Rollen', 'Hier sehen Sie alle definierten Rollen. Klicken Sie auf eine Rolle um sie zu bearbeiten.', '✏️', '#roles-table', 'Rollenliste', 'bottom'),
  -- admin.permissions.groups (page tour)
  ('50000000-0000-0000-0002-000000000002', 1, 'Gruppen verstehen', 'Gruppen fassen Benutzer zusammen.', '👥', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000002', 2, 'Gruppe erstellen', 'Klicken Sie hier, um eine neue Berechtigungsgruppe zu erstellen.', '🔑', '#btn-add-group', 'Neue Gruppe Button', 'bottom'),
  ('50000000-0000-0000-0002-000000000002', 3, 'Ihre Gruppen', 'Hier sehen Sie alle Berechtigungsgruppen. Klicken Sie auf eine Gruppe um sie zu bearbeiten.', '🏷️', '#groups-table', 'Gruppenliste', 'bottom'),
  -- admin.permissions.org-units (page tour)
  ('50000000-0000-0000-0002-000000000003', 1, 'MLM-Hierarchie', 'Unternehmen → Zweigstelle → Abteilung → Team.', '🏢', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 2, 'OU erstellen', 'Klicken Sie hier, um eine neue Organisationseinheit zu erstellen.', '📊', '#btn-add-ou', 'Neue OU Button', 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 3, 'OU-Hierarchie', 'Hier sehen Sie die hierarchische Struktur Ihrer Organisationseinheiten. Klicken Sie auf eine OU für Details.', '🔑', '#org-units-graph', 'Hierarchie-Graph', 'bottom'),
  -- admin.permissions.matrix (page tour)
  ('50000000-0000-0000-0002-000000000004', 1, 'Matrix-Ansicht', 'Alle Berechtigungen in einer Tabelle.', '📊', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000004', 2, 'Matrix Übersicht', 'Hier verwalten Sie die Zuordnung von Rollen zu Organisationseinheiten.', '↔️', '#matrix-header', 'Matrix Header', 'right'),
  ('50000000-0000-0000-0002-000000000004', 3, 'Rollen-Matrix', 'Klicken Sie auf eine Zelle um die Rollenzuweisung zu ändern. Grüne Häkchen zeigen aktive Zuweisungen.', '↕️', '#matrix-table', 'Matrix Tabelle', 'bottom'),
  -- admin.permissions.permissions (page tour)
  ('50000000-0000-0000-0002-000000000005', 1, 'Berechtigungen', 'In dieser Ansicht verwalten Sie alle Berechtigungen (Permissions) des Systems. Jede Berechtigung besteht aus einem Modul und einer Aktion.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 2, 'Neue Berechtigung', 'Klicken Sie hier, um eine neue Berechtigung hinzuzufügen. Wählen Sie ein Modul und eine Aktion aus.', '➕', '#btn-add-permission', 'Neue Berechtigung', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 3, 'Filter', 'Nutzen Sie die Filter, um Berechtigungen nach Modul oder Aktion einzugrenzen.', '🔍', '#permissions-filters', 'Filter', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 4, 'Suche', 'Suchen Sie gezielt nach Berechtigungen über das Suchfeld.', '🔎', '#permissions-search', 'Suchfeld', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 5, 'Berechtigungsliste', 'Hier sehen Sie alle Berechtigungen. Klicken Sie auf eine Berechtigung um Details anzuzeigen.', '📋', '#permissions-list', 'Berechtigungsliste', 'top'),
  -- admin.permissions.modules (page tour)
  ('50000000-0000-0000-0002-000000000006', 1, 'Module', 'Module gruppieren zusammengehörige Berechtigungen. Jedes Modul kann CRUD-Aktionen (Create, Read, Update, Delete) haben.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000006', 2, 'Neues Modul', 'Klicken Sie hier, um ein neues Modul anzulegen.', '➕', '#btn-add-module', 'Neues Modul', 'bottom'),
  ('50000000-0000-0000-0002-000000000006', 3, 'Modul-Tabelle', 'Hier sehen Sie alle Module mit ihren Schlüsseln und Beschreibungen. Klicken Sie auf ein Modul zum Bearbeiten.', '📋', '#modules-table', 'Module', 'top'),
  -- admin.permissions.variants (page tour)
  ('50000000-0000-0000-0002-000000000007', 1, 'Varianten', 'Varianten definieren vorkonfigurierte Berechtigungspakete, die Rollen zugewiesen werden können.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000007', 2, 'Neue Variante', 'Erstellen Sie eine neue Variante mit einem eindeutigen Schlüssel und Anzeigenamen.', '➕', '#btn-add-variant', 'Neue Variante', 'bottom'),
  ('50000000-0000-0000-0002-000000000007', 3, 'Varianten-Liste', 'Hier sehen Sie alle Varianten. Wählen Sie eine Variante aus, um ihre Berechtigungen zu konfigurieren.', '📋', '#variants-list', 'Varianten', 'right'),
  ('50000000-0000-0000-0002-000000000007', 4, 'Berechtigungen zuweisen', 'In diesem Bereich weisen Sie der ausgewählten Variante einzelne Berechtigungen zu.', '🔐', '#variants-permissions', 'Berechtigungen', 'left'),
  -- admin.permissions.resources (page tour)
  ('50000000-0000-0000-0002-000000000008', 1, 'Ressourcen', 'Ressourcen sind geschützte Objekte in Ihrem System, auf die Berechtigungen angewendet werden.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000008', 2, 'Neue Ressource', 'Klicken Sie hier, um eine neue Ressource zu erstellen.', '➕', '#btn-add-resource', 'Neue Ressource', 'bottom'),
  ('50000000-0000-0000-0002-000000000008', 3, 'Ressourcen-Übersicht', 'Hier sehen Sie alle Ressourcen als Karten. Klicken Sie auf eine Ressource um sie zu bearbeiten.', '📋', '#resources-grid', 'Ressourcen', 'top'),
  -- admin.permissions.effective (page tour)
  ('50000000-0000-0000-0002-000000000009', 1, 'Permission Calculator', 'Der Permission Calculator zeigt Ihnen, welche effektiven Berechtigungen ein bestimmter Benutzer hat.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000009', 2, 'Benutzer-ID eingeben', 'Geben Sie hier die UUID eines Benutzers ein, um dessen effektive Berechtigungen zu berechnen.', '🔑', '#effective-user-input', 'Benutzer-ID', 'bottom'),
  ('50000000-0000-0000-0002-000000000009', 3, 'Ergebnisse', 'Nach Eingabe einer gültigen UUID sehen Sie alle Berechtigungen, deren Quelle (Rolle, Gruppe, Override) und Priorität.', '📊', NULL, NULL, 'bottom'),
  -- admin.permissions.dashboard
  ('50000000-0000-0000-0002-000000000010', 1, 'Berechtigungs-Dashboard', 'Willkommen im Berechtigungs-Dashboard. Hier erhalten Sie einen Überblick über Rollen, Gruppen und Berechtigungen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000010', 2, 'System-Übersicht', 'Das Dashboard zeigt die Gesamtzahl der Rollen, Gruppen, Permissions und Organisationseinheiten in Ihrem System.', '📊', NULL, NULL, 'bottom'),
  -- admin.permissions.roles.create (modal tour)
  ('50000000-0000-0000-0002-000000000011', 1, 'Neue Rolle', 'Erstellen Sie eine neue Rolle mit eindeutigem Schlüssel und Anzeigenamen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 2, 'Schlüssel', 'Der Schlüssel ist ein eindeutiger technischer Bezeichner (z.B. "admin", "editor"). Nur Kleinbuchstaben und Unterstriche.', '🔑', '#create-role-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 3, 'Anzeigename', 'Der Anzeigename wird in der Oberfläche angezeigt (z.B. "Administrator", "Editor").', '📝', '#create-role-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 4, 'Beschreibung', 'Optional: Beschreiben Sie den Zweck dieser Rolle.', '📄', '#create-role-description', 'Beschreibung', 'bottom'),
  -- admin.permissions.groups.create (modal tour)
  ('50000000-0000-0000-0002-000000000012', 1, 'Neue Gruppe', 'Gruppen fassen Benutzer zusammen, um ihnen gemeinsam Rollen zuzuweisen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 2, 'Schlüssel', 'Ein eindeutiger technischer Bezeichner für die Gruppe (z.B. "developers", "marketing").', '🔑', '#create-group-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 3, 'Anzeigename', 'Der Name der Gruppe, der in der Oberfläche angezeigt wird.', '📝', '#create-group-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 4, 'Beschreibung', 'Optional: Beschreiben Sie den Zweck dieser Gruppe.', '📄', '#create-group-description', 'Beschreibung', 'bottom'),
  -- admin.permissions.permissions.create (modal tour)
  ('50000000-0000-0000-0002-000000000013', 1, 'Neue Berechtigung', 'Erstellen Sie eine neue Berechtigung, indem Sie ein Modul und eine Aktion auswählen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000013', 2, 'Modul', 'Wählen Sie das Modul, zu dem die Berechtigung gehört (z.B. "users", "permissions").', '📦', '#create-permission-module', 'Modul', 'bottom'),
  ('50000000-0000-0000-0002-000000000013', 3, 'Aktion', 'Wählen Sie die Aktion, die erlaubt werden soll (z.B. "read", "create", "update", "delete").', '⚡', '#create-permission-action', 'Aktion', 'bottom'),
  -- admin.permissions.modules.create (modal tour)
  ('50000000-0000-0000-0002-000000000014', 1, 'Neues Modul', 'Module gruppieren Berechtigungen nach Funktionsbereichen. Erstellen Sie hier ein neues Modul.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 2, 'Modul-Key', 'Ein eindeutiger technischer Schlüssel (z.B. "users", "reports"). Nur Kleinbuchstaben.', '🔑', '#create-module-key', 'Modul-Key', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 3, 'Anzeigename', 'Der Name des Moduls in der Benutzeroberfläche (z.B. "Benutzerverwaltung").', '📝', '#create-module-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 4, 'Beschreibung', 'Optional: Beschreiben Sie, wofür dieses Modul verwendet wird.', '📄', '#create-module-description', 'Beschreibung', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 5, 'CRUD-Aktionen', 'Aktivieren Sie die Standard-Aktionen (Create, Read, Update, Delete), die automatisch als Berechtigungen angelegt werden.', '⚙️', '#create-module-crud', 'CRUD-Aktionen', 'bottom'),
  -- admin.permissions.groups.edit (modal tour)
  ('50000000-0000-0000-0002-000000000015', 1, 'Gruppe bearbeiten', 'Bearbeiten Sie die Eigenschaften dieser Gruppe.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 2, 'Schlüssel', 'Der technische Schlüssel der Gruppe. Änderungen können Auswirkungen auf bestehende Zuweisungen haben.', '🔑', '#edit-group-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 3, 'Anzeigename', 'Ändern Sie den Anzeigenamen der Gruppe.', '📝', '#edit-group-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 4, 'Beschreibung', 'Aktualisieren Sie die Beschreibung der Gruppe.', '📄', '#edit-group-description', 'Beschreibung', 'bottom'),
  -- admin.permissions.modules.edit (modal tour)
  ('50000000-0000-0000-0002-000000000016', 1, 'Modul bearbeiten', 'Bearbeiten Sie die Eigenschaften dieses Moduls.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 2, 'Modul-Key', 'Der technische Schlüssel des Moduls. Vorsicht: Änderungen können bestehende Berechtigungen beeinflussen.', '🔑', '#edit-module-key', 'Modul-Key', 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 3, 'Anzeigename', 'Ändern Sie den Anzeigenamen des Moduls.', '📝', '#edit-module-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 4, 'Beschreibung', 'Aktualisieren Sie die Beschreibung des Moduls.', '📄', '#edit-module-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, icon = EXCLUDED.icon, field_selector = EXCLUDED.field_selector, field_label = EXCLUDED.field_label;

-- Seed: Tour Steps - API Keys Module
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- admin.apikeys.keys (page tour)
  ('50000000-0000-0000-0003-000000000001', 1, 'API-Schlüssel', 'Ermöglichen externen Anwendungen den Zugriff.', '🔐', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 2, 'Schlüssel generieren', 'Klicken Sie hier, um einen neuen API-Schlüssel zu erstellen.', '👤', '#btn-generate-key', 'API-Key erstellen Button', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 3, 'Ihre Schlüssel', 'Hier sehen Sie alle API-Schlüssel mit Benutzer, Tier, Status und Ablaufdatum.', '🏷️', '#apikeys-table', 'API-Keys Tabelle', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 4, 'Schlüssel sichern!', 'Der Key wird nur einmal angezeigt!', '⚠️', NULL, NULL, 'bottom'),
  -- admin.apikeys.dashboard
  ('50000000-0000-0000-0003-000000000010', 1, 'API-Key Dashboard', 'Willkommen im API-Key Dashboard. Hier sehen Sie Statistiken zu Ihren API-Schlüsseln und Validierungen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0003-000000000010', 2, 'Kennzahlen', 'Das Dashboard zeigt die Anzahl aktiver API-Keys, heutige Validierungen, die Erfolgsrate und abgelaufene Schlüssel.', '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, icon = EXCLUDED.icon, field_selector = EXCLUDED.field_selector, field_label = EXCLUDED.field_label;

-- Seed: Tour Steps - Tour Module
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- admin.tour.tours (page tour)
  ('50000000-0000-0000-0004-000000000001', 1, 'Tour-Verwaltung', 'Erstellen Sie interaktive Onboarding-Touren.', '🗺️', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000001', 2, 'Tour erstellen', 'Klicken Sie hier, um eine neue Tour zu erstellen.', '📄', '#btn-add-tour', 'Neue Tour Button', 'bottom'),
  ('50000000-0000-0000-0004-000000000001', 3, 'Ihre Touren', 'Hier sehen Sie alle Touren mit Status, Validierung und Schritt-Anzahl. Klicken Sie auf "Schritte" um die Tour-Schritte zu bearbeiten.', '✏️', '#tours-table', 'Touren-Tabelle', 'bottom'),
  -- admin.tour.steps (page tour)
  ('50000000-0000-0000-0004-000000000002', 1, 'Schritte verstehen', 'Touren bestehen aus mehreren Schritten.', '👣', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 2, 'Tour auswählen', 'Wählen Sie hier die Tour aus, deren Schritte Sie bearbeiten möchten.', '📌', '#steps-tour-select', 'Tour-Auswahl', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 3, 'Schritt hinzufügen', 'Klicken Sie hier, um einen neuen Schritt zur ausgewählten Tour hinzuzufügen.', '💬', '#btn-add-step', 'Neuer Schritt Button', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 4, 'Ihre Schritte', 'Hier sehen Sie alle Schritte der Tour. Sie können die Reihenfolge mit den Pfeilen ändern oder einzelne Schritte bearbeiten.', '🎯', '#steps-list', 'Schritte-Liste', 'bottom'),
  -- admin.tour.tours.create (modal tour)
  ('50000000-0000-0000-0004-000000000003', 1, 'Neue Tour', 'Erstellen Sie eine neue interaktive Tour für ein Formular oder eine Seite.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 2, 'Formular', 'Wählen Sie das Formular, für das die Tour erstellt werden soll. Jedes Formular kann nur eine Tour haben.', '📋', '#create-tour-formid', 'Formular', 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 3, 'Tour-Name', 'Geben Sie einen aussagekräftigen Namen für die Tour ein.', '📝', '#create-tour-name', 'Name', 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 4, 'Beschreibung', 'Optional: Beschreiben Sie, was der Benutzer in dieser Tour lernen wird.', '📄', '#create-tour-description', 'Beschreibung', 'bottom'),
  -- admin.tour.tours.edit (modal tour)
  ('50000000-0000-0000-0004-000000000004', 1, 'Tour bearbeiten', 'Bearbeiten Sie die Eigenschaften dieser Tour.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000004', 2, 'Tour-Name', 'Ändern Sie den Namen der Tour.', '📝', '#edit-tour-name', 'Name', 'bottom'),
  ('50000000-0000-0000-0004-000000000004', 3, 'Beschreibung', 'Aktualisieren Sie die Beschreibung der Tour.', '📄', '#edit-tour-description', 'Beschreibung', 'bottom'),
  -- admin.tour.steps.create (modal tour)
  ('50000000-0000-0000-0004-000000000005', 1, 'Neuer Schritt', 'Erstellen Sie einen neuen Schritt für eine bestehende Tour.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 2, 'Titel', 'Der Titel wird als Überschrift im Tour-Tooltip angezeigt.', '📝', '#step-title', 'Titel', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 3, 'Inhalt', 'Der Haupttext des Schritts. Erklären Sie dem Benutzer, was dieses Element tut.', '📄', '#step-content', 'Inhalt', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 4, 'Feld-Selektor', 'Der CSS-Selektor des Elements, auf das der Tooltip zeigen soll (z.B. "#btn-add-user"). Leer lassen für zentrierte Anzeige.', '🎯', '#step-field-selector', 'Feld-Selektor', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 5, 'Feld-Label', 'Ein menschenlesbarer Name für das Ziel-Element (z.B. "Speichern-Button").', '🏷️', '#step-field-label', 'Feld-Label', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 6, 'Position', 'Wählen Sie, wo der Tooltip relativ zum Element erscheinen soll (oben, unten, links, rechts).', '📍', '#step-position', 'Position', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 7, 'Reihenfolge', 'Die Schrittnummer bestimmt die Reihenfolge innerhalb der Tour.', '🔢', '#step-order', 'Reihenfolge', 'bottom'),
  -- admin.tour.steps.edit (modal tour)
  ('50000000-0000-0000-0004-000000000006', 1, 'Schritt bearbeiten', 'Bearbeiten Sie die Eigenschaften dieses Tour-Schritts.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 2, 'Titel', 'Ändern Sie den Titel des Schritts.', '📝', '#step-title', 'Titel', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 3, 'Inhalt', 'Aktualisieren Sie den Erklärungstext des Schritts.', '📄', '#step-content', 'Inhalt', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 4, 'Feld-Selektor', 'Ändern Sie den CSS-Selektor des Ziel-Elements.', '🎯', '#step-field-selector', 'Feld-Selektor', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 5, 'Position', 'Ändern Sie die Position des Tooltips relativ zum Element.', '📍', '#step-position', 'Position', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 6, 'Reihenfolge', 'Passen Sie die Reihenfolge des Schritts in der Tour an.', '🔢', '#step-order', 'Reihenfolge', 'bottom'),
  -- admin.tour.dashboard
  ('50000000-0000-0000-0004-000000000010', 1, 'Tour-Dashboard', 'Willkommen im Tour-Dashboard. Hier verwalten Sie interaktive Touren, die Benutzer durch die Anwendung führen.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000010', 2, 'Übersicht', 'Das Dashboard zeigt die Anzahl aktiver Touren, Schritte und den Validierungsstatus aller Touren.', '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, icon = EXCLUDED.icon, field_selector = EXCLUDED.field_selector, field_label = EXCLUDED.field_label;

-- Seed: Tour Steps - Shell Module
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- admin.shell.menu-settings (page tour)
  ('50000000-0000-0000-0005-000000000001', 1, 'Menu-Einstellungen', 'Hier verwalten Sie die Navigationsstruktur der Anwendung. Menü-Einträge können hierarchisch organisiert werden.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000001', 2, 'Neuer Eintrag', 'Erstellen Sie einen neuen Menü-Eintrag mit Modul-Key, Label und Route.', '➕', '#btn-add-menu-item', 'Neuer Eintrag', 'bottom'),
  ('50000000-0000-0000-0005-000000000001', 3, 'Menü-Baum', 'Hier sehen Sie die Menüstruktur als Baum. Elemente können per Drag & Drop umsortiert werden.', '🌳', '#menu-tree', 'Menü-Baum', 'right'),
  ('50000000-0000-0000-0005-000000000001', 4, 'Speichern', 'Vergessen Sie nicht, Ihre Änderungen zu speichern.', '💾', '#btn-save-menu', 'Speichern', 'bottom'),
  -- admin.shell.menu.create (modal tour)
  ('50000000-0000-0000-0005-000000000002', 1, 'Neuer Menü-Eintrag', 'Erstellen Sie einen neuen Eintrag für das Navigationsmenü.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 2, 'Parent', 'Wählen Sie optional ein übergeordnetes Element. Ohne Parent wird der Eintrag auf der obersten Ebene angezeigt.', '📂', '#menu-item-parent', 'Parent', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 3, 'Module Key', 'Der technische Schlüssel, der das Berechtigungsmodul für diesen Menüpunkt identifiziert.', '🔑', '#menu-item-module-key', 'Module Key', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 4, 'Anzeigename', 'Der Text, der im Menü angezeigt wird.', '📝', '#menu-item-display-name', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 5, 'Route', 'Die URL-Route, zu der navigiert wird (z.B. "/admin/user/users"). Leer lassen für Gruppen-Header.', '🔗', '#menu-item-href', 'Route', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 6, 'Icon', 'Der Name des Lucide-Icons (z.B. "Users", "Key", "LayoutDashboard").', '🎨', '#menu-item-icon', 'Icon', 'bottom'),
  -- admin.shell.menu.edit (modal tour)
  ('50000000-0000-0000-0005-000000000003', 1, 'Eintrag bearbeiten', 'Bearbeiten Sie die Eigenschaften dieses Menü-Eintrags.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 2, 'Parent', 'Ändern Sie das übergeordnete Element, um den Eintrag in der Hierarchie zu verschieben.', '📂', '#menu-item-parent', 'Parent', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 3, 'Module Key', 'Der Berechtigungs-Modulschlüssel für diesen Menüpunkt.', '🔑', '#menu-item-module-key', 'Module Key', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 4, 'Anzeigename', 'Ändern Sie den im Menü angezeigten Text.', '📝', '#menu-item-display-name', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 5, 'Route', 'Aktualisieren Sie die Ziel-URL des Menüpunkts.', '🔗', '#menu-item-href', 'Route', 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, icon = EXCLUDED.icon, field_selector = EXCLUDED.field_selector, field_label = EXCLUDED.field_label;
