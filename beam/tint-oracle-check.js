// usage: node tint-oracle-check.js ./atbc-colour-oracle.js [golem-chrome.js]
// NOTE: sidebar is expected at i(0) (the bar colour) — an intentional Golem deviation from ATBC (+5), Max 2026-09-25.
// Checks Beam's tint maths bit-for-bit against ATBC's own colour class (the oracle).
const S=require(process.argv[2]);
const all=require('fs').readFileSync(process.argv[3]||'/etc/nixos/golem-chrome.js','utf8');
const a=all.indexOf('// ---- BEAM TINT — colour maths'), b=all.indexOf('// ---- BEAM TINT — engine');
if(a<0||b<0) throw Error('tint maths block not found in '+process.argv[3]);
const src=all.slice(a,b);  // test the REAL shipped code, never a copy
const P=new Function(src+"; return {gtTheme, gtCorrect, gtBright, gtRGBA};")();
// ATBC's own de(): colours for scheme/offsets (defaults), via its REAL class
function atbc(r,g,b){
  const {colour:t,scheme:n}=new S().rgba(r,g,b,1).contrastCorrection("dark",true,90,45);
  const i=x=>t.brightness((n==="light"?-1.5:1)*x).toRGBA();
  return {scheme:n, frame:i(0), toolbar:i(0), field:i(5), fieldBorder:i(10), focus:i(5), sidebar:i(0), sidebarBorder:i(15), tabSel:i(15), popup:i(5), popupBorder:i(15)};
}
function mine(r,g,b){ const t=P.gtTheme([r,g,b]), v=t.vars;
  return {scheme:t.scheme, frame:v["--lwt-accent-color"], toolbar:v["--toolbar-background-color"], field:v["--toolbar-field-background-color"], fieldBorder:v["--toolbar-field-border-color"], focus:v["--toolbar-field-background-color-focus"], sidebar:v["--sidebar-background-color"], sidebarBorder:v["--sidebar-border-color"], tabSel:v["--tab-background-color-selected"], popup:v["--panel-background-color"], popupBorder:v["--panel-border-color"]}; }
let n=0,bad=0,schemes={};
const cases=[];
for(let r=0;r<256;r+=17)for(let g=0;g<256;g+=17)for(let b=0;b<256;b+=17)cases.push([r,g,b]);
cases.push([0,0,0],[255,255,255],[29,32,38],[192,43,59],[27,27,27],[36,36,37],[128,128,128],[250,250,250],[5,5,5],[31,31,31],[32,32,32],[63,64,65],[223,224,225]);
for(const c of cases){ n++; const a=atbc(...c), m=mine(...c); schemes[a.scheme]=(schemes[a.scheme]||0)+1;
  if(JSON.stringify(a)!==JSON.stringify(m)){ bad++; if(bad<=5) console.log("MISMATCH",c,"\n atbc",a,"\n mine",m); } }
console.log(`checked ${n} colours: ${bad} mismatches; schemes`,schemes);
console.log("example red page:", JSON.stringify(mine(192,43,59)));
