import fs from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { btree_gist } from '@electric-sql/pglite/contrib/btree_gist';
const root=process.argv[2] ?? new URL('../',import.meta.url).pathname.replace(/\/$/,'');
const db=new PGlite({extensions:{btree_gist}});
const results=[];
async function test(name,fn){try{await fn();results.push({name,status:'passed'});}catch(e){results.push({name,status:'failed',error:e.message});}}
function assert(v,msg){if(!v)throw Error(msg);}
async function expectError(sql,code){try{await db.exec(sql);}catch(e){assert(e.code===code,'Expected '+code+', got '+e.code);return;}throw Error('Expected rejection');}
await test('DDL PostgreSQL complet exécuté',async()=>await db.exec(fs.readFileSync(root+'/schema/schema-reference.sql','utf8')));
if(results[0].status==='failed'){console.log(results);await db.close();process.exit(1);}
const tableCount=Object.keys(JSON.parse(fs.readFileSync(root+'/schema/modele.json','utf8'))).length;
await test(tableCount+' tables présentes',async()=>assert((await db.query("SELECT count(*)::int n FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")).rows[0].n===tableCount,'Wrong count'));
const A='00000000-0000-4000-8000-000000000001',B='00000000-0000-4000-8000-000000000002';
const CA='10000000-0000-4000-8000-000000000001',CB='10000000-0000-4000-8000-000000000002';
await db.exec(`INSERT INTO tenants(id,name,currency,pricing_policy,ai_monthly_budget,state) VALUES ('${A}','A','EUR','{}',20,'ACTIF'),('${B}','B','EUR','{}',20,'ACTIF'); INSERT INTO clients(tenant_id,id,name,details) VALUES ('${A}','${CA}','CA','{}'),('${B}','${CB}','CB','{}');`);
await test('FK composite refuse référence client entre tenants',async()=>await expectError(`INSERT INTO requirements(tenant_id,client_id,title,current_revision) VALUES ('${A}','${CB}','bad',1)`, '23503'));
await test('Devise autre que EUR refusée dans hypothèse MVP',async()=>await expectError("INSERT INTO tenants(name,currency,pricing_policy,ai_monthly_budget,state) VALUES ('C','USD','{}',20,'ACTIF')",'23514'));
await test('Budget supérieur plafond refusé',async()=>await expectError(`INSERT INTO ai_budget_periods(tenant_id,period,limit_eur,reserved_eur,consumed_eur) VALUES ('${A}','2026-10',20,15,10)`,'23514'));
await db.exec('CREATE ROLE app_probe NOSUPERUSER NOBYPASSRLS; GRANT SELECT,INSERT ON clients TO app_probe;');
await test('RLS : sans contexte aucun client visible',async()=>{await db.exec('SET ROLE app_probe');assert((await db.query('SELECT * FROM clients')).rows.length===0,'leak');await db.exec('RESET ROLE');});
await test('RLS : contexte A ne voit que A',async()=>{await db.exec(`BEGIN; SET ROLE app_probe; SELECT set_config('app.tenant_id','${A}',true);`);const rows=(await db.query('SELECT * FROM clients')).rows;assert(rows.length===1&&rows[0].tenant_id===A,'leak');await db.exec('COMMIT; RESET ROLE;');});
await test('RLS : écriture B depuis contexte A refusée',async()=>{await db.exec(`BEGIN; SET ROLE app_probe; SELECT set_config('app.tenant_id','${A}',true);`);await expectError(`INSERT INTO clients(tenant_id,name,details) VALUES ('${B}','bad','{}')`,'42501');await db.exec('ROLLBACK; RESET ROLE;');});
await test('Contexte SET LOCAL ne survit pas à transaction',async()=>{await db.exec('SET ROLE app_probe');assert((await db.query('SELECT * FROM clients')).rows.length===0,'context leak');await db.exec('RESET ROLE');});
await test('Extension et contrainte planning exécutées',async()=>await db.exec(fs.readFileSync(root+'/schema/planning-exclusion.sql','utf8')));
const person='20000000-0000-4000-8000-000000000001';
await db.exec(`INSERT INTO accounts(id,email,password_hash,state,auth_epoch) VALUES ('${person}','probe@example.test','hash','ACTIF',1); INSERT INTO calendar_reservations(tenant_id,account_id,period,kind,active) VALUES ('${A}','${person}','[2026-10-02 08:00+00,2026-10-02 10:00+00)','AFFECTATION',true);`);
await test('Conflit planning inter-entreprises refusé',async()=>await expectError(`INSERT INTO calendar_reservations(tenant_id,account_id,period,kind,active) VALUES ('${B}','${person}','[2026-10-02 09:00+00,2026-10-02 11:00+00)','AFFECTATION',true)`,'23P01'));
await test('Planning adjacent sans chevauchement accepté',async()=>await db.exec(`INSERT INTO calendar_reservations(tenant_id,account_id,period,kind,active) VALUES ('${B}','${person}','[2026-10-02 10:00+00,2026-10-02 12:00+00)','AFFECTATION',true)`));
await test('Intervalle fermé en fin refusé',async()=>await expectError(`INSERT INTO calendar_reservations(tenant_id,account_id,period,kind,active) VALUES ('${A}','${person}','[2026-10-03 08:00+00,2026-10-03 10:00+00]','AFFECTATION',true)`,'23514'));
const req='30000000-0000-4000-8000-000000000001', rev='30000000-0000-4000-8000-000000000002', quote='40000000-0000-4000-8000-000000000001',v1='40000000-0000-4000-8000-000000000002',v2='40000000-0000-4000-8000-000000000003';
await db.exec(`INSERT INTO requirements(tenant_id,id,client_id,title,current_revision) VALUES ('${A}','${req}','${CA}','fixture',1);
 INSERT INTO requirement_revisions(tenant_id,id,requirement_id,number,payload,hash,created_by) VALUES ('${A}','${rev}','${req}',1,'{}','hash','${person}');
 INSERT INTO quotes(tenant_id,id,requirement_id,reference) VALUES ('${A}','${quote}','${req}','DEV-TEST');
 INSERT INTO quote_versions(tenant_id,id,quote_id,requirement_revision_id,number,edit_revision,state,currency,pricing_snapshot,total_ht,total_tax,total_ttc,content_hash,valid_until) VALUES
 ('${A}','${v1}','${quote}','${rev}',1,1,'ACCEPTE','EUR','{}',100,20,120,'hash','2026-11-01'),
 ('${A}','${v2}','${quote}','${rev}',2,1,'ENVOYE','EUR','{}',100,20,120,'hash','2026-11-01');`);
