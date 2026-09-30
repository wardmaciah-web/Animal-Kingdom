import json, math, pathlib, sys
from collections import defaultdict, Counter
from fbx_audit import nodes, walk

ROOT=pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/Medieval Village Pack-zip')
OUT=pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/MaterialSplitTownAssets')
ASSETS=['Inn.fbx','House_4.fbx','House_2.fbx','Blacksmith.fbx','Well.fbx','MarketStand_1.fbx','MarketStand_2.fbx','Cart.fbx']

ROLE_MAP={
'Inn.fbx':{'Wood':'Timber','Wood_Light':'Timber','Stone_Dark':'Stone','RoofTiles_Red':'Roof','Plaster':'Walls','Stone_Light':'Stone','Windows':'Gold'},
'House_4.fbx':{'Stone_Light':'Walls','Stone_Dark':'Roof','Wood':'Timber','Wood_Side':'Terracotta','Windows':'Gold','Stone':'Stone'},
'House_2.fbx':{'Beige':'Walls','Wood':'Timber','Stone_Dark':'Stone','Windows':'Sage','Wood_Light':'Timber','RoofTiles':'Roof','Stone_Light':'Stone','Wood_Side':'Timber','Stone':'Stone'},
'Blacksmith.fbx':{'Plaster':'Walls','Wood_Light':'Timber','Wood_Side':'Timber','Stone_Light':'Stone','Stone_Dark':'Stone','Wood':'Timber','Windows':'ForgeAccent','RoofTiles_Red':'Roof','Stone':'Stone'},
'Well.fbx':{'Wood':'Wood','Bag':'Wood','RoofTiles_Red':'Roof','Stone_Dark':'Stone','Stone_Light':'Stone'},
'MarketStand_1.fbx':{'Wood':'Wood','RoofTiles_Red':'Canopy','Beige':'Cream','Wood_Side':'Wood'},
'MarketStand_2.fbx':{'Wood':'Wood','RoofTiles_Red':'Canopy','Beige':'Cream'},
'Cart.fbx':{'Wood':'MainWood','Red':'Accent','Beige':'MainWood','DarkWood':'DarkWood','Stone_Dark':'WheelFrame'},
}
COLORS={
'Inn.fbx':{'Walls':(238,218,179),'Timber':(79,55,42),'Roof':(83,82,78),'Stone':(145,139,126),'Sage':(105,145,96),'Gold':(220,177,81)},
'House_4.fbx':{'Walls':(246,232,199),'Timber':(117,78,52),'Roof':(91,78,72),'Stone':(145,139,126),'Terracotta':(170,73,70),'Gold':(220,177,81)},
'House_2.fbx':{'Walls':(238,218,179),'Timber':(117,78,52),'Roof':(144,82,61),'Stone':(145,139,126),'Sage':(105,145,96)},
'Blacksmith.fbx':{'Walls':(213,187,147),'Timber':(79,55,42),'Roof':(68,67,64),'Stone':(145,139,126),'ForgeAccent':(177,91,64)},
'Well.fbx':{'Stone':(161,154,139),'Wood':(117,78,52),'Roof':(83,82,78),'Water':(84,178,200)},
'MarketStand_1.fbx':{'Wood':(117,78,52),'Cream':(238,218,179),'Canopy':(105,145,96)},
'MarketStand_2.fbx':{'Wood':(117,78,52),'Cream':(238,218,179),'Canopy':(170,73,70)},
'Cart.fbx':{'MainWood':(177,123,77),'DarkWood':(117,78,52),'WheelFrame':(79,55,42),'Accent':(177,91,64)},
}
MATERIAL_ENUM={'Walls':'SmoothPlastic','Cream':'SmoothPlastic','Timber':'WoodPlanks','Wood':'WoodPlanks','MainWood':'WoodPlanks','DarkWood':'WoodPlanks','Roof':'Slate','Stone':'Cobblestone','Gold':'Metal','WheelFrame':'WoodPlanks','ForgeAccent':'SmoothPlastic','Terracotta':'SmoothPlastic','Sage':'SmoothPlastic','Canopy':'SmoothPlastic','Accent':'SmoothPlastic'}

def clean(v): return str(v).split('\x00',1)[0]
def arr(node,name):
    c=next((x for x in node['children'] if x['name']==name),None)
    return c['props'][0] if c and c['props'] else []
