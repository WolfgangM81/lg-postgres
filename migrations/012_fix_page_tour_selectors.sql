-- Migration: Fix Page Tour Selectors
-- Date: 2026-01-27
-- Description: Page-Tours zeigen auf Page-Elemente, nicht Modal-Elemente!
--              Die Steps 3-5 zeigten auf Modal-Felder (#create-user-email etc.)
--              die nicht existieren wenn die Page-Tour startet.

BEGIN;

-- =============================================================================
-- admin.user.users: Page Tour - Fix selectors to point to PAGE elements
-- =============================================================================

-- Step 2: Change from centered to "Add User" button
UPDATE tour_steps
SET field_selector = '#btn-add-user',
    field_label = 'Neuer Benutzer Button',
    title = 'Benutzer anlegen',
    content = 'Klicken Sie hier, um einen neuen Benutzer zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users')
  AND step_order = 2;

-- Step 3: Change from modal email field to search input
UPDATE tour_steps
SET field_selector = '#users-search',
    field_label = 'Suche',
    title = 'Benutzer suchen',
    content = 'Hier können Sie nach Benutzern suchen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users')
  AND step_order = 3;

-- Step 4: Change from modal name field to users table
UPDATE tour_steps
SET field_selector = '#users-table',
    field_label = 'Benutzerliste',
    title = 'Ihre Benutzer',
    content = 'Hier sehen Sie alle Benutzer. Klicken Sie auf einen Benutzer um ihn zu bearbeiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users')
  AND step_order = 4;

-- Step 5: Remove (was pointing to modal role field)
DELETE FROM tour_steps
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users')
  AND step_order = 5;

-- Update tour validation status
UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.user.users';

-- =============================================================================
-- admin.permissions.roles: Page Tour - Fix selectors
-- =============================================================================

-- Check if tour exists, then update
UPDATE tour_steps
SET field_selector = '#btn-add-role',
    field_label = 'Neue Rolle Button',
    title = 'Rolle erstellen',
    content = 'Klicken Sie hier, um eine neue Rolle zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.roles')
  AND step_order = 2
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.roles') > 0;

UPDATE tour_steps
SET field_selector = '#roles-table',
    field_label = 'Rollenliste',
    title = 'Ihre Rollen',
    content = 'Hier sehen Sie alle definierten Rollen. Klicken Sie auf eine Rolle um sie zu bearbeiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.roles')
  AND step_order = 3
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.roles') > 0;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.permissions.roles';

-- =============================================================================
-- admin.permissions.groups: Page Tour - Fix selectors
-- =============================================================================

UPDATE tour_steps
SET field_selector = '#btn-add-group',
    field_label = 'Neue Gruppe Button',
    title = 'Gruppe erstellen',
    content = 'Klicken Sie hier, um eine neue Berechtigungsgruppe zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.groups')
  AND step_order = 2
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.groups') > 0;

UPDATE tour_steps
SET field_selector = '#groups-table',
    field_label = 'Gruppenliste',
    title = 'Ihre Gruppen',
    content = 'Hier sehen Sie alle Berechtigungsgruppen. Klicken Sie auf eine Gruppe um sie zu bearbeiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.groups')
  AND step_order = 3
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.groups') > 0;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.permissions.groups';

-- =============================================================================
-- admin.permissions.matrix: Page Tour - Fix selectors
-- =============================================================================

UPDATE tour_steps
SET field_selector = '#matrix-header',
    field_label = 'Matrix Header',
    title = 'Matrix Übersicht',
    content = 'Hier verwalten Sie die Zuordnung von Rollen zu Organisationseinheiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.matrix')
  AND step_order = 2
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.matrix') > 0;

UPDATE tour_steps
SET field_selector = '#matrix-table',
    field_label = 'Matrix Tabelle',
    title = 'Rollen-Matrix',
    content = 'Klicken Sie auf eine Zelle um die Rollenzuweisung zu ändern. Grüne Häkchen zeigen aktive Zuweisungen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.matrix')
  AND step_order = 3
  AND (SELECT COUNT(*) FROM tours WHERE form_id = 'admin.permissions.matrix') > 0;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.permissions.matrix';

COMMIT;
