pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- gooooose!!! v4
-- by @joshm & @jmk
-- todo:
-- x goose sprite
-- x soccer goal
-- x laser gate
-- x honk
-- x poo
-- x 2-players
-- x 60 fps
-- - title screen
-- x idle timer
-- - music
-- x sfx by @jmk
-- x button labels

-- to run w/o editor or splore:
-- w/in pico:
--   export goose.bin
-- then in shell:
--   goose.bin/raspi/goose

t=0
sprites={}
t_fence=0
t_goose=1
t_player=2
t_seeds=3
t_gate=4
geese={}
seeds={}
poops={}
gates={}
fences={}
players={}
living={}
obstacles={}
shouted=0
gated=0
level=0
is_win=false
coop_full=false
gate_open=true
idle=0

function mksprite(x,y,vx,vy,v)
 return {
  t=x+y,
  x=x,
  y=y,
  vx=vx,
  vy=vy,
  fx=1,
  tile=v,
  ntiles=1,
  ts=6,
  hidden=false,
  solid=true,
  update=spr_update,
  draw=spr_draw,
  shadow=false,
  say=spr_say,
  speech=nil,
  speechcount=0
 }
end

function _init()
 --music(1)
 for y=0,15 do
  for x=0,15 do
   mx=x+level*16
   v=mget(mx,y)
   if fget(v,t_fence) then
    mset(mx,y,48+rnd(4))
    s=mksprite(x,y,0,0,v)
    add(sprites,s)
    add(fences,s)
    add(obstacles,s)
   end
   if fget(v,t_goose) then
    mset(mx,y,48+rnd(4))
    s=mksprite(x,y,
     (rnd(2)-1)/16,
     (rnd(2)-1)/16,
     v)
    s.ntiles=2
    s.t=x
    s.update=chx_update
    s.eating=false
    add(sprites,s)
    add(geese,s)
    add(living,s)
   end
   if fget(v,t_player) then
    mset(mx,y,48+rnd(4))
    s=mksprite(x,y,0,0,v)
    s.id=#players
    --s.hidden=true
    s.ntiles=2
    s.update=ply_update
    add(sprites,s)
    add(players,s)
    add(living,s)
   end
   if fget(v,t_seeds) then
    mset(mx,y,48+rnd(4))
    s=mksprite(x,y,0,0,v)
    add(sprites,s)
    add(seeds,s)
   end
   if fget(v,t_gate) then
    mset(mx,y,48+rnd(4))
    s=mksprite(x,y,0,0,v-1)
    --s.solid=false
    s.ntiles=1
    s.ts=2
    add(sprites,s)
    add(gates,s)
    add(obstacles,s)
   end
  end
 end

 find_coop()
 toggle_gate()

 for s in all(living) do
  s.shadow=true
  del(sprites,s)
 end
 for s in all(living) do
  add(sprites,s)
 end
end

function find_coop()
 f=fences[1]
 coop={x0=f.x,x1=f.x,y0=f.y,y1=f.y}
 for f in all(fences) do
  if (f.x<coop.x0) coop.x0=f.x
  if (f.x>coop.x1) coop.x1=f.x
  if (f.y<coop.y0) coop.y0=f.y
  if (f.y>coop.y1) coop.y1=f.y
 end
 coop.x0+=1
 coop.x1-=1
 coop.y0+=1
 coop.y1-=1
end

function toggle_gate()
 gate_open=not gate_open
 if is_win then gate_open=false end
 for s in all(gates) do
  s.solid=not gate_open
  if gate_open then
   s.tile=53
   s.ntiles=1
  else
   s.tile=54
   s.ntiles=4
  end
 end
end

function in_zone(s,z)
 return (s.x>z.x0 and
         s.x<z.x1 and
         s.y>z.y0 and
         s.y<z.y1)
end

function all_in_zone(l,z)
 for s in all(l) do
  if not in_zone(s,z) then
   return false
  end
 end
 return true
end

