import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {root} from './generate-project.mjs';
// Dependency-free original layered Nexus mark, encoded as an opaque PNG.
const n = 1024, rows = Buffer.alloc((n * 3 + 1) * n);
const inside = (x,y,points) => {
  let value = false;
  for(let i=0,j=points.length-1;i<points.length;j=i++) {
    const [a,b]=points[i], [c,d]=points[j];
    if((b>y)!==(d>y) && x < (c-a)*(y-b)/(d-b)+a) value=!value;
  }
  return value;
};
for(let y=0;y<n;y++) for(let x=0;x<n;x++) {
  const i=y*(n*3+1)+1+x*3, glow=Math.max(0,1-Math.hypot(x-512,y-430)/700);
  let rgb=[4+7*glow,14+24*glow,12+17*glow];
  for(const offset of [180,90,0]) {
    const polygon=[[245,380+offset],[512,245+offset],[779,380+offset],[512,520+offset]];
    if(inside(x,y,polygon)) rgb=[76+40*glow-offset/5,184+30*glow-offset/6,150+30*glow-offset/7];
  }
  if(x>254&&x<770&&y>810&&y<815)rgb=[255,184,89];
  rgb.forEach((v,c)=>rows[i+c]=Math.round(v));
}
const crc = data => { let c=0xffffffff; for(const byte of data){c^=byte;for(let j=0;j<8;j++)c=(c>>>1)^((c&1)?0xedb88320:0);} return (c^0xffffffff)>>>0; };
const chunk = (type,data) => { const t=Buffer.from(type), len=Buffer.alloc(4), checksum=Buffer.alloc(4);len.writeUInt32BE(data.length);checksum.writeUInt32BE(crc(Buffer.concat([t,data])));return Buffer.concat([len,t,data,checksum]); };
const header=Buffer.alloc(13);header.writeUInt32BE(n,0);header.writeUInt32BE(n,4);header[8]=8;header[9]=2;
const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',zlib.deflateSync(rows)),chunk('IEND',Buffer.alloc(0))]);
const dir=path.join(root,'App/Resources/Assets.xcassets/AppIcon.appiconset');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'AppIcon.png'),png);
fs.writeFileSync(path.join(dir,'Contents.json'),JSON.stringify({images:[{filename:'AppIcon.png',idiom:'universal',platform:'ios',size:'1024x1024'}],info:{author:'xcode',version:1}},null,2)+'\n');
fs.writeFileSync(path.join(dir,'../Contents.json'),JSON.stringify({info:{author:'xcode',version:1}},null,2)+'\n');
console.log('Generated original app icon.');
