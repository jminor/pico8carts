pico-8 cartridge // http://www.pico-8.com
version 17
__lua__
-- main

-- todo:
-- flapping affect vx?
-- wide moving platforms
-- circular moving platforms
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
 sliders={}

 for i=1,3 do
  local pl=sprite.new("pl"..i,i)
  --pl.c=8-i
  pl.enabled=false
  pl.spd+=0.1*i
  pl.w=6
  pl.h=6
  pl.ox=-1
  pl.oy=-2
  add(actors,pl)
  add(players,pl)
 end
 if players[2] then
	 players[2].canfly=true
 end
 
 init_map()

 -- make one diagonal platform 
-- local sl=sliders[1]
-- sl.collides_map=f_solid
-- sl.collides_map_exclude=false
-- sl.vx=1/2
-- sl.vy=1/2

end


function _update60()
 cls()
 map()
 -- controls
 local cx,cy,cj=0,0,false
 if (btn(0)) cx-=1
 if (btn(1)) cx+=1
-- if (btn(2)) cy-=1
-- if (btn(3)) cy+=1
 if (btnp(2) or btnp(4)) cj=true

 update_sliders()
 update_players(cx,cy,cj)
 
 for p in all(players) do
  p:draw()
 end
 for sl in all(sliders) do
  sl:draw()
 end
end

function update_players(cx,cy,cj)
 for p in all(players) do
  p.cx=cx
  if p.canfly then
   p.cy=cj and -20 or 0
   p.vx*=0.9
   -- limit vy
   p.vy=mid(p.vy,2,-2)
  else
   -- can we jump?
   -- going up => not standing
   if p.vy>=0 and p:standing() then
    -- vy=0 is key to a
    -- consistent jump
    p.vy=0
    p.cy=cj and -20 or 0
    p.vx*=0.8
   -- wall jump
   elseif cj and p.cx~=0 and p:standing(cx,0) then
    p.vy=0
    p.cy=cj and -20 or 0
    p.vx=0
    p.cx*=-20
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
--  print("x="..p.x,p.c)
--  print("y="..p.y)
--  print("cx="..p.cx)
--  print("cy="..p.cy)
--  print("vx="..p.vx)
--  print("vy="..p.vy)
 end
end

function update_sliders()
 for sl in all(sliders) do
  local riders=sl:riders()
  local bouncex,bouncey=false,false
  local rider=""

  local mx=sl:movex(sl.vx, function()
   bouncex=true
  end)
--  assert(mx==0 or mx==1 or mx==-1)
  if mx~=0 then
   sl.collides=false
   for a in all(actors) do
    if a:overlap_spr(a.x,a.y,sl) then
     while (
      not a.squished and
      a:overlap_spr(a.x,a.y,sl)
     ) do
      a:movex(sgn(mx), function()
       a:squish()
      end)
     end
    elseif find(riders,a) then
     rider=rider.."x+"..mx
     a:movex(mx)
    end
   end
   sl.collides=true
  end

  local my=sl:movey(sl.vy, function()
   bouncey=true
  end)
--  assert(my==0 or my==-1 or my==1)
  if my~=0 then
   sl.collides=false
   for a in all(actors) do
    if a:overlap_spr(a.x,a.y,sl) then
     while (
      not a.squished and
      a:overlap_spr(a.x,a.y,sl)
     ) do
      a:movey(sgn(my), function()
       a:squish()
      end)
     end
    elseif find(riders,a) then
     rider=rider.." y+"..my
     a:movey(my)
    end
   end
   sl.collides=true
  end

  if (bouncex) sl.vx*=-1
  if (bouncey) sl.vy*=-1

