"""Verify covariance formula interfaces and their same-process R/native controls."""
import copy,hashlib,json,math,os,struct,subprocess,sys
from pathlib import Path
import core070_evidence as e
import core070_covariance_formula_programme as c
from core070_manifest_coverage import need
from core070_verify_covariance_programme import validate_payloads
from core070_verify_covariance_fits import normclose,total
ROOT=e.ROOT
STATE=ROOT/'.unlazy/core070-aghq/covariance-formulas-02'
ENV_MANIFEST=ROOT/'.unlazy/core070-aghq/aghq-public-poisson-env-01/attempt1/test/parity/Manifest.toml'
IDS=c.native.IDS+c.IDS
COUNTS={**dict.fromkeys(c.native.FIXED,27),**dict.fromkeys(c.native.MODES,176),**dict.fromkeys(c.FIXED,56),**dict.fromkeys(c.MODES,191)}
TOTAL=27+176+56+191

def check_run(run,cells,cases,execution):
    need(run['status']=='success' and run['exit_code']==0 and run['success_marker']=='CORE070_PARITY_SUCCESS','failed run')
    need(run['requested_case_ids']==IDS and run['completed_case_ids']==sorted(IDS),'missing cases')
    need(run['scope']=='subset' and run['selected_family_count']==0,'false scope')
    need(run['execution']==execution and run['contract_sha256']==e.digest(e.DEFAULT_MANIFEST),'stale source/contract')
    need(set(cells)==set(IDS) and run['cells']==cells,'missing/transplanted cells')
    need(run['assertion_counting']=='execution_groups_v1','wrong assertion accounting')
    for cid,cell in cells.items():
        row=cases[cid]
        need(cell['id']==cid and cell['status']=='success' and cell['run_id']==run['run_id'],'cell failed/transplanted')
        need(cell['execution_case_ids']==sorted(row['execution_case_ids']),'partial group')
        need(cell['fixture']==row['fixture'] and cell['fixture_sha256']==row['fixture_sha256']==e.digest(ROOT/row['fixture']),'fixture changed')
        need(cell['assertions']==dict(passed=COUNTS[cid],failed=0,errored=0,broken=0),'assertion failure or count drift')
        need(cell['contract_sha256']==run['contract_sha256'] and cell['execution_manifest_sha256']==execution['manifest_sha256'],'cell provenance drift')
    need(e.execution_assertion_counts(cells)==dict(passed=TOTAL,failed=0,errored=0,broken=0) and run['actual_assertions']==TOTAL,'wrong aggregate assertion count')

def gaussian_nll(Y,C,groups,fit):
    """Base-Python Cholesky density, independent of Julia/TMB/report booleans."""
    p=len(Y);n=len(Y[0]);N=p*n;B=fit['source_covariance'];sigma=fit['residual_sd']
    need(len(B)==p and all(len(row)==p for row in B),'wrong trait covariance shape')
    need(all(math.isfinite(v) for row in B for v in row),'nonfinite covariance')
    need(all(abs(B[i][j]-B[j][i])<=1e-12 for i in range(p) for j in range(p)),'asymmetric covariance')
    L=[[0.]*N for _ in range(N)]
    for i in range(N):
        si,ti=divmod(i,p)
        for j in range(i+1):
            sj,tj=divmod(j,p)
            value=C[groups[si]-1][groups[sj]-1]*B[ti][tj]+(sigma*sigma if i==j else 0.)
            value-=sum(L[i][k]*L[j][k] for k in range(j))
            if i==j:
                need(math.isfinite(value) and value>0,'invalid marginal covariance')
                L[i][j]=math.sqrt(value)
            else:L[i][j]=value/L[j][j]
    z=[]
    for i in range(N):
        si,ti=divmod(i,p)
        z.append((Y[ti][si]-fit['beta'][ti]-sum(L[i][k]*z[k] for k in range(i)))/L[i][i])
    return (N*math.log(2*math.pi)+2*sum(math.log(L[i][i]) for i in range(N))+sum(v*v for v in z))/2

