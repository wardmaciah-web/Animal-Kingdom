# Animal Kingdom concrete texture requirement

No existing uploaded texture is suitable for the concrete pass.

The audited alternatives are stylized cobble, loose gravel, dirt, sand, grass, or rock surfaces. Using any of them would violate the requested clean, low-contrast concrete style.

Create and upload this source file:

`/Users/jefferypryor/Downloads/RobloxBatches/Textures/AnimalKingdom_StylizedConcreteTile.png`

Required specification:

- 1024 × 1024 PNG
- seamless/tileable on all edges
- neutral medium-gray base near RGB 128, 128, 128
- subtle lighter and darker aggregate flecks
- soft stylized/cartoon finish
- low contrast, matte, clean, and non-photorealistic
- no cracks, stains, directional shadows, borders, text, or metallic highlights

Upload it through the existing Roblox texture pipeline, resolve the Decal container to its underlying Image asset ID, and insert that numeric Image ID into `CONCRETE_IMAGE_ID` in `apply_concrete_texture_v1.lua`.
