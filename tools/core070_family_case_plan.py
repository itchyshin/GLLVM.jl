"""Decompose frozen family facts without promoting candidate fixtures to evidence."""
import argparse, json
from pathlib import Path
import core070_manifest_coverage as coverage
from core070_bridge_admission import CONTRACT as BOUNDARY_CONTRACT, bound_rows

ROOT=Path(__file__).resolve().parents[1]
PLAN=coverage.PREFIX+'family-required-case-plan.json'
INPUTS=[coverage.PREFIX+'family-admission-subset.json',
        coverage.PREFIX+'family-route-contract.json',
        coverage.PREFIX+'family-model-catalogue.json',
        coverage.PREFIX+'nb2-formula-required-pb-refresh.json',
        coverage.PREFIX+'family-boundary-contract.json',
        coverage.PREFIX+'family-boundary-pb-refresh.json',
        coverage.PREFIX+'family-link-boundary-contract.json',
        coverage.PREFIX+'family-link-boundary-pb-refresh.json',
        coverage.PREFIX+'poisson-beta-required-evidence.json',
        coverage.PREFIX+'gaussian-required-contract.json',
        coverage.PREFIX+'registered-models-contract.json', coverage.PREFIX+'family-formulas-contract.json']
ROLES=['native_model','formula_interface','public_r_bridge']
BRIDGE_CONTRACT=coverage.PREFIX+'public-bridge-required-cases.json'
DESCRIPTOR_EVIDENCE=coverage.PREFIX+'bridge-descriptor-evidence.json'

