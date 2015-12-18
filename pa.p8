pico-8 cartridge // http://www.pico-8.com
version 5
__lua__
function _init()
 -- globals struct

 g_tick = 0
 g_cs = {}   --camera stack
 g_ct = 0    --controllers
 g_ctl = 0   --last controllers
 g_lv = {0,0} --p1/p2 game level


 --general objects
 g_go = {
  make_trans(
   function()
    addggo(make_title())
   end
  )
 }

 --disable sound
 --memset(0x3200,0,0x4300-0x3200)
end

function _update()
 -- naturally g_tick wraps to
 -- neg int max instead of 0
 g_tick = max(0,g_tick+1)

 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()
 -- top-level objects
 update_gobjs(g_go)
end

function _draw()
 cls()
 rectfill(0,0,127,127,5)
 draw_gobjs(g_go)
 --print('cpu:'..
 --  (flr(stat(1)*100))..'%',100,0,
 --   7)
end
--
function make_row(
  w, -- row width
  e, -- row is empty or not
  nt,-- number of tile types
  ra,-- row above (check match)
  raa)--row above row above
 
 local r = {}
 for j = 1, w do
  r[j] = {}
  local n=0
  if not e then
   n = flr(rnd(nt) + 1)
   local tries=0
   while (j > 2 and (n == r[j-1].t 
     and n == r[j-2].t)
     or (ra 
         and raa 
         and
         (raa[j].t == n 
         and ra[j].t == n)))
         and 
      tries < nt do
    n += 1
    tries += 1
    if n > nt then
     n = 1
    end
   end
  end
  r[j].t = n
 end
 return r
end

function make_board(
  w, -- width
  h, -- height
  x, -- x position
  y, -- y position
  p, -- player
  v, -- number of visible lines
  nt)-- number of tile types
 local b = {
  draw=draw_board,
  update=update_board,
  start=start_board,
  w=w,
  h=h,
  nt=nt, --tile types
  t={}, -- a list of rows
  -- cursor position (0 indexed)
  cx=flr(w/2)-1,
  cy=h-4,
  x=x,
  y=y,
  p=p, -- player (input)
  o=4,     -- rise offset
  r=0.025, -- rise rate
  mc=0, --match count
  f={},  -- tiles to fall
  go={}, -- general objects
  gq={}, -- queued garbage
  st=0   -- board state
 }

 for i = h,1,-1 do
  local e,r2,r3 = h-i > v,
    b.t[i+1],
    b.t[i+2]
  b.t[i] = make_row(
    w,e,b.nt,r2,r3)
 end  
 
 -- additional fields
 --b.s = nil -- tiles to swap
 --b.ri = nil  -- time since rise
 -- board state enum
 --     0 -- playing
 --     1 -- lose
 --     2 -- win
 --     3 -- countdown to start
 
 
 return b
end

function start_board(b)
 b.st = 3 -- countdown to start
 add(b.go,make_cnt(b))
 b.ri = nil
 if b.ob then
  b.mtlidx=1
  b.mtlcnt=0
 end
end

function input_cursor(b)
 local m,p =
   false,
   b.p
 if btnp(0, p) then
  if b.cx > 0 then
   b.cx -= 1
   m = true
  end
 end
 if btnp(1, p) then
  if b.cx < b.w - 2 then
   b.cx += 1
   m = true
  end
 end
 if btnp(2, p) then
  if b.cy > 0 then
   b.cy -= 1
   m = true
  end
 end
 if btnp(3, p) then
  if b.cy < b.h - 2 then
   b.cy += 1
   m = true
  end
 end
 if (m) sfx(0)
end

function input_board(b)
 input_cursor(b)
 if btnn(5,b.p) and b.st==0 then
  local x,y =
   b.cx+1,
   b.cy+1
  local t1,t2 =
   b.t[y][x],
   b.t[y][x+1]

  if not busy(t1, t2) and
    (t1.t>0 or t2.t>0) then
   t1.s = g_tick
   t1.ss = 1
   t2.s = g_tick
   t2.ss = -1
   b.s = {t1, t2}
   sfx(1)
  end
 end
end

function end_game(b)
 for t in all(b.s or {}) do
  t.s=nil
  t.ss=nil
 end
 if b.st==1 then
  b.et=g_tick
  sfx(6)
 end
 b.s=nil
 b.tophold=nil
 b.hd=nil
 local np=1
 if (b.ob) np=2

 addggo(make_retry(np))
 add(b.go,make_winlose(b.st==2,
   (b.w*9)/2-16,(b.h*9)/2-16))
end

