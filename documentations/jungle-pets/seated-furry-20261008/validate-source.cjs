const fs=require('fs'),path=require('path');
const dir=__dirname,results=[];
for(const name of ['tapir','ocelot']){
const b=fs.readFileSync(path.join(dir,name+'.glb'));let j,bin;
for(let o=12;o<b.length;){let n=b.readUInt32LE(o),t=b.readUInt32LE(o+4);if(t===0x4e4f534a)j=JSON.parse(b.toString('utf8',o+8,o+8+n));if(t===0x004e4942)bin=b.subarray(o+8,o+8+n);o+=8+n;}
let count=0;for(const mesh of j.meshes)for(const p of mesh.primitives){const verts=j.accessors[p.attributes.POSITION].count;const a=j.accessors[p.indices],v=j.bufferViews[a.bufferView];const bytes={5121:1,5123:2,5125:4}[a.componentType];if(!bytes)throw Error('Unknown index format');for(let i=0;i<a.count;i++){let off=(v.byteOffset||0)+(a.byteOffset||0)+i*(v.byteStride||bytes);let val=bytes===1?bin.readUInt8(off):bytes===2?bin.readUInt16LE(off):bin.readUInt32LE(off);if(val>=verts)throw Error('Index out of range');count++;}for(const key of ['NORMAL','TEXCOORD_0'])if(p.attributes[key]===undefined)throw Error('Missing '+key);}
results.push({name,validIndices:count,nodes:j.nodes,scenes:j.scenes,meshPrimitives:j.meshes.map(m=>m.primitives.length),reopened:true});}
fs.writeFileSync(path.join(dir,'source-validation.json'),JSON.stringify(results,null,2));console.log(JSON.stringify(results));