def formula_ok(row,native,fixed,Y_hash=None):
    ident=native['id'];source,mode=ident.removeprefix('FIT-').removeprefix('MODE-').split('-')
    need(row['id']==ident+'-FORMULA-INTERFACE' and row['native_id']==ident,'wrong model ID')
    need(row['source']==source and row['mode']==mode and row['ordinary_dependent_total_covariance_only']==(source=='ORD' and mode=='DEP'),'wrong covariance contract')
    need(len(row['checks'])==27 and all(v is True for v in row['checks'].values()) and row['all_checks'],'failed or omitted formula checks')
    base=row['expected_base'];Y=base['Y'];n=18 if fixed else 36;p=3
    need(len(Y)==p and all(len(x)==n for x in Y),'wrong data shape')
    if fixed:
        packed=struct.pack('<'+str(p*n)+'d',*[Y[t][s] for s in range(n) for t in range(p)])
        need(hashlib.sha256(packed).hexdigest()==Y_hash,'formula changed original data')
        cov=[[native['r_source_sd'][i]**2 if i==j else 0. for j in range(p)] for i in range(p)]
        r=dict(code=native['r_code'],gradient=native['r_gradient'],loglik=native['r_loglik'],beta=native['r_beta'],source_covariance=cov,residual_sd=native['sigma_eps_fixed'])
        native_cov=[[native['native_source_variance'][i] if i==j else 0. for j in range(p)] for i in range(p)]
        native_parameters=native['native_parameters'];dof=native['native_dof']
        C=[[float(i==j) for j in range(n)] for i in range(n)];groups=list(range(1,n+1))
    else:
        need(Y==native['Y'],'formula changed native/Rdata')
        old=native['r'];r=dict(code=old['code'],gradient=old['gradient'],loglik=old['loglik'],beta=old['beta'],source_covariance=old['covariance'],residual_sd=old['residual_sd'])
        native_cov=native['native']['source_covariance'];native_parameters=native['native']['parameters'];dof=native['native']['dof']
        C=([[float(i==j) for j in range(n)] for i in range(n)] if source=='ORD' else
           [[v+(1e-8 if i==j else 0.) for j,v in enumerate(row)] for i,row in enumerate(native['input_C'])]);groups=native['source_groups_by_site']
    r['health']=r['code']==0 and all(math.isfinite(v) for v in r['gradient']) and max(map(abs,r['gradient']))<=1e-4
    need(r['health'] and base['native'].get('health') is True,'unhealthy retained comparison')
    need(base['r']==r and base['native']['parameters']==native_parameters and base['native']['source_covariance']==native_cov,'R/native report transplanted')
    need(base['source_matrix']==C and base['source_groups']==groups,'source/ordering changed')
    D=[[float(t==j) for j in range(p)] for s in range(n) for t in range(p)]
    P=[[float(g==j+1) for j in range(len(C))] for g in groups]
    for route in ['wide','long']:
        fit=row[route]
        need(fit['available'] is True and fit['error']=='' and fit['converged'] is True,'formula fit unavailable/unhealthy')
        need(math.isfinite(fit['gradient_max']) and fit['gradient_max']<=1e-7,'formula gradient failed')
        need(fit['shape']==[p,n] and fit['design']==fit['explicit_X']==D,'shape/design changed')
        need(fit['reversed_long_input']==(route=='long') and fit['source_projection']==P and fit['source_projection_matches_input'],'source/site ordering changed')
        need(fit['free_parameters']==len(fit['parameters'])==dof,'different free coordinates')
        need(math.isfinite(fit['loglik']) and abs(fit['loglik']-r['loglik'])<=1e-6,'formula likelihood failed')
        need(normclose(fit['beta'],r['beta']),'formula beta failed')
        need(math.isfinite(fit['residual_sd']) and fit['residual_sd']>0,'invalid residual')
        need(fit['residual_fixed']==fixed,'fixed/free residual changed')
        if fixed:need(fit['residual_sd']==r['residual_sd'],'fixed residual value changed')
        if source=='ORD' and mode=='DEP':need(normclose(total(fit['source_covariance'],fit['residual_sd']),total(r['source_covariance'],r['residual_sd'])),'total covariance failed')
        else:
            need(normclose(fit['source_covariance'],r['source_covariance']),'source covariance failed')
            if not fixed:need(normclose(fit['residual_sd']**2,r['residual_sd']**2),'residual variance failed')
        need(abs(gaussian_nll(Y,C,groups,fit)+fit['loglik'])<=1e-6,'independent formula density mismatch')
    a,b=row['wide'],row['long']
    need(normclose(a['parameters'],b['parameters'],1e-7,1e-7) and normclose(a['loglik'],b['loglik'],1e-7,1e-7),'wide/long differ')

