pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function restartlevel()
	currentlevel-=1 
 enemies={}
end

function _init()
	menuitem(1, "restart level", function() 
 	restart=true
 end)
 menuitem(2, "next", function() enemies={} end)
	gameover=false
	currentlevel=1
	generatelevel()
end

--to improve performance
--_update instead of _update60 
function _update()
	if restart then
 	restartlevel()
 end
 
 restart=false
	
 timemanager:update()
 
	if life<=0 then
		gameover=true
		timemanager:addtimer(30,function() _init() end,1)
		return
	end
	
	if #enemies==0 then
		currentlevel+=1
		generatelevel()
	end
 
	if showenemies then
		return
	end
	
	s:control()
	
	foreach(towers,function(t)
		t:control()
	end)
	
	foreach(enemies,function(e)
		e:control()
	end)
end

function _draw()
	cls()
	
	if showenemies then
		camera(127,0)
	else
		camera(0,0)
	end
	
	map()
	draw_footer()
	
	if gameover then
		draw_gameover()
		return
	end
	
	s:draw()
	foreach(towers,function(t)
		t:draw()
	end)
	foreach(enemies,function(e)
		e:draw()
	end)
end

-->8
-- utils --
global=_ENV

class = setmetatable({
		new=function(self,tbl)
			tbl = tbl or {}
			
			return setmetatable(tbl,{ __index=self})
		end
},{ __index=_ENV})

function drawsprite(o)
	spr(o.sprt,o.x,o.y)
end

collideflag=function(x,y,flag)
	 for i=x,x+7,7 do
    if (fget(mget(i/8,y/8))==flag) or
         (fget(mget(i/8,(y+7)/8))==flag) then
          return true
    end
  end
  for i=y,y+7,7 do
    if (fget(mget(x/8,i/8))==flag) or
         (fget(mget((x+7)/8,i/8))==flag) then
          return true
    end
  end  
  return false
end

function rects_overlap(o1,o2)
		local o1x,o1y,o2x,o2y=
			o1.x+o1.box.x,
			o1.y+o1.box.y,
			o2.x+o2.box.x,
			o2.y+o2.box.y
		
  return o1x < o2x + o2.box.w and
         o1x + o1.box.w - 1 > o2x and
         o1y < o2y + o2.box.h and
         o1y + o1.box.h - 1 > o2y
end

timemanager = class:new({
	timers = {},
	addtimer=function(_ENV,duration,callback,dt)
		add(timers,{
			duration=duration,
		 callback=callback,
		 dt=dt,
		 elapsed=0
		})
	end,
	update=function(_ENV)
		foreach(timers,function(t)
			t.elapsed += t.dt
	  if t.elapsed >= t.duration then
	   t.callback()
	   del(timers,t)
	  end
		end)
	end
})

function distance(x1, y1, x2, y2)
  return (x2 - x1)^2 + (y2 - y1)^2
end

function draw_life()
	spr(32,8*8,15*8)
	print(life,9*8+2,15*8+2)
end

function draw_gameover()
	print("game over",4*8,6*8,8)
end

function draw_footer()
	draw_availabletowers()
	draw_life()
end
-->8
-- selector --
s = class:new({
	x=8,
	y=0,
	hm=false,--hasmoved
	at=false,--addedtower
	ctp=false,--changedtowertype
	tpi=1,--towertype index
	move=function(_ENV)
		if btn(0) then x=max(x - 8, 8) -- left
		elseif btn(1) then x=min(x + 8, 96) -- right
		elseif btn(2) then y=max(y - 8, 0) -- up
		elseif btn(3) then y=min(y + 8, 112) end -- down
	end,
	control=function(_ENV)
		if not hm and (btn(0) or btn(1) or btn(2) or btn(3)) then
			move(_ENV)
			hm=true
			timemanager:addtimer(5,function() s.hm=false end,1)
		end
		
		if not at and btn(4) 
			and	availabletowers[tpi].q>0 
			and not get_buffer(x,y).a 
			and not get_terrain_buffer(x,y).a then
				local reftower=createtower(x,y,towertypes[tpi])
				at=true
				availabletowers[tpi].q-=1
				timemanager:addtimer(10,function() s.at=false end,1)
		end
		
		if not ctp and btn(5) then
			tpi+=1
			if tpi>#towertypes then tpi=1 end
			ctp=true
			timemanager:addtimer(10,function() s.ctp=false end,1)
		end
	end,
	draw=function(_ENV)
		pal(6,towertypes[tpi].c)
		spr(1,x,y)
		pal()
	end
})

