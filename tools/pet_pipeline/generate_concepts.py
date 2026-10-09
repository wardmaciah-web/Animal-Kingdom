"""Free local SDXL concept candidates; separate environment, no paid endpoints."""
import argparse,json,os,time,gc,faulthandler
from pathlib import Path
from pet_pipeline import preflight,check_hardware,read,write,sha,HERE

def main():
    faulthandler.enable()
    parser=argparse.ArgumentParser()
    parser.add_argument('--config',required=True)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    root=Path(os.environ.get('AK_3D_ROOT','D:/AnimalKingdom3D')).resolve()
    output=Path(args.output).resolve()
    if not output.is_relative_to(root):raise ValueError('Concept output must stay beneath the D runtime')
    if output.exists():raise ValueError('Choose a new concept output directory')
    cfg=read(args.config);policy=read(HERE/'production-policy.json')
    references=[(Path(args.config).resolve().parent/p).resolve() for p in cfg.get('style_references',[])]
    mandatory={(HERE/'references/bear-front.jpg').resolve(),(HERE/'references/approved-ocelot-front.png').resolve()}
    if not mandatory.issubset(references) or not all(p.is_file() for p in references):
        raise ValueError('Original black bear and approved Ocelot references are mandatory')
    if len(cfg['seeds'])>policy['concept_candidates_per_species']:raise ValueError('Concept retry limit exceeded')
    hardware=preflight(root);check_hardware(hardware)
    output.mkdir(parents=True)
    write(output/'preflight.json',hardware);write(output/'config.json',cfg)
    manifest={'status':'loading','pet_id':cfg['pet_id'],'credits_used':0,'hosted_inference_calls':0,'candidates':[]}
    manifest['style_references']={str(p):sha(p) for p in references}
    write(output/'manifest.json',manifest)
    try:
        import torch
        print('Loading local SDXL dependencies',flush=True)
        from diffusers import StableDiffusionXLPipeline,StableDiffusionXLImg2ImgPipeline
        from PIL import Image
        import diffusers.models.model_loading_utils as loading
        import diffusers.models.modeling_utils as modeling
        torch.set_num_threads(1)
        # Keep FP16 checkpoint conversions off this machine's failing CPU copy
        # path. Meta shape probes stay meta; real safetensors load onto CUDA.
        original_load=loading.load_state_dict
        def cuda_checkpoint_load(checkpoint_file,*positional,**keywords):
            if str(checkpoint_file).endswith('.safetensors') and str(keywords.get('map_location','cpu'))=='cpu':
                keywords['map_location']='cuda:0'
            return original_load(checkpoint_file,*positional,**keywords)
        loading.load_state_dict=cuda_checkpoint_load
        modeling.load_state_dict=cuda_checkpoint_load
        weights=root/'tools/SDXL-weights'
        download=read(weights/'download-manifest.json')
        if download['revision']!=cfg['revision']:raise ValueError('Unexpected model revision')
        pipeline_class=StableDiffusionXLImg2ImgPipeline if cfg.get('design_reference_image') else StableDiffusionXLPipeline
        pipe=pipeline_class.from_pretrained(str(weights),torch_dtype=torch.float16,
            variant='fp16',use_safetensors=True,local_files_only=True,add_watermarker=False,
            device_map='cuda',low_cpu_mem_usage=True)
        pipe.enable_vae_slicing();pipe.enable_vae_tiling()
        for tokenizer in (pipe.tokenizer,pipe.tokenizer_2):
            for label in ('prompt','negative_prompt'):
                if len(tokenizer(cfg[label]).input_ids)>tokenizer.model_max_length:
                    raise ValueError(f'{label} exceeds tokenizer limit; shorten it instead of silently losing anatomy/style instructions')
        manifest['status']='encoding_prompt';write(output/'manifest.json',manifest)
        # All three candidates share text; release encoders after embedding so
        # their GPU allocation is available for 1024px denoising and decoding.
        with torch.inference_mode():
            embeddings=pipe.encode_prompt(prompt=cfg['prompt'],negative_prompt=cfg['negative_prompt'],device='cuda')
        pipe.text_encoder=None;pipe.text_encoder_2=None
        gc.collect();torch.cuda.empty_cache()
        design_args={'width':cfg['width'],'height':cfg['height']}
        if cfg.get('design_reference_image'):
            reference=(Path(args.config).resolve().parent/cfg['design_reference_image']).resolve()
            design_args={'image':Image.open(reference).convert('RGB').resize((cfg['width'],cfg['height'])),
                         'strength':cfg.get('design_strength',.7)}
            manifest['design_reference']={'path':str(reference),'sha256':sha(reference),
                                          'strength':design_args['strength']}
        for seed in cfg['seeds']:
            manifest.update(status='generating',active_seed=seed);write(output/'manifest.json',manifest)
            started=time.time()
            result=pipe(prompt_embeds=embeddings[0],negative_prompt_embeds=embeddings[1],
                pooled_prompt_embeds=embeddings[2],negative_pooled_prompt_embeds=embeddings[3],
                generator=torch.Generator(device='cuda').manual_seed(seed),
                **design_args,num_inference_steps=cfg['steps'],
                guidance_scale=cfg['guidance_scale']).images[0]
            path=output/f'concept-{seed}.png';result.save(path)
            manifest['candidates'].append({'path':path.name,'seed':seed,'sha256':sha(path),'seconds':time.time()-started,'visual_qa':'pending'})
            write(output/'manifest.json',manifest)
            result.close();del result
            gc.collect();torch.cuda.empty_cache()
        manifest['status']='concepts_pending_visual_qa'
    except Exception as error:
        manifest.update(status='failed',failure=str(error));write(output/'manifest.json',manifest)
        raise
    write(output/'manifest.json',manifest)

if __name__=='__main__':main()
