"""Decompose frozen family facts without promoting candidate fixtures to evidence."""
import argparse, json
from pathlib import Path
import core070_manifest_coverage as coverage

ROOT=Path(__file__).resolve().parents[1]
PLAN=coverage.PREFIX+'family-required-case-plan.json'
INPUTS=[coverage.PREFIX+'family-admission-subset.json',
        coverage.PREFIX+'family-route-contract.json',
        coverage.PREFIX+'family-model-catalogue.json',
        coverage.PREFIX+'nb2-required-refresh-evidence.json',
        coverage.PREFIX+'nb2-formula-evidence.json']
ROLES=['native_model','formula_interface','public_r_bridge']

def build():
    admission,entry,catalogue,paired,formula=[coverage.read_json(ROOT/p) for p in INPUTS]
    assert admission['reference_commit']==entry['reference_commit']==catalogue['reference_commit']==coverage.REFERENCE
    entries={r['source_id']:r for r in entry['rows']}
    candidates={r['id']:r for r in catalogue['cases']}
    rows=[];cases=[]
    for fact in admission['cases']:
        sid='family/'+fact['id'];route=entries[sid]
        assert route['reference_descriptor_call']==fact['reference_descriptor_call']
        classification=coverage.CLASS[fact['classification']]
        roles=ROLES if classification=='required_core' else (
            ['compatibility_adapter'] if classification=='compatibility_adapter' else (
            ['reference_boundary'] if classification=='rejected' else []))
        ids=[]
        for role in roles:
            cid=f"CORE070-{fact['id']}-{role.upper().replace('_','-')}";ids.append(cid)
            candidate=candidates.get(route.get('existing_model_id'))
            case=dict(id=cid,coverage_role=role,source_fact_ids=[sid],
                source_row_sha256=coverage.row_sha(fact),
                model_contract_id='MODEL-'+fact['id'],owner=(
                    'B2/Boole' if role=='formula_interface' else 'B5/Hopper' if role=='public_r_bridge' else route['owner']),
                reference_descriptor_call=fact['reference_descriptor_call'],
                reference_admission_expected=fact['expected'],
                status='SPECIFICATION_REQUIRED_NOT_EXECUTABLE_EVIDENCE',
                fixture=None,r_call=None,julia_call=None,
                candidate_native_entry=(route['native_probe']['call'] if route.get('native_probe') else None),
                candidate_fixture=(candidate['fixture'] if candidate else None),
                candidate_fixture_id=(candidate['id'] if candidate else None),
                candidate_is_equivalent=False,
                acceptance_level=('paired_fit' if role=='native_model' else
                    'paired_fit_interface' if role in ROLES else 'reference_boundary' if role=='reference_boundary' else 'adapter_equivalence'),
                required_contract_fields=['exact reference call','exact Julia call','fixture and realized data hash',
                    'parameterization and identification','source and environment pins','acceptance rule','evidence location'],
                prerequisite_case_ids=([f"CORE070-{fact['id']}-NATIVE-MODEL"] if role in ROLES[1:] else []))
            if classification=='required_core':
                case['required_contract_fields'] += ['nuisance grouping and fixed/free parameters',
                    'likelihood constants and curvature','fit-health checks in both engines',
                    'supported and excluded model combinations','reported estimands']
                case['acceptance_rule']=('Original required Student-t fixture keeps absolute delta logLik <= 0.001 and both-engine fit health.'
                    if fact['id']=='FAMILY-09-IDENTITY' else
                    'Pair the same model with likelihood rtol <= 1e-6 and both-engine fit health; predeclare estimand-specific checks.')
                case['scope_boundary']='Descriptor admission is only the family axis; covariance, data, inference and other parameter variants remain separate required contracts.'
                if fact['id'] in {'FAMILY-01-PROBIT','FAMILY-01-CLOGLOG'}:
                    case['candidate_warning']='The legacy K2 binomial fixture is not this link case. Use the separately declared link/trial models only after required-runner integration; cloglog observed selection is not default-Fisher equivalence.'
                elif fact['id']=='FAMILY-06-FIXED-SHAPE':
                    case['candidate_warning']='Select fixed common power1.5 explicitly; neither shared nor per-trait estimated power satisfies this case.'
                elif fact['id']=='FAMILY-09-FIXED-SHAPE':
                    case['candidate_warning']='Select fixed df4 explicitly; the original estimated-df fixture cannot satisfy it.'
                elif fact['id']=='FAMILY-16-LOGIT':
                    case['candidate_warning']='Existing fixed-effects multinomial fixture is only a baseline; required latent/structured support remains separate and unpaid.'
                else:
                    case['candidate_warning']='Candidate fixture is a lead only; confirm exact mean, link, nuisance grouping, model and interface before binding.'
            elif classification=='rejected':
                case['julia_disposition']='UNRESOLVED'
                case['acceptance_rule']='Verify the frozen R rejection; either verify equivalent Julia rejection or document and test an intentional supported Julia extension. Do not infer rejection from missing API.'
            else:
                case['acceptance_rule']='Verify the R alias resolves to the same family and information contract; do not create a duplicate Julia spelling merely to copy syntax.'
            if role=='native_model' and fact['id'] in {'FAMILY-05-LOG','FAMILY-11-LOG'}:
                assert candidate['id'] in paired['case_ids']
                case.update(fixture=candidate['fixture'],r_call=candidate['reference_call'],
                    julia_call=candidate['julia_call'],candidate_is_equivalent=True,
                    status='EXISTING_REQUIRED_NATIVE_CASE_BOUND_INTERFACES_PENDING',
                    required_runner_case_id=candidate['id'],
                    fixture_sha256=coverage.sha(ROOT/candidate['fixture']),
                    evidence=INPUTS[-2],execution_manifest_sha256=paired['execution_manifest_sha256'],
                    model=dict(seed=candidate['seed'],p=candidate['n_traits'],n=candidate['n_units'],
                        K=candidate['n_latent'],**candidate['model']))
                case['candidate_warning']='Only the original seeded native model is bound; formula, bridge, other models and broader recovery remain unpaid.'
            if role=='formula_interface' and fact['id']=='FAMILY-05-LOG':
                assert formula['case_id']==cid
                case.update(fixture=formula['fixture'],fixture_sha256=formula['fixture_sha256'],
                    r_call=candidate['reference_call'],julia_call=formula['julia_call'],
                    candidate_is_equivalent=True,status=formula['status'],
                    model=formula['model'],evidence=INPUTS[-1],
                    required_runner_status='NOT_INTEGRATED')
                case['candidate_warning']='Original intercept-only wide/long formula qualified; public R bridge, broader models and required-runner integration remain unpaid.'
            cases.append(case)
        rows.append(dict(source_id=sid,classification=classification,planned_case_ids=ids,
                         executable_case_ids=[],status='EXCLUDED' if not ids else 'SPECIFICATION_REQUIRED'))
    return dict(schema=1,status='FAMILY_DECOMPOSITION_NOT_FROZEN_NOT_EXECUTABLE',
        reference_commit=coverage.REFERENCE,inputs={p:coverage.sha(ROOT/p) for p in INPUTS},
        source_facts=69,planned_case_count=len(cases),rows=rows,cases=cases)

