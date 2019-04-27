pico-8 cartridge // http://www.pico-8.com
version 17
__lua__
-- pong in 10 minutes

ph=20
pw=2

function _init()
 p1={x=1, y=64, w=2, h=20, score=0}
 p2={x=124, y=64, w=2, h=20, score=0}
 b={x=64, y=32+rnd(64), w=2, h=2,
    vx=1, vy=1}
end

function reset()
 b.x=64
 b.y=32+rnd(64)
 b.vx*=-1
end

function _update60()
 if btn(3) then p1.y+=2 end
 if btn(2) then p1.y-=2 end
 if btn(3,1) then p2.y+=2 end
 if btn(2,1) then p2.y-=2 end
 
 b.x+=b.vx
 b.y+=b.vy
 
 if b.x<p1.x+p1.w and b.vx<0 then
  if b.y<p1.y+p1.h and b.y+b.h>p1.y then
   b.vx*=-1
  end
 end
 if b.x<-4 then
  p2.score+=1
  reset()
 end

 if b.x+b.w>p2.x and b.vx>0 then
  if b.y<p2.y+p2.h and b.y+b.h>p2.y then
   b.vx*=-1
  end
 end
 if b.x>128+4 then
  p1.score+=1
  reset()
 end

 if b.y<4 then b.vy*=-1 end
 if b.y>128-4 then b.vy*=-1 end
end

function _draw()
 cls(1)
 rectfill(p1.x,p1.y,p1.x+p1.w,p1.y+p1.h)
 rectfill(p2.x,p2.y,p2.x+p2.w,p2.y+p2.h)
 rectfill(b.x,b.y,b.x+b.w,b.y+b.h)
 print(p1.score,0,0,7)
 print(p2.score,120,0,7)
end

