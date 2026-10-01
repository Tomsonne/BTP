-- Extension PostgreSQL à valider dans l'hébergement choisi ; rôle migration seulement.
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE calendar_reservations ADD CONSTRAINT no_person_overlap
  EXCLUDE USING gist (account_id WITH =, period WITH &&) WHERE (active);
-- Les comptes multi-entreprises ne reçoivent que « indisponible » depuis le service restreint.
