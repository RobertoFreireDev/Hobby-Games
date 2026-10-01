pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main game
function _init()
	state=menu--intro
end

function _update()
	state.update()
end

function _draw()
	state.draw()
end
-->8
-- states
intro = {
	update = function()
			if btnp(4) then
					state=menu
			end
	end,	
	draw = function()
			cls()
			print("neural trainer",10,10)
			print("game made by roberto freire",10,30)
	end
}

menu = {
	update = function()
			if btnp(4) then
					state=game
					game.init()
			end
			
			if btnp(0) and curtlvl > 0 then
					curtlvl-=1
			end
			
			if btnp(1) and curtlvl < #levels then
					curtlvl+=1
			end
	end,	
	draw = function()
			cls()
			
			for i=1,#levels do
					spr(i,12+(i-1)*16,16)
					if curtlvl == i then
							spr(48,12+(i-1)*16,16)
					end
			end
	end
}

game = {
	init = function()
		levels[curtlvl]:init()
	end,
	update = function()
			if btnp(5) then
					state=menu
			end
			levels[curtlvl]:update()
	end,	
	draw = function()
			cls()
			levels[curtlvl]:draw()
			nn:draw()
	end
}

-->8
-- levels
curtlvl=1
levels = {}

levels[1] = {
	dino_x = 2,
	dino_y = 56,
	dino_vy = 0,
	on_ground = true,
	obstacle={},
	obs_speed = 2,
	add_obstacle = function(this)
	  this.obstacle={x = flr(128+rnd(128))}
		this.obs_speed=flr(1+rnd(2))
	end,
	init = function(this)
    this:add_obstacle()
    nn:init({{
      desc = "distance to next obstacle", 
      value = 0
    }},{1},{{
      desc = "jump", 
      value = false
    }})
	end,
	update = function(this)
			this.obstacle.x -= this.obs_speed
      
   if this.obstacle.x < -8 then
      this:add_obstacle()
   end
   
   local x0 = this.dino_x - this.obstacle.x
   nn:update({x0})
   local y = nn.output[1].value

   if y and this.on_ground then
    this.dino_vy = -4
    this.on_ground = false
   end
   
   this.dino_y += this.dino_vy
   if not this.on_ground then
       this.dino_vy += 0.3
   end
   if this.dino_y >= 56 then
       this.dino_y = 56
       this.dino_vy = 0
       this.on_ground = true
   end
	end,
	draw = function(this)
	  rectfill(0, 0, 127, 63, 15)
    line(0, 64, 127, 64, 5)
    spr(1,this.dino_x, this.dino_y)
    spr(32,this.obstacle.x, 56)
	end
}

levels[2] = {
	init = function(this)
	end,
	update = function(this)
	end,
	draw = function(this)
			print("level: "..2,10,10)
	end
}

