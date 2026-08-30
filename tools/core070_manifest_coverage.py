"""Known frozen-source obligations and the required source-to-executable-case map.

A known-source census is not exhaustive semantic coverage. Freezing also needs
an independent scope-review receipt bound to the exact index and mapping.
"""
import csv, hashlib, io, json, re, subprocess
from pathlib import Path

REFERENCE='b4d5fee64def88bc768dda1f1f77c29b295edd86'
PREFIX='docs/dev-log/core070/'
INDEX=PREFIX+'required-source-index.json'
MAPPING=PREFIX+'required-source-case-map.json'
REGISTRY=(
 ('family','family-admission-subset.json','cases',69),
 ('covariance','covariance-admission-subset.json','cases',95),
 ('isdm','isdm-admission-subset.json','cases',37),
 ('aghq','aghq-control-subset.json','cases',39),
 ('fit-input','fit-input-subset.json','cases',14),
 ('postfit','postfit-surface-inventory.json','entries',100),
 ('postfit-policy','postfit-policy-subset.json','cases',29),
 ('inference','inference-routing-subset.json','case_ids',98),
 ('data','data-controls-subset.json','case_ids',56),
)
CLASS={
 'required_core':'required_core','required_core_model_candidate':'required_core',
 'REQUIRED_INFORMATION':'required_core','REQUIRED_INFORMATION_CONTRACT':'required_core',
 'REFERENCE_RESPONSE_PARAMETER_NOT_CONDITIONAL_MEAN':'required_core',
 'compatibility_adapter':'compatibility_adapter','compatibility adapter':'compatibility_adapter',
 'rejected':'rejected','rejected_combination':'rejected','REFERENCE_REJECTED_COMBINATION':'rejected',
 'intentionally_excluded':'intentionally_excluded','intentionally excluded':'intentionally_excluded',
 'intentionally_excluded_constructor_only':'intentionally_excluded',
 'PUBLIC_R_BRIDGE_REQUIRED':'required_core','POSTFIT_INFORMATION_REQUIRED':'required_core',
 'CORE_MODEL_OR_FAMILY_REQUIRED':'required_core','DATA_ADAPTER_ADMISSION_PENDING':'required_core',
 'COMPATIBILITY_ADAPTER_REQUIRED':'compatibility_adapter','R_RUNTIME_REGISTRATION':'compatibility_adapter',
 'INTENTIONALLY_EXCLUDED_VA':'intentionally_excluded','INTENTIONALLY_EXCLUDED_EXPERIMENTAL':'intentionally_excluded',
 'INTENTIONALLY_EXCLUDED':'intentionally_excluded','R_EXPORTED_CONSTRUCTOR_REJECTED_BY_MULTIVAR_ENGINE':'intentionally_excluded',
 # No approved exclusion established: retain the exported preparation utility.
 'NON_CORE_R_UTILITY':'compatibility_adapter',
}
DOMAINS={'families-links-parameters','covariance-modifiers','data-missingness-offsets-trials',
         'postfit-inference','formula','public-r-bridge','public-stage1a-aghq'}

class CoverageError(ValueError):pass

