import copy, unittest
import core070_aghq_case_plan as plan

class AGHQCasePlan(unittest.TestCase):
    def test_complete_source_binding(self):
        data=plan.build();plan.validate(data)
        self.assertEqual(len(data['source_rows']),39)
        self.assertEqual(len(data['paired_control_cases']),16)
        self.assertTrue(all(not x['executable_case_ids'] for x in data['source_rows']))
    def test_omitted_fact_rejected(self):
        data=plan.build();data['source_rows'].pop()
        with self.assertRaises(ValueError):plan.validate(data)
    def test_stale_source_rejected(self):
        data=plan.build();data['source_pins']['R/fit-multi.R']='0'*64
        with self.assertRaises(ValueError):plan.validate(data)
    def test_helper_cannot_satisfy_public_fit(self):
        data=plan.build();data['public_obligations'][0]['acceptance_level']='paired_control'
        with self.assertRaises(ValueError):plan.validate(data)
    def test_missing_call_rejected(self):
        data=plan.build();data['paired_control_cases'][0]['julia_call']=''
        with self.assertRaises(ValueError):plan.validate(data)
    def test_changed_fixture_rejected(self):
        data=plan.build();data['paired_control_cases'][0]['fixture_sha256']='0'*64
        with self.assertRaises(ValueError):plan.validate(data)
    def test_no_unpaid_promotion(self):
        data=plan.build();data['source_rows'][0]['executable_case_ids']=['FAKE']
        with self.assertRaises(ValueError):plan.validate(data)

    def test_public_obligation_cannot_disappear_at_freeze(self):
        manifest={'source_coverage':{'aghq_annex':plan.PLAN,'aghq_annex_sha256':plan.sha(plan.ROOT/plan.PLAN)},'executable_case':[]}
        with self.assertRaisesRegex(ValueError,'unbound required AGHQ case'):
            plan.require_frozen_aghq(manifest,plan.ROOT)

    def test_native_process_corruptions(self):
        import json, shutil, tempfile
        from pathlib import Path
        from unittest.mock import patch
        plan.verify_evidence()  # Positive control before destructive copies.
        for defect in ['nonzero','missing-receipt','dropped-dependency','stale-plan','forged-output']:
            with self.subTest(defect=defect), tempfile.TemporaryDirectory() as folder:
                tmp=Path(folder)
                shutil.copy2(plan.NATIVE/'plan.json',tmp/'plan.json')
                shutil.copytree(plan.NATIVE/'attempt1',tmp/'attempt1')
                process_path=tmp/'attempt1/process/process-receipt.json'
                process=json.loads(process_path.read_text())
                if defect=='nonzero':
                    process['results'][0]['exit_code']=7;process_path.write_text(json.dumps(process))
                elif defect=='missing-receipt':(tmp/'attempt1/controls.toml').unlink()
                elif defect=='forged-output':
                    path=tmp/'attempt1/controls.toml';path.write_text(path.read_text()+'\n# forged\n')
                elif defect=='stale-plan':(tmp/'plan.json').write_text('{}')
                else:
                    path=tmp/'plan.json';data=json.loads(path.read_text());data['pins'].pop('Project.toml')
                    path.write_text(json.dumps(data));shutil.copy2(path,tmp/'attempt1/process/execution-plan.json')
                    process['plan_sha256']=plan.sha(path);process['source_pins']=data['pins'];process_path.write_text(json.dumps(process))
                with patch.object(plan,'NATIVE',tmp),self.assertRaises((ValueError,OSError)):
                    plan.verify_evidence()

    def test_central_freeze_invokes_aghq_contract(self):
        import json,tempfile
        from pathlib import Path
        from unittest.mock import patch
        c=plan.coverage
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/c.PREFIX).mkdir(parents=True)
            index={'facts':[{'id':'aghq/AGHQ-CTRL-FALSE','classification':'required_core'}]}
            mapping={'reference_commit':c.REFERENCE,'rows':[{'source_id':'aghq/AGHQ-CTRL-FALSE','classification':'required_core','executable_case_ids':['helper'],'rationale':'helper only'}]}
            (root/c.INDEX).write_text(json.dumps(index));(root/c.MAPPING).write_text(json.dumps(mapping))
            manifest={'executable_case':[{'id':'helper'}],'source_coverage':{'index':c.INDEX,'mapping':c.MAPPING,'index_sha256':c.sha(root/c.INDEX),'mapping_sha256':c.sha(root/c.MAPPING)}}
            with patch.object(c,'build_index',return_value=index),patch.object(plan,'require_frozen_aghq',side_effect=ValueError('AGHQ public obligations missing')):
                with self.assertRaisesRegex(c.CoverageError,'AGHQ public obligations missing'):
                    c.require_frozen_manifest(manifest,root)

    def test_synthetic_full_contract_then_helper_and_interface_deletion(self):
        # Structural positive control only: these are NOT programme model cases.
        data=plan.build();cases=[]
        for obligation in data['public_obligations']+data['family_obligations']:
            for interface in obligation['interfaces']:
                cases.append(dict(id=obligation['id']+'-'+interface.upper().replace('_','-'),
                    acceptance_level='paired_estimator' if interface=='numerical_kernel' else 'paired_fit_interface',
                    model_contract_id=obligation['id'],r_call='synthetic R fit',julia_call='synthetic Julia fit',
                    acceptance_rule='synthetic mechanism test',fixture=plan.FIXTURE,
                    aghq_obligation_ids=[obligation['id']]))
        manifest={'source_coverage':{'aghq_annex':plan.PLAN,'aghq_annex_sha256':plan.sha(plan.ROOT/plan.PLAN)},'executable_case':cases}
        plan.require_frozen_aghq(manifest,plan.ROOT)
        bad=copy.deepcopy(manifest);bad['executable_case'][0]['acceptance_level']='paired_control'
        with self.assertRaisesRegex(ValueError,'helper cannot satisfy'):plan.require_frozen_aghq(bad,plan.ROOT)
        bad=copy.deepcopy(manifest);bad['executable_case'].pop()
        with self.assertRaisesRegex(ValueError,'unbound required'):plan.require_frozen_aghq(bad,plan.ROOT)