function offset_board(b)
 if b.st ~= 0 then return end
 --pause while matching
 if b.mc>0 then
  if b.tophold then
   b.tophold+=1
  end
  if b.hd then
   b.hd+=1
  end
 end

 if b.hd then
  if b.hd > 0 then
   b.hd-=1
   if b.tophold then
    b.tophold=g_tick
   end
  else
   b.hd=nil
   --for no speed-up during
   --hold
   --b.ri=g_tick
  end
 end

 if not b.ri then
  b.ri=g_tick
 end
 if elapsed(b.ri) > 300 then
  b.ri=g_tick
  b.r+=0.01
 end

 if btn(4,b.p) then
  b.o+=1
 elseif not b.hd
   and b.mc==0 then
  b.o+=b.r
 end

 if b.o >= 9 then
  local r = b.t[1]
  for i=1,#r do
   -- lose condition
   if r[i].t > 0 then
    if b.tophold then
     b.o=9
     if elapsed(b.tophold) > 120 then
      b.st=1
      end_game(b)
      if b.ob then
       b.ob.st=2
       end_game(b.ob)
      end
     end
    else
     b.tophold=g_tick
    end
    return
   end
  end

  b.tophold=nil

  b.o=0
  del(b.t, b.t[1])
  add(b.t, make_row(b.w,false,
    b.nt))
  if b.mtlidx then
   b.mtlcnt+=1
   if b.mtlcnt >=
     g_nxtmtl[b.mtlidx] then
    b.mtlidx+=1
    if b.mtlidx > #g_nxtmtl
      then
     b.mtlidx=1
    end
    b.mtlcnt=0
    b.t[b.h][
      flr(rnd(b.w))+1].t=7
   end
  end
  if b.cy>0 then
   b.cy-=1
  end
  sfx(3)
 end
end

function update_board(b)
 if b.st==0 then
  local gb=b.gq[1]
  if gb and
    elapsed(gb[3])>40 then
   local x=garb_fits(b,gb[1],
     gb[2])
   if x then
    add_garb(b,x,0,gb[1],gb[2],
      gb[4])
    del(b.gq,gb)
   end
  end
  offset_board(b)
 end
 if b.st==0 or b.st==3 then
  input_board(b)
 end
 if b.st==0 then
  scan_board(b)
 end
 update_gobjs(b.go)
end

function garb_fits(b,w,h)
 local sx=flr(rnd(b.w-w+0.99))
 for x=sx+1,sx+w do
  for y=1,h do
   local t=b.t[y][x]
   if busy(t) or t.t>0 then
    return nil
   end
  end
 end
 return sx
end


function busy(...)
 for t in all({...}) do
  if t.m or t.s or t.f or t.g
    then
   return true
  end
 end
 return false
end

function swapt(t,t2)
 local tmp = {}
 for k,v in pairs(t) do
  tmp[k] = v
  t[k] = nil
 end
 for k,v in pairs(t2) do
  t[k] = v
  t2[k] = nil
 end
 for k,v in pairs(tmp) do
  t2[k] = v
 end
end

function update_swap(b)
 if not b.s then return end
 local t,t2 = b.s[1]
 if elapsed(t.s) > 1 then
  t2 = b.s[2]
  t.s = nil
  t.ss = nil
  t2.s = nil
  t2.ss = nil
  b.s = nil
  swapt(t, t2)
 end
end

function set_falling(b, t, t2)
 t.s = g_tick
 t.f = true
 t2.f= true
      
 add(b.f, {t,t2})
end

function update_fall(b)
 for x=1,b.w do
  for y=b.h-1,1,-1 do
   local t=b.t[y][x] 
   
   if (t.g 
       and t.g[1] ==0 
       and t.g[2] ==0) then
    if (not t.f and 
       not t.s and 
       not t.m) then
     update_fall_gb(b,x,y)
    end
   elseif y<b.h and t.t>0 then
    local t2=b.t[y+1][x]
    if t2.t==0 and
     not busy(t,t2) then
      -- mark for falling
      set_falling(b, t, t2)
       
      -- blocks above fall too
      fall_above(x,y,t,b)
    end
   end
  end
 end
 
 if (not b.f) return
 
 for f_s in all(b.f) do
  local t,t2 = f_s[1]
  if (elapsed(t.s) > 0) then
   -- execute the fall
   t2 = f_s[2]
   t.s = nil
   t.ss = nil
   t2.s = nil
   t2.ss = nil
   t.f = false
   t2.f = false
   swapt(t, t2)
   del(b.f, f_s)
  end
 end
end

function update_fall_gb(b,x,y)
 local t = b.t[y][x]
 if t.gm then
  return
 end
 local should_fall = true
 local lastgx=t.g[3]+x-1
 local lastgy=t.g[4]+y-1
 local have_cleared=false
 for xg=x,lastgx do
  local t2 = b.t[lastgy+1][xg]
  if t2.t~=0 and not t2.f then
   should_fall = false
   break
  end
 end
 if should_fall then
  for xg=x,lastgx do
   for yg=lastgy,y,-1 do
    local tg1=b.t[yg][xg]
    local tg2=b.t[yg+1][xg]
    set_falling(b, tg1, tg2)
    if yg==y then
     fall_above(xg,y,tg1,b)
    end
   end
  end
 end
end

function fall_above(x,y,t,b)
 for a=y-1,1,-1 do
  local a_t = b.t[a][x]
  if a_t.g and not a_t.f then
   update_fall_gb(
    b,
    x-a_t.g[1],
    a-a_t.g[2])
   break
  end
  if busy(a_t) then
   break
  end
  set_falling(b, a_t, t)
  t = a_t
 end
end
function above_solid(b,x,y)
 --brute force test prevent
 --mid-fall matches.
 --todo:optimize
 for i=y+1,b.h-1 do
  if b.t[i][x].t==0 then
   return false
  end
 end
 return true
end

function clr_match(b,x,y)
 local t=b.t[y][x]
 t.m=nil
 t.t=0
 t.e=nil
 --update chain count above
 local ch=t.ch
 if not ch then
  ch=2
 else
  t.ch=nil
  ch+=1
 end
 for i=y-1,1,-1 do
  local t2=b.t[i][x]
  if t2.t>0 and
    not busy(t2) then
   if t2.ch then
    t2.ch=max(ch,t2.ch)
   else
    t2.ch=ch
   end
  end
 end
 b.mc-=1