def build():
    bridge_boundaries={c['id']:c for c in bound_rows(ROOT)}
    descriptor_evidence=coverage.read_json(ROOT/DESCRIPTOR_EVIDENCE)
    assert descriptor_evidence['reference_commit']==coverage.REFERENCE
    assert descriptor_evidence['contract_sha256']==coverage.sha(ROOT/(coverage.PREFIX+'bridge-descriptor-contract.json'))
    rejected_bridge_descriptors=set(descriptor_evidence['required_native_descriptors_rejected_by_bridge'])
    bridge_contract=coverage.read_json(ROOT/BRIDGE_CONTRACT)
    bridge_cases={c['id']:c for c in bridge_contract['cases']}
    assert bridge_contract['reference_commit']==coverage.REFERENCE
    admission,entry,catalogue,paired,boundary_contract,boundary_evidence,link_contract,link_evidence,pb,gaussian,registered,interfaces=[coverage.read_json(ROOT/p) for p in INPUTS]
    registered=dict(cases=registered["cases"]+interfaces["cases"])
    formula=paired["formula"]
    boundaries={row["source_fact_id"]:row for row in boundary_contract["rows"]}
    links={row["source_fact_id"]:row for row in link_contract["rows"]}
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
                    evidence=INPUTS[3],execution_manifest_sha256=paired['execution_manifest_sha256'],
                    model=dict(seed=candidate['seed'],p=candidate['n_traits'],n=candidate['n_units'],
                        K=candidate['n_latent'],**candidate['model']))
                case['candidate_warning']='Only the original seeded native model is bound; formula, bridge, other models and broader recovery remain unpaid.'
            if role=='native_model' and fact['id'] in {'FAMILY-02-LOG','FAMILY-07-LOGIT'}:
                model=next(m for m in pb['cases'] if m['id']==candidate['id'])
                case.update(fixture=model['required_fixture'],
                    fixture_sha256=coverage.sha(ROOT/model['required_fixture']),
                    original_dgp_fixture=model['fixture'],original_dgp_sha256=model['dgp_sha256'],
                    r_call=model['reference_call'],julia_call=model['native_call'],
                    r_optimization_policy=pb['controls'],candidate_is_equivalent=True,
                    status='EXISTING_REQUIRED_NATIVE_CASE_BOUND_INTERFACES_PENDING',
                    required_runner_case_id=model['id'],evidence=INPUTS[8],
                    execution_manifest_sha256=pb['execution_manifest_sha256'],model=model)
                case['candidate_warning']='Only the original seeded native model is bound with explicit public R refinement; formula, bridge, other models and recovery remain unpaid.'
            if role=='formula_interface' and fact['id']=='FAMILY-05-LOG':
                assert formula['case_id']==cid
                case.update(fixture=formula['fixture'],fixture_sha256=formula['fixture_sha256'],
                    r_call=candidate['reference_call'],julia_call=formula['julia_call'],
                    candidate_is_equivalent=True,status=formula['status'],
                    model=formula['model'],evidence=INPUTS[3],
                    required_runner_status='VERIFIED_ORIGINAL_MODEL',
                    required_runner_case_id=cid,execution_manifest_sha256=paired['execution_manifest_sha256'])
                case['candidate_warning']='Original intercept-only wide/long formula verified in required runner; public R bridge and broader models remain unpaid.'
            if classification=='rejected' and boundaries[sid]['disposition']!='UNRESOLVED':
                boundary=boundaries[sid]
                assert boundary['source_case_id'] in boundary_evidence['case_ids']
                case.update(fixture=boundary['fixture'],fixture_sha256=coverage.sha(ROOT/boundary['fixture']),
                    r_call=boundary['reference_call'],julia_call=boundary['julia_call'],
                    julia_disposition=boundary['disposition'],
                    status='DOMAIN_BOUNDARY_VERIFIED_REQUIRED_INTEGRATION_PENDING',
                    evidence=INPUTS[5],reference_expected=boundary['reference_expected'],
                    julia_expected=boundary['julia_expected'],scope_boundary=boundary['scope'],
                    acceptance_rule='Frozen R descriptor rejects; Julia named public fitter rejects invalid input or retains a documented domain extension before response access. No fitting, recovery or bridge claim.')
            if classification=='rejected' and sid in links:
                link=links[sid]
                case['admission_observation']=link['disposition']
                case['candidate_julia_call']=link['julia_call']
                if link['disposition']=='reject':
                    assert link['id'] in link_evidence['reject_ids']
                    case.update(fixture=link_contract['fixture'],fixture_sha256=link_contract['fixture_sha256'],
                        r_call=link['reference_call'],julia_call=link['julia_call'],julia_disposition='reject',
                        status='NATIVE_LINK_REJECTION_VERIFIED_REQUIRED_INTEGRATION_PENDING',
                        evidence=INPUTS[7],reference_expected=link['reference_expected'],
                        julia_expected=link['expected'],scope_boundary=link['scope'],
                        acceptance_rule='Frozen R rejects its descriptor; the corresponding native Julia link control raises ArgumentError. No fitted-model or public R bridge promotion.')
                else:
                    case['candidate_warning']='Observed native admission remains unvalidated, or no equivalent Julia selector exists. Resolve semantics and the public R bridge before completing this boundary.'
            if sid == 'family/FAMILY-00-IDENTITY' and role in {'native_model','formula_interface'}:
                binding = next(r for r in gaussian['cases'] if r['coverage_role'] == role)
                assert binding['id'] == cid
                case.update(fixture=binding['fixture'],fixture_sha256=binding['fixture_sha256'],
                    r_call=binding['r_call'],julia_call=binding['julia_call'],
                    model_contract_id=binding['model_contract_id'],
                    model_contract=binding['model_contract'],
                    acceptance_rule=binding['acceptance_rule'],scope_boundary=binding['scope_boundary'],
                    status='REGISTERED_EXECUTABLE_CASE_REPLAY_EVIDENCE_SEPARATE',
                    required_runner_case_id=cid,required_runner_status='REGISTERED',
                    data_fixture=binding['data_fixture'],data_fixture_sha256=binding['data_fixture_sha256'])
                case['candidate_warning']='Legacy candidate fields are retained as historical leads, not the selected model. Actual fixture/calls above bind the registered original Gaussian case; execution receipts are separate. Public R bridge remains unpaid.'
            binding=next((r for r in registered['cases'] if r['planned_case_id']==cid),None)
            if binding is not None:
                case.update(fixture=binding['fixture'],fixture_sha256=binding['fixture_sha256'],
                    r_call=binding['reference_call'],julia_call=binding['julia_call'],
                    acceptance_rule=binding['acceptance_rule'],scope_boundary=binding['scope_boundary'],
                    reference_control_policy=binding['reference_control_policy'],
                    model_contract=binding['model_contract'],
                    required_runner_case_id=binding['id'],required_runner_status='REGISTERED_SOURCE_BOUND',
                    status='REGISTERED_EXECUTABLE_CASE_REPLAY_EVIDENCE_SEPARATE',
                    data_sha256=binding['data_sha256'])
                case['candidate_warning']='Actual required_runner_case_id is an existing stable runner ID; planned ID is its source-role alias. Earlier evidence is historical until replayed on current inputs; bridge and remaining models/interfaces unpaid.'
            if role=='public_r_bridge' and cid in bridge_cases:
                bridge=bridge_cases[cid]
                case.update(fixture=bridge['fixture'],fixture_sha256=coverage.sha(ROOT/bridge['fixture']),
                    r_call=bridge['r_call'],julia_call=bridge['julia_call'],
                    model_contract_id=bridge['model_contract_id'],data_sha256=bridge['data_sha256'],
                    model_contract=next(r['model_contract'] for r in registered['cases']
                        if r['coverage_role']=='native_model' and r['model_contract_id']==bridge['model_contract_id']),
                    acceptance_rule=bridge['acceptance_rule'],scope_boundary=bridge['scope_boundary'],
                    status='SEPARATE_REQUIRED_R_RUNNER_REGISTERED_AGGREGATE_PENDING',
                    required_runner_case_id=cid,required_runner_status='SEPARATE_PUBLIC_R_REGISTRY',
                    bridge_subcontract=BRIDGE_CONTRACT,
                    bridge_subcontract_sha256=coverage.sha(ROOT/BRIDGE_CONTRACT),
                    prerequisite_case_ids=[bridge['prerequisite_native_id']])
                case['candidate_warning']='Separate required R runner has exact case IDs and its own verification. Main programme receipt aggregation remains pending; this row alone does not grant full-family coverage.'
            if role=='public_r_bridge' and cid in bridge_boundaries:
                boundary=bridge_boundaries[cid]
                case.update(boundary)
                case.update(status='REFERENCE_BRIDGE_BOUNDARY_BOUND_SCOPE_REVIEW_PENDING',
                    required_runner_status='SOURCE_BOUND_REFERENCE_BEHAVIOR',
                    evidence=coverage.PREFIX+'bridge-model-admission-evidence.json',
                    prerequisite_case_ids=[boundary['native_case_id']])
                case['candidate_warning']='Reference bridge rejection or model change is verified, not same-model parity. Native and formula requirements remain unchanged; full-manifest integration and independent scope review remain unpaid.'
            elif role=='public_r_bridge' and sid in rejected_bridge_descriptors:
                case.update(acceptance_level='reference_bridge_boundary',
                    reference_bridge_observation='DESCRIPTOR_REJECTED_MODEL_BINDING_PENDING',
                    descriptor_evidence=DESCRIPTOR_EVIDENCE,
                    descriptor_evidence_sha256=coverage.sha(ROOT/DESCRIPTOR_EVIDENCE))
                case['acceptance_rule']='Bind the required native model first, then verify its frozen-reference bridge rejection with exact source, fixture and receipt contracts. Native/formula same-model parity remains required.'
                case['candidate_warning']='The descriptor rejects in both public R bridge routes. This observation is not yet a model-bound executable case; the strict bridge gate rejects it until a complete contract is registered.'
            cases.append(case)
        executable=[r['id'] for r in gaussian['cases']+registered['cases'] if sid in r['source_fact_ids']]
        rows.append(dict(source_id=sid,classification=classification,planned_case_ids=ids,
                         executable_case_ids=executable,
                         status='REGISTERED_PARTIAL_INTERFACES_UNPAID' if executable else ('EXCLUDED' if not ids else 'SPECIFICATION_REQUIRED')))
    return dict(schema=1,status='FAMILY_DECOMPOSITION_PARTIAL_EXECUTABLE_NOT_FROZEN',
        reference_commit=coverage.REFERENCE,inputs={p:coverage.sha(ROOT/p) for p in INPUTS+[BRIDGE_CONTRACT,BOUNDARY_CONTRACT,DESCRIPTOR_EVIDENCE]},
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
        assert linked['classification']==row['classification'] and linked['executable_case_ids']==row['executable_case_ids']
        assert linked['case_plan']==PLAN
    assert len({c['id'] for c in plan['cases']})==97
    bound=[c for c in plan['cases'] if c['fixture'] is not None]
    assert {c['required_runner_case_id'] for c in bound if c['coverage_role']=='native_model'}=={'NATIVE-03-POISSON','NATIVE-08-BETA','NATIVE-06-NB2','NATIVE-12-TRUNCATED-NB2','CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL'}
    assert len(bound)==31 and sum(c['coverage_role']=='formula_interface' for c in bound)==5
    bridges=[c for c in bound if c['coverage_role']=='public_r_bridge']
    paired_bridges=[c for c in bridges if c['acceptance_level']=='paired_fit_interface']
    assert {c['id'] for c in paired_bridges}=={
        'CORE070-FAMILY-02-LOG-PUBLIC-R-BRIDGE','CORE070-FAMILY-07-LOGIT-PUBLIC-R-BRIDGE',
        'CORE070-FAMILY-05-LOG-PUBLIC-R-BRIDGE'}
    assert all(c['required_runner_status']=='SEPARATE_PUBLIC_R_REGISTRY' for c in paired_bridges)
    boundary_bridges=[c for c in bridges if c['acceptance_level']=='reference_bridge_boundary']
    assert {c['id'] for c in boundary_bridges}=={
        'CORE070-FAMILY-00-IDENTITY-PUBLIC-R-BRIDGE','CORE070-FAMILY-11-LOG-PUBLIC-R-BRIDGE'}
    assert all(c['required_runner_status']=='SOURCE_BOUND_REFERENCE_BEHAVIOR' for c in boundary_bridges)
    assert sum(c['coverage_role']=='reference_boundary' for c in bound)==16
    assert all(c['r_call'] is None and c['julia_call'] is None for c in plan['cases'] if c['fixture'] is None)
    print('FAMILY_CASE_PLAN_VERIFIED 69 facts; 97 planned cases; 5 native + 5 formula + 3 paired R bridge + 2 reference bridge behaviors + 16 boundary bindings; zero full-family promotions')

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
