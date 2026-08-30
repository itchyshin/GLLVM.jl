import importlib.util, pathlib, subprocess, tempfile
spec=importlib.util.spec_from_file_location('p',pathlib.Path(__file__).with_name('core070_preserve.py'));p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
with tempfile.TemporaryDirectory() as tmp:
 root=pathlib.Path(tmp);repo=root/'repo';repo.mkdir()
 def git(*args,input=None):return subprocess.run(['git','-C',str(repo),*args],input=input,capture_output=True,check=True)
 git('init','-q');git('config','user.name','Fixture');git('config','user.email','fixture@example.invalid')
 (repo/'f').write_text('base\n');git('add','f');git('commit','-qm','fixture')
 hashes=[git('hash-object','-w','--stdin',input=value).stdout.decode().strip() for value in (b'base\n',b'ours\n',b'theirs\n')]
 rows=['0 '+'0'*40+'\tf']+[f'100644 {oid} {i}\tf' for i,oid in enumerate(hashes,1)]
 git('update-index','--index-info',input=('\n'.join(rows)+'\n').encode())
 (repo/'f').write_text('<<<<<<< ours\nours\n=======\ntheirs\n>>>>>>> theirs\n')
 result=p.capture_worktree({'worktree':str(repo)},p.Store(root/'store'))
 print('observed',result['status'])
 assert result['status']=='UNRESOLVED_INDEX_CONFLICT',result['status']
 assert any(x['reason']=='unmerged_index_not_reconstructed' for x in result['unresolved'])
 print('CORE070_CONFLICT_CLASSIFICATION_PASS')