-->8
-- tower --

--c color
--s sprite
--as attack speed
--d damage
--st stun
--r reach
--l life
towertypes = {
	{c=2,s=2,as=300,d=22,st=400,r=800,l=50},
	{c=10,s=3,as=150,d=20,st=0,r=2000,l=50},
	{c=12,s=4,as=150,d=30,st=0,r=800,l=300},
	{c=8,s=5,as=150,d=50,st=0,r=800,l=50}
}

t = class:new({
	x=0,
	y=0,
	s=0,
	twt={},-- tower type
	ce=nil,-- closest enemy
	hd=false,--hasdetected
	f=false,--fire
	l=100,--life
	ol=100,--original life,
	control=function(_ENV)
		if hd then
			return
		end
		
		ce=enemies[1]		
	 foreach(enemies,function(e)
	 	if e.x<128 and distance(x,y,e.x,e.y)
	 		<	distance(x,y,ce.x,ce.y) then
	 		ce=e
	 	end
	 end)
	 
	 if ce~=nil and ce.x<128 and distance(x,y,ce.x,ce.y)<twt.r then
	 	hd=true
	 	f=true
			timemanager:addtimer(twt.as,function() _ENV.hd=false end,1)
			timemanager:addtimer(10,function() _ENV.f=false end,1)
			timemanager:addtimer(1,function() ce:takedamage(twt.d,twt.st) end,1)
		end
	end,
	takedamage=function(_ENV,damage)
		l-=damage
		if l<=0 then
			destroytower(_ENV)
		end
	end,
	draw=function(_ENV)
		if l<ol*0.5 then
			spr(twt.s+4,x,y)
		else
			spr(twt.s,x,y)
		end
		
		if f then
			line(x+4,y+2,ce.x+4,ce.y+4,twt.c)
		end
	end
})

function createtower(x,y,tp)
	local reftower=t:new(
		{
			x=x,
			y=y,
			twt=tp,
			l=tp.l,
			ol=tp.l
		}
	)
	
	add(towers,reftower)
	set_buffer(x,y,{a=true,t=reftower})
	return reftower
end

function destroytower(t)
	del(towers,t)
	set_buffer(t.x,t.y,{a=false})
end

function generateavailabletowers(ql)
	local index=1
	foreach(ql,function(i)
		add(availabletowers,
			{
				c=towertypes[index].c,
				s=towertypes[index].s,
				q=i
			}
		)
		index+=1
	end)
end

function draw_availabletowers()
	local xx,yy=0,15
	foreach(availabletowers,function(at)
		spr(at.s,xx*8,yy*8)
		print(at.q,(xx+1)*8,yy*8+2,7)
		xx+=2
	end)
