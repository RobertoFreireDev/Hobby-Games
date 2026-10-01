const fs=require('fs');
let c=fs.readFileSync('tools/floorcfg.js','utf8');
// two mandatory gates in series on floor 15, three on floor 16, made the forced
// errand longer than the card budget could pay for. keep one gate each, and let
// the remaining pieces be obstacles rather than locks.
c=c.replace("pieces:[{ch:'2',at:'cut'},{ch:'-',at:'cut'},{ch:'x',at:'any'},{ch:'x',at:'any'},{ch:'y',at:'any'},{ch:'y',at:'any'}],",
            "pieces:[{ch:'2',at:'cut'},{ch:'-',at:'any',notCut:true},{ch:'=',at:'any',notCut:true},{ch:'x',at:'any'},{ch:'x',at:'any'},{ch:'y',at:'any'},{ch:'y',at:'any'}],");
c=c.replace("pieces:[{ch:'o',at:'cut',push:true},{ch:'2',at:'cut'},{ch:'-',at:'cut'},",
            "pieces:[{ch:'o',at:'cut',push:true},{ch:'2',at:'cut'},{ch:'-',at:'any',notCut:true},{ch:'=',at:'any',notCut:true},");
// the finale is the last floor: what it leaves with no longer matters
c=c.replace("/*16*/ F({pool:C.R,minDist:6,minLen:6,maxLen:13,wantDeath:1,minHaul:4,",
            "/*16*/ F({pool:C.R,minDist:6,minLen:6,maxLen:13,wantDeath:1,minHaul:1,");
c=c.replace("/*15*/ F({pool:C.R,minDist:6,minLen:6,maxLen:13,ms:150000,wantDeath:1,minHaul:4,",
            "/*15*/ F({pool:C.R,minDist:6,minLen:6,maxLen:12,ms:150000,wantDeath:1,minHaul:4,");
fs.writeFileSync('tools/floorcfg.js',c);
console.log(c.split('\n').slice(-14).join('\n'));
