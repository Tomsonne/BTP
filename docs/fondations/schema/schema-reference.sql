-- Schéma de référence, non migration de production. Voir documents/04-architecture.md.

BEGIN;

CREATE TABLE accounts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL,
  password_hash text NOT NULL,
  state text NOT NULL CHECK (state IN ('ACTIF','DESACTIVE')),
  auth_epoch integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (email)
);

CREATE TABLE sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL,
  token_hash text NOT NULL,
  account_auth_epoch integer NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (token_hash)
);

CREATE TABLE tenants (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  currency text NOT NULL,
  pricing_policy jsonb NOT NULL,
  ai_monthly_budget numeric(18,2) NOT NULL,
  state text NOT NULL CHECK (state IN ('ACTIF','SUSPENDU','ARCHIVE')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CHECK (currency = 'EUR'),
  CHECK (ai_monthly_budget >= 0)
);

CREATE TABLE units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL,
  dimension text NOT NULL,
  factor_to_base numeric(18,6) NOT NULL CHECK (factor_to_base > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (code)
);

CREATE TABLE knowledge_releases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  version text NOT NULL,
  state text NOT NULL CHECK (state IN ('CANDIDATE','APPROUVEE','PUBLIEE','RETIREE')),
  manifest jsonb NOT NULL,
  hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (version)
);

CREATE TABLE memberships (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL,
  state text NOT NULL CHECK (state IN ('ACTIF','REVOQUE')),
  auth_epoch integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, account_id)
);

CREATE TABLE membership_roles (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  membership_id uuid NOT NULL,
  role text NOT NULL CHECK (role IN ('AE','DV','CH','EM')),
  permissions jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, membership_id, role)
);

CREATE TABLE invitations (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL,
  token_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  roles jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, token_hash)
);

CREATE TABLE clients (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  details jsonb NOT NULL,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE client_contacts (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL,
  email text NOT NULL,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE files (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  object_key text NOT NULL,
  mime_type text NOT NULL,
  bytes bigint NOT NULL CHECK (bytes >= 0),
  sha256 text NOT NULL,
  state text NOT NULL CHECK (state IN ('QUARANTAINE','DISPONIBLE','REJETE','PURGE')),
  uploaded_by uuid NOT NULL,
  purge_after timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, object_key)
);

CREATE TABLE catalog_imports (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  file_id uuid NOT NULL,
  state text NOT NULL CHECK (state IN ('EN_ATTENTE','A_CORRIGER','PRET','CONFIRME','ECHEC')),
  mapping jsonb NOT NULL,
  report jsonb NOT NULL,
  preview_hash text NOT NULL,
  base_revision integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE catalog_revisions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  number integer NOT NULL CHECK (number > 0),
  import_id uuid,
  hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, number)
);

CREATE TABLE resources (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reference text NOT NULL,
  name text NOT NULL,
  kind text NOT NULL CHECK (kind IN ('MATERIAU','MAIN_OEUVRE','EQUIPEMENT','FRAIS')),
  unit_id uuid NOT NULL,
  pack_size numeric(18,6) CHECK (pack_size > 0),
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, reference)
);

CREATE TABLE resource_prices (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  resource_id uuid NOT NULL,
  catalog_revision_id uuid NOT NULL,
  purchase_unit_price numeric(18,6) NOT NULL CHECK (purchase_unit_price >= 0),
  currency text NOT NULL,
  source jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, resource_id, catalog_revision_id),
  CHECK (currency = 'EUR')
);

CREATE TABLE works (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reference text NOT NULL,
  trade text NOT NULL,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, reference)
);

CREATE TABLE work_revisions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  work_id uuid NOT NULL,
  number integer NOT NULL CHECK (number > 0),
  unit_id uuid NOT NULL,
  conditions jsonb NOT NULL,
  hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, work_id, number)
);

CREATE TABLE work_components (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  work_revision_id uuid NOT NULL,
  resource_id uuid NOT NULL,
  quantity_per_unit numeric(18,6) NOT NULL CHECK (quantity_per_unit > 0),
  loss_rate numeric(9,6) NOT NULL CHECK (loss_rate >= 0 AND loss_rate < 1),
  basis jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE requirements (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL,
  title text NOT NULL,
  current_revision integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE requirement_revisions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requirement_id uuid NOT NULL,
  number integer NOT NULL CHECK (number > 0),
  payload jsonb NOT NULL,
  hash text NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, requirement_id, number)
);

CREATE TABLE requirement_files (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requirement_revision_id uuid NOT NULL,
  file_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, requirement_revision_id, file_id)
);

CREATE TABLE quotes (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requirement_id uuid NOT NULL,
  reference text NOT NULL,
  draft_version_id uuid,
  active_offer_version_id uuid,
  accepted_version_id uuid,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, reference)
);

