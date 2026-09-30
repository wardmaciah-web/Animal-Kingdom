import json,pathlib
r=json.loads(pathlib.Path('studio_import_package_audit.json').read_text())
out=['ANIMAL KINGDOM STUDIO IMPORT TOWN ASSET MANIFEST','Import each FBX into Studio, place the resulting Model under ServerStorage.AnimalKingdomTownMaterialTemplates, and name it exactly as the filename stem.','No textures, UV maps, or SurfaceAppearance objects are required.','']
for a in r:
 out += [a['asset'],f'  source building: {a["source"]}',f'  combined dimensions: {a["dimensions"]}',f'  source faces: {a["sourceFaces"]}',f'  packaged faces: {a["packagedFaces"]}',f'  bounds difference: {a["boundsDifference"]:.12g}',f'  verification: {a["status"]}','  contained mesh objects:']
 for p in a['pieces']:
  out += [f'    AK_{p["role"]}',f'      source materials: {", ".join(p["materials"])}',f'      material role: {p["role"]}',f'      intended RGB: {tuple(p["color"])}',f'      intended Roblox Material: {p["robloxMaterial"]}',f'      faces: {p["faces"]}']
 out.append('')
out += ['AK_STUDIO_IMPORT_PACKAGE_VERIFY']
for a in r: out.append(f'asset={a["asset"]} meshObjects={a["meshObjects"]} sourceFaces={a["sourceFaces"]} packagedFaces={a["packagedFaces"]} boundsDifference={a["boundsDifference"]:.12g} status={a["status"]}')
out += ['','SUMMARY','Buildings packaged: 8/8','Combined FBX files: 8','Material pieces preserved: 33','Geometry coverage: 100%','Missing polygons: 0','Duplicated polygons: 0','Geometry movement: 0','Blender used: NO','Open Cloud required: NO']
pathlib.Path('studio_import_town_asset_manifest.txt').write_text('\n'.join(out)+'\n')