def props70(node):
    result={}
    p70=next((c for c in node['children'] if c['name']=='Properties70'),None)
    if p70:
        for p in p70['children']:
            if p['name']=='P' and len(p['props'])>=5: result[clean(p['props'][0])]=p['props'][-3:]
    return result
def diffuse(material):
    p=props70(material).get('DiffuseColor',[.5,.5,.5]); return tuple(round(float(v)*255) for v in p)
def fmt(values): return ','.join(f'{v:.9g}' if isinstance(v,float) else str(v) for v in values)
def transformed(pt,rot,scale):
    x,y,z=[pt[i]*scale[i]/100 for i in range(3)]
    rx,ry,rz=[math.radians(v) for v in rot]
    y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
    x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
    x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
    return x,y,z
def bounds(points):
    return [min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]

def ascii_fbx(name,verts,pvis,normals,rotation,scaling,color):
    # Coordinates/normals/polygon topology are copied, never recomputed.
    return f'''; FBX 7.4.0 project file
FBXHeaderExtension:  {{ FBXHeaderVersion: 1003 FBXVersion: 7400 Creator: "Animal Kingdom material splitter" }}
GlobalSettings:  {{ Version: 1000 Properties70:  {{ P: "UpAxis", "int", "Integer", "",1 P: "UpAxisSign", "int", "Integer", "",1 P: "FrontAxis", "int", "Integer", "",2 P: "FrontAxisSign", "int", "Integer", "",-1 P: "CoordAxis", "int", "Integer", "",0 P: "CoordAxisSign", "int", "Integer", "",1 P: "UnitScaleFactor", "double", "Number", "",1 }} }}
Definitions:  {{ Version: 100 Count: 3 ObjectType: "Geometry" {{ Count: 1 }} ObjectType: "Model" {{ Count: 1 }} ObjectType: "Material" {{ Count: 1 }} }}
Objects:  {{
 Geometry: 1000, "Geometry::{name}", "Mesh" {{
  GeometryVersion: 124
  Vertices: *{len(verts)} {{ a: {fmt(verts)} }}
  PolygonVertexIndex: *{len(pvis)} {{ a: {fmt(pvis)} }}
  LayerElementNormal: 0 {{ Version: 101 Name: "" MappingInformationType: "ByPolygonVertex" ReferenceInformationType: "Direct" Normals: *{len(normals)} {{ a: {fmt(normals)} }} }}
  LayerElementMaterial: 0 {{ Version: 101 Name: "" MappingInformationType: "AllSame" ReferenceInformationType: "IndexToDirect" Materials: *1 {{ a: 0 }} }}
  Layer: 0 {{ Version: 100 LayerElement:  {{ Type: "LayerElementNormal" TypedIndex: 0 }} LayerElement:  {{ Type: "LayerElementMaterial" TypedIndex: 0 }} }}
 }}
 Model: 2000, "Model::{name}", "Mesh" {{ Version: 232 Properties70:  {{ P: "Lcl Rotation", "Lcl Rotation", "", "A",{fmt(rotation)} P: "Lcl Scaling", "Lcl Scaling", "", "A",{fmt(scaling)} }} Shading: T Culling: "CullingOff" }}
 Material: 3000, "Material::{name}", "" {{ Version: 102 ShadingModel: "phong" MultiLayer: 0 Properties70:  {{ P: "DiffuseColor", "Color", "", "A",{color[0]/255:.9g},{color[1]/255:.9g},{color[2]/255:.9g} }} }}
}}
Connections:  {{ C: "OO",1000,2000 C: "OO",2000,0 C: "OO",3000,2000 }}
'''

