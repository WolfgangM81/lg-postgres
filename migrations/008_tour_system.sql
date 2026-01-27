-- Migration: Complete Tour System with Form Registry
-- Description: Creates form_registry, tours, tour_steps tables and seeds default admin tours
-- Version: 008
-- Date: 2026-01-26

BEGIN;

-- Drop old tour_steps if it exists (from migration 007)
DROP TABLE IF EXISTS tour_steps CASCADE;

-- ============================================================================
-- Form Registry Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS form_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id VARCHAR(255) UNIQUE NOT NULL,  -- e.g., 'admin.permissions.roles'
  form_name VARCHAR(255) NOT NULL,        -- e.g., 'Rollenverwaltung'
  form_alias VARCHAR(255),                -- e.g., 'Roles'
  form_path VARCHAR(500),                 -- e.g., '/permissions/roles'
  module VARCHAR(100),                    -- e.g., 'permissions'
  description TEXT,
  available_fields JSONB DEFAULT '[]',    -- List of CSS selectors/field names
  is_valid BOOLEAN DEFAULT true,
  last_scanned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_form_registry_form_id ON form_registry(form_id);
CREATE INDEX idx_form_registry_module ON form_registry(module);

-- ============================================================================
-- Tours Table
-- ============================================================================
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

  UNIQUE(form_id)  -- One tour per form
);

CREATE INDEX idx_tours_form_id ON tours(form_id);
CREATE INDEX idx_tours_active ON tours(is_active) WHERE is_active = true;

-- ============================================================================
-- Tour Steps Table (New Schema)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tour_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL DEFAULT 1,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  icon VARCHAR(100),                      -- Emoji or icon identifier
  field_selector VARCHAR(500),            -- CSS selector for target element
  field_label VARCHAR(255),               -- Human-readable field name
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

CREATE INDEX idx_tour_steps_tour_id ON tour_steps(tour_id);
CREATE INDEX idx_tour_steps_order ON tour_steps(tour_id, step_order);
CREATE INDEX idx_tour_steps_active ON tour_steps(is_active) WHERE is_active = true;

-- ============================================================================
-- Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- ============================================================================
-- Seed: Form Registry (Admin Pages)
-- ============================================================================
INSERT INTO form_registry (form_id, form_name, form_alias, form_path, module, description, available_fields) VALUES
  -- User Module
  ('admin.user.dashboard', 'User Dashboard', 'Dashboard', '/user/dashboard', 'user', 'Übersicht des User-Moduls', '[]'),
  ('admin.user.users', 'Benutzerverwaltung', 'Users', '/user/users', 'user', 'Benutzer anlegen, bearbeiten und löschen', '["#create-user-name", "#create-user-email", "#create-user-password", "#create-user-role"]'),

  -- Permissions Module
  ('admin.permissions.dashboard', 'Permissions Dashboard', 'Dashboard', '/permissions/dashboard', 'permissions', 'Übersicht des Berechtigungssystems', '[]'),
  ('admin.permissions.roles', 'Rollenverwaltung', 'Roles', '/permissions/roles', 'permissions', 'Rollen definieren und verwalten', '["#create-role-key", "#create-role-displayname", "#create-role-description"]'),
  ('admin.permissions.groups', 'Gruppenverwaltung', 'Groups', '/permissions/groups', 'permissions', 'Benutzergruppen verwalten', '["#create-group-key", "#create-group-displayname", "#create-group-description"]'),
  ('admin.permissions.org-units', 'Organisationseinheiten', 'OrgUnits', '/permissions/org-units', 'permissions', 'MLM-Hierarchie verwalten', '["select[name=\"orgUnitTypeId\"]", "input[name=\"key\"]", "input[name=\"displayName\"]", "select[name=\"parentId\"]"]'),
  ('admin.permissions.permissions', 'Berechtigungen', 'Permissions', '/permissions/permissions', 'permissions', 'Einzelberechtigungen verwalten', '["#create-permission-module", "#create-permission-action"]'),
  ('admin.permissions.modules', 'Module', 'Modules', '/permissions/modules', 'permissions', 'RBAC-Module verwalten', '["#create-module-key", "#create-module-displayname", "#create-module-description", "#create-module-crud"]'),
  ('admin.permissions.resources', 'Ressourcen', 'Resources', '/permissions/resources', 'permissions', 'Geschützte Ressourcen definieren', '["input[name=\"key\"]", "input[name=\"displayName\"]"]'),
  ('admin.permissions.variants', 'Varianten', 'Variants', '/permissions/variants', 'permissions', 'Berechtigungsvarianten konfigurieren', '[]'),
  ('admin.permissions.matrix', 'Berechtigungsmatrix', 'Matrix', '/permissions/matrix', 'permissions', 'Übersicht aller Berechtigungen pro Gruppe', '[]'),
  ('admin.permissions.effective', 'Effektive Rechte', 'Effective', '/permissions/effective-permissions', 'permissions', 'Berechnete Berechtigungen pro Benutzer', '[]'),

  -- API Keys Module
  ('admin.apikeys.dashboard', 'API Keys Dashboard', 'Dashboard', '/api-keys/dashboard', 'apikeys', 'Übersicht der API-Schlüssel', '[]'),
  ('admin.apikeys.keys', 'API-Schlüssel', 'Keys', '/api-keys/api-keys', 'apikeys', 'API-Schlüssel erstellen und verwalten', '["select[name=\"userId\"]", "input[name=\"name\"]", "select[name=\"tier\"]", "input[name=\"expiresAt\"]"]'),

  -- Tour Module
  ('admin.tour.dashboard', 'Tour Dashboard', 'Dashboard', '/tour/dashboard', 'tour', 'Übersicht der Guided Tours', '[]'),
  ('admin.tour.tours', 'Touren verwalten', 'Tours', '/tour/tours', 'tour', 'Onboarding-Touren erstellen und bearbeiten', '["select[name=\"formId\"]", "input[name=\"name\"]", "textarea[name=\"description\"]"]'),
  ('admin.tour.steps', 'Tour-Schritte', 'Steps', '/tour/steps', 'tour', 'Einzelne Schritte einer Tour konfigurieren', '["input[name=\"title\"]", "textarea[name=\"content\"]", "input[name=\"targetSelector\"]", "select[name=\"placement\"]"]')