def verify():
    folder=STATE/'attempt1/receipts';run,cells=e._load_receipts(folder)
    manifest=e.load_manifest(e.DEFAULT_MANIFEST);c.validate_registry(manifest)
    need(manifest['status']=='DRAFT_INCOMPLETE_NOT_FROZEN','unearned promotion')
    cases={r['id']:r for r in manifest['executable_case']};execution=e.execution_inventory(cases,IDS,e.DEFAULT_MANIFEST)
    need(not any(r['path']=='test/parity/Manifest.toml' for r in execution['entries']),'unexpected local environment')
    entries=execution['entries']+[dict(path='test/parity/Manifest.toml',sha256=e.digest(ENV_MANIFEST))];entries.sort(key=lambda r:r['path'])
    execution=dict(entries=entries,manifest_sha256=e._hash_inventory(entries));check_run(run,cells,cases,execution)
    e._validate_source(run['source'],manifest,execution,folder)
    need(run['source']['julia_threads']==run['source']['blas_threads']==1,'wrong thread budget')
    path=STATE/'attempt1/process/process-receipt.json';e.verify_process(folder,path,execution)
    proc=json.loads(path.read_text());plan=json.loads((STATE/'plan.json').read_text())
    need(proc['plan_sha256']==e.digest(STATE/'plan.json') and proc['environment_overrides']==plan['env'],'plan/environment drift')
    need(plan['env']['CORE070_PARITY_CASE_IDS']==','.join(IDS) and plan['env']['CORE070_PARITY_REQUIRED']==plan['env']['GLLVM_PARITY_TESTS']=='1','wrong or optional scope')
    need([r['id'] for r in proc['results']]==['oracle-before','registry','pair','oracle-after'] and plan['commands'][2]['argv'][-1]=='test/parity/runparity.jl','wrong entrypoint/checks')
    modes,fixed=validate_payloads(folder,plan)
    byid={r['id']:r for r in modes['cases']+fixed['cases']};all_rows=[];controls=0
    for kind,native_ids in [('fixed',c.native.FIXED),('modes',c.native.MODES)]:
        report=e.load_toml(folder/f'covariance-formula-{kind}-raw/result.toml')
        need(report['matrix_encoding']=='rows' and report['native_ids']==native_ids and report['case_ids']==report['formula_ids']==[i+'-FORMULA-INTERFACE' for i in native_ids],'changed/omitted formula group')
        need(report['all_checks'] and not report['failures'] and [r['native_id'] for r in report['cases']]==native_ids,'failed/omitted formula attempts')
        for row in report['cases']:
            native=byid[row['native_id']];isfixed=kind=='fixed';yh=fixed['data_sha256'] if isfixed else None
            formula_ok(row,native,isfixed,yh);all_rows.append(row)
            for mutation in ['gradient','loglik','shape','design','fixed','base','base_health','native_health','data','omit_check']:
                bad=copy.deepcopy(row)
                if mutation=='gradient':bad['wide']['gradient_max']=1.
                elif mutation=='loglik':bad['long']['loglik']+=1.
                elif mutation=='shape':bad['wide']['shape']=[1,1]
                elif mutation=='design':bad['long']['design'][0][0]+=1.
                elif mutation=='fixed':bad['wide']['residual_fixed']=not isfixed
                elif mutation=='base':bad['expected_base']['r']['loglik']+=1.
                elif mutation=='base_health':bad['expected_base']['r']['health']=False
                elif mutation=='native_health':bad['expected_base']['native']['health']=False
                elif mutation=='data':bad['expected_base']['Y'][0][0]+=1.
                else:bad['checks'].pop(next(iter(bad['checks'])))
                try:formula_ok(bad,native,isfixed,yh)
                except (ValueError,RuntimeError,KeyError,AssertionError):controls+=1;continue
                raise AssertionError('corrupt formula record accepted')
    for mutation in ['omit','exit','stale','source','missing_receipt','group','count']:
        r,b=copy.deepcopy(run),copy.deepcopy(cells)
        if mutation=='omit':r['completed_case_ids'].pop()
        elif mutation=='exit':r['exit_code']=1
        elif mutation=='stale':r['contract_sha256']='stale'
        elif mutation=='source':r['execution']['entries'][0]['sha256']='stale'
        elif mutation=='missing_receipt':b.pop(IDS[-1])
        elif mutation=='group':b[IDS[-1]]['execution_case_ids']=[IDS[-1]]
        else:r['actual_assertions']+=1
        try:check_run(r,b,cases,execution)
        except (ValueError,RuntimeError,KeyError,AssertionError):controls+=1;continue
        raise AssertionError('corrupt run accepted')
    missing=subprocess.run([sys.executable,str(Path(__file__).resolve())],env=dict(os.environ,PATH='/nonexistent-core070-dependency'),capture_output=True,text=True,timeout=30)
    need(missing.returncode!=0 and 'FileNotFoundError' in missing.stderr and 'Rscript' in missing.stderr,'missing dependency accepted');controls+=1
    result=dict(status='NINE_COVARIANCE_FORMULA_INTERFACES_PASS_NOT_PROGRAMME',native_cases=9,formula_cases=9,formula_routes=18,assertions=TOTAL,negative_controls=controls,elapsed_seconds=proc['results'][2]['elapsed_seconds'],max_formula_absolute_delta_loglik=max(abs(r[route]['loglik']-r['expected_base']['r']['loglik']) for r in all_rows for route in ['wide','long']),process_sha256=e.digest(path))
    print('CORE070_COVARIANCE_FORMULAS_VERIFIED',json.dumps(result));return result
if __name__=='__main__':verify()
