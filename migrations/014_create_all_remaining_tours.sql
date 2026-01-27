-- Migration 014: Create tours for all 23 remaining registered forms
-- Date: 2026-01-27
-- Purpose: Every form in form_registry gets a tour with meaningful steps

BEGIN;

-- ============================================================================
-- DASHBOARD TOURS (4) - Overview pages with centered intro steps
-- ============================================================================

-- 1. admin.user.dashboard
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0001-000000000010', 'admin.user.dashboard', 'Benutzer-Dashboard',
   'Überblick über das Benutzer-Dashboard', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0001-000000000010', 1, 'Benutzer-Dashboard',
   'Willkommen im Benutzer-Dashboard. Hier sehen Sie eine Übersicht über alle registrierten Benutzer und deren Status.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000010', 2, 'Statistiken',
   'Das Dashboard zeigt Ihnen wichtige Kennzahlen wie die Anzahl aktiver Benutzer, neue Registrierungen und Login-Aktivitäten.',
   '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 2. admin.permissions.dashboard
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000010', 'admin.permissions.dashboard', 'Berechtigungs-Dashboard',
   'Überblick über das Berechtigungssystem', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000010', 1, 'Berechtigungs-Dashboard',
   'Willkommen im Berechtigungs-Dashboard. Hier erhalten Sie einen Überblick über Rollen, Gruppen und Berechtigungen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000010', 2, 'System-Übersicht',
   'Das Dashboard zeigt die Gesamtzahl der Rollen, Gruppen, Permissions und Organisationseinheiten in Ihrem System.',
   '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 3. admin.apikeys.dashboard
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0003-000000000010', 'admin.apikeys.dashboard', 'API-Keys Dashboard',
   'Überblick über das API-Key Dashboard', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0003-000000000010', 1, 'API-Key Dashboard',
   'Willkommen im API-Key Dashboard. Hier sehen Sie Statistiken zu Ihren API-Schlüsseln und Validierungen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0003-000000000010', 2, 'Kennzahlen',
   'Das Dashboard zeigt die Anzahl aktiver API-Keys, heutige Validierungen, die Erfolgsrate und abgelaufene Schlüssel.',
   '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 4. admin.tour.dashboard
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0004-000000000010', 'admin.tour.dashboard', 'Tour-Dashboard',
   'Überblick über das Tour-System Dashboard', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0004-000000000010', 1, 'Tour-Dashboard',
   'Willkommen im Tour-Dashboard. Hier verwalten Sie interaktive Touren, die Benutzer durch die Anwendung führen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000010', 2, 'Übersicht',
   'Das Dashboard zeigt die Anzahl aktiver Touren, Schritte und den Validierungsstatus aller Touren.',
   '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;


-- ============================================================================
-- PAGE TOURS (6) - Pages with interactive elements
-- ============================================================================

