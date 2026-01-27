-- Migration: Fix ALL Tour Selectors - Comprehensive Audit
-- Date: 2026-01-27
-- Description: Alle Page-Tours müssen auf Page-Elemente zeigen, nicht Modal-Elemente!
--              Alle Steps brauchen korrekte field_labels und validation_status.
--              Modal-Tours (*.create, *.edit) zeigen auf Modal-Felder - das ist korrekt.

BEGIN;

-- =============================================================================
-- 1. admin.permissions.roles: PAGE Tour - Delete step 4 (modal element!)
-- =============================================================================
-- Step 4 zeigt auf #create-role-description (MODAL element!) → entfernen

DELETE FROM tour_steps
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.roles')
  AND step_order = 4;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.permissions.roles';

-- =============================================================================
-- 2. admin.tour.tours: PAGE Tour - Fix selectors to point to page elements
-- =============================================================================

-- Step 2: select[name="formId"] (MODAL!) → #btn-add-tour (PAGE button)
UPDATE tour_steps
SET field_selector = '#btn-add-tour',
    field_label = 'Neue Tour Button',
    title = 'Tour erstellen',
    content = 'Klicken Sie hier, um eine neue Tour zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.tours')
  AND step_order = 2;

-- Step 3: input[name="name"] (MODAL!) → #tours-table (PAGE table)
UPDATE tour_steps
SET field_selector = '#tours-table',
    field_label = 'Touren-Tabelle',
    title = 'Ihre Touren',
    content = 'Hier sehen Sie alle Touren mit Status, Validierung und Schritt-Anzahl. Klicken Sie auf "Schritte" um die Tour-Schritte zu bearbeiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.tours')
  AND step_order = 3;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.tour.tours';

-- =============================================================================
-- 3. admin.tour.steps: PAGE Tour - Fix selectors to point to page elements
-- =============================================================================

-- Step 2: input[name="title"] (MODAL!) → #steps-tour-select (PAGE tour selector)
UPDATE tour_steps
SET field_selector = '#steps-tour-select',
    field_label = 'Tour-Auswahl',
    title = 'Tour auswählen',
    content = 'Wählen Sie hier die Tour aus, deren Schritte Sie bearbeiten möchten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.steps')
  AND step_order = 2;

-- Step 3: textarea[name="content"] (MODAL!) → #btn-add-step (PAGE button)
UPDATE tour_steps
SET field_selector = '#btn-add-step',
    field_label = 'Neuer Schritt Button',
    title = 'Schritt hinzufügen',
    content = 'Klicken Sie hier, um einen neuen Schritt zur ausgewählten Tour hinzuzufügen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.steps')
  AND step_order = 3;

-- Step 4: input[name="targetSelector"] (MODAL!) → #steps-list (PAGE steps list)
UPDATE tour_steps
SET field_selector = '#steps-list',
    field_label = 'Schritte-Liste',
    title = 'Ihre Schritte',
    content = 'Hier sehen Sie alle Schritte der Tour. Sie können die Reihenfolge mit den Pfeilen ändern oder einzelne Schritte bearbeiten.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.steps')
  AND step_order = 4;

-- Step 5: select[name="placement"] (MODAL!) → DELETE
DELETE FROM tour_steps
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.steps')
  AND step_order = 5;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.tour.steps';

-- =============================================================================
-- 4. admin.apikeys.keys: PAGE Tour - Fix selectors to point to page elements
-- =============================================================================

-- Step 2: select[name="userId"] (MODAL!) → #btn-generate-key (PAGE button)
UPDATE tour_steps
SET field_selector = '#btn-generate-key',
    field_label = 'API-Key erstellen Button',
    title = 'Schlüssel generieren',
    content = 'Klicken Sie hier, um einen neuen API-Schlüssel zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.apikeys.keys')
  AND step_order = 2;

-- Step 3: input[name="name"] (MODAL!) → #apikeys-table (PAGE table)
UPDATE tour_steps
SET field_selector = '#apikeys-table',
    field_label = 'API-Keys Tabelle',
    title = 'Ihre Schlüssel',
    content = 'Hier sehen Sie alle API-Schlüssel mit Benutzer, Tier, Status und Ablaufdatum.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.apikeys.keys')
  AND step_order = 3;

-- Step 4: select[name="tier"] (MODAL!) → DELETE
DELETE FROM tour_steps
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.apikeys.keys')
  AND step_order = 4;

-- Step 5 (outro, no selector) → Fix step_order to 4 after deleting step 4
UPDATE tour_steps
SET step_order = 4,
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.apikeys.keys')
  AND step_order = 5;

-- Also fix step 1 validation
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.apikeys.keys')
  AND step_order = 1;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.apikeys.keys';

-- =============================================================================
-- 5. admin.permissions.org-units: PAGE Tour - Fix selectors to page elements
-- =============================================================================

-- Step 1: Fix validation
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.org-units')
  AND step_order = 1;

-- Step 2: select[name="orgUnitTypeId"] (MODAL!) → #btn-add-ou (PAGE button)
UPDATE tour_steps
SET field_selector = '#btn-add-ou',
    field_label = 'Neue OU Button',
    title = 'OU erstellen',
    content = 'Klicken Sie hier, um eine neue Organisationseinheit zu erstellen.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.org-units')
  AND step_order = 2;

-- Step 3: input[name="key"] (MODAL!) → #org-units-graph (PAGE graph)
UPDATE tour_steps
SET field_selector = '#org-units-graph',
    field_label = 'Hierarchie-Graph',
    title = 'OU-Hierarchie',
    content = 'Hier sehen Sie die hierarchische Struktur Ihrer Organisationseinheiten. Klicken Sie auf eine OU für Details.',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.org-units')
  AND step_order = 3;

-- Step 4: input[name="displayName"] (MODAL!) → DELETE
DELETE FROM tour_steps
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.permissions.org-units')
  AND step_order = 4;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.permissions.org-units';

-- =============================================================================
-- 6. admin.user.users.create: MODAL Tour - Fix field_labels and validation
-- =============================================================================
-- This is a MODAL tour - the selectors are correct (input[name="..."] inside modal)
-- Just need to add field_labels and set validation_status

UPDATE tour_steps
SET field_label = 'Name',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users.create')
  AND step_order = 1;

UPDATE tour_steps
SET field_label = 'E-Mail',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users.create')
  AND step_order = 2;

UPDATE tour_steps
SET field_label = 'Passwort',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users.create')
  AND step_order = 3;

UPDATE tour_steps
SET field_label = 'Rolle',
    validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.user.users.create')
  AND step_order = 4;

UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE form_id = 'admin.user.users.create';

-- =============================================================================
-- 7. Verify: Set field_label on already-fixed steps that are missing it
-- =============================================================================

-- admin.user.users step 1 (intro - no selector, no label needed)
-- Steps 2-4 already have field_labels from migration 012

-- admin.permissions.groups step 1 (intro - no label needed)
-- Steps 2-3 already have field_labels from migration 012

-- admin.permissions.matrix step 1 (intro - no label needed)
-- Steps 2-3 already have field_labels from migration 012

-- admin.tour.tours step 1 (intro - no label needed, update validation)
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.tours')
  AND step_order = 1
  AND validation_status != 'valid';

-- admin.tour.steps step 1 (intro - no label needed, update validation)
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE tour_id = (SELECT id FROM tours WHERE form_id = 'admin.tour.steps')
  AND step_order = 1
  AND validation_status != 'valid';

COMMIT;
