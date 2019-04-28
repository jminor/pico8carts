pico-8 cartridge // http://www.pico-8.com
version 17
__lua__
-- main

-- todo:
-- flapping affect vx?
-- moving platforms
-- make it fun
-- graphics

dirs={
 {x=-1,y=0},
 {x= 1,y=0},
 {x=0,y=-1},
 {x=0,y= 1},
}

gravity=1

function _init()
 actors={}
 solids={}
 players={}

 for i=1,3 do
  local pl=sprite.new(nil)
  pl.c=11-i
  pl.spd+=0.1*i
  pl.w=i*2
  pl.h=i*5
  pl.ox=-pl.w/2
  pl.oy=0
  add(actors,pl)
  add(players,pl)
 end
 players[2].canfly=true

 init_map()

end


function _update60()
 cls()
 map()
 -- controls
 local cx,cy,cj=0,0,false
 if (btn(0)) cx-=1
 if (btn(1)) cx+=1
 if (btn(2)) cy-=1
 if (btn(3)) cy+=1
 if (btnp(4)) cj=true
 for p in all(players) do
  p.cx=cx
  if p.canfly then
   p.cy=cj and -20 or 0
   p.vx*=0.9
   -- limit vy
   p.vy=mid(p.vy,2,-2)
  else
   -- going up => not standing
   if p.vy>=0 and p:standing() then
    -- vy=0 is key to a
    -- consistent jump
    p.vy=0
    p.cy=cj and -20 or 0
    p.vx*=0.8
   else
    p.cy=0
    p.vx*=0.9
   end
  end
  p:accel(
   p.cx*p.spd,
   p.cy*p.spd + gravity
  )
  p:movex(p.vx, function()
   p.vx=0
  end)
  p:movey(p.vy, function()
   p.vy=0
  end)
  p:draw()
  print("x="..p.x,p.c)
  print("y="..p.y)
  print("cx="..p.cx)
  print("cy="..p.cy)
  print("vx="..p.vx)
  print("vy="..p.vy)
 end
 
end


-->8
-- sprite stuff
sprite = {}

-- bare bones oop
function sprite.__index(t,k)
 return sprite[k]
end

function sprite.new(tile)
 local s={
 	t=tile,
 	c=nil, -- color
 	-- pos, size, vel, rem, offset
  x=0, w=8, vx=0, rx=0, ox=0,
  y=0, h=8, vy=0, ry=0, oy=0,
  spd=1
 }
 setmetatable(s,sprite)
 return s
end

function sprite.draw(self)
 if self.t~=nil then
  spr(
   self.t,
   self.x + self.ox,
   self.y + self.oy
  )
 end
 -- border
 if self.c~=nil then
  rect(
   self.x,
   self.y,
   self.x+self.w-1,
   self.y+self.h-1,
   self.c
  )
 end
end

function int(v)
 return v>=0 and flr(v) or -(flr(-v))
end

assert(int(0.7)==0)
assert(int(-0.7)==0)
assert(int(1.7)==1)
assert(int(-1.7)==-1)

function sprite:movex(dx,cb)
 local step=sgn(dx)
 self.rx+=dx
 local move=int(self.rx)
 self.rx-=move
 while move!=0 do
  if not self:overlap(self.x+step,self.y) then
   self.x+=step
  else
   if cb~=nil then cb() end
   break
  end
  move-=step
 end
end

function sprite:movey(dy,cb)
 local step=sgn(dy)
 self.ry+=dy
 local move=int(self.ry)
 self.ry-=move
 while move!=0 do
  if not self:overlap(self.x,self.y+step) then
   self.y+=step
  else
   if cb~=nil then cb() end
   break
  end
  move-=step
 end
end

function sprite:accel(ax,ay)
 local dt=0.1
 self.vx+=ax*dt
 self.vy+=ay*dt
end

function sprite:overlap(x,y)
 for a in all(actors) do
  if a~=self and self:overlap_spr(x,y,a) then
   return true
  end
 end
 -- check the corners vs map
 return map_overlap(f_solid,x,y,self.w,self.h)
end

function sprite:overlap_spr(x,y,a)
 return (x < a.x+a.w) and
  (y < a.y+a.h) and
  (x+self.w > a.x) and
  (y+self.h > a.y)
end

function sprite:standing()
 return self:overlap(self.x,self.y+1)
end

-->8
-- map stuff

-- flags
f_player=1
f_solid=2

function init_map()
 for x=0,15 do
  for y=0,15 do
   local t=mget(x,y)
   -- player
   if fget(t)==f_player then
    if players[t] then
     players[t].x=x*8
     players[t].y=y*8
    end
    mset(x,y,0)
   end
   -- solid
   if fget(t)==f_solid then
    -- randomize gfx
    if rnd()<0.5 then
     mset(x,y,t+1)
    end
   end
  end
 end
end

function map_overlap(flag,x,y,w,h)
 -- each tile is 8 pixels
 local x,y,w,h=x/8,y/8,w/8,h/8
 -- loop across each tile x,y
 -- that the rect covers
 for tx=flr(x),ceil(x+w-1) do
  for ty=flr(y),ceil(y+h-1) do
   -- what tile is there?
   local t=mget(tx,ty)
   -- does it match the flag?
   if (fget(t)==flag) return true
  end
 end
 -- no overlap
 return false
end

__gfx__
00000000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555555ddd50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555ddd55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000000000000000000555555550000000000000000000000000000000000000000000000005555ddd5
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000000000000000000555555550000000000000000000000000000000000000000000000005ddd5555
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
5555ddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
5ddd5555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
5555ddd50000000000000000000000000000000000000000000aaaaaaaa00000000000000000000000000000000000000000000055555555000000005555ddd5
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
5ddd55550000000000000000000000000000000000000000000aaaaaaaa00000000000000000000000000000000000000000000055555555000000005ddd5555
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
555555550000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000555555550000000055555555
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000005555ddd55555ddd500000000000000000000000000000000000000005555ddd500000000000000005555ddd5
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000005ddd55555ddd555500000000000000000000000000000000000000005ddd555500000000000000005ddd5555
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000005555555555555555000000000000000000000000000000000000000055555555000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555ddd500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005ddd555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000088888888000000005555555500000000000000000000000055555555
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
5555ddd500000000555555550000000000000000555555550000000000000000000000005555ddd5555555555555ddd50000000000000000000000005555ddd5
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
5ddd555500000000555555550000000000000000555555550000000000000000000000005ddd5555555555555ddd55550000000000000000000000005ddd5555
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
55555555000000005555555500000000000000005555555500000000000000000000000055555555555555555555555500000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
5555ddd5000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
5ddd5555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000055555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555ddd555555555555555555555ddd55555ddd555555555555555555555ddd55555ddd555555555555555555555555555555555555555555555ddd55555ddd5
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ddd555555555555555555555ddd55555ddd555555555555555555555ddd55555ddd555555555555555555555555555555555555555555555ddd55555ddd5555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001010100000000000000000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000100000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000100000101000000000001000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000100000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000100000001010100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
