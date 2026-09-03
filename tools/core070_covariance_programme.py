"""Nine Gaussian covariance models, separate from full covariance admission scope."""
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REFERENCE='b4d5fee64def88bc768dda1f1f77c29b295edd86'
CONTRACT='docs/dev-log/core070/covariance-programme-contract.json'
FIXED=['MODE-ORD-INDEP','MODE-ORD-COMMON']
MODES=['FIT-MODE-ORD-DEP']+[f'FIT-MODE-{s}-{m}' for s in ['ANIMAL','KERNEL'] for m in ['INDEP','COMMON','DEP']]
IDS=FIXED+MODES
FIXTURES=['test/parity/test_covariance_fixed_required.jl','test/parity/test_covariance_modes_required.jl']
DEPENDENCIES=['tools/core070_covariance_mode_fits.jl','tools/core070_source_fixed_residual_pair.jl',
 'test/parity/fixtures/core070_covariance_modes.R','test/parity/fixtures/core070_covariance_fits.R',CONTRACT]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def need(x,msg):
    if not x:raise ValueError('COVARIANCE_PROGRAMME: '+msg)
def build(root=ROOT):
    rows=[]
    for ident in IDS:
        fixed=ident in FIXED
        source,mode=ident.removeprefix('FIT-').removeprefix('MODE-').split('-')
        group=FIXED if fixed else MODES
        kind='INDEP' if mode=='COMMON' else mode
        fact='covariance/COV-'+source+'-'+kind
        if source=='ORD' and mode=='COMMON':fact='covariance/COV-ORD-INDEP-COMMON'
        terms={('ORD','INDEP'):'indep(0+trait|site)',('ORD','COMMON'):'indep(0+trait|site,common=TRUE)',
          ('ORD','DEP'):'dep(0+trait|site)',('ANIMAL','INDEP'):'animal_indep(0+trait|species,A=C)',
          ('ANIMAL','COMMON'):'animal_indep(0+trait|species,A=C,common=TRUE)',('ANIMAL','DEP'):'animal_dep(0+trait|species,A=C)',
          ('KERNEL','INDEP'):'kernel_indep(species,K=C,name="known")',
          ('KERNEL','COMMON'):'kernel_indep(species,K=C,name="known",common=TRUE)',
          ('KERNEL','DEP'):'kernel_dep(species,K=C,name="known")'}
        controls='gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE'+(')' if fixed else ',optArgs=list(control=list(rel.tol=1e-12,sing.tol=1e-12,eval.max=2000L,iter.max=1500L)))')
        rcall='gllvmTMB(value~0+trait+'+terms[source,mode]+',df,cluster="species",control='+controls+')'
        count=(4 if mode=='COMMON' else 6) if fixed else {'DEP':10,'INDEP':7,'COMMON':5}[mode]
        fixture=FIXTURES[0 if fixed else 1]
        data='test/parity/fixtures/core070_covariance_'+('modes.R' if fixed else 'fits.R')
        runner='tools/core070_source_fixed_residual_pair.jl' if fixed else 'tools/core070_covariance_mode_fits.jl'
        definition=('p3,n18; original sin(index/3)+trait/5 data; independent ordinary source; residual SD c=max(.001sd(y),1e-6) fixed by reference; trait means; '+mode if fixed else
          'p3,n36; uncentered declared known-DGP data; '+source+' '+mode+'; trait means; free common residual SD; source C=I36 for ordinary, else .7I12+.3J12+1e-8I12; 12 groups with3 repeats for structured sources')
        definition+='; native independent coordinates logSD, dependent packed lower L; normalized exact Gaussian marginal; '+str(count)+' free parameters'
        acceptance='Both engines converge; R max abs gradient<=1e-4 and Julia<=1e-7; abs delta logLik<=1e-6; exact data/shapes/maps/free counts; beta and identifiable covariance atol/rtol1e-5; reported objective consistency'
        if not fixed:acceptance+='; independent normalized objective and common-point checks'
        if source=='ORD' and mode=='DEP':acceptance+='; compare TOTAL covariance only, never separately identify source and residual'
        rows.append(dict(id=ident,executor='julia',coverage_role='native_model',acceptance_level='paired_fit',
          source_fact_ids=[fact],model_contract_id='GAUSSIAN-'+ident,model_contract=definition,
          reference_call=rcall,r_call=rcall,
          julia_call='fit_gaussian_sources(Y;sources=[SourceCovariance(C_effective;groups,mode=:'+('dep' if mode=='DEP' else 'indep')+',common='+str(mode=='COMMON').lower()+')],'+('sigma_eps_fixed=c,' if fixed else '')+'g_tol=1e-7'+(')' if fixed else ',iterations=2000)'),
          fixture=fixture,fixture_sha256=sha(root/fixture),data_fixture=data,data_fixture_sha256=sha(root/data),
          runner=runner,runner_sha256=sha(root/runner),execution_case_ids=group,free_parameters=count,
          acceptance_rule=acceptance,control_policy='reference_default_fixed_residual' if fixed else 'explicit_tight_R_controls_native_defaults',
          scope_boundary='Gaussian native model only. Formula/bridge, other families, complete grammar, inference/recovery/performance remain unpaid.',owner='A3/B1'))
    return dict(schema=1,status='NINE_NATIVE_GAUSSIAN_MODE_CONTRACTS_NOT_FULL_COVARIANCE',reference_commit=REFERENCE,cases=rows)
def validate_registry(manifest,root=ROOT):
    path=root/CONTRACT
    need(manifest.get('covariance_case_ids')==IDS,'required covariance IDs differ')
    need(manifest.get('covariance_registry')==dict(path=CONTRACT,sha256=sha(path)),'registry pin differs')
    contract=json.loads(path.read_text());need(contract==build(root),'model contracts differ from fixtures')
    rows=manifest.get('covariance_models',[])
    need([r['id'] for r in rows]==IDS and all(r['fixture']==FIXTURES[0 if r['id'] in FIXED else 1] for r in rows),'runner model inventory differs')
    executable={r['id']:r for r in manifest.get('executable_case',[])}
    for row in contract['cases']:
        need(row['id'] in executable and all(executable[row['id']].get(k)==v for k,v in row.items()),'missing or altered executable model '+row['id'])
    return contract