end
-->8
-- enemies --
e = class:new({
	x=0,
	y=0,
	s=0,
	hm=false,-- has moved
	ist=false,-- is stunned 
	move=false,
	dir=1,--3 up 2 down 1 left
	l=100,--life
	atk=5,--attack
	atktwr=false,--attack tower
	spd=60,--speed
	moveleft=function(_ENV)
		if not get_buffer(x-8,y).a and x>0 then
			x-=8
			move=true
			dir=1
		end
	end,
	movedown=function(_ENV)
		if not get_buffer(x,y+8).a and y<112 then
			y+=8
			move=true
			dir=2
		end
	end,
	moveup=function(_ENV)
		if not get_buffer(x,y-8).a and y>0 then
			y-=8
			move=true
			dir=3
		end
	end,
	attacktower=function(_ENV)
	 local t=get_buffer(x-8,y).t	
		if t~=nil then
				t:takedamage(atk)
				atktwr=true
			return
		else
		 atktwr=false
		end
	end,
	control=function(_ENV)	
		local lx,ly=x,y
		move=false
		
		if hm or ist then
			return
		end
		hm=true
		timemanager:addtimer(spd,function() _ENV.hm=false end,1) 
		
		attacktower(_ENV)
		moveleft(_ENV)
		
		if not move then
			if dir==3 then
				moveup(_ENV)
			elseif dir==2 then
				movedown(_ENV)
			else
				if rnd({false,true}) then
				 moveup(_ENV)
					if not move then
						movedown(_ENV)
					end
				else
					movedown(_ENV)
					if not move then
						moveup(_ENV)
					end
				end
			end
		end
		
		if move then
			set_buffer(lx,ly,{a=false})
			
			if x<7 then
				del(enemies,_ENV)
				global.life-=1
			else
			 set_buffer(x,y,{a=true})
			end
		end
	end,
	takedamage=function(_ENV,damage,stn)
		l-=damage
		
		if stn>0 then
			ist=true
			timemanager:addtimer(stn,function() _ENV.ist=false end,1)
		end		
		
		if l<=0 then
			del(enemies,_ENV)
			set_buffer(x,y,{a=false})
		end
	end,
	draw=function(_ENV)
		if atktwr then
			pal(14,8)
		end
		
		if ist then
			pal(6,13)
		end
		
		if l<30 then			
		 spr(s+2,x,y)
		elseif l<80 then
			spr(s+1,x,y)
		else
			spr(s,x,y)
		end
		pal()
	end
})

function generateenemies(ens)
	local lx,ly=16,0
	
	foreach(ens,function(e)		
		if e[5]==1 then
			for i=e[1],e[1]+e[3]-1 do
				for j=e[2],e[2]+e[4]-1 do
					createenemy1((lx+i)*8,(ly+j)*8)
				end
			end
		elseif e[5]==2 then
			for i=e[1],e[1]+e[3]-1 do
				for j=e[2],e[2]+e[4]-1 do
					createenemy2((lx+i)*8,(ly+j)*8)
				end
			end
		end
	end)
end

function createenemy1(x,y)
	add(enemies,e:new(
		{x=x,y=y,s=16,l=200,atk=20,spd=200})
	)
end

function createenemy2(x,y)
 add(enemies,e:new(
 	{x=x,y=y,s=19,l=120,atk=20,spd=120})
 )
end


-->8
-- buffer --
function create_buffer()
 for i=0,31 do
   buffer[i] = {}
   for j=0,15 do
    buffer[i][j]={a=false}
   end
 end
end

function get_buffer(x,y)
	if x<0 or y<0 then
		return {a=false}
	end
	
	return buffer[flr(x/8)][flr(y/8)]
end

function set_buffer(x,y,value)
	buffer[flr(x/8)][flr(y/8)]=value
end

function create_terrain_buffer()
 for i=0,31 do
   terrain[i] = {}
   for j=0,15 do
    terrain[i][j]={a=false}
   end
 end
end

function get_terrain_buffer(x,y)
	if x<0 or y<0 then
		return {a=false}
	end
	
	return terrain[flr(x/8)][flr(y/8)]
end

function set_terrain_buffer(x,y,value)
	terrain[flr(x/8)][flr(y/8)]=value
end
-->8
-- walls --
function generatewalls(ws)
	if ws==nil then
		return
	end
	
	foreach(ws,function(w)
		if w[3]==5 then	
			mset(w[1],w[2],10)
			set_buffer(w[1]*8,w[2]*8,{a=true})	
		else
			createtower(w[1]*8,w[2]*8,towertypes[w[3]])
		end
	end)
end

-- terrain --
function generateterrain(trs)
	if trs==nil then
		return
	end
	
	foreach(trs,function(t)
		if t[3]==1 then	
			mset(t[1],t[2],11)
			set_terrain_buffer(t[1]*8,t[2]*8,{a=true})	
		end
	end)
