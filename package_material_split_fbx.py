import json, pathlib, re, math

SPLIT=pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/MaterialSplitTownAssets')
OUT=pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/StudioImportTownAssets')
MANIFEST=json.loads((SPLIT/'material_split_manifest.json').read_text())
NAMES={'Inn.fbx':'TradingHall_MaterialSplit','House_4.fbx':'Rewards_MaterialSplit','House_2.fbx':'GeneralStore_MaterialSplit','Blacksmith.fbx':'Blacksmith_MaterialSplit','Well.fbx':'Well_MaterialSplit','MarketStand_1.fbx':'MarketStand1_MaterialSplit','MarketStand_2.fbx':'MarketStand2_MaterialSplit','Cart.fbx':'Cart_MaterialSplit'}

def block(text, marker):
    start=text.index(marker); brace=text.index('{',start); depth=0
    for i in range(brace,len(text)):
        if text[i]=='{': depth+=1
        elif text[i]=='}':
            depth-=1
            if depth==0:return text[start:i+1]
    raise ValueError(marker)
def numbers(text,label):
    m=re.search(r'\b'+re.escape(label)+r':\s*\*\d+\s*\{\s*a:\s*([^}]*)}',text,re.S)
    if not m:return []
    return [float(x) for x in m.group(1).split(',') if x.strip()]
def transformed(pt,rot,scale):
    x,y,z=[pt[i]*scale[i]/100 for i in range(3)];rx,ry,rz=map(math.radians,rot)
    y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
    x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
    x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
    return x,y,z
def bounds(points):return [min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]

OUT.mkdir(parents=True,exist_ok=True)
reports=[]
for source,data in MANIFEST.items():
    package=NAMES[source]; objects=[];connections=[]
    for index,piece in enumerate(data['pieces'],1):
        text=pathlib.Path(piece['file']).read_text()
        semantic='AK_'+piece['role']
        g=block(text,'Geometry: 1000').replace('Geometry: 1000',f'Geometry: {1000+index}').replace('Geometry::'+pathlib.Path(piece['file']).stem,'Geometry::'+semantic)
        m=block(text,'Model: 2000').replace('Model: 2000',f'Model: {2000+index}').replace('Model::'+pathlib.Path(piece['file']).stem,'Model::'+semantic)
        mat=block(text,'Material: 3000').replace('Material: 3000',f'Material: {3000+index}').replace('Material::'+pathlib.Path(piece['file']).stem,'Material::'+semantic)
        objects += [g,m,mat]
        connections += [f'C: "OO",{1000+index},{2000+index}',f'C: "OO",{2000+index},0',f'C: "OO",{3000+index},{2000+index}']
    out='''; FBX 7.4.0 project file
FBXHeaderExtension:  { FBXHeaderVersion: 1003 FBXVersion: 7400 Creator: "Animal Kingdom material package" }
GlobalSettings:  { Version: 1000 Properties70:  { P: "UpAxis", "int", "Integer", "",1 P: "UpAxisSign", "int", "Integer", "",1 P: "FrontAxis", "int", "Integer", "",2 P: "FrontAxisSign", "int", "Integer", "",-1 P: "CoordAxis", "int", "Integer", "",0 P: "CoordAxisSign", "int", "Integer", "",1 P: "UnitScaleFactor", "double", "Number", "",1 } }
Definitions:  { Version: 100 Count: %d ObjectType: "Geometry" { Count: %d } ObjectType: "Model" { Count: %d } ObjectType: "Material" { Count: %d } }
Objects:  {
%s
}
Connections:  { %s }
'''%(len(objects),len(data['pieces']),len(data['pieces']),len(data['pieces']),'\n'.join(objects),' '.join(connections))
    path=OUT/(package+'.fbx');path.write_text(out)
    # Reparse the packaged arrays, ensuring packaging—not the prior manifest—is verified.
    packaged=path.read_text(); geometry_blocks=[]; cursor=0
    while True:
        try: start=packaged.index('Geometry: ',cursor)
        except ValueError: break
        geometry_blocks.append(block(packaged[start:],'Geometry: '));cursor=start+len(geometry_blocks[-1])
    face_total=0;allpoints=[]
    for gb in geometry_blocks:
        verts=numbers(gb,'Vertices');pvi=numbers(gb,'PolygonVertexIndex');face_total+=sum(1 for x in pvi if x<0)
        raw=list(zip(verts[0::3],verts[1::3],verts[2::3]));allpoints += [transformed(p,data['rotation'],data['scaling']) for p in raw]
    bmin,bmax=bounds(allpoints); expected_min=data['sourceBoundsMin'];expected_max=data['sourceBoundsMax']
    difference=max([abs(bmin[i]-expected_min[i]) for i in range(3)]+[abs(bmax[i]-expected_max[i]) for i in range(3)])
    status='PASS' if len(geometry_blocks)==len(data['pieces']) and face_total==data['sourceFaces'] and difference<1e-6 else 'FAIL'
    reports.append({'asset':package+'.fbx','source':source,'meshObjects':len(geometry_blocks),'sourceFaces':data['sourceFaces'],'packagedFaces':face_total,'boundsDifference':difference,'status':status,'dimensions':[expected_max[i]-expected_min[i] for i in range(3)],'pieces':data['pieces']})
if any(r['status']!='PASS' for r in reports):raise SystemExit(json.dumps(reports,indent=2))
pathlib.Path('studio_import_package_audit.json').write_text(json.dumps(reports,indent=2))
print(json.dumps({'files':len(reports),'pieces':sum(r['meshObjects'] for r in reports),'status':'PASS','reports':[{k:v for k,v in r.items() if k!='pieces'} for r in reports]},indent=2))