await test('Index interdit deux versions acceptées d’un même devis',async()=>await expectError(`UPDATE quote_versions SET state='ACCEPTE' WHERE tenant_id='${A}' AND id='${v2}'`,'23505'));
await test('TTC incohérent refusé',async()=>await expectError(`UPDATE quote_versions SET total_ttc=999 WHERE tenant_id='${A}' AND id='${v2}'`,'23514'));
await test('Pointeur version accepté pour son agrégat',async()=>await db.exec(`UPDATE quotes SET accepted_version_id='${v1}' WHERE tenant_id='${A}' AND id='${quote}'`));
const other='40000000-0000-4000-8000-000000000004';
await db.exec(`INSERT INTO quotes(tenant_id,id,requirement_id,reference) VALUES ('${A}','${other}','${req}','DEV-OTHER')`);
await test('Pointeur refusé vers version d’un autre devis du même tenant',async()=>await expectError(`UPDATE quotes SET accepted_version_id='${v1}' WHERE tenant_id='${A}' AND id='${other}'`,'23503'));
fs.writeFileSync(root+'/verification/sql-checks.json',JSON.stringify({runtime:'PGlite 0.3.14, PostgreSQL WASM, pas production',results},null,2));
console.log(JSON.stringify(results));
await db.close();
process.exit(results.some(x=>x.status==='failed')?1:0);