ON CONFLICT (form_id) DO UPDATE SET
  form_name = EXCLUDED.form_name,
  form_path = EXCLUDED.form_path,
  module = EXCLUDED.module,
  description = EXCLUDED.description,
  available_fields = EXCLUDED.available_fields;

-- ============================================================================
-- Seed: Default Tours
-- ============================================================================
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  -- User Module Tours
  ('50000000-0000-0000-0001-000000000001', 'admin.user.users', 'Benutzerverwaltung Tour', 'Lernen Sie, wie Sie Benutzer anlegen und verwalten', true, 'valid'),

  -- Permissions Module Tours
  ('50000000-0000-0000-0002-000000000001', 'admin.permissions.roles', 'Rollen erstellen', 'Schritt-für-Schritt Anleitung zur Rollenerstellung', true, 'valid'),
  ('50000000-0000-0000-0002-000000000002', 'admin.permissions.groups', 'Gruppen verwalten', 'Anleitung zur Gruppenverwaltung', true, 'valid'),
  ('50000000-0000-0000-0002-000000000003', 'admin.permissions.org-units', 'Organisationseinheiten', 'MLM-Hierarchie verstehen und konfigurieren', true, 'valid'),
  ('50000000-0000-0000-0002-000000000004', 'admin.permissions.matrix', 'Berechtigungsmatrix', 'Die Matrix-Ansicht effektiv nutzen', true, 'valid'),

  -- API Keys Module Tours
  ('50000000-0000-0000-0003-000000000001', 'admin.apikeys.keys', 'API-Schlüssel erstellen', 'Anleitung zur Erstellung von API-Schlüsseln', true, 'valid'),

  -- Tour Module Tours
  ('50000000-0000-0000-0004-000000000001', 'admin.tour.tours', 'Touren verwalten', 'Lernen Sie, eigene Onboarding-Touren zu erstellen', true, 'valid'),
  ('50000000-0000-0000-0004-000000000002', 'admin.tour.steps', 'Tour-Schritte konfigurieren', 'Detaillierte Anleitung zur Schritt-Konfiguration', true, 'valid')