end
-->8
-- level --
function generatelevel()
	reload()
	enemies={}
	showenemies=true
	timemanager:addtimer(60,function() showenemies=false end,1)
	buffer={}
	terrain={}
	towers= {}
	availabletowers = {}
	
	local level=levels[currentlevel]
 generateavailabletowers(level[1])
 create_buffer()
 create_terrain_buffer()
	generateenemies(level[2])
	life=level[3]
	generatewalls(level[4])
	generateterrain(level[5])
end

aaa={
		{0,0,0,0},
		{
			{0,2,1,1,1},
			{0,5,1,1,1},
			{0,8,1,1,1},
			{0,11,2,1,1}
		},1,
		{
		 {9,2,3},{9,5,2},
		 {9,8,1},{9,11,4},
		},
		{
		 {11,4,1},{11,5,1},
		 {3,8,1},{3,9,1},{4,8,1},
		}
}

aab={
	{5,0,0,0},
	{
		{0,4,1,4,1},
	},1
}

aac={
	{4,0,0,0},
	{
		{0,4,1,4,1},
	},1,
	{
	 {8,5,5},{8,6,5}
	},
}

aad={
	{4,1,0,0},
	{
		{0,4,1,4,1},
	},1,{},
	{
	 {11,4,1},{11,5,1},
	 {10,3,1},{10,4,1},{10,5,1},
	 {9,3,1},{9,4,1},{9,6,1},
	 {8,4,1},{8,5,1},{8,6,1},
	 {7,4,1},{7,5,1},{7,6,1},{7,7,1},
	 {6,4,1},{6,5,1},{6,6,1},
	 {5,4,1},{5,5,1},{5,6,1},
	 {4,5,1},{4,6,1},{4,7,1},
	 {3,5,1},{3,6,1},{3,7,1},
	}
}

aae={
	{2,4,0,0},
	{
		{0,4,1,4,1},
		{1,4,1,3,1},
		{10,4,1,4,1},
	},1
}

aaf={
	{2,4,0,0},
	{
		{0,4,3,4,1},
	},1,
	{
	 {10,4,3},
	 {6,4,5},{6,5,5},{6,6,5}
	}
}

-- pending
aba = {
	{2,4,0,0},
	{
		{0,4,3,4,1},
	},1,
	{
	 {8,4,5},{8,5,5},{8,6,5},{8,7,5},
	}
}

lastlevel={
	{1,1,1,1},
	{
		{0,2,1,1,1},
	},1
}

levels={
	aba,
	aaa,
	aab,
	aac,
	aad,
	aae,
	aaf,
	lastlevel
}
__gfx__
00000000660660660000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000000000000000000
00000000600000060022220000aaaa0000cccc000088880000022200000aaa00000ccc000008880050505050cccccccc00000000000000000000000000000000
00700700000000000022220000aaaa0000cccc00008888000022220000aaaa0000cccc000088880055555550cccccccc00000000000000000000000000000000
000770006000000600a22a00009aa90000dccd0000f88f0000a22a00009aa90000dccd0000f88f0055555550cccccccc00000000000000000000000000000000
0007700060000006000aa00000099000000dd000000ff000000aa00000099000000dd000000ff00005555500cccccccc00000000000000000000000000000000
0070070000000000000440000004400000055000000440000004400000044000000550000004400005555500cccccccc00000000000000000000000000000000
0000000060000006004444000044440000555500004444000004500000045000000550000004500005555500cccccccc00000000000000000000000000000000
00000000660660660444444004444440055555500444444000464400004444000056550000464400555555500cccccc000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600066667000666670006666600066667000666670000000000000000000000000000000000000000000000000000000000000000000000000000000000
55665560556677705566777055665500556677705566777000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e66e6606e66e7602e66e7606e66e6606e66e7602e66e76000000000000000000000000000000000000000000000000000000000000000000000000000000000
66664440666644402266444066666660666666602266666000000000000000000000000000000000000000000000000000000000000000000000000000000000
66554540665545406655454066556660665566606655666000000000000000000000000000000000000000000000000000000000000000000000000000000000
06664440066644400666444006666600066666000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000
04004000040040000400400006006000060060000600600000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888868000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888868000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
