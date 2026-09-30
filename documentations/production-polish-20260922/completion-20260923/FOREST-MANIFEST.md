# Verified Forest import manifest

All eleven entries were found in the user’s **My Models**, inserted into the verified testing place, visually identified, and registered as real imported meshes. Original import names and pivots are preserved in the JSON manifest and the live `ServerStorage.ForestImportArchive`. Each canonical model is stored locally as a Rojo `.rbxmx` asset.

| PetTypeId / display name | Canonical path | My Models asset ID | MeshParts | MeshId | TextureID | Ready |
| --- | --- | --- | ---: | --- | --- | --- |
| ForestRaccoon / Raccoon | `ReplicatedStorage.PetAssets.ForestRaccoon` | 85734355315305 | 1 | rbxassetid://97924899190875 | rbxassetid://129022509074285 | Yes |
| ForestBlackBearCub / Black Bear Cub | `ReplicatedStorage.PetAssets.ForestBlackBearCub` | 134079974891290 | 1 | rbxassetid://131926612358052 | rbxassetid://95294656364429 | Yes |
| ForestSkunk / Skunk | `ReplicatedStorage.PetAssets.ForestSkunk` | 103074281827139 | 1 | rbxassetid://94866246199758 | rbxassetid://119398526295183 | Yes |
| ForestBadger / Badger | `ReplicatedStorage.PetAssets.ForestBadger` | 114016759553112 | 1 | rbxassetid://130215170262976 | rbxassetid://135911004193278 | Yes |
| ForestTreeFrog / Tree Frog | `ReplicatedStorage.PetAssets.ForestTreeFrog` | 127911896145490 | 1 | rbxassetid://126806763850171 | rbxassetid://133597800956686 | Yes |
| ForestRiverOtter / River Otter | `ReplicatedStorage.PetAssets.ForestRiverOtter` | 76913333675834 | 1 | rbxassetid://125023493018070 | rbxassetid://131616920065617 | Yes |
| ForestBrownBat / Brown Bat | `ReplicatedStorage.PetAssets.ForestBrownBat` | 122381922150314 | 1 | rbxassetid://106744044776841 | rbxassetid://84452625990128 | Yes |
| ForestWoodlandOwl / Woodland Owl | `ReplicatedStorage.PetAssets.ForestWoodlandOwl` | 120411588642627 | 1 | rbxassetid://95294648810339 | rbxassetid://102420541096782 | Yes |
| ForestCrestedOwl / Crested Owl | `ReplicatedStorage.PetAssets.ForestCrestedOwl` | 90100153950093 | 1 | rbxassetid://82138478193574 | rbxassetid://126502584357511 | Yes |
| ForestLeafAntler / Leaf-Antler Guardian | `ReplicatedStorage.PetAssets.ForestLeafAntler` | 112384650584330 | 1 | rbxassetid://111837749719637 | rbxassetid://123865829385359 | Yes |
| ForestEmeraldWing / Emerald-Wing Guardian | `ReplicatedStorage.PetAssets.ForestEmeraldWing` | 80671057535524 | 1 | rbxassetid://89750756176673 | rbxassetid://73081746031370 | Yes |

All eleven use one textured MeshPart, with no SurfaceAppearance in these particular source imports. MeshPart color, material and TextureID are preserved. The generic path also preserves SurfaceAppearance when present, including the existing Meadow PBR models. Orientation normalization is `ModelRotation = -90` in the Forest definitions; canonical source mesh orientation is unchanged.

## Archived imports

| PetTypeId | Current original-import path |
| --- | --- |
| ForestRaccoon | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_663443bd_ROBLOX_READY` |
| ForestBlackBearCub | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_fca34df2_ROBLOX_READY` |
| ForestSkunk | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_34254bc8_ROBLOX_READY` |
| ForestBadger | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_7603cf3a_ROBLOX_READY` |
| ForestTreeFrog | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_f8e98947_ROBLOX_READY` |
| ForestRiverOtter | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_35be4ffb_ROBLOX_READY` |
| ForestBrownBat | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_a167f18d_ROBLOX_READY` |
| ForestWoodlandOwl | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_237a53a2_ROBLOX_READY` |
| ForestCrestedOwl | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_58c6a281_ROBLOX_READY` |
| ForestLeafAntler | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_e23de4f2_ROBLOX_READY` |
| ForestEmeraldWing | `ServerStorage.ForestImportArchive.ChatGPT_Image_Sep_21_20...31_06acbd90_ROBLOX_READY` |

[Full measured bounds, sizes, source pivots, texture references and verification contexts](forest-model-manifest.json).