def verify():
    plan=coverage.read_json(ROOT/PLAN)
    assert plan==build(),'family plan differs from grounded inputs'
    assert len(plan['rows'])==69 and len(plan['cases'])==97
    mapping=coverage.read_json(ROOT/coverage.MAPPING)
    by_id={row['source_id']:row for row in mapping['rows']}
    for row in plan['rows']:
        linked=by_id[row['source_id']]
        assert linked['planned_case_ids']==row['planned_case_ids']
        assert linked['classification']==row['classification'] and linked['executable_case_ids']==[]
        assert linked['case_plan']==PLAN
    assert len({c['id'] for c in plan['cases']})==97
    bound=[c for c in plan['cases'] if c['fixture'] is not None]
    assert {c['required_runner_case_id'] for c in bound if c['coverage_role']=='native_model'}=={'NATIVE-06-NB2','NATIVE-12-TRUNCATED-NB2'}
    assert len(bound)==3 and sum(c['coverage_role']=='formula_interface' for c in bound)==1
    assert all(c['r_call'] is None and c['julia_call'] is None for c in plan['cases'] if c['fixture'] is None)
    print('FAMILY_CASE_PLAN_VERIFIED 69 facts; 97 planned cases; 2 native + 1 formula bindings; zero full-family promotions')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');args=p.parse_args()
    if args.write:
        target=ROOT/PLAN
        assert not target.exists(),'Do not overwrite a reviewed or edited plan'
        plan=build();target.write_text(json.dumps(plan,indent=2)+'\n')
        mapping=coverage.read_json(ROOT/coverage.MAPPING)
        family={r['source_id']:r for r in plan['rows']}
        for row in mapping['rows']:
            if row['source_id'] in family:
                row['planned_case_ids']=family[row['source_id']]['planned_case_ids'];row['case_plan']=PLAN
                row['rationale']=('Constructor-only exclusion preserved.' if row['classification']=='intentionally_excluded' else
                    'Family descriptor decomposed into typed model/interface or boundary cases; fixture leads are not executable coverage.')
        (ROOT/coverage.MAPPING).write_text(json.dumps(mapping,indent=2)+'\n')
    verify()