def need(value,message):
    if not value:raise CoverageError('SOURCE_COVERAGE: '+message)

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def row_sha(row):return hashlib.sha256(json.dumps(row,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def read_json(path):
    try:return json.loads(path.read_text())
    except (OSError,ValueError) as error:raise CoverageError('SOURCE_COVERAGE: missing or invalid '+str(path)) from error

def safe_path(root,relative):
    need(isinstance(relative,str) and relative and not Path(relative).is_absolute() and '..' not in Path(relative).parts,'invalid artifact path')
    path=root/relative
    need(path.resolve().is_relative_to(root.resolve()) and path.is_file() and not path.is_symlink(),'missing or escaping artifact '+relative)
    return path

def build_index(root):
    pins={}; facts=[]
    def pin(relative):
        path=safe_path(root,relative);pins[relative]=sha(path);return path
    def add(group,row,classification,origin):
        need(classification in CLASS,'unclassified source row '+str(row))
        facts.append(dict(id=group+'/'+str(row['id']),classification=CLASS[classification],
          source_classification=classification,source_inventory=origin,source_row_sha256=row_sha(row)))
    oracle=read_json(pin('.unlazy/core070-aghq/oracle-source/source.json'))
    need(oracle['reference_commit']==REFERENCE,'oracle reference drift')
    source_hash=hashlib.sha256('\n'.join(sorted(k+'\0'+v for k,v in oracle['source_files'].items())).encode()).hexdigest()
    need(source_hash==oracle['source_tree_sha256']=='f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7','oracle source inventory drift')
    def source_pin(name,expected):
        need(oracle['source_files'].get(name)==expected,'source declaration differs from frozen archive '+name)
        need(sha(pin('.unlazy/core070-aghq/oracle-source/readback/'+name))==expected,'frozen source bytes differ '+name)
    source_pin('NAMESPACE',oracle['namespace_sha256'])
    ns=PREFIX+'frozen-r070-namespace-inventory.tsv' 
    text=pin(ns).read_text();rows=list(csv.DictReader(io.StringIO('\n'.join(l for l in text.splitlines() if l and not l.startswith('#'))),delimiter='\t'))
    need(len(rows)==215,'namespace count drift')
    namespace_lines=(root/'.unlazy/core070-aghq/oracle-source/readback/NAMESPACE').read_text().splitlines()
    actual={i+1:line for i,line in enumerate(namespace_lines) if re.match(r'^(S3method|export|useDynLib)\(',line)}
    need({int(row['namespace_line']) for row in rows}==set(actual),'namespace registrations omitted or invented')
    for row in rows:
        expected=row['registration']+'('+row['name']+')'
        if row['registration']=='useDynLib':expected='useDynLib(gllvmTMB, .registration = TRUE)'
        need(re.sub(r'\s+','',actual[int(row['namespace_line'])])==re.sub(r'\s+','',expected),'namespace name differs from frozen declaration')
        row=dict(row,id=row['registration']+'/'+row['name'])
        add('namespace',row,row['obligation'],ns)
    for group,file,key,count in REGISTRY:
        relative=PREFIX+file;d=read_json(pin(relative))
        need(d['reference_commit']==REFERENCE,'reference pin drift '+relative)
        for name,expected in d.get('source_pins',{}).items():source_pin(name,expected)
        for pins_key in ['current_pins','artifacts']:
            for name,expected in d.get(pins_key,{}).items():
                marker='.unlazy/core070-aghq/oracle-source/readback/'
                if name.startswith(marker):source_pin(name[len(marker):],expected)
        rows=d[key];need(len(rows)==count,'source row count drift '+relative)
        if group=='inference':
            fixture=pin(d['fixture'])
            parsed=list(csv.DictReader(io.StringIO(fixture.read_text()),delimiter='\t'))
            need([x['id'] for x in parsed]==rows,'inference fixture ID drift')
            rows=parsed
        elif group=='data':
            fixture=pin(d['fixture']);parser=pin('tools/core070_data_case_index.R')
            out=subprocess.check_output(['Rscript',str(parser),str(fixture)],text=True)
            parsed=list(csv.DictReader(io.StringIO(out),delimiter='\t'))
            need([x['id'] for x in parsed]==rows,'data fixture ID drift')
            rows=parsed
        for row in rows:add(group,row,row['classification'],relative)
    need(len(facts)==752 and len({f['id'] for f in facts})==752,'duplicate or missing source facts')
    return dict(schema=1,status='KNOWN_SOURCE_CENSUS_NOT_EXHAUSTIVE_SCOPE',reference_commit=REFERENCE,
      inventories=pins,facts=sorted(facts,key=lambda x:x['id']))

def validate_mapping(mapping,facts,case_ids):
    need(mapping.get('reference_commit')==REFERENCE,'mapping reference differs')
    rows=mapping.get('rows',[])
    need(isinstance(rows,list) and all(isinstance(r,dict) for r in rows),'mapping rows must be records')
    by_id={r.get('source_id'):r for r in rows}
    need(len(rows)==len(by_id)==len(facts) and set(by_id)=={r['id'] for r in facts},'missing or duplicated source mappings')
    mapped=set()
    for fact in facts:
        row=by_id[fact['id']]
        need(row.get('classification')==fact['classification'],'classification drift '+fact['id'])
        ids=row.get('executable_case_ids')
        need(isinstance(ids,list) and all(isinstance(x,str) for x in ids) and len(set(ids))==len(ids),'invalid case list '+fact['id'])
        need(set(ids)<=set(case_ids),'unknown executable case '+fact['id'])
        need(isinstance(row.get('rationale'),str) and row['rationale'].strip(),'missing mapping rationale '+fact['id'])
        if fact['classification'] not in {'intentionally_excluded','r_only_presentation'}:
            need(ids,'unmapped required or negative case '+fact['id'])
        mapped.update(ids)
    need(mapped==set(case_ids),'executable cases lack source obligations')

def require_frozen_manifest(manifest,root):
    c=manifest.get('source_coverage',{})
    need(c.get('index')==INDEX and c.get('mapping')==MAPPING,'frozen manifest has no source-to-case coverage binding')
    index_path=safe_path(root,INDEX);map_path=safe_path(root,MAPPING)
    index=read_json(index_path);mapping=read_json(map_path)
    need(index==build_index(root),'source census is stale or incomplete')
    need(c.get('index_sha256')==sha(index_path) and c.get('mapping_sha256')==sha(map_path),'source-to-case pins differ')
    cases=manifest.get('executable_case',[])
    ids=[x.get('id') for x in cases]
    need(ids and len(set(ids))==len(ids),'no unique executable cases')
    validate_mapping(mapping,index['facts'],ids)
    review_path=safe_path(root,c.get('scope_review',''))
    need(c.get('scope_review_sha256')==sha(review_path),'scope review bytes are unpinned')
    review=read_json(review_path)
    need(review.get('status')=='ACCEPTED' and review.get('reference_commit')==REFERENCE,'independent scope review missing')
    need(review.get('index_sha256')==sha(index_path) and review.get('mapping_sha256')==sha(map_path),'scope review is stale')
    need(set(review.get('reviewed_domains',[]))==DOMAINS and review.get('unresolved')==[],'unreviewed domains or unresolved source branches')
    review_evidence=safe_path(root,review.get('evidence',''))
    need(review.get('evidence_sha256')==sha(review_evidence),'scope review evidence bytes are unpinned')
    need(isinstance(review.get('reviewer'),str) and review['reviewer'].strip() and
         isinstance(review.get('evidence'),str) and review['evidence'].strip(),'scope review lacks reviewer/evidence')

if __name__=='__main__':
    import argparse,collections
    p=argparse.ArgumentParser();p.add_argument('--write-index',action='store_true');args=p.parse_args()
    root=Path(__file__).resolve().parents[1];index=build_index(root)
    if args.write_index:
        need(not (root/MAPPING).exists(),'do not overwrite an existing reviewed mapping')
        (root/INDEX).write_text(json.dumps(index,indent=2)+'\n')
        mapping=dict(schema=1,status='MAPPING_REQUIRED_NOT_FROZEN',reference_commit=REFERENCE,
          rows=[dict(source_id=f['id'],classification=f['classification'],executable_case_ids=[],
                     rationale=('Approved exclusion recorded by the source inventory; remains reviewable.' if f['classification']=='intentionally_excluded' else 'Executable model/interface or rejection case mapping remains required.')) for f in index['facts']])
        (root/MAPPING).write_text(json.dumps(mapping,indent=2)+'\n')
    else:
        need(read_json(root/INDEX)==index,'saved source index differs from current inputs')
    print(json.dumps(dict(source_facts=len(index['facts']),classification_counts=dict(collections.Counter(x['classification'] for x in index['facts'])),status=index['status'])))
