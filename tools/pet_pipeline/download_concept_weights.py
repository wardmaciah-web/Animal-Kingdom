"""Download pinned public SDXL files to D; no hosted inference or credentials."""
import hashlib,json,os,urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

ROOT=Path(os.environ.get('AK_3D_ROOT','D:/AnimalKingdom3D'))
REPO='stabilityai/stable-diffusion-xl-base-1.0'
REVISION='462165984030d82259a11f4367a4eed129e94a7b'
destination=ROOT/'tools/SDXL-weights'
destination.mkdir(exist_ok=True)
metadata=json.load(urllib.request.urlopen(f'https://huggingface.co/api/models/{REPO}/revision/{REVISION}?blobs=true'))
records=[]
prefixes=('text_encoder/','text_encoder_2/','tokenizer/','tokenizer_2/','unet/','vae/','scheduler/')
for entry in metadata['siblings']:
    name=entry['rfilename']
    if not (name in ('LICENSE.md','README.md','model_index.json') or
            (name.startswith(prefixes) and (name.endswith(('.json','.txt')) or name.endswith('.fp16.safetensors')))):
        continue
    path=destination/name;path.parent.mkdir(parents=True,exist_ok=True)
    expected=entry.get('lfs',{}).get('sha256')
    if path.exists() and (not expected or hashlib.file_digest(path.open('rb'),'sha256').hexdigest()==expected):
        print('Preserved',name,flush=True)
    else:
        print('Downloading',name,entry.get('size'),flush=True)
        temporary=path.with_suffix(path.suffix+'.partial')
        url=f'https://huggingface.co/{REPO}/resolve/{REVISION}/{name}'
        size=entry.get('size',0)
        if size>256*1024*1024:
            # Bounded range requests avoid stalled multi-GB CDN streams.
            chunk_size=16*1024*1024
            with temporary.open('wb') as target:target.truncate(size)
            def download_range(start):
                end=min(start+chunk_size,size)-1
                request=urllib.request.Request(url,headers={'Range':f'bytes={start}-{end}'})
                with urllib.request.urlopen(request,timeout=45) as source,temporary.open('r+b') as target:
                    if source.status!=206 or source.headers.get('Content-Range')!=f'bytes {start}-{end}/{size}':
                        raise RuntimeError('Server did not honor requested byte range')
                    target.seek(start);remaining=end-start+1
                    while remaining:
                        block=source.read(min(65536,remaining))
                        if not block:raise RuntimeError('Incomplete model range')
                        target.write(block);remaining-=len(block)
                return end-start+1
            with ThreadPoolExecutor(max_workers=4) as executor:
                completed=0
                for count in executor.map(download_range,range(0,size,chunk_size)):
                    completed+=count
                    if completed%(256*1024*1024)==0:print('Verified transfer progress',name,completed,size,flush=True)
        else:
            with urllib.request.urlopen(url,timeout=45) as source,temporary.open('wb') as target:
                while block:=source.read(65536):target.write(block)
        actual=hashlib.file_digest(temporary.open('rb'),'sha256').hexdigest()
        if expected and actual!=expected:raise RuntimeError(f'Hash mismatch: {name}')
        temporary.replace(path)
    records.append({'path':name,'bytes':path.stat().st_size,'sha256':hashlib.file_digest(path.open('rb'),'sha256').hexdigest()})
(destination/'download-manifest.json').write_text(json.dumps({'repository':REPO,'revision':REVISION,'files':records,'hosted_inference_calls':0},indent=2))
print('Download and verification complete',flush=True)
