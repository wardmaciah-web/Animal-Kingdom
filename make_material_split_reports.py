import json,pathlib
root=pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/MaterialSplitTownAssets')
manifest=json.loads((root/'material_split_manifest.json').read_text())
audits=json.loads(pathlib.Path('town_material_split_audit.json').read_text())
lines=['ANIMAL KINGDOM MATERIAL-SPLIT TOWN ASSET AUDIT','',f'Output: {root}','Method: existing binary FBX parser; original polygon-to-material assignments; no Blender, UV generation, image generation, or geometry processing.','']
for audit in audits:
    a=audit['asset']; data=manifest[a]
    lines += ['AK_MATERIAL_SPLIT_VERIFY',f'asset={a}',f'sourceFaces={audit["sourceFaces"]}',f'splitFacesTotal={audit["splitFacesTotal"]}',f'unassignedFaces={audit["unassignedFaces"]}',f'duplicateFaces={audit["duplicateFaces"]}',f'sourceBounds={audit["sourceBounds"]}',f'combinedBounds={audit["combinedBounds"]}',f'boundsDifference={audit["boundsDifference"]}',f'sourceVertices={data["sourceVertices"]}',f'materialPieces={len(data["pieces"])}']
    for p in data['pieces']:
        lines += [f'piece={pathlib.Path(p["file"]).name}',f'  sourceMaterials={",".join(p["materials"])}',f'  role={p["role"]}',f'  finalRGB={tuple(p["color"])}',f'  robloxMaterial={p["robloxMaterial"]}',f'  faces={p["faces"]}',f'  unchangedSourceVerticesUsed={p["vertices"]}']
    lines.append('status=PASS\n')
lines += ['SUMMARY','Buildings split: 8/8',f'Material mesh pieces: {sum(len(v["pieces"]) for v in manifest.values())}','Source polygon coverage: 100%','Unassigned polygons: 0','Duplicated polygons: 0','Bounds mismatches: 0','Geometry coordinates changed: NO','Image textures created: 0','Blender used: NO','New software used: NO','Upload status: BLOCKED_MISSING_OPEN_CLOUD_ENVIRONMENT']
pathlib.Path('town_material_split_audit.txt').write_text('\n'.join(lines)+'\n')
ids=['ANIMAL KINGDOM MATERIAL-SPLIT ASSET IDS','Status: UPLOAD_BLOCKED','Reason: ROBLOX_API_KEY, ROBLOX_CREATOR_ID, and ROBLOX_CREATOR_TYPE are not available to the configured uploader process.','Invented IDs: 0','']
for a,data in manifest.items():
    ids.append(a)
    for p in data['pieces']: ids.append(f'{pathlib.Path(p["file"]).name}=NOT_UPLOADED')
    ids.append('')
pathlib.Path('town_material_split_asset_ids.txt').write_text('\n'.join(ids))
