function new_body(i,s,c,t,x,y,x1,y1,w,h)
	local o={i=i,s=s,c=c,t=t,x=x,y=y,box={x=x1,y=y1,w=w,h=h}}
		
	function o:collides(dx,dy,o2)		
		local b=self
			
		if o2.box==nil then
			return
		end
			
		local o1x,o1y,o2x,o2y=
			b.x+b.box.x+dx,
			b.y+b.box.y+dy,
			o2.x+o2.box.x,
			o2.y+o2.box.y
		
		return o1x < o2x + o2.box.w and
			o1x + b.box.w > o2x and
			o1y < o2y + o2.box.h and
			o1y + b.box.h > o2y
	end

	function o:contains(p)
		local b=self
		local bx = b.x + b.box.x
		local by = b.y + b.box.y
		return p.x >= bx and p.x < bx + b.box.w and
		       p.y >= by and p.y < by + b.box.h
	end
		
	function o:draw()
		local b=self
		_dimg(b.i,b.s,b.x,b.y,b.c,b.t, 1, 1, false, false)
	end
		
	return o
end

function new_button(i,s,c,t,x,y,x1,y1,w,h)
	local o={}
	o.b = new_body(i,s,c,t,x,y,x1,y1,w,h)

	function o:update() 
		if _mouseclickp(0) and o.b:contains(_mousepos()) then
			o:clicked()
		end
	end

	function o:updatesprite(s) 
		o.b.s=s
	end
		
	function o:draw()
		o.b:draw()
	end
		
	return o
end

function new_colorbutton(c,x,y,x1,y1,w,h)
	local o = {c=c,x=x,y=y,box={x=x1,y=y1,w=w,h=h}}

	function o:contains(p)
		local bx = o.x + o.box.x
		local by = o.y + o.box.y
		return p.x >= bx and p.x <= bx + o.box.w and
		       p.y >= by and p.y <= by + o.box.h
	end

	function o:update() 
		if _mouseclickp(0) and o:contains(_mousepos()) then
			o:clicked()
		end
	end
		
	function o:draw()
		_rectfill(o.x + o.box.x,o.y + o.box.y,o.box.w,o.box.h,o.c)
	end
		
	return o
end

function new_flagbutton(c,cb,x,y,x1,y1,w,h,index)
	local o = {c=c,cb=cb,x=x,y=y,box={x=x1,y=y1,w=w,h=h},active=false,index=index}

	function o:contains(p)
		local bx = o.x + o.box.x
		local by = o.y + o.box.y
		return p.x >= bx and p.x <= bx + o.box.w and
		       p.y >= by and p.y <= by + o.box.h
	end

	function o:update()
		if _mouseclickp(0) and o:contains(_mousepos()) then
			o:clicked()
		end
	end

	function o:setflag(a)
		if a == 1 then
			self.active = true
		elseif a == 0 then
			self.active = false
		end
	end

	function o:toggleflag()
		self.active = not self.active
	end
		
	function o:draw()
		if self.active then
			_circfill2(o.x + o.box.x,o.y + o.box.y,0,0,o.box.w,o.box.h,o.c)
		end
		_circ2(o.x + o.box.x,o.y + o.box.y,0,0,o.box.w,o.box.h,o.cb)
	end
		
	return o
end

function new_verticalbar(x,y,steps,w,h)
    local bar = {
        x=x,
        y=y,
        steps=steps or 10,
        w=w or 10,
        h=h or 5,
        value=0
    }

    function bar:update(p)
		if p.x < self.x or p.x >= self.x+self.w then 
			return -1
		end
		local t = false
        for i=0,self.steps-1 do
            if p.y <  self.y - i*self.h and p.y >= self.y - (i+1)*self.h then
                self.value = i
				t = true
            end
        end

		if t == false then
			return -1
		end

		return self.value
    end

    function bar:draw()
		_rectfill(self.x,self.y - (self.value+1)*self.h,self.w,self.h,self.value%10+1)
    end

    return bar
end

function new_horizontalbar(x,y,v,w,h,max)
	local bar = {
        x=x,
        y=y,
        w=w,
        h=h,
        value=v,
		min=0,
		max=max
    }

    function bar:update(p)
		if p.y < self.y or p.y >= self.y + self.h then 
			return -1
		end

		local t = false
        for i=0,self.max do
            if p.x >= self.x + i*self.w and p.x < self.x + (i+1)*self.w then
                self.value = i
				t = true
            end
        end

		if t == false then
			return -1
		end

		return self.value
    end

    function bar:draw()
		_rectfill(self.x,self.y + self.h/2 - 2,(self.max+1)*self.w,4,11)
		_rectfill(self.x+self.value*self.w,self.y,self.w,self.h,self.value%10+1)
		_print(tostring(self.value),self.x+(self.max+2)*self.w,self.y,12)
    end

    return bar
end