--  if sl==sliders[1] then
--  color(7)
--  print("x="..sl.x)
--  print("y="..sl.y)
--  print("mx="..mx)
--  print("my="..my)
--  print("r="..rider.."#"..#riders)
--  end
 end
 
end

-->8
-- sprite stuff
sprite = {}

-- bare bones oop
function sprite.__index(t,k)
 return sprite[k]
end

function sprite.new(name, tile)
 local s={
  name=name,
 	t=tile,
 	ts={tile},
 	enabled=true,
 	c=nil, -- color
 	-- pos, size, vel, rem, offset
  x=0, w=8, vx=0, rx=0, ox=0,
  y=0, h=8, vy=0, ry=0, oy=0,
  spd=1, -- speed
  collides_actors=true,
  collides_solids=true,
  collides_map=f_solid,
  collides_exclude=false,
  collides=true
 }
 setmetatable(s,sprite)
 return s
end

function sprite.draw(self)
 if not self.enabled then return end
 if self.t~=nil or self.ts~=nil then
  if self.w>8 or self.h>8 then
   local ti=1
   for tx=0,ceil(self.w/8)-1 do
    for ty=0,ceil(self.h/8)-1 do
     spr(
      self.ts[ti],
      self.x+tx*8 + self.ox,
      self.y+ty*8 + self.oy
     )
     ti=(ti%#self.ts)
    end
   end
  else
   spr(
    self.t,
    self.x + self.ox,
    self.y + self.oy
   )
  end
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

function sprite:movex(dx,cb,flag)
 if not self.enabled then return end
 if (dx==0) return 0
 local step=sgn(dx)
 self.rx+=dx
 local move=int(self.rx)
 local moved=0
 self.rx-=move
 while move!=0 do
  if self:overlap(self.x+step,self.y,flag) then
   if (cb) cb()
   break
  end
  self.x+=step
  moved+=step
  move-=step
 end
 return moved
end

function sprite:movey(dy,cb,flag)
 if not self.enabled then return end
 if (dy==0) return 0
 local step=sgn(dy)
 self.ry+=dy
 local move=int(self.ry)
 local moved=0
 self.ry-=move
 while move!=0 do
  if self:overlap(self.x,self.y+step,flag) then
   if (cb) cb()
   break
  end
  self.y+=step
  moved+=step
  move-=step
 end
 return moved
end

function sprite:accel(ax,ay)
 local dt=0.1
 self.vx+=ax*dt
 self.vy+=ay*dt
end

function sprite:overlap(x,y,flag)
 if (not self.collides or not self.enabled) return
 if self.collides_actors then
  for a in all(actors) do
   if a~=self and a.enabled and a.collides and self:overlap_spr(x,y,a) then
    return true
   end
  end
 end
 if self.collides_solids then
  for s in all(solids) do
   if s~=self and s.enabled and s.collides and self:overlap_spr(x,y,s) then
    return true
   end
  end
 end
 if self.collides_map then
  -- check the corners vs map
  return map_overlap(
   self.collides_map,
   x,y,self.w,self.h,
   self.collides_map_exclude)
 end
 return false
end

function sprite:overlap_spr(x,y,a)
 return (x < a.x+a.w) and
  (y < a.y+a.h) and
  (x+self.w > a.x) and
  (y+self.h > a.y)
end

function sprite:standing(x,y)
 if x==nil then x,y=0,1 end
 return self:overlap(self.x+x,self.y+y)
end

function sprite:riders()
 local t={}
 for a in all(actors) do
  if a.enabled and a:overlap_spr(a.x,a.y+1,self) then
   add(t,a)
  end
 end
 return t
end

function sprite:squish()
 self.c=8
 self.squished=true
end

-->8
-- map stuff

-- flags
f_player=1
f_solid=2
f_slider=4
f_track=8

function init_map()
 local si=1
 for x=0,15 do
  for y=0,15 do
   local t=mget(x,y)
   local f=fget(t)
   -- player
   if f==f_player then
    local pl=players[t]
    if pl then
     pl.enabled=true
     pl.x=x*8
     pl.y=y*8
    end
    mset(x,y,0)
   end
   -- solid
   if f==f_solid then
    -- randomize gfx
    if rnd()<0.5 then
     mset(x,y,t+1)
    end
   end
   -- sliders
   if f==f_slider then
    local sl=sprite.new("sl"..si,t)
    si+=1
    sl.x=x*8
    sl.y=y*8
    sl.vx=t==32 and 1/4 or 0
    sl.vy=t==48 and 1/4 or 0
    sl.collides_actors=false
    sl.collides_solids=false
    sl.collides_map=f_track
    sl.collides_map_exclude=true
    add(sliders,sl)
    add(solids,sl)
    mset(x,y,t+1)
    -- look for wide platforms
    for x2=ceil(x+sl.w/8),15 do
     local t2=mget(x2,y)
     if fget(t2)!=f_slider then break end
     -- add the tile to .ts
     add(sl.ts,t2)
     -- replace with a track
     mset(x2,y,t2+1)
     -- make sl wider
     sl.w+=8
     x2+=1
    end
   end
  end
 end
end

function map_overlap(flag,x,y,w,h,exclude)
 -- each tile is 8 pixels
 local x,y,w,h=x/8,y/8,w/8,h/8
 -- loop across each tile x,y
 -- that the rect covers
 for tx=flr(x),ceil(x+w-1) do
  for ty=flr(y),ceil(y+h-1) do
   -- what tile is there?
   local t=mget(tx,ty)
   -- does it match the flag?
   local f=fget(t)
   if (
    (exclude and f~=flag) or
    (not exclude and f==flag)
   ) then
    return true
   end
  end
 end
 -- no overlap
 return false
end

-->8
-- utils

function int(v)
 return v>=0 and flr(v) or -(flr(-v))
end

assert(int(0.7)==0)
assert(int(-0.7)==0)
assert(int(1.7)==1)
assert(int(-1.7)==-1)

function find(table,value)
 for k,v in pairs(table) do
  if (v==value) return k
 end
 return nil
end

function _test_find()
 assert(find({6,7},7)==2)
 assert(find({6,7},8)==nil)
 local a={1}
 local b={1}
 assert(find({a,b},a)==1)
 assert(find({a,b},b)==2)
 assert(find({a,b},{1})==nil)
end
_test_find()

__gfx__
000000000a0000a09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000a0aa0a09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000aaaaaa09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000aa00aa09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000aaaaaa09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a00a009999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa00aa09999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555555ddd50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555ddd55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dddddd6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dddddd6010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd66dd6000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001010100000000000000000000000002020000000000000000000000000000040800000000000000000000000000000408000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111311111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111310031003111000000313131011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111310031003000000011313131001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111310031003111000031303130001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111310030003111000031313031001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100310031003100001130113131001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100300030003011000031003131001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100310031003100000031003131001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100311131003100000000113030001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100112131202030212030001031111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100111131003000001111212130211100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000031113100000000110000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111000000000000000000000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
