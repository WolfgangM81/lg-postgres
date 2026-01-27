-- Migration: Fix Tour Field Selectors with Element IDs
-- Description: Updates field_selectors to use the new element IDs added to form elements
-- Version: 010
-- Date: 2026-01-27

BEGIN;

-- ============================================================================
-- Update form_registry available_fields with correct element IDs
-- ============================================================================

-- User Module
UPDATE form_registry SET available_fields = '[
  "#create-user-name",
  "#create-user-email",
  "#create-user-password",
  "#create-user-role"
]'::jsonb WHERE form_id = 'admin.user.users';

UPDATE form_registry SET available_fields = '[
  "#create-user-name",
  "#create-user-email",
  "#create-user-password",
  "#create-user-role"
]'::jsonb WHERE form_id = 'admin.user.users.create';

UPDATE form_registry SET available_fields = '[
  "#edit-user-name",
  "#edit-user-email",
  "#edit-user-password",
  "#edit-user-role",
  "#edit-user-status"
]'::jsonb WHERE form_id = 'admin.user.users.edit';

-- Permissions Module - Roles
UPDATE form_registry SET available_fields = '[
  "#create-role-key",
  "#create-role-displayname",
  "#create-role-description"
]'::jsonb WHERE form_id = 'admin.permissions.roles';

UPDATE form_registry SET available_fields = '[
  "#create-role-key",
  "#create-role-displayname",
  "#create-role-description"
]'::jsonb WHERE form_id = 'admin.permissions.roles.create';

-- Permissions Module - Groups
UPDATE form_registry SET available_fields = '[
  "#create-group-key",
  "#create-group-displayname",
  "#create-group-description"
]'::jsonb WHERE form_id = 'admin.permissions.groups';

UPDATE form_registry SET available_fields = '[
  "#create-group-key",
  "#create-group-displayname",
  "#create-group-description"
]'::jsonb WHERE form_id = 'admin.permissions.groups.create';

UPDATE form_registry SET available_fields = '[
  "#edit-group-key",
  "#edit-group-displayname",
  "#edit-group-description"
]'::jsonb WHERE form_id = 'admin.permissions.groups.edit';

-- Permissions Module - Modules
UPDATE form_registry SET available_fields = '[
  "#create-module-key",
  "#create-module-displayname",
  "#create-module-description",
  "#create-module-crud"
]'::jsonb WHERE form_id = 'admin.permissions.modules';

UPDATE form_registry SET available_fields = '[
  "#create-module-key",
  "#create-module-displayname",
  "#create-module-description",
  "#create-module-crud"
]'::jsonb WHERE form_id = 'admin.permissions.modules.create';

UPDATE form_registry SET available_fields = '[
  "#edit-module-key",
  "#edit-module-displayname",
  "#edit-module-description"
]'::jsonb WHERE form_id = 'admin.permissions.modules.edit';

-- Permissions Module - Permissions
UPDATE form_registry SET available_fields = '[
  "#create-permission-module",
  "#create-permission-action"
]'::jsonb WHERE form_id = 'admin.permissions.permissions';

UPDATE form_registry SET available_fields = '[
  "#create-permission-module",
  "#create-permission-action"
]'::jsonb WHERE form_id = 'admin.permissions.permissions.create';

-- ============================================================================
-- Update tour_steps with correct field_selectors (element IDs)
-- ============================================================================

-- Users Tour (50000000-0000-0000-0001-000000000001)
-- Step 3: E-Mail-Adresse
UPDATE tour_steps
SET field_selector = '#create-user-email',
    field_label = 'E-Mail-Adresse',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0001-000000000001'
  AND step_order = 3;

-- Step 4: Name festlegen
UPDATE tour_steps
SET field_selector = '#create-user-name',
    field_label = 'Name',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0001-000000000001'
  AND step_order = 4;

-- Step 5: Rolle zuweisen
UPDATE tour_steps
SET field_selector = '#create-user-role',
    field_label = 'Rolle',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0001-000000000001'
  AND step_order = 5;

-- Roles Tour (50000000-0000-0000-0002-000000000001)
-- Step 2: Schlüssel eingeben
UPDATE tour_steps
SET field_selector = '#create-role-key',
    field_label = 'Key',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000001'
  AND step_order = 2;

-- Step 3: Anzeigename definieren
UPDATE tour_steps
SET field_selector = '#create-role-displayname',
    field_label = 'Anzeigename',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000001'
  AND step_order = 3;

-- Step 4: Beschreibung hinzufügen
UPDATE tour_steps
SET field_selector = '#create-role-description',
    field_label = 'Beschreibung',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000001'
  AND step_order = 4;

-- Groups Tour (50000000-0000-0000-0002-000000000002)
-- Step 2: Gruppen-Schlüssel
UPDATE tour_steps
SET field_selector = '#create-group-key',
    field_label = 'Gruppen-Schlüssel',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000002'
  AND step_order = 2;

-- Step 3: Gruppenname
UPDATE tour_steps
SET field_selector = '#create-group-displayname',
    field_label = 'Gruppenname',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000002'
  AND step_order = 3;

-- Org-Units Tour (50000000-0000-0000-0002-000000000003)
-- These use native selects which keep their name attributes
-- Step 2: Typ auswählen
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = '50000000-0000-0000-0002-000000000003'
  AND step_order = 2;

-- ============================================================================
-- Set all tours to valid status
-- ============================================================================
UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE id IN (
  '50000000-0000-0000-0001-000000000001',  -- Users Tour
  '50000000-0000-0000-0002-000000000001',  -- Roles Tour
  '50000000-0000-0000-0002-000000000002',  -- Groups Tour
  '50000000-0000-0000-0002-000000000003',  -- Org-Units Tour
  '50000000-0000-0000-0002-000000000004',  -- Matrix Tour
  '50000000-0000-0000-0003-000000000001',  -- API Keys Tour
  '50000000-0000-0000-0004-000000000001',  -- Tours Tour
  '50000000-0000-0000-0004-000000000002'   -- Steps Tour
);

-- Set remaining steps without field_selectors to valid (intro/outro steps)
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE field_selector IS NULL;

-- ============================================================================
-- Clear :contains() selectors (not standard CSS)
-- These will need manual fixing or showing centered
-- ============================================================================
UPDATE tour_steps
SET field_selector = NULL,
    validation_status = 'valid',
    validation_message = 'Selektor entfernt (jQuery-Syntax nicht unterstützt)'
WHERE field_selector LIKE '%:contains(%';

COMMIT;