CREATE TABLE quote_versions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_id uuid NOT NULL,
  requirement_revision_id uuid NOT NULL,
  number integer NOT NULL CHECK (number > 0),
  edit_revision integer NOT NULL CHECK (edit_revision > 0),
  state text NOT NULL CHECK (state IN ('BROUILLON','EN_REVUE','VALIDE','ENVOYE','ACCEPTE','REFUSE','EXPIRE','REMPLACE','ABANDONNE')),
  currency text NOT NULL,
  pricing_snapshot jsonb NOT NULL,
  total_ht numeric(18,2) NOT NULL,
  total_tax numeric(18,2) NOT NULL,
  total_ttc numeric(18,2) NOT NULL,
  content_hash text NOT NULL,
  valid_until timestamptz NOT NULL,
  frozen_at timestamptz,
  validated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, quote_id, number),
  UNIQUE (tenant_id, quote_id, id),
  CHECK (currency = 'EUR'),
  CHECK (total_ttc = total_ht + total_tax)
);

CREATE TABLE quote_lines (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_version_id uuid NOT NULL,
  position integer NOT NULL CHECK (position > 0),
  work_revision_id uuid,
  label text NOT NULL,
  unit_id uuid NOT NULL,
  quantity numeric(18,6) NOT NULL CHECK (quantity > 0),
  sale_unit_price numeric(18,6) NOT NULL CHECK (sale_unit_price >= 0),
  cost_unit numeric(18,6) NOT NULL CHECK (cost_unit >= 0),
  tax_rate numeric(9,6) NOT NULL CHECK (tax_rate >= 0 AND tax_rate < 1),
  amount_ht numeric(18,2) NOT NULL,
  origin text NOT NULL CHECK (origin IN ('EXPLICITE','ESTIMEE','MANUELLE')),
  confirmed boolean NOT NULL,
  provenance jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, quote_version_id, position)
);

CREATE TABLE line_components (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_line_id uuid NOT NULL,
  resource_price_id uuid,
  label text NOT NULL,
  unit_id uuid NOT NULL,
  quantity numeric(18,6) NOT NULL CHECK (quantity >= 0),
  purchase_unit_snapshot numeric(18,6) NOT NULL CHECK (purchase_unit_snapshot >= 0),
  facturable boolean NOT NULL CHECK (facturable = false),
  allocation jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE quote_decisions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_version_id uuid NOT NULL,
  decision text NOT NULL CHECK (decision IN ('ACCEPTE','REFUSE')),
  recorded_by uuid NOT NULL,
  proof_file_id uuid,
  proof jsonb NOT NULL,
  decided_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, quote_version_id)
);

CREATE TABLE generation_jobs (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_id uuid NOT NULL,
  requirement_revision_id uuid NOT NULL,
  base_version_id uuid,
  base_edit_revision integer NOT NULL,
  catalog_revision_id uuid NOT NULL,
  knowledge_release_id uuid NOT NULL,
  input_snapshot jsonb NOT NULL,
  input_hash text NOT NULL,
  state text NOT NULL CHECK (state IN ('EN_ATTENTE','EN_COURS','A_REPRENDRE','REUSSI','OBSOLETE','ECHEC','ANNULE')),
  attempts integer NOT NULL CHECK (attempts >= 0 AND attempts <= 3),
  lease_token bigint NOT NULL,
  lease_until timestamptz,
  next_run_at timestamptz NOT NULL,
  result jsonb NOT NULL,
  requested_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE idempotency_keys (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL,
  operation text NOT NULL,
  key text NOT NULL,
  request_hash text NOT NULL,
  response jsonb NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, account_id, operation, key)
);

CREATE TABLE ai_budget_periods (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  period text NOT NULL,
  limit_eur numeric(18,2) NOT NULL,
  reserved_eur numeric(18,2) NOT NULL,
  consumed_eur numeric(18,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, period),
  CHECK (limit_eur >= 0 AND reserved_eur >= 0 AND consumed_eur >= 0),
  CHECK (reserved_eur + consumed_eur <= limit_eur)
);

CREATE TABLE ai_usage (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL,
  attempt integer NOT NULL CHECK (attempt > 0),
  provider_request_id text,
  model text NOT NULL,
  input_tokens integer NOT NULL CHECK (input_tokens >= 0),
  output_tokens integer NOT NULL CHECK (output_tokens >= 0),
  cost_eur numeric(18,2) NOT NULL,
  cost_state text NOT NULL CHECK (cost_state IN ('MESURE','ESTIME','INCONNU')),
  tariff_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, job_id, attempt)
);

CREATE TABLE sites (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_id uuid NOT NULL,
  reference_quote_version_id uuid NOT NULL,
  client_id uuid NOT NULL,
  state text NOT NULL CHECK (state IN ('PREPARATION','EN_COURS','SUSPENDU','A_RECEVOIR','RESERVES','RECEPTIONNE','CLOTURE','ANNULE')),
  baseline_revision integer NOT NULL CHECK (baseline_revision > 0),
  contract_total_ht numeric(18,2) NOT NULL,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, quote_id)
);

