const G=require('./gen'); const S=require('./search');
const b=G.generate('bcb','',{maxStraight:4,minOpen:34,minDist:9,jitter:2,
  pool:['b','c','b','c','a','.','.'],iters:800,ms:90000,cap:60000,
  minLen:4,maxLen:7,noDeath:1,routes:4,minHaul:3,freeMin:80,haulMax:8,good:150});
S.show(b,'floor1 lattice');