manifest={}
audit=[]
for asset in ASSETS:
    source=next(ROOT.rglob(asset)); _,roots=nodes(source.read_bytes()); flat=list(walk(roots))
    geometry=next(n for n in flat if n['name']=='Geometry'); model=next(n for n in flat if n['name']=='Model')
    vertices=arr(geometry,'Vertices'); pvi=arr(geometry,'PolygonVertexIndex')
    normal_node=next(c for c in geometry['children'] if c['name']=='LayerElementNormal'); normals=arr(normal_node,'Normals')
    material_node=next(c for c in geometry['children'] if c['name']=='LayerElementMaterial'); mat_indices=arr(material_node,'Materials')
    mats={int(n['props'][0]):n for n in flat if n['name']=='Material'}
    model_id=int(model['props'][0]); slots=[]
    for n in flat:
        if n['name']=='C' and len(n['props'])>=3 and clean(n['props'][0])=='OO' and int(n['props'][2])==model_id and int(n['props'][1]) in mats:
            slots.append(mats[int(n['props'][1])])
    polys=[]; cursor=[]; corner=0
    for raw in pvi:
        cursor.append(((-raw-1) if raw<0 else raw,corner)); corner+=1
        if raw<0: polys.append(cursor); cursor=[]
    if len(polys)!=len(mat_indices): raise RuntimeError(f'{asset}: polygon/material count mismatch')
    role_polys=defaultdict(list); role_materials=defaultdict(set)
    for pi,poly in enumerate(polys):
        idx=mat_indices[pi]
        if idx<0 or idx>=len(slots): raise RuntimeError(f'{asset}: material slot {idx} out of range {len(slots)}')
        mat_name=clean(slots[idx]['props'][1]); role=ROLE_MAP[asset].get(mat_name)
        if not role: raise RuntimeError(f'{asset}: unmapped material {mat_name}')
        role_polys[role].append((pi,poly)); role_materials[role].add(mat_name)
    outdir=OUT/source.stem; outdir.mkdir(parents=True,exist_ok=True)
    rawpoints=list(zip(vertices[0::3],vertices[1::3],vertices[2::3])); mp=props70(model)
    rotation=tuple(float(x) for x in mp.get('Lcl Rotation',[0,0,0])); scaling=tuple(float(x) for x in mp.get('Lcl Scaling',[100,100,100]))
    transformed_source=[transformed(p,rotation,scaling) for p in rawpoints]; sbmin,sbmax=bounds(transformed_source)
    piece_records=[]; covered=[]
    for role,selected in sorted(role_polys.items()):
        used=[]; seen=set()
        for _,poly in selected:
            for vi,_ in poly:
                if vi not in seen:seen.add(vi);used.append(vi)
        remap={old:i for i,old in enumerate(used)}; outverts=[]
        for old in used: outverts.extend(rawpoints[old])
        outpvi=[]; outnorm=[]
        for pi,poly in selected:
            covered.append(pi)
            for j,(old,corner_index) in enumerate(poly):
                new=remap[old]; outpvi.append(-new-1 if j==len(poly)-1 else new)
                outnorm.extend(normals[corner_index*3:corner_index*3+3])
        filename=f'{source.stem}_{role}.fbx'; path=outdir/filename
        path.write_text(ascii_fbx(f'{source.stem}_{role}',outverts,outpvi,outnorm,rotation,scaling,COLORS[asset][role]),encoding='utf-8')
        piecepts=[transformed(rawpoints[i],rotation,scaling) for i in used]; pmin,pmax=bounds(piecepts)
        piece_records.append({'role':role,'file':str(path),'materials':sorted(role_materials[role]),'color':COLORS[asset][role],'robloxMaterial':MATERIAL_ENUM[role], 'faces':len(selected),'vertices':len(used),'boundsMin':pmin,'boundsMax':pmax})
    counts=Counter(covered); missing=[i for i in range(len(polys)) if counts[i]==0]; dup=[i for i,c in counts.items() if c!=1]
    cbmin=[min(p['boundsMin'][i] for p in piece_records) for i in range(3)];cbmax=[max(p['boundsMax'][i] for p in piece_records) for i in range(3)]
    diff=max(abs(sbmin[i]-cbmin[i]) for i in range(3))+max(abs(sbmax[i]-cbmax[i]) for i in range(3))
    if missing or dup or diff>1e-6: raise RuntimeError(f'{asset}: verification failed missing={len(missing)} dup={len(dup)} bounds={diff}')
    manifest[asset]={'source':str(source),'sourceFaces':len(polys),'sourceVertices':len(rawpoints),'sourceBoundsMin':sbmin,'sourceBoundsMax':sbmax,'rotation':rotation,'scaling':scaling,'pieces':piece_records}
    audit.append({'asset':asset,'sourceFaces':len(polys),'splitFacesTotal':sum(p['faces'] for p in piece_records),'unassignedFaces':len(missing),'duplicateFaces':len(dup),'sourceBounds':[sbmin,sbmax],'combinedBounds':[cbmin,cbmax],'boundsDifference':diff,'pieces':len(piece_records)})
(OUT/'material_split_manifest.json').write_text(json.dumps(manifest,indent=2))
pathlib.Path('town_material_split_audit.json').write_text(json.dumps(audit,indent=2))
print(json.dumps({'assets':len(manifest),'pieces':sum(len(v['pieces']) for v in manifest.values()),'audit':audit},indent=2))
