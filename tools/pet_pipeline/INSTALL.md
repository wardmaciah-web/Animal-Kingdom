# Free pet pipeline environment

The production runtime is separate from the repository. On this machine it is
`E:/AnimalKingdom3D`; pass another root explicitly when relocating it. Keep large
models, caches and run outputs on a drive with free space. The repository contains
the inference source and recipes, not a second copy of the model weights.

The preserved working environments are Python 3.11.17, PyTorch 2.5.1+cu124,
torchvision 0.20.1+cu124 and Blender Python `bpy` 4.5.3. Full installed versions are
recorded in `preserved/inference-environment.txt` and
`preserved/blender-environment.txt`. Do not upgrade the existing environments in
place. Create separate environments for any dependency experiment.

For recovery, create Python 3.11 environments at `tools/deps-stage` and
`tools/blender-env` beneath the runtime root. Install the respective frozen
requirements, using the PyTorch cu124 package index for the CUDA wheels. Restore
`config.yaml` and `model.ckpt` from the pinned stabilityai/TripoSR revision in
`pipeline-lock.json` to `tools/TripoSR-weights`. Verify both SHA256 values before
running. TripoSR source is vendored with its license; the model revision and source
commit are independently pinned. NVIDIA CUDA-capable hardware and an appropriate
driver are required by this preserved production method.

The verified host has an RTX 3060 with 12 GB VRAM and 16 GB installed RAM. The
approved inference loads FP16 weights through memory mapping to avoid Windows
commit pressure. Mesh extraction uses the preserved CPU marching-cubes adapter,
so a local CUDA C++ compiler is unnecessary. Texture baking uses xatlas and
ModernGL; refinement runs in a separate Blender process.

Installation recovery has not yet been tested on a second computer. The existing
environments remain the authoritative working runtime until that test passes.