function _update60()
 t=t+1
 for s in all(sprites) do
  s:update()
 end

 check_win()

 idle=idle+1
 if idle>1800 then
  -- after 1 min idle, restart
  run()
 end
end

function check_win()
 if is_win then
  if #players == 1 then
   players[1]:say("i did it!")
  else
   for p in all(players) do
    p:say("we did it!")
   end
  end
  if t>win_time+1000 then
    run()
  end
 else
  coop_full = all_in_zone(geese,coop)
  if coop_full and not gate_open then
   is_win=true
   win_time=t
   sfx(2)
  end
 end
end

function _draw()
 cls()
 mapdraw(level*16,0,0,0,16,16)
-- for s in all(sprites) do
 for i=#sprites,1,-1 do
  s=sprites[i]
  s:draw()
 end
 if is_win then
  rcprint2("gooooose!!!",64,1*8)
  rcprint2("you win!!!",64,12*8)
 elseif coop_full and gate_open then
  xcprint2(62,"quick! close the goal!",64,14*8,7)
 else
  if t<400 or idle>=400 then
   rcprint2("gooooose!!!",64,1*8)
   cprint2("get all the geese",64,14*8,7)
   cprint2("into the goal",64,15*8,7)
  else
   if shouted<3 then
    xcprint2(63,"to yell",64,14*8,7)
   end
   if gated<3 then
    xcprint2(62,"to open/close the goal",64,15*8,7)
   end
  end
 end
end

function clamp(t,a,b)
 if (t<a) return a
 if (t>b) return b
 return t
end

function wrap(t,a,b)
 return a+(t-a)%(b-a)
end

function lerp(t,a,b)
 return a+t*(b-a)
end

function unlerp(t,a,b)
 return (t-a)/(b-a)
end

function overlaps(a,b)
 return (abs(a.x-b.x)<1 and
         abs(a.y-b.y)<1)
end

function overlaps_any(s,l)
 for o in all(l) do
  if overlaps(s,o) then
   return true
  end
 end
 return false
end

function willbump(s,dx,dy,ss)
 if not s.solid then return nil end
 if s.hidden then return nil end
 ox=s.x
 oy=s.y
 s.x+=dx
 s.y+=dy
 result=nil
 for o in all(ss) do
  if s!=o and o.hidden==false and o.solid and overlaps(s,o) then
   result=o
   break
  end
 end
 s.x=ox
 s.y=oy
 return result
end

function sign(x)
 if x<0 then return -1 end
 if x>0 then return 1 end
 return 0
end

function length(x,y)
 return sqrt(x*x+y*y)
end

function flee(s,o)
 vel=length(s.vx,s.vy)
 if vel<1/16 then vel=1/16 end
 --if vel>1 then vel=1 end
 dx=s.x-o.x
 dy=s.y-o.y
 len=length(dx,dy)
 --if len<1/8 then len=1/8 end
 s.vx=dx/len*vel
 s.vy=dy/len*vel
end

function spr_update(s)
 s.x=wrap(s.x+s.vx,-1,16)
 s.y=wrap(s.y+s.vy,-1,16)

 if s.vx<0 then s.fx=-1 end
 if s.vx>0 then s.fx=1 end

 s.t+=1
end

function spr_say(s,speech)
 s.speech=speech
 s.speechcount=60
end

