-- Migration: Fix Tour Selectors
-- Description: Updates field_selectors to match actual DOM elements in lg-admin
-- Version: 009
-- Date: 2026-01-27

BEGIN;

-- ============================================================================
-- Add new form_registry entries for modal forms
-- ============================================================================
INSERT INTO form_registry (form_id, form_name, form_alias, form_path, module, description, available_fields) VALUES
  -- User Module - Modals
  ('admin.user.users.create', 'Benutzer erstellen', 'Create User', '/user/users#create', 'user', 'Modal: Neuen Benutzer erstellen', '[]'),
  ('admin.user.users.edit', 'Benutzer bearbeiten', 'Edit User', '/user/users#edit', 'user', 'Modal: Benutzer bearbeiten', '[]'),

  -- Permissions Module - Modals
  ('admin.permissions.roles.create', 'Rolle erstellen', 'Create Role', '/permissions/roles#create', 'permissions', 'Modal: Neue Rolle erstellen', '[]'),
  ('admin.permissions.permissions.create', 'Berechtigung erstellen', 'Create Permission', '/permissions/permissions#create', 'permissions', 'Modal: Neue Berechtigung erstellen', '[]'),
  ('admin.permissions.groups.create', 'Gruppe erstellen', 'Create Group', '/permissions/groups#create', 'permissions', 'Modal: Neue Gruppe erstellen', '[]'),
  ('admin.permissions.groups.edit', 'Gruppe bearbeiten', 'Edit Group', '/permissions/groups#edit', 'permissions', 'Modal: Gruppe bearbeiten', '[]'),
  ('admin.permissions.modules.create', 'Modul erstellen', 'Create Module', '/permissions/modules#create', 'permissions', 'Modal: Neues Modul erstellen', '[]'),
  ('admin.permissions.modules.edit', 'Modul bearbeiten', 'Edit Module', '/permissions/modules#edit', 'permissions', 'Modal: Modul bearbeiten', '[]'),

  -- Tour Module - Modals
  ('admin.tour.tours.create', 'Tour erstellen', 'Create Tour', '/tour/tours#create', 'tour', 'Modal: Neue Tour erstellen', '[]'),
  ('admin.tour.tours.edit', 'Tour bearbeiten', 'Edit Tour', '/tour/tours#edit', 'tour', 'Modal: Tour bearbeiten', '[]'),
  ('admin.tour.steps.create', 'Schritt erstellen', 'Create Step', '/tour/steps#create', 'tour', 'Modal: Neuen Schritt erstellen', '[]'),
  ('admin.tour.steps.edit', 'Schritt bearbeiten', 'Edit Step', '/tour/steps#edit', 'tour', 'Modal: Schritt bearbeiten', '[]'),

  -- Shell Module - Modals
  ('admin.shell.menu.create', 'Menu-Eintrag erstellen', 'Create Menu Item', '/shell/menu-settings#create', 'shell', 'Modal: Neuen Menu-Eintrag erstellen', '[]'),
  ('admin.shell.menu.edit', 'Menu-Eintrag bearbeiten', 'Edit Menu Item', '/shell/menu-settings#edit', 'shell', 'Modal: Menu-Eintrag bearbeiten', '[]'),

  -- Shell Module - Pages
  ('admin.shell.menu-settings', 'Menu-Einstellungen', 'Menu Settings', '/shell/menu-settings', 'shell', 'Menu-Struktur verwalten', '[]')
ON CONFLICT (form_id) DO UPDATE SET
  form_name = EXCLUDED.form_name,
  form_path = EXCLUDED.form_path,
  module = EXCLUDED.module,
  description = EXCLUDED.description;

-- ============================================================================
-- Update field_selectors to be more robust
-- Using generic CSS class selectors instead of button text content
-- Note: Tours will need manual validation after DOM analysis
-- ============================================================================

-- Update User Tours - Remove selectors that use :contains() which is not standard CSS
UPDATE tour_steps
SET field_selector = NULL, -- Will show centered, needs manual update after DOM analysis
    validation_status = 'pending',
    validation_message = 'Selektor muss nach DOM-Analyse angepasst werden'
WHERE field_selector LIKE '%:contains(%'
  AND tour_id IN (SELECT id FROM tours);

-- ============================================================================
-- Set validation_status to 'warning' for all tours
-- This signals to the UI that tours need manual review
-- ============================================================================

-- Mark all existing tours as needing validation
UPDATE tours
SET validation_status = 'warning',
    validation_message = 'Tour-Schritte müssen nach UI-Refactoring validiert werden',
    last_validated_at = NULL
WHERE validation_status = 'valid';

-- Mark all steps with field_selectors as needing validation
UPDATE tour_steps
SET validation_status = 'pending',
    validation_message = 'Selektor muss validiert werden'
WHERE field_selector IS NOT NULL
  AND validation_status = 'valid';

-- ============================================================================
-- Comments
-- ============================================================================
COMMENT ON COLUMN tour_steps.field_selector IS 'CSS selector for target element. Use standard CSS selectors, not jQuery extensions like :contains()';

COMMIT;