end

function reset_chain(b)
 for x=1,b.w do
  local tt = b.t[b.h-1][x]
  if not busy(tt) then
   tt.ch=nil
  end
  for y=b.h-2,1,-1 do
   local t=b.t[y][x]
   if not busy(t) and t.ch then
    if (tt.t>0 and
      not busy(tt)) and
      not tt.ch
      then
     t.ch=nil
    end
   end
   tt=t
  end
 end
end

function match_garb(b,x,y,ch,gbt)
 local t=b.t[y][x]
 if not t.g or t.gm then
  return
 end
 --metal vs regular
 if gbt and t.g[5] ~= gbt then
  return
 end
 gbt=t.g[5]
 x-=t.g[1]
 y-=t.g[2]
 local xe=x+t.g[3]-1
 local ye=y+t.g[4]-1
 local w=t.g[3]
 for yy=y,ye do
  local r=make_row(
    w,false,b.nt)
  for xx=x,xe do
   t=b.t[yy][xx]
   --charge preservation
   t.ch=max(ch,t.ch or 1)
   t.t=r[xx-x+1].t
   t.gm=g_tick
   --match top and bottom
   if yy==y and yy>1 then
    match_garb(b,xx,yy-1,ch,gbt)
   end
   if yy==ye and yy<b.h-1 then
    match_garb(b,xx,yy+1,ch,gbt)
   end
   --
  end
 end
end

function scan_board(b)
 local ms = {}

 update_fall(b)
 update_swap(b)

 for h = 1, b.h do
  local r = b.t[h]
  for w = 1,b.w do
   local t = r[w]

   if t.m then
    if elapsed(t.m) > 30 then
     clr_match(b,w,h)
    end
   end

   if t.gm and
     elapsed(t.gm)>60 then
    t.gm=nil
    t.g=nil
   end
   if t.t > 0 and
     not busy(t) and
     above_solid(b,w,h) then
    if w < b.w-1 then
     local wc = 1
     for i=(w+1),b.w do
      if t.t == r[i].t and
        not busy(r[i]) and
        above_solid(b,i,h) then
       wc+=1
      else
       break
      end
     end
     if wc > 2 then
      for i=w,w+(wc-1) do
       add(ms,{r[i],i,h})
      end
     end 
    end

    if h < b.h-2 then
     local hc = 1
     for i=(h+1),b.h-1 do
      if t.t == b.t[i][w].t and
        not busy(b.t[i][w]) then
       hc+=1
      else
       break
      end
     end
     if hc > 2 then
      for i=h,h+(hc-1) do
       add(ms,{b.t[i][w],w,i})
      end
     end

    end
   end
  end
 end

 --collase to unique matches
 local mc=0
 local mtlc=0 --mtl count
 local um={}
 local ch=1
 local mm={b.w,0,b.h,0}
 for m in all(ms) do
  local t=m[1]
  local x=m[2]
  local y=m[3]
  mm[1]=min(x,mm[1])
  mm[2]=max(x,mm[2])
  mm[3]=min(y,mm[3])
  mm[4]=max(y,mm[4])
  if not um[t] then
   um[t]={x,y}
   t.m=g_tick
   if t.t==7 then
    mtlc+=1
   else
    mc+=1
   end
   t.e=30-((mc*3)%15)
   if t.ch then
    ch=max(ch,t.ch)
   end
  end
 end
 local mx=mm[1]+(mm[2]-mm[1])/2
 local my=mm[3]+(mm[4]-mm[3])/2-1
 b.mc+=mc+mtlc
 if mc>0 then
  sfx(2)
 end
 
 --check for adjacent garbage
 for t,xy in pairs(um) do
  local x,y,chp =
    xy[1],
    xy[2],
    ch+1
  if x>1 then
   match_garb(b,x-1,y,chp)
  end
  if x<b.w-1 then
   match_garb(b,x+1,y,chp)
  end
  if y>1 then
   match_garb(b,x,y-1,chp)
  end
  if y<b.h-1 then
   match_garb(b,x,y+1,chp)
  end
 end

 if ch>1 then
  addggo(make_bubble(
    max(0,b.x+(mx-1)*9-17),
    b.y+my*9,ch..'x',true,9,0))
  incr_hold(b,ch*25)	--tune
 end

 if mc>3 then
  incr_hold(b,mc*12) --todo tune
  addggo(make_bubble(
    min(112,b.x+mx*9),
      b.y+my*9-5,mc,false))
 end

 if mtlc>2 then
  incr_hold(b,mtlc*12) --todo tune
  send_garb(
    b.x+mx*9,
    b.y+my*9,
    b.ob,
    {1,(mtlc-2)*6+1,g_tick,1},
    g_tick)
 end

 if b.ob and
   (ch>1 or mc>3) then
  send_garb(
    b.x+mx*9,
    b.y+my*9,
    b.ob,
    {ch,mc,g_tick,0},
    g_tick)
 end

 reset_chain(b)
end

function garb_size(gb)
 local r={}
 local sum=(gb[2]-1)*gb[1]
 local left=sum%6
 if sum-left>0 then
  add(r,{6,flr(sum/6),gb[3],gb[4]})
 end
 if left>2 then
  add(r,{left,1,gb[3],gb[4]})
 end
 return r
