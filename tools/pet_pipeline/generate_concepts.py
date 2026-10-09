"""Free local SDXL concept candidates; separate environment, no paid endpoints."""
import argparse,json,os,time
from pathlib import Path
from pet_pipeline import preflight,check_hardware,read,write,sha,HERE

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--config',required=True)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    root=Path(os.environ.get('AK_3D_ROOT','D:/AnimalKingdom3D')).resolve()
    output=Path(args.output).resolve()
    if not output.is_relative_to(root):raise ValueError('Concept output must stay beneath the D runtime')
    if output.exists():raise ValueError('Choose a new concept output directory')
    cfg=read(args.config);policy=read(HERE/'production-policy.json')
    if len(cfg['seeds'])>policy['concept_candidates_per_species']:raise ValueError('Concept retry limit exceeded')
    hardware=preflight(root);check_hardware(hardware)
    output.mkdir(parents=True)
    write(output/'preflight.json',hardware);write(output/'config.json',cfg)
    manifest={'status':'loading','pet_id':cfg['pet_id'],'credits_used':0,'hosted_inference_calls':0,'candidates':[]}
    write(output/'manifest.json',manifest)
    try:
        import torch
        from diffusers import StableDiffusionXLPipeline
        torch.set_num_threads(1)
        weights=root/'tools/SDXL-weights'
        download=read(weights/'download-manifest.json')
        if download['revision']!=cfg['revision']:raise ValueError('Unexpected model revision')
        pipe=StableDiffusionXLPipeline.from_pretrained(str(weights),torch_dtype=torch.float16,
            variant='fp16',use_safetensors=True,local_files_only=True,add_watermarker=False,
            device_map='cuda',low_cpu_mem_usage=True)
        pipe.enable_vae_slicing();pipe.enable_vae_tiling()
        for seed in cfg['seeds']:
            started=time.time()
            result=pipe(prompt=cfg['prompt'],negative_prompt=cfg['negative_prompt'],
                generator=torch.Generator(device='cuda').manual_seed(seed),
                width=cfg['width'],height=cfg['height'],num_inference_steps=cfg['steps'],
                guidance_scale=cfg['guidance_scale']).images[0]
            path=output/f'concept-{seed}.png';result.save(path)
            manifest['candidates'].append({'path':path.name,'seed':seed,'sha256':sha(path),'seconds':time.time()-started,'visual_qa':'pending'})
            write(output/'manifest.json',manifest)
        manifest['status']='concepts_pending_visual_qa'
    except Exception as error:
        manifest.update(status='failed',failure=str(error));write(output/'manifest.json',manifest)
        raise
    write(output/'manifest.json',manifest)

if __name__=='__main__':main()
