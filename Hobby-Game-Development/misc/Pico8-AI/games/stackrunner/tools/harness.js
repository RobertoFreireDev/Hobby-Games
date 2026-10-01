// build _test.p8: game.p8 with a scripted-input driver appended to __lua__
const fs=require('fs');
function build(cartPath,outPath,chain){
  const lines=fs.readFileSync(cartPath,'utf8').split(/\r?\n/);
  const gi=lines.findIndex(l=>l==='__gfx__');
  const qs='X'+chain.join('');
  const drv=`
-->8
-- test driver (generated)
_qs="${qs}"
_qi=1 _fr=0 _dead=0
_bm={["<"]=0,[">"]=1,["^"]=2,["v"]=3,["X"]=5}
function btnp(b,pl)
 local c=sub(_qs,_qi,_qi)
 if c=="" then return false end
 if _bm[c]==b then _qi+=1 return true end
 return false
end
function _stk(t)
 local s=""
 for v in all(t) do s=s..v end
 if s=="" then s="-" end
 return s
end
_ld=loadlv
function loadlv(n,f)
 _ld(n,f)
 if f then printh("floor "..n.."  mv=".._stk(mv).."  it=".._stk(it)) end
end
_di=die
function die()
 _dead+=1
 printh("DEATH on floor "..lv.." at press ".._qi)
 extcmd("shutdown")
end
_up=_update
function _update()
 _fr+=1
 _up()
 if mode==2 then printh("WIN reached the win screen") extcmd("shutdown") end
 if _qi>#_qs and _fr>60 and wi<1 and ph<1 then
  printh("OUT OF SCRIPT on floor "..lv) extcmd("shutdown")
 end
 if _fr>7000 then printh("TIMEOUT floor "..lv) extcmd("shutdown") end
end
`;
  lines.splice(gi,0,...drv.split('\n'));
  fs.writeFileSync(outPath,lines.join('\n'));
}
module.exports={build};
if(require.main===module){
  const chain=JSON.parse(fs.readFileSync(process.argv[4],'utf8'));
  build(process.argv[2],process.argv[3],chain);
  console.log('wrote '+process.argv[3]);
}