-->8
-- neural network
nn = {
  input = {},
  hiddenlayer1nodes = {},
  hiddenlayer2nodes = {},
  output = {},
  tmrnt = 0,
  curel = {
    x = 1,
    y = 1,
    xmax = 1,
    ymax = {}
  },
  init = function(this, input, hidden_layer_nodes, output)
    this.input = input
    this.output = output
    -- hidden_layer_nodes is a table like. Example {2, 1}
    -- for up to 3 hidden layers with corresponding node counts

    -- clear existing layers
    nn.hiddenlayer1nodes = {}
    nn.hiddenlayer2nodes = {}

    this.curel.xmax = 2
    add(this.curel.ymax,#input)

    -- initialize hidden layers
    if #hidden_layer_nodes >= 1 then
        nn.hiddenlayer1nodes = init_layer(hidden_layer_nodes[1], #input)
        add(this.curel.ymax,#nn.hiddenlayer1nodes)
        this.curel.xmax += #input + 1 -- bias
    end

    if #hidden_layer_nodes >= 2 then
        nn.hiddenlayer2nodes = init_layer(hidden_layer_nodes[2], hidden_layer_nodes[1])
        add(this.curel.ymax,#nn.hiddenlayer2nodes)
        this.curel.xmax += hidden_layer_nodes[1]
    end

    add(this.curel.ymax,#output)

    --start: mockup neural values
    nn.hiddenlayer1nodes[1].w0=1
		nn.hiddenlayer1nodes[1].b=20
    --end: mockup neural values
  end,
  update=function(this,inputs)
    if btnp(0) and this.curel.x > 1 then this.curel.x-=1 end
    if btnp(1) and this.curel.x < this.curel.xmax then this.curel.x+=1 end
    if btnp(2) and this.curel.y > 1 then this.curel.y-=1 end
    if btnp(3) and this.curel.y < this.curel.ymax[this.curel.x] then this.curel.y+=1 end

    for i=1,#this.input do
			this.input[i].value = inputs[i]
		end

    -- reset values
    local res = {}

    this.tmrnt += 1
    if this.tmrnt > 5 then
        this.tmrnt = 0
        res = calculate_output()
    end

    for i=1,#res do
      this.output[i].value = res[i]
    end
  end,
  draw=function(this)
    rectfill(0, 119, 127, 127, 5)

    for i=1,#this.input do
			spr(54,2,66+(i-1)*16)
			print(this.input[i].value,2,74+(i-1)*16,12)
      if this.curel.x == 1 then
        spr(48,2,66+(i-1)*16)
        print(this.input[i].desc,2,121,12)
      end
		end

    for i=1,#this.hiddenlayer1nodes do
      for j=1,#this.input + 1 do
			  spr(49,10 + (j)*8,66+(i-1)*16)
        if this.curel.x == 1 + j then
          spr(48,10 + (j)*8,66+(i-1)*16)
          print("layer:1 node:"..i.." w"..(j-1),2,121,12)
        end
      end      
		end
    
    for i=1,#this.output do
			spr(55,110,66+(i-1)*16)
      if this.curel.x == this.curel.xmax then
        spr(48,110,66+(i-1)*16)
        print("output: "..this.output[i].desc,2,121,12)
      end
		end
  end
}

-- helper to initialize a layer
function init_layer(num_nodes, num_inputs)
  local layer = {}
  for i=1,num_nodes do
      local node = {}
      -- initialize weights for each input
      for j=1,num_inputs do
          node["w"..(j-1)] = 0 -- or random value like rnd()
      end
      node["b"] = 0 -- bias
      add(layer, node)
  end
  return layer
end

function calculate_output()
  local input_values = {}
  for i=1,#nn.input do
      input_values[i] = nn.input[i].value
  end
  
  local out1 = nil
  local out2 = nil

  if #nn.hiddenlayer1nodes > 0 then
      out1 = process_layer(nn.hiddenlayer1nodes, input_values)
  end

  if #nn.hiddenlayer2nodes > 0 then
      return process_layer(nn.hiddenlayer2nodes, out1)
  end
  
  return out1
end

-- function to calculate a layer output
function process_layer(layer, inputs)
 local outputs = {}
 for i=1,#layer do
     local node = layer[i]
     local sum = 0
     for j=1,#inputs do
         sum += node["w"..(j-1)] * inputs[j]
     end
     sum += node.b
     --printh(inputs[1]..","..node.b..","..node.w0..","..sum)
     outputs[i] = sigmoid(sum)
 end
 return outputs
end

function sigmoid(res)
  return res > 0
end

__gfx__
00000000000033330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000030330550055200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000033332088800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000300333002882288200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000333333302882288200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333002088800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033330000550055200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ee0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0eeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c006556000055660000666600006666000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000066556600655666005566660066666600666666000000000000000000000000000dddd00000000000000000000000000000000000000000000000000
0000000c66655666665566666555666655566666666666660011110000333300008888000dddddd0000000000000000000000000000000000000000000000000
c0000000666556666665566666555666555556665555566601cccc1003bbbb3008eeee800dddddd0000000000000000000000000000000000000000000000000
0000000c666556666665566666655666666556665555566601cccc1003bbbb3008eeee800dddddd0000000000000000000000000000000000000000000000000
c000000066666666666666666666666666666666666666660011110000333300008888000dddddd0000000000000000000000000000000000000000000000000
0000000c066666600666666006666660066666600666666000000000000000000000000000dddd00000000000000000000000000000000000000000000000000
c0c0c0c0006666000066660000666600006666000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000
