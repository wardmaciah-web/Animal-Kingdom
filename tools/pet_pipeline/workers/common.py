import argparse, hashlib, json
from pathlib import Path

def context():
    parser=argparse.ArgumentParser();parser.add_argument('--config',required=True)
    path=Path(parser.parse_args().config)
    cfg=json.loads(path.read_text(encoding='utf-8-sig'))
    return cfg,Path(cfg['output_directory']),Path(cfg['runtime_root']),Path(cfg['pipeline_root'])

def write(path,value):
    Path(path).write_text(json.dumps(value,indent=2),encoding='utf-8')

def sha(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()
