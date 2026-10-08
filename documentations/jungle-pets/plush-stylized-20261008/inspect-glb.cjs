const fs=require('fs'),path=require('path'),crypto=require('crypto');
const file=process.argv[2], b=fs.readFileSync(file);
if(b.toString('ascii',0,4)!=='glTF'||b.readUInt32LE(4)!==2||b.readUInt32LE(8)!==b.length)throw Error('Invalid GLB header');
let j,bin;for(let o=12;o<b.length;){const n=b.readUInt32LE(o),t=b.readUInt32LE(o+4);if(o+8+n>b.length)throw Error('Truncated chunk');if(t===0x4e4f534a)j=JSON.parse(b.toString('utf8',o+8,o+8+n).trim());if(t===0x004e4942)bin=b.subarray(o+8,o+8+n);o+=8+n;}
if(!j||!bin)throw Error('Missing JSON or binary');
for(const v of j.bufferViews)if((v.byteOffset||0)+v.byteLength>bin.length)throw Error('Invalid buffer range');
let triangles=0,vertices=0,min=[Infinity,Infinity,Infinity],max=[-Infinity,-Infinity,-Infinity];
const positions=[];
for(const mesh of j.meshes)for(const p of mesh.primitives){if((p.mode??4)!==4)throw Error('Non-triangle mesh');const a=j.accessors[p.attributes.POSITION],v=j.bufferViews[a.bufferView];if(a.componentType!==5126||a.type!=='VEC3')throw Error('Unsupported positions');vertices+=a.count;triangles+=(p.indices===undefined?a.count:j.accessors[p.indices].count)/3;const stride=v.byteStride||12,off=(v.byteOffset||0)+(a.byteOffset||0);for(let i=0;i<a.count;i++){const pos=[0,1,2].map(k=>bin.readFloatLE(off+i*stride+k*4));if(pos.some(x=>!Number.isFinite(x)))throw Error('Nonfinite vertex');positions.push(pos);for(let k=0;k<3;k++){min[k]=Math.min(min[k],pos[k]);max[k]=Math.max(max[k],pos[k]);}}}
const images=[];for(const [i,img]of(j.images||[]).entries()){if(img.bufferView===undefined)throw Error('External texture not durable');const v=j.bufferViews[img.bufferView],bytes=bin.subarray(v.byteOffset||0,(v.byteOffset||0)+v.byteLength),ext=img.mimeType==='image/png'?'png':'jpg',out=path.join(path.dirname(file),path.basename(file,'.glb')+'_texture_'+i+'.'+ext);fs.writeFileSync(out,bytes);images.push({name:img.name,mimeType:img.mimeType,path:path.basename(out),bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});}
const report={file:path.basename(file),sha256:crypto.createHash('sha256').update(b).digest('hex'),bytes:b.length,triangles,vertices,bounds:{min,max,dimensions:max.map((x,k)=>x-min[k])},images,materials:j.materials};
fs.writeFileSync(file+'.inspection.json',JSON.stringify(report,null,2));fs.writeFileSync(file+'.positions.json',JSON.stringify(positions));console.log(JSON.stringify(report));

