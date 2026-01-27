-- Migration: Validate and Clean Tour Selectors
-- Description: Removes invalid jQuery-style selectors and sets validation status
-- Version: 011
-- Date: 2026-01-27

BEGIN;

-- ============================================================================
-- Remove all invalid jQuery selectors (not standard CSS)
-- ============================================================================

-- :contains() is jQuery-specific, not valid CSS
UPDATE tour_steps
SET field_selector = NULL,
    validation_status = 'valid',
    validation_message = 'Selektor entfernt (jQuery-Syntax :contains nicht unterstützt)'
WHERE field_selector LIKE '%:contains(%';

-- :first, :last, :eq() are also jQuery-specific
UPDATE tour_steps
SET field_selector = NULL,
    validation_status = 'valid',
    validation_message = 'Selektor entfernt (jQuery-Syntax nicht unterstützt)'
WHERE field_selector LIKE '%:first%'
   OR field_selector LIKE '%:last%'
   OR field_selector LIKE '%:eq(%';

-- ============================================================================
-- Set steps without selector to valid (centered tooltip is OK)
-- ============================================================================
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE field_selector IS NULL
  AND validation_status != 'valid';

-- ============================================================================
-- Validate ID selectors (these should work)
-- ============================================================================
UPDATE tour_steps
SET validation_status = 'valid',
    validation_message = NULL
WHERE field_selector LIKE '#%'
  AND field_selector NOT LIKE '% %'  -- No spaces (simple ID selector)
  AND validation_status != 'valid';

-- ============================================================================
-- Mark complex selectors as pending for manual review
-- (tour_steps only allows: valid, invalid, pending)
-- ============================================================================
UPDATE tour_steps
SET validation_status = 'pending',
    validation_message = 'Komplexer Selektor - manuell prüfen'
WHERE field_selector IS NOT NULL
  AND field_selector NOT LIKE '#%'
  AND validation_status NOT IN ('valid');

-- ============================================================================
-- Update tours to valid if all their steps are valid
-- ============================================================================
UPDATE tours t
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM tour_steps ts
  WHERE ts.tour_id = t.id
    AND ts.validation_status NOT IN ('valid')
);

-- Update tours with warnings if they have pending steps
UPDATE tours t
SET validation_status = 'warning',
    validation_message = 'Einige Steps erfordern manuelle Prüfung',
    last_validated_at = NOW()
WHERE EXISTS (
  SELECT 1 FROM tour_steps ts
  WHERE ts.tour_id = t.id
    AND ts.validation_status = 'pending'
)
AND validation_status != 'warning';

COMMIT;
