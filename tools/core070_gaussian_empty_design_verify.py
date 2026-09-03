"""Verify empty Gaussian design regression and its preserved integration evidence."""
import argparse,re,json
from core070_verify_link_boundaries import ROOT,process,sha
from core070_aghq_binomial_verify import current
import core070_aghq_public_gaussian_verify as gu
BASE=ROOT/'.unlazy/core070-aghq'

def verify():
    rootred=BASE/'gaussian-empty-root-red-01'
    assert sha(rootred/'confint_profile.jl')==json.loads((rootred/'source-pins.json').read_text())['src/confint_profile.jl']
    assert '1 passed, 2 failed' in (rootred/'output.log').read_text()
    _,_,red=process(BASE/'gaussian-empty-red-01',False,1)
    assert 'zero(::Type{Any})' in red
    _,_,bad=process(BASE/'gaussian-empty-green-01',False,1)
    assert re.search(r'GE Gaussian empty design\s*\|\s*22\s+2\s+24',bad)
    _,_,profilebad=process(BASE/'gaussian-empty-profile-red-01',False,1)
    assert re.search(r'GE Gaussian empty design\s*\|\s*24\s+2\s+26',profilebad)
    p,_,log=process(BASE/'gaussian-empty-green-03',False,0)
    for name in ('src/profile.jl','src/confint.jl','src/confint_profile.jl','test/test_gaussian_empty_design.jl','test/test_profile_failure_bounds.jl'):
        assert p['pins'][name]==sha(ROOT/name)
    assert p['commands'][1]['argv'][-1]=='tools/core070_gaussian_empty_design_run.jl'
    assert re.search(r'GE Gaussian empty design\s*\|\s*26\s+26',log)
    gu.STATE=BASE/'gaussian-empty-integrated-01'
    gu.DOCS=BASE/'gaussian-empty-docs-01'
    gu.kernel();gu.docs_verify()
    integrated,_,final=process(gu.STATE,False,0);current(integrated)
    assert integrated['pins']['test/test_gaussian_empty_design.jl']==p['pins']['test/test_gaussian_empty_design.jl']
    assert re.search(r'GE Gaussian empty design\s*\|\s*26\s+26',final)
    assert re.search(r'GE profile failure bounds\s*\|\s*4\s+4',final)
    assert re.search(r'Profile CI root-finder \(fast false-position\)\s*\|\s*9\s+9',final)
    print('CORE070_GAUSSIAN_EMPTY_DESIGN_VERIFIED')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--pair',action='store_true');args=ap.parse_args()
    verify()
    if args.pair:
        gu.PAIR=BASE/'gaussian-empty-pair-01';gu.pair();gu.negatives()
        print('CORE070_GAUSSIAN_EMPTY_DESIGN_PAIR_VERIFIED')
