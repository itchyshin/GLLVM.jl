"""Source-pinned Stage1a obligations; helper bindings never imply fitted parity."""
import argparse, hashlib, json, tomllib
from pathlib import Path
import core070_manifest_coverage as coverage
ROOT=Path(__file__).resolve().parents[1]
PREFIX=coverage.PREFIX
PLAN=PREFIX+'aghq-required-case-plan.json'
SUBSET=PREFIX+'aghq-control-subset.json'
FIXTURE='test/parity/core070_aghq_controls.toml'
STATE=ROOT/'.unlazy/core070-aghq/aghq-case-plan-01'
NATIVE=ROOT/'.unlazy/core070-aghq/aghq-case-plan-02'
def read(path):return json.loads((ROOT/path).read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def need(condition,message):
    if not condition:raise ValueError(message)

# These model/estimator obligations supplement the old helper-only inventory.
# A candidate file is a place to inspect, not a passing receipt.
PUBLIC=[
 ('FIXED-BETA','Ordinary fixed predictors are not excluded by the Stage1a admission chain; qualify their b_fix parameter/random-vector construction separately from predictor-informed scores. Paired models must preserve design/contrasts and coefficient constraints; current Poisson/binomial AGHQ intercept-only routes are a gap, not an exclusion.', '6356-6359',None),
 ('REML-RANDOM-BLOCK','Classify the actual frozen random vector for a Gaussian REML request; if beta joins random, retain the same Laplace/REML target with warning. Do not infer Gaussian-only REML from non-Gaussian engine paths.', '6351-6355',None),
 ('GATE-K5','Retain actual frozen R Hessian-sparsity gate table for ordinary K5; compare treewidth4/quadrature to native eligibility. K<=5 is not by itself a graph proof.', '6362-6365','test/test_aghq_gate.jl'),
 ('GATE-K6','Retain actual frozen R gate table for ordinary K6; verify treewidth5/Laplace and warning. Examine model-zero/sparsity cases before claiming universal dimension equivalence.', '6362-6365','test/test_aghq_gate.jl'),
 ('NOOP-WARNING','Quadrature used with zero parameter movement must retain selected-start/shift information and explicit warning; no improvement claim.', '7024-7036','test/test_aghq_public_poisson.jl'),
 ('FAILED-ADAPTATION','All-unusable starts or failed re-adaptation: preserve the reference-selected valid iterate or explicit Laplace fallback and failure history, never silent success.', '6639-6655','test/test_aghq_multistart.jl'),
 ('FALLBACK-CURVATURE-CONTROL','Specify family-consistent handling of explicit Fisher curvature on an ineligible AGHQ request. Current Gaussian checks before fallback, Poisson/binomial after; record as unresolved interface decision.', '6333-6400',None),
 ('INTEGER-DIALECT','R whole numerics and auto strings map to Julia Integer and :auto. Test 9.0 and string auto rejection explicitly; these are language adapters, not identical accepted input types.', '6330-6333','test/parity/core070_aghq_controls.toml'),
 ('DEFAULT-OFF','Compare omitted aghq and false on the same ordinary model; unchanged objective/parameters and no quadrature metadata.', '1861-1864','test/test_aghq_public_poisson.jl'),
 ('K1-PRECEDENCE','Compare aghq=1 to Laplace on eligible and structurally ineligible models; no ignored-request warning, actual Laplace and one node.', '6336-6386','test/test_aghq_public_gaussian.jl'),
 ('EVEN-K2','An explicit k=2 eligible model executes two nodes per axis; no odd-node restriction; retain fit health and reference comparison.', '6333-6403',None),
 ('UNIQUE-DEFAULT','Ordinary latent default unique adds s_B; requested quadrature retains Laplace with warning and reason. Compare same-model Laplace baseline.', '6351-6395','test/test_aghq_public_gaussian.jl'),
 ('EXTRA-RANDOM-BLOCK','Add an ordinary or phylogenetic random block to loadings-only B; warning, requested vs actual method, unchanged Laplace target.', '6351-6355','test/test_aghq_public_gaussian.jl'),
 ('NO-B-BLOCK','No B-tier loadings block: retain Laplace with explicit reason. Preserve first-failing-branch order when random is not z_B.', '6351-6355',None),
 ('PREDICTOR-LATENTS','Predictor-informed B scores: retain matching Laplace model with warning/provenance.', '6356-6357','test/test_aghq_public_poisson.jl'),
 ('MISSING-PREDICTORS','A supported mi() predictor model: retain matching Laplace model and warning. Missing responses are a different axis.', '6358-6359',None),
 ('MULTINOMIAL','Any family_id 16, including mixed rows, declines Stage1a. Retain the same multinomial model; rejection of an unsupported Julia model is not equivalent fallback.', '6360-6361',None),
 ('GRAPH-NO-QUADRATURE','Present graph gate with no quadrature route declines even explicit nodes; demonstrate a reachable model or document internal branch reachability.', '6362-6365','test/test_aghq_gate.jl'),
 ('AUTO-TRAIT-CUTOFF','Same eligible structure at 19 and 20 traits: auto executes/declines respectively; explicit nodes at 20 bypass only the auto cutoff.', '6366-6377',None),
 ('AUTO-AFFORDABILITY','Auto malformed/absent/empty/unresolved gate declines; explicit numeric bypasses only auto policy. Separate injected helper checks from reachable public models.', '6362-6377','test/test_aghq_gate.jl'),
 ('AUTO-FAMILY-NODES','Verify selected node counts on actual admitted families: k5 ordinary versus k9 Tweedie/ordinal/delta. A family-label helper alone cannot satisfy this case.', '6330-6333',None),
 ('MIXED-FAMILIES','Mixed admitted nonmultinomial rows with one z_B block: same row-specific likelihoods, nuisance grouping, masks and observed curvature; no unsupported homogeneous-only restriction inferred.', '6360-6361',None),
 ('INVALID-CONTROLS','Through native, formula and bridge: invalid controls fail before optimizer; accepted language adapters preserve values and never coerce numeric strings.', '6330-6333','test/test_aghq_public_poisson.jl'),
 ('UNPENALISED','All R fit calls explicitly use aghq_ridge=Inf; native has no loading penalty. Verify objective constants and diagnostics; adaptation eigenvalue repair is separate.', '6407-6413','tools/core070_aghq_poisson_pair_run.jl'),
 ('ADAPTATION-OBSERVED','At fixed parameters compare conditional modes, observed Hessian, Cholesky factors/logdet and normalized objective, not the generic Fisher default.', '9554-9584','test/test_aghq_frozen.jl'),
 ('CURVATURE-REPAIR','Trigger reference eigenvalue floor 1e-8 and record original spectrum and actual repair. PD-only fixtures cannot satisfy; invalid trials must not become certified healthy fits.', '9554-9584','test/test_aghq_frozen.jl'),
 ('GRID-NORMALIZATION','Gaussian mass/moments, nonidentity transformations, low-dimensional independent quadrature and k1/Laplace equality. Check peer-grid substitution convention.', '9520-9543','test/test_aghq_grid.jl'),
 ('NODE-REFINEMENT','Fixed-model increasing k comparisons with predeclared accuracy and health; auto selects one k, not a claimed adaptive ladder.', '6400-6406','tools/core070_aghq_poisson_pair_run.jl'),
 ('OUTER-FROZEN','Differentiate frozen adaptation objective; validate AD/FD with caches fixed and measure omitted total-derivative chain term separately. Never certify total stationarity from frozen-gradient stopping.', '6550-6850','test/test_aghq_outer.jl'),
 ('OUTER-CONVERGENCE','Retain short-pass caps, backtracking merit acceptance, mode-shift/gradient stopping and two accepted passes; stagnation is not convergence.', '6743-6825','test/test_aghq_outer.jl'),
 ('MULTISTART','Retain every start; native ranking must match reference selection. Nonconverged original binomial seed43 k5 remains failed, not replaced by an easier start or k.', '6440-6490','test/test_aghq_multistart.jl'),
 ('POSTFIT-INFERENCE','Final logLik/coef/predictions/modes and frozen-objective Hessian/Wald/profile/bootstrap preserve fitted estimator and data; same-model R comparisons of functional results. Recovery/coverage is a separate validation design, not a source-code assertion.', '6825-6950','test/test_aghq_public_poisson.jl'),
]

def build():
    subset=read(SUBSET)
    fixture=tomllib.loads((ROOT/FIXTURE).read_text())
    facts={r['id']:r for r in subset['cases']}
    paired=[]
    for row in fixture['cases']:
        fact=facts[row['id']]
        paired.append(dict(id='CORE070-'+row['id']+'-PAIRED-CONTROL',source_fact_ids=['aghq/'+row['id']],
            coverage_role='normalization_control',acceptance_level='paired_control',
            fixture=FIXTURE,fixture_sha256=sha(ROOT/FIXTURE),r_call=fact['r_call'],r_assertion=fact['assertion'],
            julia_call=row['julia_call'],expected=row['expected'],owner='Ada/B6',
            acceptance_rule='Frozen R assertion true and native normalization value/error matches; zero fit or interface claim.'))
    by_source={p['source_fact_ids'][0]:p['id'] for p in paired}
    rows=[]
    for fact in subset['cases']:
        sid='aghq/'+fact['id'];excluded=fact['classification']=='intentionally_excluded'
        rows.append(dict(source_id=sid,source_row_sha256=coverage.row_sha(fact),
            classification=fact['classification'],planned_case_ids=[] if excluded else [
                by_source.get(sid,'CORE070-'+fact['id']+'-CONTROL-CONTRACT')],
            executable_case_ids=[],status='EXCLUDED_LOADING_RIDGE' if excluded else
                'PAIRED_CONTROL_BOUND_NOT_PUBLIC_FIT' if sid in by_source else 'CONTROL_MAPPING_REQUIRED',
            remaining_obligation='No loading-ridge programme.' if excluded else
                'Public native/formula/bridge model replay remains separate.' if sid in by_source else
                'Name an exact native policy call or same-model public fit; helper source observation alone is insufficient.'))
    anchor_overrides={
        'FIXED-BETA':[('R/fit-multi.R','4583-4583'),('R/fit-multi.R','5889-5893'),('R/fit-multi.R','6351-6361')],
        'REML-RANDOM-BLOCK':[('R/fit-multi.R','5889-5893'),('R/aghq-gate.R','225-249')],
        'GATE-K5':[('R/aghq-gate.R','185-194'),('R/aghq-gate.R','241-260'),('R/fit-multi.R','6362-6365')],
        'GATE-K6':[('R/aghq-gate.R','185-194'),('R/aghq-gate.R','241-260'),('R/fit-multi.R','6362-6365')],
        'GRAPH-NO-QUADRATURE':[('R/aghq-gate.R','241-260'),('R/fit-multi.R','6362-6365')],
        'AUTO-AFFORDABILITY':[('R/aghq-control.R','311-368'),('R/fit-multi.R','6366-6377')],
        'AUTO-FAMILY-NODES':[('R/aghq-control.R','192-275'),('R/fit-multi.R','6330-6333')],
        'UNPENALISED':[('R/gllvmTMB.R','1861-1864'),('R/fit-multi.R','6419-6419')],
        'NODE-REFINEMENT':[('R/fit-multi.R','6330-6333'),('R/fit-multi.R','6404-6411'),('R/fit-multi.R','6972-6994')],
        'MULTISTART':[('R/fit-multi.R','6440-6490'),('R/fit-multi.R','6906-6945')],
        'POSTFIT-INFERENCE':[('R/fit-multi.R','7041-7090')],
    }
    obligations=[]
    for name,rule,lines,candidate in PUBLIC:
        obligations.append(dict(id='CORE070-AGHQ-PUBLIC-'+name,owner='B6/Gauss',
            acceptance_level='public_model_or_estimator_contract',acceptance_rule=rule,
            reference_sources=[dict(path=path,lines=span) for path,span in anchor_overrides.get(name,[('R/gllvmTMB.R' if name=='DEFAULT-OFF' else 'R/fit-multi.R',lines)])],
            requirement_origin=('approved programme validation' if name in {'UNPENALISED','NODE-REFINEMENT','GRID-NORMALIZATION'} else 'frozen source contract, pending callable-domain qualification'),interfaces=(['numerical_kernel'] if name in {'ADAPTATION-OBSERVED','CURVATURE-REPAIR','GRID-NORMALIZATION','NODE-REFINEMENT','OUTER-FROZEN','OUTER-CONVERGENCE','MULTISTART'} else ['native','formula','public_r_bridge']),
            status='REQUIRED_NOT_CERTIFIED',candidate_fixture=candidate,
            candidate_fixture_sha256=sha(ROOT/candidate) if candidate else None,
            evidence=None,coverage_boundary='Existing helper/internal/native tests do not certify all three public surfaces.'))
    family=read(PREFIX+'family-admission-subset.json')
    families=[]
    for fact in family['cases']:
        if fact['classification']!='required_core':continue
        families.append(dict(id='CORE070-AGHQ-'+fact['id'],family_source_id='family/'+fact['id'],
            reference_descriptor_call=fact['reference_descriptor_call'],
            disposition='required_laplace_fallback' if fact['id']=='FAMILY-16-LOGIT' else 'requires_callable_domain_qualification',
            interfaces=['native','formula','public_r_bridge'],status='NOT_CERTIFIED',
            contract='One ordinary z_B loadings block, unique=false, unpenalized, observed adaptation; same family/link and fixed/free nuisance parameters. No automatic product with other covariance forms.'))
    return dict(schema=1,status='REQUIRED_CASE_ANNEX_NOT_FROZEN',reference_commit=coverage.REFERENCE,
        source_pins={**subset['source_pins'],'R/aghq-gate.R':read('.unlazy/core070-aghq/oracle-source/source.json')['source_files']['R/aghq-gate.R']},source_subset=SUBSET,source_subset_sha256=sha(ROOT/SUBSET),
        family_inventory_sha256=sha(ROOT/PREFIX/'family-admission-subset.json'),
        source_rows=rows,paired_control_cases=paired,public_obligations=obligations,family_obligations=families,
        validation_designs=['Known-DGP recovery with every attempted fit retained, declared estimands and sign/rotation alignment.', 'Coverage must detect under- and over-coverage; size and approve campaigns separately before runs over30min.'],
        remaining_domains='Core covariance/data/postfit and exhaustive source admission review remain separate; this annex cannot freeze the full manifest.')

def validate(data):
    expected=build()
    need(data==expected,'AGHQ annex differs from pinned source/fixture and declared obligations')
    need(len(data['source_rows'])==39 and len(data['paired_control_cases'])==16,'control census mismatch')
    need(all(not row['executable_case_ids'] for row in data['source_rows']),'unverified executable promotion')
    need(len(data['family_obligations'])==21 and len(data['public_obligations'])==32,'public/family axis omission')
    need(all(p['acceptance_level']=='paired_control' and p['r_call'] and p['julia_call'] for p in data['paired_control_cases']),'invalid control binding')
    need(all(p['acceptance_level']=='public_model_or_estimator_contract' and p['evidence'] is None for p in data['public_obligations']),'helper-to-fit promotion')
    for name,pin in data['source_pins'].items():
        need(sha(ROOT/'.unlazy/core070-aghq/oracle-source/readback'/name)==pin,'stale reference source '+name)


def verify_evidence():
    data=read(PLAN);validate(data)
    reference=read('.unlazy/core070-aghq/aghq-case-plan-01/r/receipt.json')
    need(reference['status']=='PASS' and reference['actual_exit']==0 and reference['source_unchanged'],'reference controls failed')
    need(reference['manifest_sha256']==sha(ROOT/SUBSET) and reference['source_pins']==read(SUBSET)['source_pins'],'reference pins differ')
    expected_ids=[r['id'] for r in read(SUBSET)['cases']]
    need(reference['expected_case_ids']==expected_ids,'reference cases omitted')
    need((STATE/'r/raw.log').read_text().splitlines()==[x+'\tPASS' for x in expected_ids],'reference control output differs')
    need(sha(STATE/'r/raw.log')==reference['log_sha256'] and sha(STATE/'r/replay.R')==reference['script_sha256'],'reference artifacts changed')
    process=json.loads((NATIVE/'attempt1/process/process-receipt.json').read_text())
    plan=json.loads((NATIVE/'plan.json').read_text())
    need(process['status']=='PASS' and process['source_unchanged'] and not process['supervisor_error'],'native process failed')
    need(sha(NATIVE/'plan.json')==process['plan_sha256']==sha(NATIVE/'attempt1/process/execution-plan.json'),'stale native plan')
    need(process['source_pins']==plan['pins'] and process['environment_overrides']==plan['env'],'native execution differs')
    need(process['expected_ids']==['normalization'] and len(process['results'])==1,'native process inventory differs')
    need(plan['env']['JULIA_NUM_THREADS']==plan['env']['OPENBLAS_NUM_THREADS']==plan['env']['OMP_NUM_THREADS']=='1','thread settings differ')
    expected_paths={str(p.relative_to(ROOT)) for p in ROOT.glob('src/**/*.jl')}|{'Project.toml','test/parity/Project.toml',FIXTURE,'tools/core070_aghq_controls_run.jl','tools/core070_targeted_run.py','test/parity/Manifest.toml'}
    need(set(plan['pins'])==expected_paths,'missing native dependency pin')
    for name,pin in plan['pins'].items():
        if name=='test/parity/Manifest.toml':
            need(pin==sha(ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'),'runtime dependency pin differs');continue
        need(sha(ROOT/name)==pin,'native source changed '+name)
    result=process['results'][0]
    need(result['id']=='normalization' and result['exit_code']==0 and result['argv']==plan['commands'][0]['argv'] and not result['supervisor_error'],'native exit failed')
    need(sha(NATIVE/'attempt1/process'/result['log'])==result['log_sha256'],'native log changed')
    receipt=tomllib.loads((NATIVE/'attempt1/controls.toml').read_text())
    need(receipt['package_root']==plan['cwd'] and receipt['julia_version']=='1.12.6','wrong loaded runtime/root')
    log=(NATIVE/'attempt1/process'/result['log']).read_text()
    need('CONTROL_RECEIPT_SHA256 '+sha(NATIVE/'attempt1/controls.toml') in log,'native receipt detached from process')
    need(receipt['dialect_checks']=={'whole_float_rejected':True,'auto_string_rejected':True},'unrecorded dialect distinction')
    expected=tomllib.loads((ROOT/FIXTURE).read_text())['cases']
    need(receipt['fixture_sha256']==sha(ROOT/FIXTURE) and receipt['threads']==1,'native fixture/runtime mismatch')
    need([c['id'] for c in receipt['cases']]==[c['id'] for c in expected],'native case omitted')
    need(all(a['pass'] and a['actual']==a['expected']==b['expected'] for a,b in zip(receipt['cases'],expected)),'native assertion failed')
    print('CORE070_AGHQ_CASE_PLAN_VERIFIED_NOT_FROZEN 39 R controls; 16 paired normalizations; zero public-fit promotions')


def require_frozen_aghq(manifest,root):
    """Freeze needs actual case contracts for annex obligations, not helper labels.

    This checks specification completeness only. Numerical success belongs to
    run receipts; source-domain adequacy still requires independent review.
    """
    c=manifest.get('source_coverage',{})
    need(c.get('aghq_annex')==PLAN,'frozen manifest has no AGHQ required-case annex')
    path=coverage.safe_path(root,PLAN)
    need(c.get('aghq_annex_sha256')==sha(path),'stale AGHQ annex pin')
    annex=json.loads(path.read_text());validate(annex)
    cases={row['id']:row for row in manifest.get('executable_case',[])}
    for obligation in annex['public_obligations']+annex['family_obligations']:
        contracts=set()
        for interface in obligation['interfaces']:
            cid=obligation['id']+'-'+interface.upper().replace('_','-')
            need(cid in cases,'unbound required AGHQ case '+cid)
            row=cases[cid]
            need(row.get('acceptance_level') in {'paired_fit','paired_fit_interface','paired_estimator','paired_fallback'},'helper cannot satisfy AGHQ case '+cid)
            for field in ['r_call','julia_call','model_contract_id','acceptance_rule']:
                need(isinstance(row.get(field),str) and row[field].strip(),'missing AGHQ '+field+' '+cid)
            coverage.safe_path(root,row.get('fixture',''))
            need(obligation['id'] in row.get('aghq_obligation_ids',[]),'AGHQ obligation not bound '+cid)
            contracts.add(row['model_contract_id'])
        need(len(contracts)==1,'AGHQ surfaces changed the model '+obligation['id'])

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--write',action='store_true');parser.add_argument('--verify-evidence',action='store_true');args=parser.parse_args()
    if args.write:
        need(not (ROOT/PLAN).exists(),'refusing to overwrite existing case plan')
        data=build();validate(data);(ROOT/PLAN).write_text(json.dumps(data,indent=2)+'\n')
    elif args.verify_evidence:verify_evidence()
    else:validate(read(PLAN));print('AGHQ_REQUIRED_CASE_ANNEX_VALID_NOT_FROZEN')
