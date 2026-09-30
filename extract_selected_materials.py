import pathlib, sys
from fbx_audit import nodes, walk, inspect

ROOT = pathlib.Path('/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/Medieval Village Pack-zip')
NAMES = ['Inn.fbx','House_4.fbx','House_1.fbx','House_2.fbx','Blacksmith.fbx','Well.fbx','MarketStand_1.fbx','MarketStand_2.fbx','Cart.fbx']

def clean(v):
    return str(v).split('\x00',1)[0]

def child_value(node, wanted):
    for c in node['children']:
        if c['name'] == wanted and c['props']:
            return c['props'][-1]
    return None

def material_data(path):
    version, roots = nodes(path.read_bytes())
    flat = list(walk(roots))
    mats = []
    ids = {}
    connections = []
    for n in flat:
        if n['name'] in ('Geometry','Model','Material') and n['props']:
            ids[int(n['props'][0])] = (n['name'], clean(n['props'][1]) if len(n['props']) > 1 else '')
        if n['name'] == 'C' and len(n['props']) >= 3:
            connections.append((clean(n['props'][0]), int(n['props'][1]), int(n['props'][2])))
        if n['name'] == 'Material':
            props70 = next((c for c in n['children'] if c['name']=='Properties70'), None)
            diffuse = None
            if props70:
                for p in props70['children']:
                    if p['name']=='P' and len(p['props']) >= 7 and clean(p['props'][0]) in ('DiffuseColor','Diffuse'):
                        diffuse = tuple(float(x) for x in p['props'][-3:])
                        break
            mats.append((int(n['props'][0]), clean(n['props'][1]), diffuse))
    result=[]
    for mid, name, diffuse in mats:
        targets=[ids.get(dst,('Unknown',str(dst))) for kind,src,dst in connections if src==mid]
        rgb=tuple(max(0,min(255,round(v*255))) for v in diffuse) if diffuse else None
        result.append((name,diffuse,rgb,targets))
    return inspect(path), result

matches={n:list(ROOT.rglob(n)) for n in NAMES}
for n in NAMES:
    if len(matches[n]) != 1:
        raise SystemExit(f'{n}: expected one match, got {len(matches[n])}')
    path=matches[n][0]
    meta,mats=material_data(path)
    print('ASSET',n)
    print('PATH',path)
    print('OBJECTS',', '.join(meta['model_names']))
    print('GEOMETRY',', '.join(meta['geometry_names']))
    print('GEOMETRY_COUNT',meta['geometry_count'],'MATERIAL_GROUPS',len(mats),'UVS',meta['uv_present'])
    for name,diffuse,rgb,targets in mats:
        print('MATERIAL',name,'DIFFUSE',diffuse,'RGB',rgb,'TARGETS',targets)
    print()
