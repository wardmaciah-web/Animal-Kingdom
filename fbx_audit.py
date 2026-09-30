import json, math, pathlib, struct, sys, zlib

ROOT = pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else None

def prop(data, pos):
    t = chr(data[pos]); pos += 1
    fmts = {'Y':('<h',2),'C':('<?',1),'I':('<i',4),'F':('<f',4),'D':('<d',8),'L':('<q',8)}
    if t in fmts:
        fmt,n=fmts[t]; return struct.unpack_from(fmt,data,pos)[0],pos+n
    if t in 'SR':
        n=struct.unpack_from('<I',data,pos)[0];pos+=4;raw=data[pos:pos+n];pos+=n
        return (raw.decode('utf-8','replace').rstrip('\x00') if t=='S' else raw),pos
    if t in 'fdilbc':
        count,encoding,n=struct.unpack_from('<III',data,pos);pos+=12;raw=data[pos:pos+n];pos+=n
        if encoding==1: raw=zlib.decompress(raw)
        fm={'f':'f','d':'d','i':'i','l':'q','b':'b','c':'B'}[t]
        return list(struct.unpack('<'+fm*count,raw[:struct.calcsize('<'+fm*count)])),pos
    raise ValueError('unknown property '+t)

def nodes(data):
    version=struct.unpack_from('<I',data,23)[0]; header=25 if version>=7500 else 13
    def one(pos,limit):
        if pos+header>len(data): return None,pos
        if version>=7500: end,nprops,plen,nlen=struct.unpack_from('<QQQB',data,pos)
        else: end,nprops,plen,nlen=struct.unpack_from('<IIIB',data,pos)
        if end==0: return None,pos+header
        start=pos;pos+=header;name=data[pos:pos+nlen].decode('utf-8','replace');pos+=nlen
        ps=[]
        for _ in range(nprops): v,pos=prop(data,pos);ps.append(v)
        children=[]
        while pos<end-header:
            child,newpos=one(pos,end)
            if child is None: pos=newpos;break
            children.append(child);pos=newpos
        return {'name':name,'props':ps,'children':children,'start':start,'end':end},end
    out=[];pos=27
    while pos<len(data):
        node,newpos=one(pos,len(data))
        if node is None: break
        out.append(node);pos=newpos
    return version,out

def walk(ns):
    for n in ns:
        yield n
        yield from walk(n['children'])

def inspect(path):
    data=path.read_bytes();version,root=nodes(data);flat=list(walk(root))
    geometries=[];models=[];materials=[];textures=[];videos=[];uv=False
    for n in flat:
        p=n['props'];name=n['name']
        if name=='Geometry' and len(p)>=3:
            verts=[]
            for c in n['children']:
                if c['name']=='Vertices' and c['props']: verts=c['props'][0]
                if c['name'].startswith('LayerElementUV'): uv=True
            if verts:
                pts=list(zip(verts[0::3],verts[1::3],verts[2::3]));mins=[min(q[i] for q in pts) for i in range(3)];maxs=[max(q[i] for q in pts) for i in range(3)]
                geometries.append({'name':str(p[1]),'type':str(p[2]),'vertices':len(pts),'min':mins,'max':maxs})
        elif name=='Model' and len(p)>=3: models.append({'name':str(p[1]),'type':str(p[2])})
        elif name=='Material' and len(p)>=2: materials.append(str(p[1]))
        elif name=='Texture': textures.append([str(x) for x in p])
        elif name=='Video': videos.append([str(x) for x in p])
    if geometries:
        mins=[min(g['min'][i] for g in geometries) for i in range(3)];maxs=[max(g['max'][i] for g in geometries) for i in range(3)];dims=[maxs[i]-mins[i] for i in range(3)]
    else: dims=[]
    refs=[]
    for n in flat:
        if n['name'] in ('FileName','RelativeFilename') and n['props']:
            refs.extend(str(x) for x in n['props'] if isinstance(x,str) and x)
    return {'path':str(path),'version':version,'bytes':len(data),'geometry_count':len(geometries),'model_count':len(models),'material_count':len(materials),'materials':materials,'texture_nodes':len(textures),'video_nodes':len(videos),'texture_refs':sorted(set(refs)),'uv_present':uv,'raw_dimensions':dims,'vertices':sum(g['vertices'] for g in geometries),'geometry_names':[g['name'] for g in geometries],'model_names':[m['name'] for m in models]}

if __name__=='__main__':
    result=[]
    for path in sorted(ROOT.rglob('*')):
        if path.suffix.lower()=='.fbx':
            try: result.append(inspect(path))
            except Exception as exc: result.append({'path':str(path),'error':repr(exc)})
    print(json.dumps(result,indent=2))