ON CONFLICT (form_id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

-- ============================================================================
-- Seed: Tour Steps - User Module
-- ============================================================================
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- Benutzerverwaltung Tour
  ('50000000-0000-0000-0001-000000000001', 1, 'Willkommen', 'In dieser Tour lernen Sie, wie Sie Benutzer in LicenseGuard verwalten können.', '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 2, 'Neuen Benutzer anlegen', 'Klicken Sie auf "Add User", um das Formular zu öffnen.', '➕', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 3, 'E-Mail-Adresse', 'Geben Sie eine eindeutige E-Mail-Adresse ein. Diese dient als Login-Name.', '📧', '#create-user-email', 'E-Mail-Adresse', 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 4, 'Name festlegen', 'Der vollständige Name wird in der Oberfläche angezeigt.', '👤', '#create-user-name', 'Name', 'bottom'),
  ('50000000-0000-0000-0001-000000000001', 5, 'Rolle zuweisen', 'Wählen Sie "admin" für Administratoren oder "user" für normale Benutzer.', '🎭', '#create-user-role', 'Rolle', 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET
  title = EXCLUDED.title,
  content = EXCLUDED.content,
  icon = EXCLUDED.icon,
  field_selector = EXCLUDED.field_selector,
  field_label = EXCLUDED.field_label;

-- ============================================================================
-- Seed: Tour Steps - Permissions Module
-- ============================================================================
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- Rollen erstellen Tour
  ('50000000-0000-0000-0002-000000000001', 1, 'Willkommen zur Rollenverwaltung', 'Rollen sind Vorlagen für Berechtigungen, die Benutzern oder Gruppen zugewiesen werden können.', '🎭', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000001', 2, 'Schlüssel eingeben', 'Der Schlüssel ist ein eindeutiger technischer Identifier. Verwenden Sie snake_case, z.B. "sales_manager".', '🔑', '#create-role-key', 'Key', 'bottom'),
  ('50000000-0000-0000-0002-000000000001', 3, 'Anzeigename definieren', 'Der Anzeigename wird in der Benutzeroberfläche angezeigt, z.B. "Vertriebsleiter".', '✏️', '#create-role-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000001', 4, 'Beschreibung hinzufügen', 'Eine hilfreiche Beschreibung erleichtert anderen Administratoren das Verständnis dieser Rolle.', '📝', '#create-role-description', 'Beschreibung', 'bottom'),

  -- Gruppen verwalten Tour
  ('50000000-0000-0000-0002-000000000002', 1, 'Gruppen verstehen', 'Gruppen fassen Benutzer zusammen und ermöglichen die gemeinsame Zuweisung von Berechtigungen.', '👥', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000002', 2, 'Gruppen-Schlüssel', 'Wählen Sie einen eindeutigen Schlüssel für die Gruppe, z.B. "marketing_team".', '🔑', '#create-group-key', 'Gruppen-Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000002', 3, 'Gruppenname', 'Der Anzeigename sollte die Funktion der Gruppe beschreiben.', '🏷️', '#create-group-displayname', 'Gruppenname', 'bottom'),

  -- Organisationseinheiten Tour
  ('50000000-0000-0000-0002-000000000003', 1, 'MLM-Hierarchie', 'Organisationseinheiten bilden Ihre Unternehmensstruktur ab: Unternehmen → Zweigstelle → Abteilung → Team.', '🏢', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 2, 'Typ auswählen', 'Wählen Sie die Hierarchieebene. Dies bestimmt die Position in der Struktur.', '📊', 'select[name="orgUnitTypeId"]', 'Typ', 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 3, 'Schlüssel vergeben', 'Der Schlüssel identifiziert diese Einheit eindeutig, z.B. "hq_munich".', '🔑', 'input[name="key"]', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 4, 'Namen festlegen', 'Geben Sie einen beschreibenden Namen ein, z.B. "Hauptsitz München".', '🏷️', 'input[name="displayName"]', 'Name', 'bottom'),
  ('50000000-0000-0000-0002-000000000003', 5, 'Übergeordnete Einheit', 'Wählen Sie die übergeordnete Organisationseinheit (falls vorhanden).', '⬆️', 'select[name="parentId"]', 'Übergeordnete Einheit', 'bottom'),

  -- Berechtigungsmatrix Tour
  ('50000000-0000-0000-0002-000000000004', 1, 'Matrix-Ansicht', 'Die Matrix zeigt alle Berechtigungen pro Gruppe in einer übersichtlichen Tabelle.', '📊', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000004', 2, 'Zeilen = Gruppen', 'Jede Zeile repräsentiert eine Benutzergruppe mit ihren zugewiesenen Berechtigungen.', '↔️', '.matrix-row', 'Gruppen-Zeile', 'right'),
  ('50000000-0000-0000-0002-000000000004', 3, 'Spalten = Berechtigungen', 'Jede Spalte zeigt eine spezifische Berechtigung (Modul + Aktion).', '↕️', '.matrix-header', 'Berechtigungs-Header', 'bottom'),
  ('50000000-0000-0000-0002-000000000004', 4, 'Direktes Bearbeiten', 'Klicken Sie auf eine Zelle, um die Berechtigung zu aktivieren oder zu deaktivieren.', '✅', '.matrix-cell', 'Matrix-Zelle', 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET
  title = EXCLUDED.title,
  content = EXCLUDED.content,
  icon = EXCLUDED.icon,
  field_selector = EXCLUDED.field_selector,
  field_label = EXCLUDED.field_label;

-- ============================================================================
-- Seed: Tour Steps - API Keys Module
-- ============================================================================
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- API-Schlüssel erstellen Tour
  ('50000000-0000-0000-0003-000000000001', 1, 'API-Schlüssel Übersicht', 'API-Schlüssel ermöglichen externen Anwendungen den sicheren Zugriff auf LicenseGuard.', '🔐', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 2, 'Benutzer auswählen', 'Wählen Sie den Benutzer, dem dieser API-Schlüssel zugeordnet werden soll.', '👤', 'select[name="userId"]', 'Benutzer', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 3, 'Schlüssel benennen', 'Geben Sie einen beschreibenden Namen ein, z.B. "Production Integration" oder "Test-Key".', '🏷️', 'input[name="name"]', 'Name', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 4, 'Tier festlegen', 'Der Tier bestimmt Rate-Limits: Basic (1.000/Tag), Pro (10.000/Tag), Enterprise (unbegrenzt).', '⭐', 'select[name="tier"]', 'Tier', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 5, 'Ablaufdatum (optional)', 'Setzen Sie ein Ablaufdatum für zusätzliche Sicherheit.', '📅', 'input[name="expiresAt"]', 'Ablaufdatum', 'bottom'),
  ('50000000-0000-0000-0003-000000000001', 6, 'Schlüssel sichern!', 'WICHTIG: Der generierte Schlüssel wird nur einmal angezeigt. Kopieren Sie ihn sofort!', '⚠️', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO UPDATE SET
  title = EXCLUDED.title,
  content = EXCLUDED.content,
  icon = EXCLUDED.icon,
  field_selector = EXCLUDED.field_selector,
  field_label = EXCLUDED.field_label;

-- ============================================================================
-- Seed: Tour Steps - Tour Module
-- ============================================================================
INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  -- Touren verwalten Tour
  ('50000000-0000-0000-0004-000000000001', 1, 'Tour-Verwaltung', 'Hier erstellen und verwalten Sie interaktive Onboarding-Touren für Ihre Admin-Seiten.', '🗺️', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000001', 2, 'Formular auswählen', 'Wählen Sie die Admin-Seite, für die Sie eine Tour erstellen möchten.', '📄', 'select[name="formId"]', 'Formular', 'bottom'),
  ('50000000-0000-0000-0004-000000000001', 3, 'Tour benennen', 'Geben Sie einen klaren Namen für die Tour ein, z.B. "Erste Schritte".', '✏️', 'input[name="name"]', 'Tour-Name', 'bottom'),
  ('50000000-0000-0000-0004-000000000001', 4, 'Beschreibung', 'Eine kurze Beschreibung hilft Benutzern zu verstehen, was sie lernen werden.', '📝', 'textarea[name="description"]', 'Beschreibung', 'bottom'),

  -- Tour-Schritte konfigurieren Tour
  ('50000000-0000-0000-0004-000000000002', 1, 'Schritte verstehen', 'Jede Tour besteht aus mehreren Schritten, die Benutzer durch die Seite führen.', '👣', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 2, 'Titel eingeben', 'Der Titel wird als Überschrift im Tooltip angezeigt.', '📌', 'input[name="title"]', 'Titel', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 3, 'Inhalt beschreiben', 'Erklären Sie, was der Benutzer an dieser Stelle tun soll.', '💬', 'textarea[name="content"]', 'Inhalt', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 4, 'Ziel-Element', 'CSS-Selektor des Elements, das hervorgehoben werden soll, z.B. "#submit-btn".', '🎯', 'input[name="targetSelector"]', 'CSS-Selektor', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 5, 'Position wählen', 'Bestimmen Sie, wo der Tooltip erscheinen soll: oben, unten, links oder rechts.', '📍', 'select[name="placement"]', 'Position', 'bottom'),
  ('50000000-0000-0000-0004-000000000002', 6, 'Reihenfolge anpassen', 'Nutzen Sie die Pfeile, um die Reihenfolge der Schritte zu ändern.', '↕️', '.step-order-buttons', 'Sortier-Buttons', 'right')
ON CONFLICT (tour_id, step_order) DO UPDATE SET
  title = EXCLUDED.title,
  content = EXCLUDED.content,
  icon = EXCLUDED.icon,
  field_selector = EXCLUDED.field_selector,
  field_label = EXCLUDED.field_label;

-- ============================================================================
-- Comments
-- ============================================================================
COMMENT ON TABLE form_registry IS 'Registry of admin forms/pages that can have guided tours';
COMMENT ON TABLE tours IS 'Guided tours for admin pages (one tour per form)';
COMMENT ON TABLE tour_steps IS 'Individual steps within a guided tour';

COMMIT;
