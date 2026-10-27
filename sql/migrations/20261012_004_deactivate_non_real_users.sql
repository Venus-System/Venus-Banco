-- Venus — desativar usuários seed/teste — 2026-10-12
--
-- Preserva os registros e todo o histórico; somente troca o status para
-- inactive. O filtro usa marcadores inequívocos de carga artificial.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path TO venus, public;

UPDATE venus.users
   SET status = 'inactive',
       updated_at = NOW()
 WHERE status = 'active'
   AND (
       firebase_uid LIKE 'venus-seed-user-%'
       OR firebase_uid LIKE 'legacy-%'
       OR LOWER(COALESCE(name, '')) LIKE '%teste%'
       OR LOWER(COALESCE(email, '')) LIKE '%@exemplo.%'
   );

COMMIT;