end

function send_garb(sx,sy,b,gb,e)
 addggo({
  sx=sx,sy=sy,b=b,gb=gb,e=e,
  update=function(t,s)
   if elapsed(t.e)>15 then
    for gb in all(
      garb_size(t.gb)) do
     add(t.b.gq,gb)
    end
    del(s,t)
   end
  end,
  draw=function(t)
   local v=elapsed(t.e)/15
   local v2=v^3
   palt(2,true)
   palt(0,false)
   spr(42,
     (b.x+5-t.sx)*v+t.sx-3,
     (b.y-10-t.sy)*v2+t.sy-3)
   palt()
  end
 })
end

function incr_hold(b,v)
 b.hd=(b.hd or 0)+v
end

function calc_offset(b)
 local offset=b.o
 if b.et then
  local e=elapsed(b.et)
  if e<10 then
   offset+=sin(e/5)*3*((9-e)/9)
  else
   b.et=nil
  end
 end
 return offset
end

function draw_board(b)
 rectfill(-1,-9,b.w*9-2,b.h*9,0)
 color(1)
 line(-1,-9,-1,b.h*9)
 line(b.w*9-1,-9,b.w*9-1,b.h*9)
 line(-1,-10,b.w*9-1,-10)
 if b.hd then
  local btm=(b.h-1)*9+2
  line(-1,btm,-1,
    max(-10,btm-b.hd),12)
 end
 color()

 local offset = calc_offset(b)
 pushc(0,offset)

 for h = 1, b.h do
  local r = b.t[h]
  for w = 1, b.w do
   local s = r[w].t
   local warn = (
       b.t[1][w].t > 0 and g_tick%16>7)
   if r[w].s then
    if not r[w].f then
     pushc(
      -r[w].ss*(elapsed(r[w].s)+1)
      ,0
     )
    else
     pushc( 
      0,
      -1*(elapsed(r[w].s)+1)
     ) 
    end
   end
   
   local t=r[w]
   if t.g then
    if t.gm then
     local i=t.g[2]*t.g[3]+t.g[1]
     local s=24
     local mt=(i+1)*3
     local ge=elapsed(t.gm)
     if ge==50-mt or
       ge==40-mt then
      sfx(7)
     end

     if ge>40-mt then
      s=t.t
      if ge<50-mt then
       s+=16
      end
     end

     spr(s,(w-1)*9,(h-1)*9)
    elseif t.g[1]==0 and
      t.g[2]==0 then
     local warn=false
     if b.st==0 and
       g_tick%16>7 then
      for i=w,w+t.g[3]-1 do
       if b.t[1][i].t>0 then
        warn=true
        break
       end
      end
     end
     if b.st==1 or b.st==2 then
      pal(13,6)
     end
     draw_garb((w-1)*9,
      (h-1)*9, t.g[3],t.g[4],
       warn,t.g[5])
     pal()
    end
   elseif s > 0 then
    if b.st<1 or b.st>2 then
     if r[w].m then
      local e=elapsed(r[w].m)
      if e%3 == 0 then
       s+=16
      end
      if e>15 then
       s=8
       if e>t.e then
        if e==t.e+1 then
         sfx(7)
        end
        s=0
       end
      end
     else
      if warn then
       s+=32
      end
     end
    else
     s+=16
    end
    spr(s,(w-1)*9,(h-1)*9)
    --if g_dbg and t.ch then
    -- print(t.ch,
    --  (w-1)*9+2,(h-1)*9+1,7)
    --end
   end

   if r[w].s then
    popc()
   end
   
  end
 end

 pal(1,0)
 local by = (b.h-1)*9+offset
 local sx,sy = toscn(0,by)
 clip(sx, sy-offset,b.w*9, 17)
 for y=0,1 do
  for x=1,b.w do
   --+(g_tick%3)*16
   spr(16+(y*16),(x-1)*9,by-(y*8))
  end
 end
 clip()
 pal()

 if b.st<1 or b.st>2 then
  draw_curs(b.cx*9,b.cy*9,
    b.s==nil and g_tick%30 < 15)
 end
 
 draw_gobjs(b.go)
 
 popc()

 palt(2,true)
 palt(0,false)
 if b.tophold then
  spr(
   49+elapsed(b.tophold)/120*8,
    b.w*9-7,-18)
 end
 if #b.gq > 0 then
  spr(26,0,-18,2,1)
  spr(10,14,-18)
  print(#b.gq,18,-17,6)
 end
 palt()

 --bottom cover
 --rectfill(-1,b.h*9-9-1,
 --  b.w*9-1,b.h*9-1,1)
 ----tokens-permitting
 --palt(0,false)
 --palt(1,true)
 --clip(b.x,0,b.w*9-1,128)
 --local y=b.h*9-9
 --for i=0,b.w do
 -- spr(11,i*8,y,1,1,b.p==1)
 --end
 --clip()
 --palt()

end

function draw_curs(x, y, grow)
 local s=12
 if grow then
  s=13
 end
 spr(s,x-1,y-1)
 spr(s,x+10,y-1,1,1,true)
 spr(s,x-1,y+1,1,1,
   false,true)
 spr(s,x+10,y+1,1,1,
   true,true)
 s+=2
 spr(s,x+6,y-1)
 spr(s,x+6,y+1,1,1,
   false,true)
end

function add_garb(b,x,y,w,h,mtl)
 for by=y+1,min(b.h,y+h) do
  for bx=x+1,min(b.w,x+w) do
   local t=b.t[by][bx]
   t.g={bx-x-1,by-y-1,w,h,mtl}
   t.t=8
  end
 end
end

function draw_garb(x,y,w,h,warn,
		mtl)
 if mtl==1 then
  pal(13,5)
  pal(5,13)
 end
 rectfill(x,y,x+w*9-2,
    y+h*9-2,13)
 rect(x,y,x+w*9-2,y+h*9-2,5)
 local s=8
 if warn then s+=32 end
 spr(s,x+(w*9)/2-4-((w+1)%2),
   y+((h-1)*9)/2)
	pal()
end

function make_winlose(
  wl, --true win
  x,y
 )
 local r={
  x=x,y=y,
  e=g_tick,
  draw=function(t)
   local y=sin(g_tick/35)*3
   local e=elapsed(t.e)
   if e<10 then
    y=(10-e)*-4
   end
   spr(t.s,0,y,4,2)
  end
 }
 if wl then
  r.s=64
 else
  r.s=68
 end
 return r
end

function make_cnt(b)
 if b.p==0 then
  addggo(make_clock(b))
 end
 return {
  x=b.w*9/2-8,
  y=b.h*9/2-8,2,
  c=3,
  e=g_tick,
  b=b, --potential cycle
  draw=function(t)
   pal(6,0)
   spr(96+(3-t.c)*2,0,0,2,2)
   pal()
  end,
  update=function(t,s)
   if elapsed(t.e)>30 then
    t.c-=1
    if t.c==0 then
     t.b.st=0
     del(s,t)
     sfx(5)
    else
     sfx(4)
     t.e=g_tick
    end
   end
  end
 }
end

--todo, trim palette stuff
--      to a sprite for tokens
function make_bubble(
  x,y,n,f,p,p2)
 return {
  x=x,y=y,n=n..'',
  b=g_tick,f=f,p=p,p2=p2,
  draw=function(t)
   if t.p then
    pal(13,t.p)
   end
   if t.p2 then
    pal(6,t.p2)
   end
   local sx=1
   if #t.n>1 then
    sx-=1
   end
   spr(102,0,0,2,2,t.f)
   print(t.n,5+sx,3,6)
   pal()
  end,
  update=function(t,s)
   if elapsed(t.b) > 60 then
    del(s,t)
   end
   t.y-=1
  end
 }
end

function make_clock(b)
 return {
  x=54,y=2,c=0,b=b,m=0,s=0,
  draw=function(t)
   rectfill(-1,-1,19,5,6)
   local mp,sp = '',''
   if (t.m<10) mp=0
   if (t.s<10) sp=0
   print(mp..t.m..':'..sp..t.s,
     0,0,0)
  end,
  update=function(t)
   if (t.b.st~=0) return
   t.c+=1
   --fixed-point math not
   --accurate enough for
   --division of seconds.
   --do addition instead
   if t.c>=30 then
    t.c=0
    t.s+=1
    if t.s>=60 then
     t.s=0
     t.m+=1
    end
   end
  end
 }
end

function draw_title(t)
 draw_gobjs(t.ts)
 for i=1,15 do
  pal(i,0)
 end
 spr(72,32,36,8,4)
 spr(72,34,36,8,4)
 spr(72,33,35,8,4)
 spr(72,33,37,8,4)
 pal()
 spr(72,33,36,8,4)
 draw_gobjs(t.mn)
end

function update_title(t,s)
 if rnd(1)>0.92 then
  add(t.ts,{
   x=flr(rnd(128)),
   y=144,
   r=flr(rnd(2))+1,
   sx=8*(flr(rnd(5))+1),
   update=function(t,s)
    t.y-=t.r
    if t.y<-16 then
     del(s,t)
    end
   end,
   draw=function(t)
    rect(-17,-17,16,16,0)
    sspr(t.sx,0,8,8,-16,-16,32,32)
   end
  })
 end
 update_gobjs(t.ts)
 update_gobjs(t.mn)
end

function make_title()
 return {
  ts={},
  np=2, --num players
  draw=draw_title,
  update=update_title,
  mn={make_main()}
 }
end

function make_menu(
 lbs, --menu lables
 fnc, --chosen callback
 x,y, --pos
 omb, --omit backdrop
 p,   --player
 cfnc --cancel callback
)
 local m={
  lbs=lbs,
  f=fnc,
  fc=cfnc,
  i=0, --item
  s=g_tick,
  e=5,
  x=x or 64,
  y=y or 80,
  h=10*#lbs+4,
  omb=omb,
  tw=0,--text width
  p=p or -1,
  draw=function(t)
   local e=elapsed(t.s)
   local w=t.tw*4+10
   local x=min(1,e/t.e)*(w+9)/2
   if not t.omb then
    rectfill(-x,0,x,t.h,0)
    rect(-x,0,x,t.h,1)
   end
   if e<t.e then
    return
   end
   x=w/2+1
   for i,l in pairs(t.lbs) do
    if not t.off or i==t.i+1 then
     local y=4+(i-1)*10
     print(l,-x+9,y+1,0)
     print(l,-x+9,y,7)
    end
   end
   spr(48,-x,3+10*t.i)
  end,
  update=function(t,s)
   if (t.off) return
   if elapsed(t.s)<(t.e*2) then
    return
   end

   if btnn(5,t.p) then
    if t.f then
     t:f(t.i,s)
     sfx(2)
    end
   end

   --cancel
   if btnn(4,t.p) then
    if t.fc then
     t:fc(s)
     sfx(2)
    end
   end

   if btnn(2,t.p) and
     t.i>0 then
    t.i-=1
    sfx(1)
   end
   if btnn(3,t.p) and
     t.i<(#t.lbs-1) then
    t.i+=1
    sfx(1)
   end
  end
 }
 for l in all(lbs) do
  m.tw=max(m.tw,#l)
 end
 return m
end

function make_retry(np)
 return make_timer(30,
  function(t,s)
   local m = make_menu(
    {'retry','quit'},
    function(t,i,s)
     if i==0 then
      addggo(make_trans(
       function(t,s)
        start_game(t.d)
       end,
       t.np))
     else
      addggo(make_trans(
       function()
        g_go={
         make_title()}
       end))
     end
    end
   )
   m.np=t.d
   add(s,m)
  end,
  np) --added to timer as d
end

function make_lmenu(p,pm)
 local m=make_menu(
  {'easy',
   'normal',
   'hard',
   'expert'},
  function(t,i,s)
   t.off=true
   g_lv[p+1]=i
   t.pm:accept(t,s)
  end,
  64,70,nil,p,
  function(t,s)
   t.pm:cancel(t,s)
  end
 )
 m.i=g_lv[p+1]
 m.p=p
 m.pm=pm
 return m
end

function make_lmenuc(pm,np,s)
 local c={
  np=np,
  pm=pm,
  ac=0, --num accepted
  mns={},
  accept=function(t,mn,s)
   t.ac+=1
   if t.ac==t.np then
    t:_done()
    addggo(make_trans(
     function(t,s)
     	start_game(t.d)
     end,t.np))
   end
  end,
  cancel=function(t,mn,s)
   t.pm.off=nil
   t:_done(s)
  end,
  _done=function(t,s)
   for mn in all(t.mns) do
    del(s,mn)
   end
   del(s,t)
  end
 }
 for i=1,np do
  local mn=make_lmenu(i-1,c)
  if np==2 then
   mn.x+=(i*2-3)*39.5
  end
  add(c.mns,mn)
  add(s,mn)
 end
 add(s,c)
end

function make_main()
 return make_menu(
  {'1 player','2 player'},
  function(t,i,s)
   t.off=true
   make_lmenuc(t,i+1,s)
  end,
  62,76,true
 )
end

--function make_stats(b,x,y)
-- return {
--  b=b,x=x,y=y,
--  draw=function(t)
--   print('speed '..
--    (t.b.r-0.025)/0.01+1,0,0,6)
--   if b.hd then
--    print('hold '..b.hd,0,8,6)
--   end
--   print('mc '..b.mc,0,16,6)
--  end
-- }
--end

function get_lv(l)
 l=g_lv[l]
 local r={}
 if l>2 then
  r.nt=6
 else
  r.nt=5
 end
 r.r=0.025
 for i=2,l*20 do
  r.r+=0.01
 end
 return r
end

function start_game(np)
 g_go={}
 local bs={}
 local lv={get_lv(1),get_lv(2)}
 if np==2 then
  for i=1,2 do
   bs[i] = make_board(
     6,12,1,30,i-1,5,
       lv[i].nt)
   bs[i].r=lv[i].r
  end
  bs[2].x=74
  bs[1].ob=bs[2]
  bs[2].ob=bs[1]

  --sync initial tiles
  if bs[1].nt == bs[2].nt then
   for y=1,bs[1].h do
    for x=1,bs[2].w do
     bs[2].t[y][x].t=
       bs[1].t[y][x].t
    end
   end
  end
 else
  add(bs,
   make_board(6,12,38,30,0,6,
     lv[1].nt))
  --addggo(make_stats(bs[1],2,2))
  bs[1].r=lv[1].r

  -- uncomment to test garbage
  --bs[1].ob=bs[1]
 end
 for b in all(bs) do
  addggo(b)
  b:start()
 end
 g_nxtmtl={}
 for i=1,100 do
  add(g_nxtmtl,flr(rnd(4)))
 end
end

--
function update_gobjs(s)
 for o in all(s) do
  if o.update then
   o:update(s)
  end
 end
end

function draw_gobjs(s)
 for o in all(s) do
  if o.draw then
   pushc(-(o.x or 0),
     -(o.y or 0))
   o:draw(s)
   popc()
  end
 end
end

function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
end

function pushc(x, y)
 local l=g_cs[#g_cs] or {0,0}
 local n={l[1]+x,l[2]+y}
 add(g_cs, n)
 camera(n[1], n[2])
end

function popc()
 local len = #g_cs
 g_cs[len] = nil
 len -= 1
 if len > 0 then
  local xy=g_cs[len]
  camera(xy[1],xy[2])
 else
  camera()
 end
end

function toscn(x,y)
 if #g_cs==0 then
  return x,y
 end
 local c=g_cs[#g_cs]
 return x-c[1],y-c[2]
end

function make_timer(e,f,d)
 return {
  e=e,f=f,d=d,s=g_tick,
  update=function(t,s)
   if elapsed(t.s)>t.e then
    del(s,t)
    t.f(t,s)
   end
  end
 }
end

--returns state,changed
function btns(i,p)
 i=shl(1,i)
 if p==1 then
  i=shl(i,8)
 end
 local c,cng =
   band(i,g_ct),
   band(i,g_ctl)
 return c>0,c~=cng
end

--returns new press only
function btnn(i,p)
 if p==-1 then --either
  return btnn(i,0) or btnn(i,1)
 end
 local pr,chg=btns(i,p)
 return pr and chg
end

function addggo(t)
 add(g_go,t)
end

function trans(s)
 if (s<1) return
 s=2^s
 local b,m,o =
   0x6000,
   15,
   s/2-1+(32*s)

 for y=0,128-s,s do
  for x=0,128-s,s do
   local a=b+x/2
   local c=band(peek(a+o),m)
   c=bor(c,shl(c,4))
   for i=1,s do
    memset(a,c,s/2)
    a+=64
   end
  end
  b+=s*64
 end
end

function make_trans(f,d,i)
 return {
  d=d,
  e=g_tick,
  f=f,
  i=i,
  update=function(t,s)
   if elapsed(t.e)>10 then
    if (t.f) t:f(s)
    del(s,t)
    if not t.i then
     addggo(
       make_trans(nil,nil,1))
    end
   end
  end,
  draw=function(t)
   local x=flr(elapsed(t.e)/2)
   if t.i then
    x=5-x
   end
   trans(x)
  end
 }
end

__gfx__
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d00000000dddddddd222222220011001100000000777000000000000077777000
00000000888ee888ccccccccb333333beeeffeee999ff99922e22e22555665550dddddd05d5d5d5d222222220110011007700000700000000777000000700000
00000000888ee888cc6666ccb3bbbb3beeffffee99f99f992ee22ee2555665550d5dd5d0dddddddd626222221100110007000000700000000070000000700000
000000008eeeeee8cc6666ccb3bbbb3beffffffe9f9999f922222222555665550d5dd5d05d5d5d5d262222221001100100000000000000000000000000000000
000000008eeeeee8cc6666ccb3bbbb3beffffffe9f9999f922222222555665550dddddd0dddddddd626222220011001100000000000000000000000000000000
00000000888ee888cc6666ccb3bbbb3beeffffee99f99f992ee22ee2555555550d5555d05d5d5d5d222222220110011000000000000000000000000000000000
00000000888ee888ccccccccb333333beeeffeee999ff99922e22e22555665550dddddd0dddddddd222222221100110000000000000000000000000000000000
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d000000005d5d5d5d222222221001100100000000000000000000000000000000
01101101666666666666666666666666666666666666666666666666666666665555555500000000000000000000022200000000000000000000000000000000
11111111666776666666666667777776666776666667766666766766666776665dddddd5000000000ddddddddddd022200000000000000000000000000000000
10110110666776666677776667666676667777666676676667766776666776665d5dd5d5000000000dddd5d5dddd022200000000000000000000000000000000
11111111677777766677776667666676677777766766667666666666666776665d5dd5d5000000000ddddddddddd022200000000000000000000000000000000
01101101677777766677776667666676677777766766667666666666666776665dddddd5000000000dddd555dddd022200000000000000000000000000000000
11111111666776666677776667666676667777666676676667766776666666665d5555d5000000000ddddddddddd022200000000000000000000000000000000
10110110666776666666666667777776666776666667766666766766666776665dddddd500000000000000000000022200000000000000000000000000000000
11111111666666666666666666666666666666666666666666666666666666665555555500000000222222222222222200000000000000000000000000000000
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d0000000000000000000000020000000000000000000000000000000000000000
1010101088888888ccccccccbbbbbbbbeeeeeeee9999999922222222555555550dddddd0000000000ddddd020000000000000000000000000000000000000000
0111010188eeee88cccccccc33333333effffffe9ffffff9eee22eee556666550dddddd0000000000d5d5d020000000000000000000000000000000000000000
11011011eeeeeeeec666666c3bbbbbb3fffffffff999999f2222222255666655055dd550000000000ddddd020000000000000000000000000000000000000000
01101101eeeeeeeec666666c3bbbbbb3fffffffff999999f22222222555555550dddddd0000000000d555d020000000000000000000000000000000000000000
1111111188eeee88cccccccc33333333effffffe9ffffff9eee22eee5566665505555550000000000ddddd020000000000000000000000000000000000000000
1011011088888888ccccccccbbbbbbbbeeeeeeee9999999922222222555555550dddddd000000000000000020000000000000000000000000000000000000000
1111111188888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d0000000000000000222222220000000000000000000000000000000000000000
00660000222222222222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000
006d6000211111122111111221111112211111122111111221111112211111122111111221111112000000000000000000000000000000000000000000000000
006dd600210000122100dd122100dd122100dd122100dd122100dd122100dd122100dd1221dddd12000000000000000000000000000000000000000000000000
006ddd60210000122100d0122100dd122100dd122100dd122100dd122100dd1221d0dd1221dddd12000000000000000000000000000000000000000000000000
006dd65021000012210000122100001221000d122100dd122100dd1221dddd1221dddd1221dddd12000000000000000000000000000000000000000000000000
006d6500210000122100001221000012210000122100dd12210ddd1221dddd1221dddd1221dddd12000000000000000000000000000000000000000000000000
00665000211111122111111221111112211111122111111221111112211111122111111221111112000000000000000000000000000000000000000000000000
00550000222222222222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000
00ffff0000ffff00000000000ffff0000ffff0000000000000000000000ffff00000000000000000000000000000000000000000000000000000000000000000
00f33f0000f33f00000000000f33f0000f88f0000000000000000000000f88f00000000000000000000000000000000000000000000000000000000000000000
00f33f0000f33ffff00000000f33f0000f88f0000000000000000000000f88f06666660066600006666000006660006666666606666660000666600006666660
00f33f0000f33f33f00000000f33f0000f88f0000000000000000000000f88f06ddddd605660006dddd60006ddd6006dddddd606ddddd60006dd60006ddddd60
00f33ffffff33f33f00000000f33f0000f88f0000000000000000000000f88f06dddddd6056006dddddd606ddddd606dddddd606dddddd6006dd6006dddddd60
00f33ff33ff33ffffff0fff00f33f0000f88f0000ffff000fffff0ffff0f88f06dd66ddd60606ddd66dd606dd6dd60666dd66606dd66ddd606dd606dddd66660
00f33ff33ff33f33f33f333f0f33f0000f88f000f8888fff8888ff8888ff88f06dd656dd60606dd656dd606dd6dd60556dd65506dd656dd606dd606ddd655550
00f33ff33ff33f33f3333333ff33f0000f88f00f888888f88888f888888f88f06dd606dd60606dd60666606dd6dd60006dd60006dd606dd606dd606ddd600000
00f33ff33ff33f33f333ff33ff33f0000f88f00f88ff88f88ffff88ff88f88f06dd66ddd60606dd60555506dd6dd60006dd60006dd66dd6506dd606dddd60000
00f33ff33ff33f33f33f5f33ff33f0000f88f00f88ff88f88888f888888f88f06dddddd650606dd60000006dd6dd60006dd60006ddddd65006dd6056dddd6000
00f33ff33ff33f33f33f0f33ff33f0000f88f00f88ff88f88888f888888f88f06ddddd6500606dd60000006dd6dd60006dd60006dddd650006dd60056dddd600
00f3333333333f33f33f0f33fffff0000f88ffff88ff88ffff88f88ffffffff06dd6665006606dd60000006dd6dd60006dd60006dd6dd60006dd600056dddd60
00f3333ff3333f33f33f0f33ff33f0000f88888f888888f88888f888888f88f06dd655006d606dd60666606dd6dd60006dd60006dd66dd6006dd6000056ddd60
005f333ff333ff33f33f0f33ff33f0000f88888ff8888ff8888fff8888ff88f06dd60006dd606dd606dd606dd6dd60006dd60006dd656dd606dd6000006ddd60
0005fff55fff5fffffff0ffffffff0000ffffffffffff5fffff555ffff5ffff06dd60006dd606ddd66dd606dd6dd60006dd60006dd606dd606dd606666dddd60
00005550055505555555055555555000055555555555505555500055550555506dd60006dd6056dddddd606ddddd60006dd60006dd606dd606dd606dddddd650
00066666666600000006666666666000000006666660000000000000000000006dd60006dd60056dddd65056ddd650006dd60006dd606dd606dd606ddddd6500
00067777777600000006777777776000000006777760000000666666666666006666000666600056666500056665000066660006666066660666606666665000
000677777776000000067777777760000000067777600000006dddddddddd6005555000555500005555000005550000055550005555055550555505555550000
000666666776000000066666667760000000066677600000006dddddddddd6000000000000000000000000000000000000000000000000000000000000000000
00055555677600000005555556776000000005567760000006ddddddddddd6000000066666000666666666066666666600066666000006666660666006666000
0000066667760000000666666677600000000006776000006dddddddddddd6000000666666600666666666066666666600666666600066666660666066665000
00000677777600000006777777776000000000067760000056ddddddddddd6000006665556660555666555055566655506665556660666555550666666650000
000006777776000000067777777760000000000677600000056dddddddddd6000006660006660000666000000066600006660006660666000000666666500000
000006666776000000067766666660000000000677600000006dddddddddd6000006666666660000666000000066600006666666660666000000666665000000
00000555677600000006776555555000000000067760000000666666666666000006666666660000666000000066600006666666660666000000666666000000
00066666677600000006776666666000000000067760000000555555555555000006665556660000666000000066600006665556660666000000666666600000
00067777777600000006777777776000000000067760000000000000000000000006660006660000666000000066600006660006660566666660666566660000
00067777777600000006777777776000000000067760000000000000000000000006660006660000666000000066600006660006660056666660666056666000
00066666666600000006666666666000000000066660000000000000000000000005550005550000555000000055500005550005550005555550555005555000
00055555555500000005555555555000000000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000c0700c0700c0700d07010070120701407016070160700d0000e0000f00010000130001400026000180000b0000a0000a0000a00009000080000700004000010000000000000000000000000000
000400000e600146101b620226402c660226202b60021600066001a60001200022001b6001b6001b60019600186000a6001450000000000000000000000000000000000000000000000000000000000000000000
00010000071400614006140061400c140141401914018140131400f1400d1400c1400c1400c1401014013130181301c14021140271402a1402b14028130231301c12014110101100d1700c1700c1700317002170
000400000253004530055200250009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002514022100221002210022100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001400003015030140301300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001e1731e1731e1731d1731c1731917315173101730c1730b1730c1730f173121630f1630b1530815304153021430213301133031130510301103000030000300003000030000300003000030000300003
000300001307117071190011400100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