-- 5. admin.permissions.permissions
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000005', 'admin.permissions.permissions', 'Berechtigungen verwalten',
   'Lernen Sie, wie Sie Berechtigungen anzeigen und verwalten', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000005', 1, 'Berechtigungen',
   'In dieser Ansicht verwalten Sie alle Berechtigungen (Permissions) des Systems. Jede Berechtigung besteht aus einem Modul und einer Aktion.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 2, 'Neue Berechtigung',
   'Klicken Sie hier, um eine neue Berechtigung hinzuzufügen. Wählen Sie ein Modul und eine Aktion aus.',
   '➕', '#btn-add-permission', 'Neue Berechtigung', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 3, 'Filter',
   'Nutzen Sie die Filter, um Berechtigungen nach Modul oder Aktion einzugrenzen.',
   '🔍', '#permissions-filters', 'Filter', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 4, 'Suche',
   'Suchen Sie gezielt nach Berechtigungen über das Suchfeld.',
   '🔎', '#permissions-search', 'Suchfeld', 'bottom'),
  ('50000000-0000-0000-0002-000000000005', 5, 'Berechtigungsliste',
   'Hier sehen Sie alle Berechtigungen. Klicken Sie auf eine Berechtigung um Details anzuzeigen.',
   '📋', '#permissions-list', 'Berechtigungsliste', 'top')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 6. admin.permissions.modules
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000006', 'admin.permissions.modules', 'Module verwalten',
   'Lernen Sie, wie Sie Module anlegen und verwalten', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000006', 1, 'Module',
   'Module gruppieren zusammengehörige Berechtigungen. Jedes Modul kann CRUD-Aktionen (Create, Read, Update, Delete) haben.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000006', 2, 'Neues Modul',
   'Klicken Sie hier, um ein neues Modul anzulegen.',
   '➕', '#btn-add-module', 'Neues Modul', 'bottom'),
  ('50000000-0000-0000-0002-000000000006', 3, 'Modul-Tabelle',
   'Hier sehen Sie alle Module mit ihren Schlüsseln und Beschreibungen. Klicken Sie auf ein Modul zum Bearbeiten.',
   '📋', '#modules-table', 'Module', 'top')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 7. admin.permissions.variants
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000007', 'admin.permissions.variants', 'Varianten verwalten',
   'Lernen Sie, wie Sie Berechtigungsvarianten erstellen', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000007', 1, 'Varianten',
   'Varianten definieren vorkonfigurierte Berechtigungspakete, die Rollen zugewiesen werden können.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000007', 2, 'Neue Variante',
   'Erstellen Sie eine neue Variante mit einem eindeutigen Schlüssel und Anzeigenamen.',
   '➕', '#btn-add-variant', 'Neue Variante', 'bottom'),
  ('50000000-0000-0000-0002-000000000007', 3, 'Varianten-Liste',
   'Hier sehen Sie alle Varianten. Wählen Sie eine Variante aus, um ihre Berechtigungen zu konfigurieren.',
   '📋', '#variants-list', 'Varianten', 'right'),
  ('50000000-0000-0000-0002-000000000007', 4, 'Berechtigungen zuweisen',
   'In diesem Bereich weisen Sie der ausgewählten Variante einzelne Berechtigungen zu.',
   '🔐', '#variants-permissions', 'Berechtigungen', 'left')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 8. admin.permissions.resources
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000008', 'admin.permissions.resources', 'Ressourcen verwalten',
   'Lernen Sie, wie Sie Ressourcen erstellen und verwalten', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000008', 1, 'Ressourcen',
   'Ressourcen sind geschützte Objekte in Ihrem System, auf die Berechtigungen angewendet werden.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000008', 2, 'Neue Ressource',
   'Klicken Sie hier, um eine neue Ressource zu erstellen.',
   '➕', '#btn-add-resource', 'Neue Ressource', 'bottom'),
  ('50000000-0000-0000-0002-000000000008', 3, 'Ressourcen-Übersicht',
   'Hier sehen Sie alle Ressourcen als Karten. Klicken Sie auf eine Ressource um sie zu bearbeiten.',
   '📋', '#resources-grid', 'Ressourcen', 'top')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 9. admin.permissions.effective
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000009', 'admin.permissions.effective', 'Permission Calculator',
   'Berechnen Sie effektive Berechtigungen für einen Benutzer', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000009', 1, 'Permission Calculator',
   'Der Permission Calculator zeigt Ihnen, welche effektiven Berechtigungen ein bestimmter Benutzer hat.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000009', 2, 'Benutzer-ID eingeben',
   'Geben Sie hier die UUID eines Benutzers ein, um dessen effektive Berechtigungen zu berechnen.',
   '🔑', '#effective-user-input', 'Benutzer-ID', 'bottom'),
  ('50000000-0000-0000-0002-000000000009', 3, 'Ergebnisse',
   'Nach Eingabe einer gültigen UUID sehen Sie alle Berechtigungen, deren Quelle (Rolle, Gruppe, Override) und Priorität.',
   '📊', NULL, NULL, 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 10. admin.shell.menu-settings
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0005-000000000001', 'admin.shell.menu-settings', 'Menu-Einstellungen',
   'Lernen Sie, wie Sie das Navigationsmenü konfigurieren', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0005-000000000001', 1, 'Menu-Einstellungen',
   'Hier verwalten Sie die Navigationsstruktur der Anwendung. Menü-Einträge können hierarchisch organisiert werden.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000001', 2, 'Neuer Eintrag',
   'Erstellen Sie einen neuen Menü-Eintrag mit Modul-Key, Label und Route.',
   '➕', '#btn-add-menu-item', 'Neuer Eintrag', 'bottom'),
  ('50000000-0000-0000-0005-000000000001', 3, 'Menü-Baum',
   'Hier sehen Sie die Menüstruktur als Baum. Elemente können per Drag & Drop umsortiert werden.',
   '🌳', '#menu-tree', 'Menü-Baum', 'right'),
  ('50000000-0000-0000-0005-000000000001', 4, 'Speichern',
   'Vergessen Sie nicht, Ihre Änderungen zu speichern.',
   '💾', '#btn-save-menu', 'Speichern', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;


-- ============================================================================
-- MODAL CREATE TOURS (7) - Form field tours inside create modals
-- ============================================================================

-- 11. admin.permissions.roles.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000011', 'admin.permissions.roles.create', 'Rolle erstellen',
   'Anleitung zum Erstellen einer neuen Rolle', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000011', 1, 'Neue Rolle',
   'Erstellen Sie eine neue Rolle mit eindeutigem Schlüssel und Anzeigenamen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 2, 'Schlüssel',
   'Der Schlüssel ist ein eindeutiger technischer Bezeichner (z.B. "admin", "editor"). Nur Kleinbuchstaben und Unterstriche.',
   '🔑', '#create-role-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 3, 'Anzeigename',
   'Der Anzeigename wird in der Oberfläche angezeigt (z.B. "Administrator", "Editor").',
   '📝', '#create-role-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000011', 4, 'Beschreibung',
   'Optional: Beschreiben Sie den Zweck dieser Rolle.',
   '📄', '#create-role-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 12. admin.permissions.groups.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000012', 'admin.permissions.groups.create', 'Gruppe erstellen',
   'Anleitung zum Erstellen einer neuen Gruppe', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000012', 1, 'Neue Gruppe',
   'Gruppen fassen Benutzer zusammen, um ihnen gemeinsam Rollen zuzuweisen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 2, 'Schlüssel',
   'Ein eindeutiger technischer Bezeichner für die Gruppe (z.B. "developers", "marketing").',
   '🔑', '#create-group-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 3, 'Anzeigename',
   'Der Name der Gruppe, der in der Oberfläche angezeigt wird.',
   '📝', '#create-group-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000012', 4, 'Beschreibung',
   'Optional: Beschreiben Sie den Zweck dieser Gruppe.',
   '📄', '#create-group-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 13. admin.permissions.permissions.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000013', 'admin.permissions.permissions.create', 'Berechtigung erstellen',
   'Anleitung zum Erstellen einer neuen Berechtigung', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000013', 1, 'Neue Berechtigung',
   'Erstellen Sie eine neue Berechtigung, indem Sie ein Modul und eine Aktion auswählen.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000013', 2, 'Modul',
   'Wählen Sie das Modul, zu dem die Berechtigung gehört (z.B. "users", "permissions").',
   '📦', '#create-permission-module', 'Modul', 'bottom'),
  ('50000000-0000-0000-0002-000000000013', 3, 'Aktion',
   'Wählen Sie die Aktion, die erlaubt werden soll (z.B. "read", "create", "update", "delete").',
   '⚡', '#create-permission-action', 'Aktion', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 14. admin.permissions.modules.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000014', 'admin.permissions.modules.create', 'Modul erstellen',
   'Anleitung zum Erstellen eines neuen Moduls', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000014', 1, 'Neues Modul',
   'Module gruppieren Berechtigungen nach Funktionsbereichen. Erstellen Sie hier ein neues Modul.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 2, 'Modul-Key',
   'Ein eindeutiger technischer Schlüssel (z.B. "users", "reports"). Nur Kleinbuchstaben.',
   '🔑', '#create-module-key', 'Modul-Key', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 3, 'Anzeigename',
   'Der Name des Moduls in der Benutzeroberfläche (z.B. "Benutzerverwaltung").',
   '📝', '#create-module-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 4, 'Beschreibung',
   'Optional: Beschreiben Sie, wofür dieses Modul verwendet wird.',
   '📄', '#create-module-description', 'Beschreibung', 'bottom'),
  ('50000000-0000-0000-0002-000000000014', 5, 'CRUD-Aktionen',
   'Aktivieren Sie die Standard-Aktionen (Create, Read, Update, Delete), die automatisch als Berechtigungen angelegt werden.',
   '⚙️', '#create-module-crud', 'CRUD-Aktionen', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 15. admin.shell.menu.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0005-000000000002', 'admin.shell.menu.create', 'Menu-Eintrag erstellen',
   'Anleitung zum Erstellen eines neuen Menü-Eintrags', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0005-000000000002', 1, 'Neuer Menü-Eintrag',
   'Erstellen Sie einen neuen Eintrag für das Navigationsmenü.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 2, 'Parent',
   'Wählen Sie optional ein übergeordnetes Element. Ohne Parent wird der Eintrag auf der obersten Ebene angezeigt.',
   '📂', '#menu-item-parent', 'Parent', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 3, 'Module Key',
   'Der technische Schlüssel, der das Berechtigungsmodul für diesen Menüpunkt identifiziert.',
   '🔑', '#menu-item-module-key', 'Module Key', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 4, 'Anzeigename',
   'Der Text, der im Menü angezeigt wird.',
   '📝', '#menu-item-display-name', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 5, 'Route',
   'Die URL-Route, zu der navigiert wird (z.B. "/admin/user/users"). Leer lassen für Gruppen-Header.',
   '🔗', '#menu-item-href', 'Route', 'bottom'),
  ('50000000-0000-0000-0005-000000000002', 6, 'Icon',
   'Der Name des Lucide-Icons (z.B. "Users", "Key", "LayoutDashboard").',
   '🎨', '#menu-item-icon', 'Icon', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 16. admin.tour.tours.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0004-000000000003', 'admin.tour.tours.create', 'Tour erstellen',
   'Anleitung zum Erstellen einer neuen Tour', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0004-000000000003', 1, 'Neue Tour',
   'Erstellen Sie eine neue interaktive Tour für ein Formular oder eine Seite.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 2, 'Formular',
   'Wählen Sie das Formular, für das die Tour erstellt werden soll. Jedes Formular kann nur eine Tour haben.',
   '📋', '#create-tour-formid', 'Formular', 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 3, 'Tour-Name',
   'Geben Sie einen aussagekräftigen Namen für die Tour ein.',
   '📝', '#create-tour-name', 'Name', 'bottom'),
  ('50000000-0000-0000-0004-000000000003', 4, 'Beschreibung',
   'Optional: Beschreiben Sie, was der Benutzer in dieser Tour lernen wird.',
   '📄', '#create-tour-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 17. admin.tour.steps.create
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0004-000000000005', 'admin.tour.steps.create', 'Tour-Schritt erstellen',
   'Anleitung zum Erstellen eines neuen Tour-Schritts', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0004-000000000005', 1, 'Neuer Schritt',
   'Erstellen Sie einen neuen Schritt für eine bestehende Tour.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 2, 'Titel',
   'Der Titel wird als Überschrift im Tour-Tooltip angezeigt.',
   '📝', '#step-title', 'Titel', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 3, 'Inhalt',
   'Der Haupttext des Schritts. Erklären Sie dem Benutzer, was dieses Element tut.',
   '📄', '#step-content', 'Inhalt', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 4, 'Feld-Selektor',
   'Der CSS-Selektor des Elements, auf das der Tooltip zeigen soll (z.B. "#btn-add-user"). Leer lassen für zentrierte Anzeige.',
   '🎯', '#step-field-selector', 'Feld-Selektor', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 5, 'Feld-Label',
   'Ein menschenlesbarer Name für das Ziel-Element (z.B. "Speichern-Button").',
   '🏷️', '#step-field-label', 'Feld-Label', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 6, 'Position',
   'Wählen Sie, wo der Tooltip relativ zum Element erscheinen soll (oben, unten, links, rechts).',
   '📍', '#step-position', 'Position', 'bottom'),
  ('50000000-0000-0000-0004-000000000005', 7, 'Reihenfolge',
   'Die Schrittnummer bestimmt die Reihenfolge innerhalb der Tour.',
   '🔢', '#step-order', 'Reihenfolge', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;


-- ============================================================================
-- MODAL EDIT TOURS (6) - Form field tours inside edit modals
-- ============================================================================

-- 18. admin.permissions.groups.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000015', 'admin.permissions.groups.edit', 'Gruppe bearbeiten',
   'Anleitung zum Bearbeiten einer Gruppe', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000015', 1, 'Gruppe bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieser Gruppe.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 2, 'Schlüssel',
   'Der technische Schlüssel der Gruppe. Änderungen können Auswirkungen auf bestehende Zuweisungen haben.',
   '🔑', '#edit-group-key', 'Schlüssel', 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 3, 'Anzeigename',
   'Ändern Sie den Anzeigenamen der Gruppe.',
   '📝', '#edit-group-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000015', 4, 'Beschreibung',
   'Aktualisieren Sie die Beschreibung der Gruppe.',
   '📄', '#edit-group-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 19. admin.permissions.modules.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0002-000000000016', 'admin.permissions.modules.edit', 'Modul bearbeiten',
   'Anleitung zum Bearbeiten eines Moduls', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0002-000000000016', 1, 'Modul bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieses Moduls.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 2, 'Modul-Key',
   'Der technische Schlüssel des Moduls. Vorsicht: Änderungen können bestehende Berechtigungen beeinflussen.',
   '🔑', '#edit-module-key', 'Modul-Key', 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 3, 'Anzeigename',
   'Ändern Sie den Anzeigenamen des Moduls.',
   '📝', '#edit-module-displayname', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0002-000000000016', 4, 'Beschreibung',
   'Aktualisieren Sie die Beschreibung des Moduls.',
   '📄', '#edit-module-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 20. admin.shell.menu.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0005-000000000003', 'admin.shell.menu.edit', 'Menu-Eintrag bearbeiten',
   'Anleitung zum Bearbeiten eines Menü-Eintrags', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0005-000000000003', 1, 'Eintrag bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieses Menü-Eintrags.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 2, 'Parent',
   'Ändern Sie das übergeordnete Element, um den Eintrag in der Hierarchie zu verschieben.',
   '📂', '#menu-item-parent', 'Parent', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 3, 'Module Key',
   'Der Berechtigungs-Modulschlüssel für diesen Menüpunkt.',
   '🔑', '#menu-item-module-key', 'Module Key', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 4, 'Anzeigename',
   'Ändern Sie den im Menü angezeigten Text.',
   '📝', '#menu-item-display-name', 'Anzeigename', 'bottom'),
  ('50000000-0000-0000-0005-000000000003', 5, 'Route',
   'Aktualisieren Sie die Ziel-URL des Menüpunkts.',
   '🔗', '#menu-item-href', 'Route', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 21. admin.tour.tours.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0004-000000000004', 'admin.tour.tours.edit', 'Tour bearbeiten',
   'Anleitung zum Bearbeiten einer Tour', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0004-000000000004', 1, 'Tour bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieser Tour.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000004', 2, 'Tour-Name',
   'Ändern Sie den Namen der Tour.',
   '📝', '#edit-tour-name', 'Name', 'bottom'),
  ('50000000-0000-0000-0004-000000000004', 3, 'Beschreibung',
   'Aktualisieren Sie die Beschreibung der Tour.',
   '📄', '#edit-tour-description', 'Beschreibung', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 22. admin.tour.steps.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0004-000000000006', 'admin.tour.steps.edit', 'Tour-Schritt bearbeiten',
   'Anleitung zum Bearbeiten eines Tour-Schritts', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0004-000000000006', 1, 'Schritt bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieses Tour-Schritts.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 2, 'Titel',
   'Ändern Sie den Titel des Schritts.',
   '📝', '#step-title', 'Titel', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 3, 'Inhalt',
   'Aktualisieren Sie den Erklärungstext des Schritts.',
   '📄', '#step-content', 'Inhalt', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 4, 'Feld-Selektor',
   'Ändern Sie den CSS-Selektor des Ziel-Elements.',
   '🎯', '#step-field-selector', 'Feld-Selektor', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 5, 'Position',
   'Ändern Sie die Position des Tooltips relativ zum Element.',
   '📍', '#step-position', 'Position', 'bottom'),
  ('50000000-0000-0000-0004-000000000006', 6, 'Reihenfolge',
   'Passen Sie die Reihenfolge des Schritts in der Tour an.',
   '🔢', '#step-order', 'Reihenfolge', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;

-- 23. admin.user.users.edit
INSERT INTO tours (id, form_id, name, description, is_active, validation_status) VALUES
  ('50000000-0000-0000-0001-000000000003', 'admin.user.users.edit', 'Benutzer bearbeiten',
   'Anleitung zum Bearbeiten eines Benutzers', true, 'valid')
ON CONFLICT (form_id) DO NOTHING;

INSERT INTO tour_steps (tour_id, step_order, title, content, icon, field_selector, field_label, side) VALUES
  ('50000000-0000-0000-0001-000000000003', 1, 'Benutzer bearbeiten',
   'Bearbeiten Sie die Eigenschaften dieses Benutzers.',
   '👋', NULL, NULL, 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 2, 'Name',
   'Ändern Sie den Anzeigenamen des Benutzers.',
   '📝', 'input[name="name"]', 'Name', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 3, 'E-Mail',
   'Ändern Sie die E-Mail-Adresse. Diese dient gleichzeitig als Login-Name.',
   '📧', 'input[name="email"]', 'E-Mail', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 4, 'Passwort',
   'Setzen Sie ein neues Passwort. Leer lassen, um das bestehende Passwort beizubehalten.',
   '🔐', 'input[name="password"]', 'Passwort', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 5, 'Rolle',
   'Ändern Sie die Rolle des Benutzers (z.B. Admin, User).',
   '👤', 'select[name="role"]', 'Rolle', 'bottom'),
  ('50000000-0000-0000-0001-000000000003', 6, 'Status',
   'Aktivieren oder deaktivieren Sie den Benutzer. Deaktivierte Benutzer können sich nicht anmelden.',
   '✅', 'select[name="isActive"]', 'Status', 'bottom')
ON CONFLICT (tour_id, step_order) DO NOTHING;


-- ============================================================================
-- Set all new tours as valid
-- ============================================================================
UPDATE tours
SET validation_status = 'valid',
    validation_message = NULL,
    last_validated_at = NOW()
WHERE id IN (
  '50000000-0000-0000-0001-000000000003',
  '50000000-0000-0000-0001-000000000010',
  '50000000-0000-0000-0002-000000000005',
  '50000000-0000-0000-0002-000000000006',
  '50000000-0000-0000-0002-000000000007',
  '50000000-0000-0000-0002-000000000008',
  '50000000-0000-0000-0002-000000000009',
  '50000000-0000-0000-0002-000000000010',
  '50000000-0000-0000-0002-000000000011',
  '50000000-0000-0000-0002-000000000012',
  '50000000-0000-0000-0002-000000000013',
  '50000000-0000-0000-0002-000000000014',
  '50000000-0000-0000-0002-000000000015',
  '50000000-0000-0000-0002-000000000016',
  '50000000-0000-0000-0003-000000000010',
  '50000000-0000-0000-0004-000000000003',
  '50000000-0000-0000-0004-000000000004',
  '50000000-0000-0000-0004-000000000005',
  '50000000-0000-0000-0004-000000000006',
  '50000000-0000-0000-0004-000000000010',
  '50000000-0000-0000-0005-000000000001',
  '50000000-0000-0000-0005-000000000002',
  '50000000-0000-0000-0005-000000000003'
);

COMMIT;