CREATE TABLE site_access (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  account_id uuid NOT NULL,
  contact_id uuid,
  state text NOT NULL CHECK (state IN ('ACTIF','REVOQUE')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, site_id, account_id)
);

CREATE TABLE site_stages (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  name text NOT NULL,
  weight numeric(18,6) NOT NULL CHECK (weight > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE site_tasks (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  stage_id uuid NOT NULL,
  description text NOT NULL,
  progress numeric(18,6) NOT NULL CHECK (progress >= 0 AND progress <= 1),
  weight numeric(18,6) NOT NULL CHECK (weight > 0),
  assigned_membership_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE site_media (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  file_id uuid NOT NULL,
  created_by uuid NOT NULL,
  visibility text NOT NULL CHECK (visibility IN ('INTERNE','CLIENT')),
  taken_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE site_messages (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  author_id uuid NOT NULL,
  body text NOT NULL,
  visibility text NOT NULL CHECK (visibility IN ('INTERNE','CLIENT')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE scope_changes (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  reference text NOT NULL,
  state text NOT NULL CHECK (state IN ('SUGGERE','CONFIRME','REJETE','COUVERT')),
  delta_quantity numeric(18,6) NOT NULL,
  unit_id uuid NOT NULL,
  evidence jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, site_id, reference)
);

CREATE TABLE amendments (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  scope_change_id uuid NOT NULL,
  reference_quote_version_id uuid NOT NULL,
  reference text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, scope_change_id),
  UNIQUE (tenant_id, site_id, reference)
);

CREATE TABLE amendment_versions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  amendment_id uuid NOT NULL,
  number integer NOT NULL CHECK (number > 0),
  edit_revision integer NOT NULL,
  baseline_revision integer NOT NULL,
  state text NOT NULL CHECK (state IN ('BROUILLON','EN_REVUE','VALIDE','ENVOYE','ACCEPTE','REFUSE','EXPIRE','REMPLACE','ABANDONNE')),
  pricing_snapshot jsonb NOT NULL,
  delta_ht numeric(18,2) NOT NULL,
  delta_tax numeric(18,2) NOT NULL,
  delta_ttc numeric(18,2) NOT NULL,
  content_hash text NOT NULL,
  valid_until timestamptz NOT NULL,
  frozen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, amendment_id, number),
  CHECK (delta_ttc = delta_ht + delta_tax)
);

CREATE TABLE amendment_lines (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  amendment_version_id uuid NOT NULL,
  position integer NOT NULL,
  label text NOT NULL,
  unit_id uuid NOT NULL,
  delta_quantity numeric(18,6) NOT NULL,
  sale_unit_price numeric(18,6) NOT NULL CHECK (sale_unit_price >= 0),
  tax_rate numeric(9,6) NOT NULL CHECK (tax_rate >= 0 AND tax_rate < 1),
  amount_ht numeric(18,2) NOT NULL,
  provenance jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, amendment_version_id, position)
);

CREATE TABLE amendment_decisions (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  amendment_version_id uuid NOT NULL,
  decision text NOT NULL CHECK (decision IN ('ACCEPTE','REFUSE')),
  recorded_by uuid NOT NULL,
  proof jsonb NOT NULL,
  decided_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, amendment_version_id)
);

CREATE TABLE pdf_documents (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_version_id uuid,
  amendment_version_id uuid,
  file_id uuid NOT NULL,
  content_hash text NOT NULL,
  pdf_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  CHECK (num_nonnulls(quote_version_id, amendment_version_id) = 1)
);

CREATE TABLE deliveries (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quote_version_id uuid,
  amendment_version_id uuid,
  pdf_document_id uuid NOT NULL,
  recipient_email text NOT NULL,
  dedupe_key text NOT NULL,
  state text NOT NULL CHECK (state IN ('EN_ATTENTE','EN_COURS','CONFIRME','ECHEC','INCERTAIN')),
  provider_id text,
  authorized_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, dedupe_key),
  CHECK (num_nonnulls(quote_version_id, amendment_version_id) = 1)
);

CREATE TABLE outbox (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_key text NOT NULL,
  kind text NOT NULL,
  payload jsonb NOT NULL,
  state text NOT NULL CHECK (state IN ('EN_ATTENTE','EN_COURS','CONFIRME','ECHEC','INCERTAIN')),
  attempts integer NOT NULL,
  lease_token bigint NOT NULL,
  lease_until timestamptz,
  next_run_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, event_key)
);

CREATE TABLE audit_events (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  actor_id uuid,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  correlation_id text NOT NULL,
  details jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE feedback (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  job_id uuid,
  comment text NOT NULL,
  sharing text NOT NULL CHECK (sharing IN ('PRIVE','PROPOSE_COMMUN','AUTORISE','REJETE')),
  sharing_authorization jsonb NOT NULL,
  release_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE calendar_reservations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  account_id uuid NOT NULL,
  period tstzrange NOT NULL,
  kind text NOT NULL CHECK (kind IN ('AFFECTATION','ABSENCE')),
  active boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (tenant_id, id),
  CHECK (NOT isempty(period) AND NOT lower_inf(period) AND NOT upper_inf(period) AND lower_inc(period) AND NOT upper_inc(period))
);

CREATE TABLE assignments (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  calendar_reservation_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, calendar_reservation_id)
);

