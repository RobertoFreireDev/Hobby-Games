pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
 init_grid()
 spawn_piece()
end

function _update()
 if game_over then return end
 
 if btnp(⬆️) and can_move(piece_x, piece_y - 1, piece_rot) then
  piece_y -= 1
 elseif btnp(⬇️) and can_move(piece_x, piece_y + 1, piece_rot) then
  piece_y += 1
 elseif btnp(🅾️) then
  local new_rot = (piece_rot + 1) % 4
  if can_move(piece_x, piece_y, new_rot) then
   piece_rot = new_rot
  end
 elseif btnp(❎) then
  while can_move(piece_x - 1, piece_y, piece_rot) do
   piece_x -= 1
  end
  lock_piece()
 end

 fall_timer += 1
 if fall_timer / 60 >= fall_speed then
  if can_move(piece_x, piece_y + 1, piece_rot) then
   piece_x -= 1
  else
   lock_piece()
  end
  fall_timer = 0
 end
end

function _draw()
 cls(bg_color)
 draw_grid()
 draw_piece()
 draw_next_piece()
 print("score: "..score, 1,121, 7)
 if game_over then
  print("game over", 35, 60, 8)
 end
end

-->8
-- constants
grid_width = 16
grid_height = 14
cell_size = 8

-- colors
bg_color = 0
grid_color = 1

-- shapes
shapes = {
 { {1, 1, 1, 1} },           -- i
 { {2, 2, 0}, {0, 2, 2} },   -- z
 { {0, 3, 3}, {3, 3, 0} },   -- s
 { {4, 4, 4}, {0, 4, 0} },   -- t
 { {5, 5}, {5, 5} },         -- o
 { {6, 6, 6}, {6, 0, 0} },   -- l
 { {7, 7, 7}, {0, 0, 7} }    -- j
}

-- variables
grid = {}
current_piece = nil
piece_x = 0
piece_y = 0
piece_rot = 0
next_piece = nil
score = 0
game_over = false
fall_timer = 0
fall_speed = 0.5  -- slower fall speed
-->8
-- update logic

function init_grid()
 for y=1,grid_height do
  grid[y] = {}
  for x=1,grid_width do
   grid[y][x] = 0
  end
 end
end

function spawn_piece()
 current_piece = next_piece or flr(rnd(#shapes)) + 1
 next_piece = flr(rnd(#shapes)) + 1
 piece_x = 12
 piece_y = 4
 piece_rot = 0
 fall_timer = 0
 if not can_move(piece_x, piece_y, piece_rot) then
  game_over = true
 end
end

function can_move(px, py, prot)
 local shape = get_rotated_shape(current_piece, prot)
 for y=1,#shape do
  for x=1,#shape[1] do
   if shape[y][x] != 0 then
    local gx = px + x
    local gy = py + y
    if gx < 1 or gx > grid_width or gy > grid_height or grid[gy][gx] != 0 then
     return false
    end
   end
  end
 end
 return true
end

function get_rotated_shape(piece, rot)
 local shape = shapes[piece]
 for i=1,rot do
  shape = rotate(shape)
 end
 return shape
end

function rotate(shape)
 local new_shape = {}
 for x=1,#shape[1] do
  new_shape[x] = {}
  for y=1,#shape do
   new_shape[x][y] = shape[#shape-y+1][x]
  end
 end
 return new_shape
end

function lock_piece()
 local shape = get_rotated_shape(current_piece, piece_rot)
 for y=1,#shape do
  for x=1,#shape[1] do
   if shape[y][x] != 0 then
    grid[piece_y + y][piece_x + x] = shape[y][x]
   end
  end
 end
 clear_lines()
 spawn_piece()
end

function clear_lines()
 for y=grid_height,1,-1 do
  local full = true
  for x=1,grid_width do
   if grid[y][x] == 0 then
    full = false
    break
   end
  end
  if full then
   for yy=y,2,-1 do
    for xx=1,grid_width do
     grid[yy][xx] = grid[yy-1][xx]
    end
   end
   for xx=1,grid_width do
    grid[1][xx] = 0
   end
   score += 100
   y += 1
  end
 end
end
-->8
-- draw logic

function draw_grid()
 for y=1,grid_height do
  for x=1,grid_width do
   local cell = grid[y][x]
   if cell != 0 then
    rectfill((x-1) * cell_size, (y-1) * cell_size, x * cell_size - 1, y * cell_size - 1, cell)
   else
    rect((x-1) * cell_size, (y-1) * cell_size, x * cell_size - 1, y * cell_size - 1, grid_color)
   end
  end
 end
end

function draw_piece()
 local shape = get_rotated_shape(current_piece, piece_rot)
 for y=1,#shape do
  for x=1,#shape[1] do
   if shape[y][x] != 0 then
    rectfill((piece_x + x - 1) * cell_size, (piece_y + y - 1) * cell_size, (piece_x + x) * cell_size - 1, (piece_y + y) * cell_size - 1, shape[y][x])
   end
  end
 end
end

function draw_next_piece()
 local shape = get_rotated_shape(next_piece, 0)
 local offset_x = 90
 local offset_y = 112
 for y=1,#shape do
  for x=1,#shape[1] do
   if shape[y][x] != 0 then
    rectfill(offset_x + (x-1) * cell_size, offset_y + (y-1) * cell_size, offset_x + x * cell_size - 1, offset_y + y * cell_size - 1, shape[y][x])
   end
  end
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