function cprint(txt,x,y,c)
 print(txt,x-#txt*2,y,c)
end
function cprint2(txt,x,y,c)
 local xx=x-#txt*2
 --if t%2==0 then
  print(txt,xx+1,y+1,0)
 --end
 print(txt,xx,y,c)
end
function rprint(txt,x,y)
 for i=1,#txt do
  c=(i+t/3)%8+8
  print(sub(txt,i,i),x-4+i*4,y,c)
 end
end
function rcprint2(txt,x,y)
 local xx=x-#txt*2
 print(txt,xx+1,y+1,0)
 rprint(txt,xx,y)
end
function xcprint2(z,txt,x,y,c)
 local txt="   "..txt
 local xx=x-#txt*2
 allpal(0)
 spr(z,xx,y,1,1)
 pal()
 yy=y-(((t+y)/12)%2)
 spr(z,xx,yy,1,1)
 print(txt,xx+1,y+1,0)
 print(txt,xx,y,c)
end
function allpal(c)
 for i=0,15 do
  pal(i,c)
 end
end

function spr_draw(s)
 if s.hidden then return end
 tile=s.tile
 if s.ntiles>1 then
  tile += (s.t/s.ts)%(s.ntiles)
 end
 if s.shadow and (t%2)==0 then
  pal(5,0)
  spr(0,s.x*8,s.y*8+4,1,1)
  pal()
 end
 spr(tile,s.x*8,s.y*8,1,1,s.fx<0)
 if s.speechcount>0 then
  cprint2(s.speech,s.x*8+4,s.y*8-8,7)
  s.speechcount-=1
 end
end

function ply_update(s)
 s.vx=0
 s.vy=0
 local speed=1/10
 if btn(0,s.id) then s.vx=-speed end
 if btn(1,s.id) then s.vx=speed end
 if btn(2,s.id) then s.vy=-speed end
 if btn(3,s.id) then s.vy=speed end
 if btnp(4,s.id) then
  idle=0
  s.hidden=false
  gated+=1
  toggle_gate()
  sfx(3)
 end
 if btnp(5,s.id) then
  idle=0
  s.hidden=false
  shouted+=1
  s:say("!!!")
  sfx(8)
  for c in all(geese) do
   flee(c,s)
   c:say("honk!")
  end
 end

 if s.hidden then return end

 if s.vx~=0 or s.vy~=0 then
  idle=0
 end

 ox=willbump(s,s.vx,0,obstacles)
 if ox!=nil then
  s.vx=0
 end
 oy=willbump(s,0,s.vy,obstacles)
 if oy!=nil then
  s.vy=0
 end

 ox=willbump(s,s.vx,0,players)
 if ox!=nil then
  s.vx=0
 end
 ox=willbump(s,0,s.vy,players)
 if ox!=nil then
  s.vy=0
 end

 st=s.t
 spr_update(s)
 if s.vx==0 and s.vy==0 then
  s.t=st
 end
end

function sfx_honk()
  -- note: rnd({5,6,7}) always
  -- returns zero??
  sfx(rnd(3)+5)
end

function chx_update(s)
 if overlaps_any(s,seeds) then
  s.vx=0
  s.vy=0
  s.tile=2
  s.ntiles=12
  s.eating=true
 else
  s.tile=1
  s.ntiles=2
  s.eating=false
 end

 o=willbump(s,s.vx,s.vy,living)
 if o!=nil then
  flee(s,o)
  x = rnd({5,6,7})
  --print(x)
  if (t%10==0) sfx_honk()
  s:say("honk!")
 end

 ox=willbump(s,s.vx,0,obstacles)
 if ox!=nil then
  s.vx*=-1
  s:say("honk!")
 end
 oy=willbump(s,0,s.vy,obstacles)
 if oy!=nil then
  s.vy*=-1
  s:say("honk!")
 end

 if rnd(50) < 1 then
  poop(s.x,s.y)
 end

 spr_update(s)
end

function poop(x,y)
 s=mksprite(x,y,0,0,31)
 s.solid=false
 add(sprites,s)
 add(poops,s)
 if #poops>500 then
  del(sprites,poops[1])
  del(poops,poops[1])
 end
end

__gfx__
00000000000001100000011000000110000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007550000075500000755000007550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000700000007000000070000000705666000056660000566600005666000056660000566600005666000056660000566600005666000056660000
00000000556660105566601055666010556660105566600055666000556660005566600055666000556660005566600055666000556660005566600055666000
05555550055667100556671005566710055667100556771105567711055677110556771105567711055677110556771105567711055677110556771105567711
55555555005577000055770000557700005577000056717100567171005671710056717100567171005671710056717100567171005671710056717100567171
05555550000110000001000000010000000100000001007500010075000100750001007500010075000100750001007500010075000100750001007500010075
00000000001001000001100000011000000110000001100500011005000110050001100500011005000110050001100500011005000110050001100500011005
08888880088888800111111001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888fff00888fff001114440011144400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88f5f50088f5f5001145450011454500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88ffff0088ffff001144440011444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8ccccc008ccccc001999990019999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f66666f0f66666f04eeeee404eeeee40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc000ccccc000999990009999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000100001010000100010000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000
00000000007760070077667000000000000000000000000033333333333363333333333333336333333656333333333300000000000000000000000000000000
0000007600770607007766700000000000a000a00000000033333333333363333333333333336333333666333333333300000000000000000000000000000000
77777776007700677777760000000000000000000000a00033333333333363333333333333336333336777633367776300000000000000000000000000000000
0000060000770007007776000000000000a00a0000000000666366633333333366633333666333333377c776337ccc7600000000000000000000000000000000
600060600077006700777600000aa00000000000000000a033333333333363333333633333333333337ccc763377c77600000000000000000000000000000000
06060006007706070077760000aaaa000a0000a000a0000033333333333363333333633333333333336777633367776300000000000000000000000000000000
0060000000776007007776700aaaaaa0000a00000000000033333333333363333333633333333333335666533356665300000000000000000000000000000000
77777776007700077777777000000000000000a00000000033333333333333333333333333333333333555333336563300000000000000000000000000000000
333333333333333333333333333333333333333300000000000c7c00000c0c00000c0c00000c7c00000000000000000000000000000000000000000000000000
3333333333333b333b333333333333333b33333300000000000c7c00000c7c00000c0c00000c0c00000000000000000000000000000000000088880000999900
333333333b3333333333333333333333333333b300000000000c0c00000c7c00000c7c00000c0c00000000000000000000000000000000000882888009949990
b333333333b3333333333333333333333333333300000000000c0c00000c0c00000c7c00000c7c00000000000000000000000000000000000828888009499990
3b3333b333b3333b3333333333333333333b333300000000000c7c00000c0c00000c0c00000c7c000000000000000000000000000000000008888f8009999a90
3b333b33333333b333333333333333333333333b00000000000c7c00000c7c00000c0c00000c0c00000000000000000000000000000000000888f8800999a990
3b3b3b33333333b3333333b3333333333b33333300000000000c0c00000c7c00000c7c00000c0c00000000000000000000000000000000000088880000999900
333333333333333333333333333333333333333300000000000c0c00000c0c00000c7c00000c7c00000000000000000000000000000000000000000000000000
__label__
11333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333b333b33333333333333333333333333333333333b333b333333333333333b333333333333333333333333333b333b3333333333333333333333
333333333b333333333333333333333333333333333333333b3333333333333333333333333333b333333333333333333b333333333333333333333333333333
b333333333b33333333333333333333333333333b333333333b3333333333333333333333333333333333333b333333333b33333333333333333333333333333
3b3333b333b3333b3333333333333333333333333b3333b333b3333b3333333333333333333b3333333333333b3333b333b3333b333333333333333333333333
3b333b33333333b33333333333333333333333333b333b33333333b333333333333333333333333b333333333b333b33333333b3333333333113333333333333
3b3b3b33333333b3333333b333333333333333333b3b3b33333333b3333333b3333333333b333333333333333b3b3b33333333b3333333b35573333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333733333333333333
33333333333333333333333333333333333333333339933aa33bb33cc33dd33ee33ff3888339333a333b33333333333333333333333333333136665533333333
3333333333333b333b3333333b3333333b333333339300a3a0b3b0c3c0d3d0e3e0f300800039033a033b033333333b333b333333333333333176655333333333
333333333b33333333333333333333b333333333339033a0a0b0b0c0c0d0d0e0e0fff388333903ba033b03333b3333333333333333333333337755b333333333
3333333333b33333333333333333333333333333339093a0a0b0b0c0c0d0d0e0e030f080033303330333033333b3333333333333333333333331133333333333
3333333333b3333b33333333333b333333333333339990aa30bb30cc30dd30ee30ff30888339333a333b333333b3333b3333333333333333331b313333333333
33333333333333b3333333333333333b33333333333000300330033003300330033003300033033b03330333333333b333333333333333333000000b33333333
33333333333333b3333333b33b333333333333b3333333333b333333333333b3333333333b33333333333333333333b3333333b3333333330000000033333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333000000333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333b333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333b3
66636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663333333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333336333333b3333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333363333333333b
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333363333b333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
33333333333333333b3333333b33333333333b3333333b3333333b333b3333333b11333333333333333333333b333333333333333b3333333333633333333b33
3333333333333333333333b3333333b33b3333333b3333333b333333333333b3113333b33333333333333333333333b333333333333333b3333363333b333333
3333333333333333333333333333333333b3333333b3333333b33333333333333333333333333333333333333333333333333333333333333333333333b33333
3333333333333333333b3333333b333333b3333b33b3333b33b3333b333b3333333b33333333333333333333333b333333333333333b33333333633333b3333b
33333333333333333333333b3333333b333333b3333333b3333333b33333333b3333333b33333333333333333333333b333333333333333b33336333333333b3
33333333333333333b3333333b333333333333b3333333b3333333b33b3333333b33333333333333333333333b333333333333333b33333333336333333333b3
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333337766733333633333333333
3b33333333333b333b3333333333333333333b333333333333331133333333333333333333333333333333763b333376333333763b7766733333633333333333
333333b33b33333333333333333333333b333333333333333b333333333333333333333333677763777777767777777677777776777776333333633333333333
3333333333b33333333333333333333333b33333b333333333b333333333333333333333337ccc76333336333333363333333633337776333333333333333333
333b333333b3333b333333333333333337b73377377337b73373333b33333333333333333377c776633363636333636363336363337776333333633333333333
3333333b333333b33333333333333333370707b707073707037033b3333333333333333333677763363633363636333636363336337776333333633333333333
3b333333333333b3333333b3333333333777070707070773037033b333333333333333333356665333633333336333b333633333337776733333633333333333
33333333333333333333333333333333370707070707070733303333333333333333333333365633777777767777777677777776777777733333333333333333
333333333333333333333333333333333707077307070707037333333333333333333333333c7c33333333333333333333333333337763373333633333333333
3b33333333333b333b3333333b3333333b0303003b030303033033333b3333333b333333333c7c333b3333333333333333a333a3337736373333633333333333
333333b33b333333333333b3333333b333333333333333b33333333333333333333333b3333c3c333333333333333333333333333b7733673333633333333333
3333333333b3333333333333333333333333333333333333333333333333333333333333333c3c33333333333333333333a33a333377333733333333b3333333
333b333333b3333b333b3333333b333333333333113b33333333333333333333333b3333333c7c3333333333333333333333333333773367333363333b3333b3
3333333b333333b33333333b3333333b333333355733333b33333333333333333333333b333c7c3333333333333333333a3333a3337736b7333363333b333b33
3b333333333333b33b3333333b333333333333b37b33333333333333333333b33b333333333c3c33333333b333333333333a3333337763b7333363333b3b3b33
333333333333333333333333333333333333333313666553333333333333333333333333333c3c333333333333333333333333a3337733373333333333333333
333333333888888333333333333333333333333317665533333333333333333333333333333c7c33333333333333333333333333337763373333633333333333
33333333888fff3333333333333333333b333333377553333b3333333333333333333333333c7c333b33333333333333333333333b7736373333633333333333
3333333388f5f5333333333333333333333333b333113333333333b33333333333333333333c3c33333333b33333a33333333333337733673333633333333333
b333333388ffff3333333333333333333333333331331113333333333333333333333333333c3c333333333333333333b3333333337733373333333333333333
3b3333b38cccccb33333331133333333333b333300000033333b33333331133333333333333c7c33333b3333333333a33b3aa3b3337733673333633333333333
3b333b33f66666f3333333333333333333333330000000033333333b3333333333333333333c7c333333333b33a333333baaaa33337736373333633333333333
3b3b3b333ccccc3333333333333333333b333333000000333b3333333333331133333333333c3c333b333333333333333aaaaaa3337763b73333633333333333
333333333313133333333333333333333333333333333333333333333333333333333333333c3c33333333333333333333333333337733373333333333333333
333333333000000333333333333333333333333333333333333333333333333333113333333c3c33333333333333333333333333337763373333633333333333
3b333333000000003b33333333333b333b3333333333333333333333333333333b333333333c7c333333333333333b3333a333a3337736373333633333333b33
333333b330000003333333b33b333333333333b333333333333333333333333333333333333c7c33333333333b333333333333333b773367333363333b333333
33333333333333333333333333b3333333333333b3333333333333333333333333333333b33c3c333333333333b3333333a33a33337733373333333333b33333
333b3333333b3333333b333333b3333b333b33333b3333b33333333333333333333333333b3c3cb33333333333b3333b33333333337733673333633333b3333b
3333333b3333333b3333333b333333b33333333b3b333b333333333333333333333333333b3c7c3333333333333333b33a3333a3337736b733336333333333b3
3b3333333b3333333b333333333333b33b3333333b3b3b333333333333333333333333b33b3c7c3333333333333333b3333a3333337763b733336333333333b3
333333333333333333333333333333333333333333333333333333333333333333333333333c3c333333333333333333333333a3337733373333333333333333
333333333111111333333333333333333333333333333333333333333333333333333333333c3c33333333333333333333333333337763373333633333333333
33333333111444333b333333333333333b3333333333333333333b333b33333333333333333c7c333b33333333333333333333333b773637333363333b333333
3333333311454533333333b333333333333333b3333333333b3333333333333333333333333c7c333333333333333333333333333377336733336333333333b3
b333333311444433333333333333333333333333b333333333b333333333333333333333b33c3c33333333333333333333333333337733373333333333333333
3b3333b319999933333b311333333333333b33333b3333b333b3333b33333333333333333b3c3cb33333333333333333333333333377336733336333333b3333
3b333b334eeeee433333333b333333333333333b3b333b33333333b333333333333333333b3c7c3333333333333333333333333333773637333363333333333b
3b3b3b33399999333b333333333333333b3333333b3b3b33333333b3333333b3333333333b3c7c33333333b33333333333333333337763b7333363333b333333
333333333313133333333333333333333333333333333333333333333333333333333333333c3c33333333333333333333333333337733373333333333333333
333333333000000333333333333333333333333333333333333333333333333333333333333c3c33333333333333333333333333337763373333633333333333
33333b330000000033333333333333333b3333333b1133333b3333333b33333333333b33333c3c333333333333333b3333333b33337736373333633333333b33
3b333333300000033333113333333333333333333333333333333333333333333b3333333b3c7c33333333333b3333333b33333333773367333363333b333333
33b3333333b33333b3333333333333333333333333333333333333333333333333b3333333bc7c333333333333b3333333b33333b37733373333333333b33333
33b3333b33b3333b3b3333b3333333333333333333333333333333333333333333b3333b33bc3c3b3333333333b3333b33b3333b3b7733673333633333b3333b
333333b3333333b33b333b333333333333333333333333333333333333333333333333b3333c3cb333333333333333b3333333b33b77363733336333333333b3
333333b3333333b33b3b3b3333333333333333b3333333b3333333b3333333b3333333b3333c7cb333333333333333b3333333b33b776b3733336333333333b3
333333333333333333333333333333333333333333333333333333333333333333333333333c7c33333333333333333333333333337733373333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333365633333333333333333333333333337766733333633333333333
3333333333333b333b3333333333333333333b333333333333333b3333333b333b333333333666333333337633333376333333763b776673333363333b333333
333333333b333333333333b3333333333b333333333333333b3333333b3333333333333333677763777777767777777677777776777776333333633333333333
3333333333b33333333333333333333333b333333333333333b3333333b33333333333333377c77633333633b333363333333633337776333333333333333333
3333333333b3333b333b33333333333333b3333b3333333333b3333b33b3333b33333333337ccc76633363636b33636363336363337776333333633333333333
33333333333333b33333333b33333333333333b333333333333333b3333333b333333333336777633636333636363b3636363336337776333333633333333333
33333333333333b33b33333333333333333333b333333333333333b3333333b3333333b333566653336333333b6b3b33336333333377767333336333333333b3
33333333333333333333333333333333333333333333333333333333333333333333333333355533777777767777777677777776777777733333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
33333b3333333b333b333333333333333b3333333b3333333b33333333333b333b3333333b333333333333333b3333333b3333333b333333333363333b333333
3b3333333b33333333333333333333333333333333333333333333333b333333333333b3333333333333333333333333333333333333333333336333333333b3
33b3333333b33333333333333333333333333333333333333333333333b333333333333333333333333333333333333333333333333333333333333333333333
33b3333b33b3333b333333333333333333333333333333333333333333b3333b333b3333333333333333333333333333333333333333333333336333333b3333
333333b3333333b33333333333333333333333333333333333333333333333b33333333b3333333333333333333333333333333333333333333363333333333b
333333b3333333b3333333b333333333333333b3333333b3333333b3333333b33b333333333333b333333333333333b3333333b3333333b3333363333b333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
333331133b33333333333b33333333333b33333333333b3333333b333b33333333333b333b3333331133333333333333333333333b3333333333633333333b33
33333333333333333b33333333333333333333333b3333333b333333333333333b33333333333333333333b3333333333333333333333333333363333b333333
333113333333333333b33333333333333333333333b3333333b333333333333333b3333333333333333333333333333333333333333333333333333333b33333
333333333333333333b3333b333333333333333333b3333b33b3333b3333333333b3333b33333333333b33333333333333333333333333333333633333b3333b
1133333333333333333333b33333333333333333333333b3333333b333333333333333b3333333333333333b33333333333333333333333333336333333333b3
33333333333333b3333333b333333333333333b3333333b3333333b3333333b3333333b3333333b33b3333333333333333333333333333b333336333333333b3
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333633333333333
66636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663666366636663333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333311333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333331133333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333337737773777331137773733373333333777373737773333337737773777337737773333333333333333333333333333333
3333333333333b333b3333333b3333730070003700333370707033703b33333700707070003333730070007000730070003333333333333333333b333b333333
333333333b3333333333333333333370337733370333337770703370333333370377707733333370337733773377737733333333333333333b333333333333b3
3333333333b3333333333333333333707370033703333370707033703333333703707070033333707370037003307070033333333333333333b3333333333333
3333333333b3333b33333333333b33777077733703333370707773777333333703707077733333777077737773773077733333333333333311b3333b333b3333
33333333333333b3333333333333333000300033033333303030003000333333033030300033333000300030003003300033333333333333333333b33333333b
33333333333333b3333333b33b333333333333b33333333333333333333333b3333333b3333333b3333333b3333333b3333333b333333333333333b33b333333
33333311333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333311333333333333333333
33333557333333333333333333333333333333777377337773377333337773737377733333377337737773733333333333333333333333333333333333333333
33333b733b333333333333333b3333333b33333700707b370073703333370070707000333b730073707070703b3333333b3333333b33333333333b3333333b33
3b333313666553333333333333333333333333370b70703703707033333703777077333333703370707770703333333333333333333333b33b3333333b333333
33b33317665533333333333311333333333333370370703703707033b337037070700333337073707070707033333333333333333333333333b3333333b33333
33b333377553333333333333333333333333337773707037037730333b3703707077733333777077307070777133333333333333333b333333b3333b33b3333b
333333b311333333333311333333333333333330003030b3033003333b330b3030300033333000300330303000333333333333333333333b333333b3333333b3
333333b1331333b333333333333333b3333333b3333333b3333333333b3b3b3333333333333333b333333333733333b3331133b33b333333333333b3333333b3
33333300000033333333333333333333333333333333333333333333333333333333333333333333333333331366655333333333333333333333333333333333

__gff__
0002020202020202020202020202020204040404000000000000000000000000010101080808000000000101000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3031323333303132333433303132333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3331323432333432333401313233343300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2626262626262626262626262626283400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333343431313134343333343334273100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3431323331303133332b20202022273300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3431343432340132343632332421273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3010333334333433333634252321273300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3434343134303333323633312421273100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3012343334303132333632333321273400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131013332323232313633313121273100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3331343331333131322a20202022273200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131323332323231343233323232273400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3332313332313132313234013332273100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2626262626262626262626262626293300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3331323432333332323232323233313400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132333232313330333233323234313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f000018120181201c1200000000000000001f1501815000000000001a1301d120000002112000000000002312000000000001f12000000000001c1400000000000181700000017170000001a1501814000000
01060000131500000010150000000c15000000151500000012150000000e150000001715017150141501415010150101500b1500b150081500815004150041500000000000000000000000000000000000000000
010400002860010600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000287002c7002d7002f7002f700347000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000201501f1501d1501b1501a150191401715016150151501515015150181501815018150191501e2501e2501d2501d2501d2501d2402223022220222302224021240212502226022260222502225023250
000100002715027150271502225021250202501f2501e2501d2501c2501b1501e1501e1501e1501e1501e1501e1501e1501e1501e1501e1501e1501d1501d1501d1501c1501c1501c1501c1501a1501915018150
000100002625026250262502525025250242502425024250242502325023250232502325023250222502225021250252502625026250252502425023250202501f2501e2501f2502425000000000000000000000
0001000024030230302304023040230402304023040230402302023040220302203021030200301e0301c0301b0301903018030160401504013040100400d0400904005030010000000000000000000000000000
000c001f0032000320003100031000310003100031000310003100031000320003200032000320003200032000320003200032000320003200032000310003100031000310003100031000310003100032000120
001000001a15300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c0001c00020000200001c0001c00020000200001c0001c00021000210001c0001c00021000210001c0001c00020000200001c0001c00020000200001c0001c0001e0001e0001c0001c0001e0001e000
001000001000000000170000000010000000001700000000100000000017000000001000000000170000000010000000001700000000100000000017000000001000000000170000000010000000001700000000
001000001c600186003b6000060004600006003b6000060004600006003b6000060004600006003b6000060004600006003b6000060004600006003b6000060004600006003b6000060004600006003b60000600
001000001c0001c00020000200001c0001c00020000200001c0001c00021000210001c0001c00021000210001c0001c00023000230001c0001c00023000230001c0001c00021000210001c0001c0002100021000
001000002800028000240002400024000240002f0002f0002d0002d00024000240002a0002a00024000240002c0002c000240002400024000240002d0002d0002c0002c00024000240002a0002a0002400024000
001000002800028000240002400024000240002f0002f0002d0002d00024000240002a0002a000240001c0002c0002c0002c0002c0002c0002c0002c0002c0002400024000000000000000000000000000000000
0010000004000000000b0000000004000000000b000000000b0000000003000000000b00000000030000000001000000000800000000010000000008000000000900000000040000000009000000000400000000
001000001c0001c00020000200001c0001c00020000200001b0001b0001e0001e0001b0001b0001e0001e0001c0001c00020000200001c0001c00020000200001c0001c00021000210001c0001c0002100021000
001000002800028000240002400024000240002f0002f0002d0002d00024000240002a0002a000240001c00028000280002800028000280002800028000280000000000000000000000000000000000000000000
0010000004000000000b0000000004000000000b000000000b0000000003000000000b000000000300000000010000000008000000000100000000080000000009000000000b000000000d000000000f00000000
__music__
00 01020304
01 010b0c0d
00 010b0c0d
00 0f0e0c0d
00 100e0c0d
00 0f12110d
02 1312140d