CREATE TABLE leave_requests (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  membership_id uuid NOT NULL,
  period tstzrange NOT NULL,
  state text NOT NULL CHECK (state IN ('DEMANDEE','APPROUVEE','REFUSEE','ANNULEE')),
  calendar_reservation_id uuid,
  approved_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE time_entries (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  started_at timestamptz NOT NULL,
  ended_at timestamptz NOT NULL,
  state text NOT NULL CHECK (state IN ('BROUILLON','SOUMIS','APPROUVE')),
  category text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  CHECK (ended_at > started_at)
);

ALTER TABLE sessions ADD CONSTRAINT fk_sessions_account_id FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_sessions_account_id ON sessions (account_id);

ALTER TABLE memberships ADD CONSTRAINT fk_memberships_account_id FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_memberships_account_id ON memberships (account_id);

ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;

ALTER TABLE memberships FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON memberships USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE membership_roles ADD CONSTRAINT fk_membership_roles_membership_id FOREIGN KEY (tenant_id, membership_id) REFERENCES memberships (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_membership_roles_membership_id ON membership_roles (tenant_id, membership_id);

ALTER TABLE membership_roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE membership_roles FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON membership_roles USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

ALTER TABLE invitations FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON invitations USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

ALTER TABLE clients FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON clients USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE client_contacts ADD CONSTRAINT fk_client_contacts_client_id FOREIGN KEY (tenant_id, client_id) REFERENCES clients (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_client_contacts_client_id ON client_contacts (tenant_id, client_id);

ALTER TABLE client_contacts ENABLE ROW LEVEL SECURITY;

ALTER TABLE client_contacts FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON client_contacts USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE files ADD CONSTRAINT fk_files_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_files_uploaded_by ON files (uploaded_by);

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

ALTER TABLE files FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON files USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE catalog_imports ADD CONSTRAINT fk_catalog_imports_file_id FOREIGN KEY (tenant_id, file_id) REFERENCES files (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_catalog_imports_file_id ON catalog_imports (tenant_id, file_id);

ALTER TABLE catalog_imports ENABLE ROW LEVEL SECURITY;

ALTER TABLE catalog_imports FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON catalog_imports USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE catalog_revisions ADD CONSTRAINT fk_catalog_revisions_import_id FOREIGN KEY (tenant_id, import_id) REFERENCES catalog_imports (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_catalog_revisions_import_id ON catalog_revisions (tenant_id, import_id);

ALTER TABLE catalog_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE catalog_revisions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON catalog_revisions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE resources ADD CONSTRAINT fk_resources_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_resources_unit_id ON resources (unit_id);

ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

ALTER TABLE resources FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON resources USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE resource_prices ADD CONSTRAINT fk_resource_prices_resource_id FOREIGN KEY (tenant_id, resource_id) REFERENCES resources (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_resource_prices_resource_id ON resource_prices (tenant_id, resource_id);

ALTER TABLE resource_prices ADD CONSTRAINT fk_resource_prices_catalog_revision_id FOREIGN KEY (tenant_id, catalog_revision_id) REFERENCES catalog_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_resource_prices_catalog_revision_id ON resource_prices (tenant_id, catalog_revision_id);

ALTER TABLE resource_prices ENABLE ROW LEVEL SECURITY;

ALTER TABLE resource_prices FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON resource_prices USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE works ENABLE ROW LEVEL SECURITY;

ALTER TABLE works FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON works USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE work_revisions ADD CONSTRAINT fk_work_revisions_work_id FOREIGN KEY (tenant_id, work_id) REFERENCES works (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_work_revisions_work_id ON work_revisions (tenant_id, work_id);

ALTER TABLE work_revisions ADD CONSTRAINT fk_work_revisions_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_work_revisions_unit_id ON work_revisions (unit_id);

ALTER TABLE work_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE work_revisions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON work_revisions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE work_components ADD CONSTRAINT fk_work_components_work_revision_id FOREIGN KEY (tenant_id, work_revision_id) REFERENCES work_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_work_components_work_revision_id ON work_components (tenant_id, work_revision_id);

ALTER TABLE work_components ADD CONSTRAINT fk_work_components_resource_id FOREIGN KEY (tenant_id, resource_id) REFERENCES resources (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_work_components_resource_id ON work_components (tenant_id, resource_id);

ALTER TABLE work_components ENABLE ROW LEVEL SECURITY;

ALTER TABLE work_components FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON work_components USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE requirements ADD CONSTRAINT fk_requirements_client_id FOREIGN KEY (tenant_id, client_id) REFERENCES clients (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_requirements_client_id ON requirements (tenant_id, client_id);

ALTER TABLE requirements ENABLE ROW LEVEL SECURITY;

ALTER TABLE requirements FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON requirements USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE requirement_revisions ADD CONSTRAINT fk_requirement_revisions_requirement_id FOREIGN KEY (tenant_id, requirement_id) REFERENCES requirements (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_requirement_revisions_requirement_id ON requirement_revisions (tenant_id, requirement_id);

ALTER TABLE requirement_revisions ADD CONSTRAINT fk_requirement_revisions_created_by FOREIGN KEY (created_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_requirement_revisions_created_by ON requirement_revisions (created_by);

ALTER TABLE requirement_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE requirement_revisions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON requirement_revisions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE requirement_files ADD CONSTRAINT fk_requirement_files_requirement_revision_id FOREIGN KEY (tenant_id, requirement_revision_id) REFERENCES requirement_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_requirement_files_requirement_revision_id ON requirement_files (tenant_id, requirement_revision_id);

ALTER TABLE requirement_files ADD CONSTRAINT fk_requirement_files_file_id FOREIGN KEY (tenant_id, file_id) REFERENCES files (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_requirement_files_file_id ON requirement_files (tenant_id, file_id);

ALTER TABLE requirement_files ENABLE ROW LEVEL SECURITY;

ALTER TABLE requirement_files FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON requirement_files USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE quotes ADD CONSTRAINT fk_quotes_requirement_id FOREIGN KEY (tenant_id, requirement_id) REFERENCES requirements (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quotes_requirement_id ON quotes (tenant_id, requirement_id);

ALTER TABLE quotes ADD CONSTRAINT fk_quotes_draft_version_id FOREIGN KEY (tenant_id, id, draft_version_id) REFERENCES quote_versions (tenant_id, quote_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quotes_draft_version_id ON quotes (tenant_id, id, draft_version_id);

ALTER TABLE quotes ADD CONSTRAINT fk_quotes_active_offer_version_id FOREIGN KEY (tenant_id, id, active_offer_version_id) REFERENCES quote_versions (tenant_id, quote_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quotes_active_offer_version_id ON quotes (tenant_id, id, active_offer_version_id);

ALTER TABLE quotes ADD CONSTRAINT fk_quotes_accepted_version_id FOREIGN KEY (tenant_id, id, accepted_version_id) REFERENCES quote_versions (tenant_id, quote_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quotes_accepted_version_id ON quotes (tenant_id, id, accepted_version_id);

ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

ALTER TABLE quotes FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON quotes USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE quote_versions ADD CONSTRAINT fk_quote_versions_quote_id FOREIGN KEY (tenant_id, quote_id) REFERENCES quotes (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_versions_quote_id ON quote_versions (tenant_id, quote_id);

ALTER TABLE quote_versions ADD CONSTRAINT fk_quote_versions_requirement_revision_id FOREIGN KEY (tenant_id, requirement_revision_id) REFERENCES requirement_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_versions_requirement_revision_id ON quote_versions (tenant_id, requirement_revision_id);

ALTER TABLE quote_versions ADD CONSTRAINT fk_quote_versions_validated_by FOREIGN KEY (validated_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_versions_validated_by ON quote_versions (validated_by);

ALTER TABLE quote_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE quote_versions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON quote_versions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE quote_lines ADD CONSTRAINT fk_quote_lines_quote_version_id FOREIGN KEY (tenant_id, quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_lines_quote_version_id ON quote_lines (tenant_id, quote_version_id);

ALTER TABLE quote_lines ADD CONSTRAINT fk_quote_lines_work_revision_id FOREIGN KEY (tenant_id, work_revision_id) REFERENCES work_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_lines_work_revision_id ON quote_lines (tenant_id, work_revision_id);

ALTER TABLE quote_lines ADD CONSTRAINT fk_quote_lines_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_lines_unit_id ON quote_lines (unit_id);

ALTER TABLE quote_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE quote_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON quote_lines USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE line_components ADD CONSTRAINT fk_line_components_quote_line_id FOREIGN KEY (tenant_id, quote_line_id) REFERENCES quote_lines (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_line_components_quote_line_id ON line_components (tenant_id, quote_line_id);

ALTER TABLE line_components ADD CONSTRAINT fk_line_components_resource_price_id FOREIGN KEY (tenant_id, resource_price_id) REFERENCES resource_prices (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_line_components_resource_price_id ON line_components (tenant_id, resource_price_id);

ALTER TABLE line_components ADD CONSTRAINT fk_line_components_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_line_components_unit_id ON line_components (unit_id);

ALTER TABLE line_components ENABLE ROW LEVEL SECURITY;

ALTER TABLE line_components FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON line_components USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE quote_decisions ADD CONSTRAINT fk_quote_decisions_quote_version_id FOREIGN KEY (tenant_id, quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_decisions_quote_version_id ON quote_decisions (tenant_id, quote_version_id);

ALTER TABLE quote_decisions ADD CONSTRAINT fk_quote_decisions_recorded_by FOREIGN KEY (recorded_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_decisions_recorded_by ON quote_decisions (recorded_by);

ALTER TABLE quote_decisions ADD CONSTRAINT fk_quote_decisions_proof_file_id FOREIGN KEY (tenant_id, proof_file_id) REFERENCES files (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_quote_decisions_proof_file_id ON quote_decisions (tenant_id, proof_file_id);

ALTER TABLE quote_decisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE quote_decisions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON quote_decisions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_quote_id FOREIGN KEY (tenant_id, quote_id) REFERENCES quotes (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_quote_id ON generation_jobs (tenant_id, quote_id);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_requirement_revision_id FOREIGN KEY (tenant_id, requirement_revision_id) REFERENCES requirement_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_requirement_revision_id ON generation_jobs (tenant_id, requirement_revision_id);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_base_version_id FOREIGN KEY (tenant_id, base_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_base_version_id ON generation_jobs (tenant_id, base_version_id);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_catalog_revision_id FOREIGN KEY (tenant_id, catalog_revision_id) REFERENCES catalog_revisions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_catalog_revision_id ON generation_jobs (tenant_id, catalog_revision_id);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_knowledge_release_id FOREIGN KEY (knowledge_release_id) REFERENCES knowledge_releases (id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_knowledge_release_id ON generation_jobs (knowledge_release_id);

ALTER TABLE generation_jobs ADD CONSTRAINT fk_generation_jobs_requested_by FOREIGN KEY (requested_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_generation_jobs_requested_by ON generation_jobs (requested_by);

ALTER TABLE generation_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE generation_jobs FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON generation_jobs USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE idempotency_keys ADD CONSTRAINT fk_idempotency_keys_account_id FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_idempotency_keys_account_id ON idempotency_keys (account_id);

ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;

ALTER TABLE idempotency_keys FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON idempotency_keys USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE ai_budget_periods ENABLE ROW LEVEL SECURITY;

ALTER TABLE ai_budget_periods FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON ai_budget_periods USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE ai_usage ADD CONSTRAINT fk_ai_usage_job_id FOREIGN KEY (tenant_id, job_id) REFERENCES generation_jobs (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_ai_usage_job_id ON ai_usage (tenant_id, job_id);

ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

ALTER TABLE ai_usage FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON ai_usage USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE sites ADD CONSTRAINT fk_sites_quote_id FOREIGN KEY (tenant_id, quote_id) REFERENCES quotes (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_sites_quote_id ON sites (tenant_id, quote_id);

ALTER TABLE sites ADD CONSTRAINT fk_sites_reference_quote_version_id FOREIGN KEY (tenant_id, reference_quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_sites_reference_quote_version_id ON sites (tenant_id, reference_quote_version_id);

ALTER TABLE sites ADD CONSTRAINT fk_sites_client_id FOREIGN KEY (tenant_id, client_id) REFERENCES clients (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_sites_client_id ON sites (tenant_id, client_id);

ALTER TABLE sites ENABLE ROW LEVEL SECURITY;

ALTER TABLE sites FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON sites USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE site_access ADD CONSTRAINT fk_site_access_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_access_site_id ON site_access (tenant_id, site_id);

ALTER TABLE site_access ADD CONSTRAINT fk_site_access_account_id FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_site_access_account_id ON site_access (account_id);

ALTER TABLE site_access ADD CONSTRAINT fk_site_access_contact_id FOREIGN KEY (tenant_id, contact_id) REFERENCES client_contacts (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_access_contact_id ON site_access (tenant_id, contact_id);

ALTER TABLE site_access ENABLE ROW LEVEL SECURITY;

ALTER TABLE site_access FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON site_access USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE site_stages ADD CONSTRAINT fk_site_stages_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_stages_site_id ON site_stages (tenant_id, site_id);

ALTER TABLE site_stages ENABLE ROW LEVEL SECURITY;

ALTER TABLE site_stages FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON site_stages USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE site_tasks ADD CONSTRAINT fk_site_tasks_stage_id FOREIGN KEY (tenant_id, stage_id) REFERENCES site_stages (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_tasks_stage_id ON site_tasks (tenant_id, stage_id);

ALTER TABLE site_tasks ADD CONSTRAINT fk_site_tasks_assigned_membership_id FOREIGN KEY (tenant_id, assigned_membership_id) REFERENCES memberships (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_tasks_assigned_membership_id ON site_tasks (tenant_id, assigned_membership_id);

ALTER TABLE site_tasks ENABLE ROW LEVEL SECURITY;

ALTER TABLE site_tasks FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON site_tasks USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE site_media ADD CONSTRAINT fk_site_media_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_media_site_id ON site_media (tenant_id, site_id);

ALTER TABLE site_media ADD CONSTRAINT fk_site_media_file_id FOREIGN KEY (tenant_id, file_id) REFERENCES files (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_media_file_id ON site_media (tenant_id, file_id);

ALTER TABLE site_media ADD CONSTRAINT fk_site_media_created_by FOREIGN KEY (created_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_site_media_created_by ON site_media (created_by);

ALTER TABLE site_media ENABLE ROW LEVEL SECURITY;

ALTER TABLE site_media FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON site_media USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE site_messages ADD CONSTRAINT fk_site_messages_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_site_messages_site_id ON site_messages (tenant_id, site_id);

ALTER TABLE site_messages ADD CONSTRAINT fk_site_messages_author_id FOREIGN KEY (author_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_site_messages_author_id ON site_messages (author_id);

ALTER TABLE site_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE site_messages FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON site_messages USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE scope_changes ADD CONSTRAINT fk_scope_changes_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_scope_changes_site_id ON scope_changes (tenant_id, site_id);

ALTER TABLE scope_changes ADD CONSTRAINT fk_scope_changes_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_scope_changes_unit_id ON scope_changes (unit_id);

ALTER TABLE scope_changes ENABLE ROW LEVEL SECURITY;

ALTER TABLE scope_changes FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON scope_changes USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE amendments ADD CONSTRAINT fk_amendments_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendments_site_id ON amendments (tenant_id, site_id);

ALTER TABLE amendments ADD CONSTRAINT fk_amendments_scope_change_id FOREIGN KEY (tenant_id, scope_change_id) REFERENCES scope_changes (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendments_scope_change_id ON amendments (tenant_id, scope_change_id);

ALTER TABLE amendments ADD CONSTRAINT fk_amendments_reference_quote_version_id FOREIGN KEY (tenant_id, reference_quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendments_reference_quote_version_id ON amendments (tenant_id, reference_quote_version_id);

ALTER TABLE amendments ENABLE ROW LEVEL SECURITY;

ALTER TABLE amendments FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON amendments USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE amendment_versions ADD CONSTRAINT fk_amendment_versions_amendment_id FOREIGN KEY (tenant_id, amendment_id) REFERENCES amendments (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendment_versions_amendment_id ON amendment_versions (tenant_id, amendment_id);

ALTER TABLE amendment_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE amendment_versions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON amendment_versions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE amendment_lines ADD CONSTRAINT fk_amendment_lines_amendment_version_id FOREIGN KEY (tenant_id, amendment_version_id) REFERENCES amendment_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendment_lines_amendment_version_id ON amendment_lines (tenant_id, amendment_version_id);

ALTER TABLE amendment_lines ADD CONSTRAINT fk_amendment_lines_unit_id FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT;

CREATE INDEX ix_amendment_lines_unit_id ON amendment_lines (unit_id);

ALTER TABLE amendment_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE amendment_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON amendment_lines USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE amendment_decisions ADD CONSTRAINT fk_amendment_decisions_amendment_version_id FOREIGN KEY (tenant_id, amendment_version_id) REFERENCES amendment_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_amendment_decisions_amendment_version_id ON amendment_decisions (tenant_id, amendment_version_id);

ALTER TABLE amendment_decisions ADD CONSTRAINT fk_amendment_decisions_recorded_by FOREIGN KEY (recorded_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_amendment_decisions_recorded_by ON amendment_decisions (recorded_by);

ALTER TABLE amendment_decisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE amendment_decisions FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON amendment_decisions USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE pdf_documents ADD CONSTRAINT fk_pdf_documents_quote_version_id FOREIGN KEY (tenant_id, quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_pdf_documents_quote_version_id ON pdf_documents (tenant_id, quote_version_id);

ALTER TABLE pdf_documents ADD CONSTRAINT fk_pdf_documents_amendment_version_id FOREIGN KEY (tenant_id, amendment_version_id) REFERENCES amendment_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_pdf_documents_amendment_version_id ON pdf_documents (tenant_id, amendment_version_id);

ALTER TABLE pdf_documents ADD CONSTRAINT fk_pdf_documents_file_id FOREIGN KEY (tenant_id, file_id) REFERENCES files (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_pdf_documents_file_id ON pdf_documents (tenant_id, file_id);

ALTER TABLE pdf_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE pdf_documents FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON pdf_documents USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE deliveries ADD CONSTRAINT fk_deliveries_quote_version_id FOREIGN KEY (tenant_id, quote_version_id) REFERENCES quote_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_deliveries_quote_version_id ON deliveries (tenant_id, quote_version_id);

ALTER TABLE deliveries ADD CONSTRAINT fk_deliveries_amendment_version_id FOREIGN KEY (tenant_id, amendment_version_id) REFERENCES amendment_versions (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_deliveries_amendment_version_id ON deliveries (tenant_id, amendment_version_id);

ALTER TABLE deliveries ADD CONSTRAINT fk_deliveries_pdf_document_id FOREIGN KEY (tenant_id, pdf_document_id) REFERENCES pdf_documents (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_deliveries_pdf_document_id ON deliveries (tenant_id, pdf_document_id);

ALTER TABLE deliveries ADD CONSTRAINT fk_deliveries_authorized_by FOREIGN KEY (authorized_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_deliveries_authorized_by ON deliveries (authorized_by);

ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

ALTER TABLE deliveries FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON deliveries USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE outbox ENABLE ROW LEVEL SECURITY;

ALTER TABLE outbox FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON outbox USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE audit_events ADD CONSTRAINT fk_audit_events_actor_id FOREIGN KEY (actor_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_audit_events_actor_id ON audit_events (actor_id);

ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE audit_events FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON audit_events USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE feedback ADD CONSTRAINT fk_feedback_job_id FOREIGN KEY (tenant_id, job_id) REFERENCES generation_jobs (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_feedback_job_id ON feedback (tenant_id, job_id);

ALTER TABLE feedback ADD CONSTRAINT fk_feedback_release_id FOREIGN KEY (release_id) REFERENCES knowledge_releases (id) ON DELETE RESTRICT;

CREATE INDEX ix_feedback_release_id ON feedback (release_id);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

ALTER TABLE feedback FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON feedback USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE calendar_reservations ADD CONSTRAINT fk_calendar_reservations_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE RESTRICT;

CREATE INDEX ix_calendar_reservations_tenant_id ON calendar_reservations (tenant_id);

ALTER TABLE calendar_reservations ADD CONSTRAINT fk_calendar_reservations_account_id FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_calendar_reservations_account_id ON calendar_reservations (account_id);

ALTER TABLE assignments ADD CONSTRAINT fk_assignments_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_assignments_site_id ON assignments (tenant_id, site_id);

ALTER TABLE assignments ADD CONSTRAINT fk_assignments_membership_id FOREIGN KEY (tenant_id, membership_id) REFERENCES memberships (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_assignments_membership_id ON assignments (tenant_id, membership_id);

ALTER TABLE assignments ADD CONSTRAINT fk_assignments_calendar_reservation_id FOREIGN KEY (tenant_id, calendar_reservation_id) REFERENCES calendar_reservations (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_assignments_calendar_reservation_id ON assignments (tenant_id, calendar_reservation_id);

ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

ALTER TABLE assignments FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON assignments USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE leave_requests ADD CONSTRAINT fk_leave_requests_membership_id FOREIGN KEY (tenant_id, membership_id) REFERENCES memberships (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_leave_requests_membership_id ON leave_requests (tenant_id, membership_id);

ALTER TABLE leave_requests ADD CONSTRAINT fk_leave_requests_calendar_reservation_id FOREIGN KEY (tenant_id, calendar_reservation_id) REFERENCES calendar_reservations (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_leave_requests_calendar_reservation_id ON leave_requests (tenant_id, calendar_reservation_id);

ALTER TABLE leave_requests ADD CONSTRAINT fk_leave_requests_approved_by FOREIGN KEY (approved_by) REFERENCES accounts (id) ON DELETE RESTRICT;

CREATE INDEX ix_leave_requests_approved_by ON leave_requests (approved_by);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE leave_requests FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON leave_requests USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE time_entries ADD CONSTRAINT fk_time_entries_site_id FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_time_entries_site_id ON time_entries (tenant_id, site_id);

ALTER TABLE time_entries ADD CONSTRAINT fk_time_entries_membership_id FOREIGN KEY (tenant_id, membership_id) REFERENCES memberships (tenant_id, id) ON DELETE RESTRICT;

CREATE INDEX ix_time_entries_membership_id ON time_entries (tenant_id, membership_id);

ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE time_entries FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_scope ON time_entries USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

CREATE UNIQUE INDEX uq_quote_accepted ON quote_versions(tenant_id,quote_id) WHERE state = 'ACCEPTE';

CREATE UNIQUE INDEX uq_amendment_accepted ON amendment_versions(tenant_id,amendment_id) WHERE state = 'ACCEPTE';

CREATE INDEX ix_generation_ready ON generation_jobs(next_run_at) WHERE state IN ('EN_ATTENTE','A_REPRENDRE');

CREATE INDEX ix_generation_leases ON generation_jobs(lease_until) WHERE state = 'EN_COURS';

CREATE INDEX ix_outbox_ready ON outbox(next_run_at) WHERE state IN ('EN_ATTENTE','ECHEC');

CREATE INDEX ix_pdf_quote ON pdf_documents(tenant_id,quote_version_id);

CREATE INDEX ix_pdf_amendment ON pdf_documents(tenant_id,amendment_version_id);

CREATE INDEX ix_audit_object ON audit_events(tenant_id,entity_type,entity_id,created_at);

CREATE INDEX ix_calendar_account ON calendar_reservations(account_id);

COMMIT;
