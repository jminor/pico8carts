pico-8 cartridge // http://www.pico-8.com
version 15
__lua__

-- today:
-- trees
-- wind
-- the moon
-- meteors
-- juicy title screen
-- randomly spawn coud 

-- have it drift across the sky ("wind") [x]
-- bounded world [x]
-- basic title screen [x]
-- starfield instead of world grid [x]
-- stars twinkle [x]
-- cloud [x]

-- idea is to make an experience/game about sitting on the porch and looking
-- at stars in the night sky, maybe seeing meteors
-- because maybe its cold, or cloudy, or you don't have a porch
-- basic title screen with menu to start (maybe you're looking through a window?)
-- starfield you can pan around (maybe based on a real na sky?)
-- meteors that show up periodically
-- clouds that blow by
-- trees on the edges of teh frame
-- little bit of wind that blows the trees around
-- nice feel on moving the stars around
-- some music / sfx
-- a button to 'go back inside' (the menu)
-- maybe a button to zoom in or zoom out (and impact the sound)?


function repr(arg)
 -- turn any thing into a string (table, boolean, whatever)
 if type(arg) == "table" then 
  local retval = " table{ "
  for k, v in pairs(arg) do
   retval = retval .. k .. ": ".. repr(v).. ","
  end
  retval = retval .. "} "
  return retval
 end
 return tostr(arg)
end
-- { debug stuff can be deleted
function make_debugmsg()
 return {
  space=sp_screen_native,
  draw=function(t)
   color(14)
   cursor(1,1)
   print("cpu: ".. stat(1))
   print("mem: ".. stat(2))
  end
 }
end

function print_stdout(msg)
 -- print 'msg' to the terminal, whatever it might be
 printh("["..repr(g_tick).."] "..repr(msg))
end
-- }

-- { particle stuff
function add_particle(x, y, dx, dy, life, color, ddy)
 particle_array_length += 1

 -- grow if needed
 if (#particle_array < particle_array_length) add(particle_array, 0)
 
 -- insert into the next available spot
 particle_array[particle_array_length] = {x = x, y = y, dx = dx, dy = dy, life = life or 8, color = color or 6, ddy = ddy or 0.0625}
end


function process_particles(at_scope)
 -- @casualeffects particle system
 -- http://casual-effects.com

 -- simulate particles during rendering for efficiency
 local p = 1
 local off = {0,0}
 if at_scope == sp_world and g_cam != nil then
  off = {-g_cam.x + 64, -g_cam.y + 64}
  -- off = {g_cam.x + 64, -g_cam.y + 64}
 end
 while p <= particle_array_length do
  local particle = particle_array[p]
  
  -- the bitwise expression will have the high (negative) bit set
  -- if either coordinate is negative or greater than 127, or life < 0
  if bor(band(0x8000, particle.life), band(bor(off[1]+particle.x, off[2]+particle.y), 0xff80)) != 0 then

   -- delete dead particles efficiently. pico8 doesn't support
   -- table.setn, so we have to maintain an explicit length variable
   particle_array[p], particle_array[particle_array_length] = particle_array[particle_array_length], nil
   particle_array_length -= 1

  else

   -- draw the particle by directly manipulating the
   -- correct nibble on the screen
   local addr = bor(0x6000, bor(shr(off[1]+particle.x, 1), shl(band(off[2]+particle.y, 0xffff), 6)))
   local pixel_pair = peek(addr)
   if band(off[1]+particle.x, 1) == 1 then
    -- even x; we're writing to the high bits
    pixel_pair = bor(band(pixel_pair, 0x0f), shl(particle.color, 4))
   else
    -- odd x; we're writing to the low bits
    pixel_pair = bor(band(pixel_pair, 0xf0), particle.color)
   end
   poke(addr, pixel_pair)
   
   -- acceleration
   particle.dy += particle.ddy
  
   -- advance state
   particle.x += particle.dx
   particle.y += particle.dy
   particle.life -= 1

   for _, c in pairs(collision_objects) do
    local collision_result = c:collides(particle)
    if collision_result != nil then
     particle.x += collision_result[1]
     particle.y += collision_result[2]
     particle.dy = 0
     particle.dx = 0
    end
   end

   p += 1
  end -- if alive
 end -- while
end

collision_objects = {
 {
  x=50,
  y=80,
  width=27,
  height=14,
  collides=function(t, part)
   if (
    part.x > t.x 
    and part.x - t.x < t.width 
    and part.y > t.y and
    part.y - t.y < t.height
   ) then
    -- particle sits on top of the collider
    return {0, - 1}
   end
  end,
  draw=function(t)
   rectfill(t.x, t.y, t.x + t.width, t.y + t.height, 11)
  end
 }
}

function make_particle_manager()
 particle_array, particle_array_length = {}, 0

 return {
  draw=function(t)
   process_particles(sp_world)
  end
 }
end
-- }

function print_cent(str, col)
 str = tostr(str)
 print(str, -(#str)*2, g_cursor_y, col or 8)
 g_cursor_y += 6
end

function make_title()
 return { 
  space=sp_screen_center,
  draw=function(t)
   g_cursor_y = -16
   print_cent("looking for meteors", 6)
   print_cent("on a starry night", 6)
   g_cursor_y=58
   print_cent("  by @stephan_gfx", 6)
  end
 }
end

function _init()
 WORLD_DIM = {
  vecmake(-110, -110),
  vecmake(180, 180)
 }

 stdinit()

 add_gobjs(make_title())

 add_gobjs(
   make_menu(
   {
    'go',
   },
   function (t, i, s)
    add (
     s,
     make_trans(
     function()
      game_start()
     end
     )
    )
   end
  )
 )
end

function _update()
 stdupdate()
end

function _draw()
 stddraw()
end

-- coordinate systems
sp_world = 0
sp_local = 1
sp_screen_native = 2
sp_screen_center = 3

-- @{ useful utility function for getting started
function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end
-- @}

-- @{ mouse support
-- poke(0x5f2d, 1)

-- function make_mouse_ptr()
--  return {
--   x=0,
--   y=0,
--   button_down={false,false,false},
--   space=sp_screen_native,
--   update=function(t)
--    -- if you have the vector functions
--    -- vecset(t, makev(stat(32), stat(33)))
--    t.x = stat(32)
--    t.y = stat(33)
--
--    local mbtn=stat(34)
--    for i,mask in pairs({1,2,4}) do
--     t.button_down[i] = band(mbtn, mask) == mask and true or false
--    end
--   end,
--   draw=function(t)
--    -- chang the color if you have one of the buttons down
--    if t.button_down[1] then
--     pal(3, 11)
--     -- add_particle(0, 0, 0, 1, 60, 11, 1)
--    end
--    if t.button_down[2] then
--     pal(3, 12)
--    end
--    if t.button_down[3] then
--     pal(3, 10)
--    end
--    spr(3, t.x-3, t.y-3)
--    if t.button_down[1] or t.button_down[2] or t.button_down[3] then
--     pal(3,3)
--    end
--    print("("..t.x..","..t.y..")", 1, 13)
--   end
--  }
-- end
-- @}

-- @{ built in diagnostic stuff
function make_player(p)
 return {
  x=0,
  y=0,
  p=p,
  space=sp_world,
  c_objs={},
  -- c_objs={make_grid(sp_local, 64)},
  update=function(t)
   local m_x = 0
   local m_y = 0
   if btn(0, t.p) then
    m_x =-1
   end 
   if btn(1, t.p) then
    m_x = 1
   end
   if btn(2, t.p) then
    m_y = -1
   end
   if btn(3, t.p) then
    m_y = 1
   end
   t.x += m_x
   t.y += m_y
   t.x = max(t.x, WORLD_DIM[1].x)
   t.x = min(t.x, WORLD_DIM[2].x)
   t.y = max(t.y, WORLD_DIM[1].y)
   t.y = min(t.y, WORLD_DIM[2].y)
   updateobjs(t.c_objs)
  end,
  draw=function(t)
   spr(2, -3, -3)
   rect(-3,-3, 3,3, 8)
   local str = "world: " .. t.x .. ", " .. t.y
   print(str, -(#str)*2, 12, 8)
   drawobjs(t.c_objs)
  end
 }
end

function make_grid(space, spacing)
 return {
  x=0,
  y=0,
  space=space,
  spacing=spacing,
  update=function(t) end,
  draw=function(t) 
   local space_label = "local"
   if t.space == sp_world then
    space_label = "world" 
   elseif t.space == sp_screen_center then
    space_label = "screen_center"
   elseif t.space == sp_screen_native then
    space_label = "screen_native"
   end

   for x=0,3 do
    for y=0,3 do
     local col = y*4+x
     local xc =(x-1.5)*t.spacing 
     local yc = (y-1.5)*t.spacing
     rect(xc-1, yc-1,xc+1, yc+1, col)
     circ(xc, yc, 7, col)
     local str = space_label .. ": " .. xc .. ", ".. yc
     print(str, xc-#str*2, yc+9, col)
    end
   end
  end
 }
end

function make_camera()
 return {
  x=0,
  y=0,
  update=function(t)
   t.x=g_p1.x
   t.y=g_p1.y
  end,
  draw=function(t)
  end
 }
end
-- @}

cols = {5,6,1,13,15,5,1,13,5,13,15}
twinkle_color = {}
twinkle_color[5] = 6
twinkle_color[6] = 7
twinkle_color[7] = 15
twinkle_color[1] = 5
twinkle_color[13]= 15
twinkle_color[15]= 7

function make_starfield(sky_half_width, pixels_per_chunk, stars_per_chunk)
 -- @todo: starfield
 stars = {}
 for x_iter = -sky_half_width,sky_half_width,pixels_per_chunk do
  for y_iter = -sky_half_width,sky_half_width,pixels_per_chunk do
   for s = 0,(stars_per_chunk - 1) do
    local star_geom = vecadd(vecmake(x_iter, y_iter), vecflr(vecrand(pixels_per_chunk)))
    star_geom.c = cols[flr(rnd(#cols))+1]
    star_geom.twinkle = flr(rnd(512))
    add(stars, star_geom)
   end
  end
 end

 return {
  x=0,
  y=0,
  space=sp_world,
  draw=function(t)
   for starcoord in all(stars) do
    local c=starcoord.c
    if (((starcoord.twinkle + g_tick) % 512) < 10) then
     c = twinkle_color[c]
    end
    circfill(starcoord.x, starcoord.y,c  == 7 and 1, c)
   end
  end
 }
end

function drawvecline(from,to,thickness, col)
 local dir_vec = vecsub(to, from)
 local dir_vec_perp = vecnormalized(vecperp(dir_vec))

 for i=-thickness,thickness,1 do
-- local i=-thickness
  local from_current = vecadd(vecscale(dir_vec_perp, i), from)
  local to_current = vecadd(vecscale(dir_vec_perp, i), to)
  -- circfill(from_current.x, from_current.y, 1, 8)
  -- circfill(from.x, from.y, 1, 6)
  -- circfill(to_current.x, to_current.y, 1, 9)
  -- circfill(to.x, to.y, 1, 7)
  line(from_current.x, from_current.y, to_current.x, to_current.y, col)
 end
end

-- function make_branch(base, tip, thickness)
--  return {
--   space=sp_local,
--   x=base.x,
--   y=base.y,
--   thickness=thickness,
--   tip=tip,
--   dir_vec=vecsub(tip, base),
--   draw=function(t)
--    -- circfill(0,0,2,11)
--    -- circfill(tip.x,tip.y,2,12)
--    drawvecline(vecmake(), t.tip, t.thickness, 5)
--    -- print("thickness: "..t.thickness, 0,0, 12)
--
--    -- leaves
--    local leaf_root = vecscale(t.dir_vec, 0.5)
--    local leaf_end = vecadd(vecscale(vecnormalized(t.dir_vec), 5), leaf_root)
--    rectfill(leaf_root.x, leaf_root.y, leaf_end.x, leaf_end.y, 3)
--   end
--  }
-- end

function make_tree(loc)
 local bottom_thickness = 4
 local thickness_reduce = 1
 local segment_length = 10


 return {
  x=0,
  y=0,
  space=sp_world,
  -- children = trunk_segments,
  draw=function(t)
   local angle = 0.25 + 0.1 * (sin(loop_over(80)) + sin(loop_over((120))))
   local target = vecfromangle(angle, segment_length)
   drawvecline(null_v, target, 5, 5)
   -- for trunk_sec = 0,5 do
   --  local current_thickness = bottom_thickness - thickness_reduce*trunk_sec
   --
   --  local offset = trunk_sec*segment_length
   --
   --  -- trunk top
   --  local top = vecmake(0, -offset+segment_length)
   --  local bottom = vecmake(0,-offset)
   --  drawvecline(bottom, top, current_thickness, 5)
   --  -- print(""..trunk_sec, bottom.x, bottom.y, 11)
   -- end

   -- circfill(0,0,10,5)

   -- segments
   -- branches
   -- leaves
  end
 }
end

function make_cloud(origin, num_bubbles, vel)
 -- -8         x         8
 --  +-+---+---+---+---+-+
 local bubbles = {}
 local space=3
 local b = add(bubbles, vecmake(-8*space,0))
 b.r = 5
 b = add(bubbles, vecmake(8*space,0))
 b.r = 5

 for i=0,4 do
  add(bubbles, vecmake((-6+i*3)*space,rnd(4)-2))
 end
 for i=3,#bubbles do
  bubbles[i].r = 8-rnd(2)
 end
 
 local new_cloud = {
  space=sp_world,
  update=function(t)
   t.x += vel.x
  end,
  draw=function(t)
   for b in all(bubbles) do
    circfill(b.x+2,b.y+2,b.r,12)
    circfill(b.x,  b.y,  b.r,13)
   end
   for b in all(bubbles) do
    circfill(b.x+1,b.y+1,b.r,1)
    circfill(b.x+1,b.y,  b.r,13)
    circfill(b.x+1,b.y+1,b.r,1)
   end
  end
 }
 vecset(new_cloud, origin)

 return new_cloud
end

function make_meteor()
 return {
  x=0,
  y=0,
  space=sp_world,
  draw=function(t)

   local p1 = vecmake( -10, -10)
   local p2 = vecmake( 20, 10)

   -- 
   -- vecdrawpt(p1, 11)
   -- vecdrawpt(p2, 12)
   -- vecdrawline(p1, p2, 9)

   local tval = (g_tick % 60)/60
   local val = ef_out_quad(tval)

   local p_now = veclerp(p1, p2, val)
   vecdrawpt(p_now, 10)

   local d_val_dt = -2 * tval

   local tval_last = -d_val_dt
   local p_last = veclerp(p1, p2, tval_last)
   vecdrawpt(p_last, 11)



   -- tail
  end
 }
end

function ef_out_quad(amount)
 return -1 * amount*(amount-2);
end

function game_start()
 g_objs = {
  -- make_mouse_ptr(),
  -- make_grid(sp_world, 128),
  make_starfield(192,64,20),
  make_meteor(),
  -- make_cloud(vecmake(0), 4, vecmake(0.01, 0)),
  -- make_tree(vecmake()),
  -- make_grid(sp_screen_center, 128),
  -- make_particle_manager(),
  make_debugmsg(),
 }

 g_cam= add_gobjs(make_camera())
 g_p1 = add_gobjs(make_player(0))


--  g_brd = make_board()
--  add(g_objs, g_brd)
--  g_tgt = make_tgt(0,0)
--  add(g_objs,g_tgt)
end

------------------------------

function stdinit()
 g_tick=0    --time
 g_ct=0      --controllers
 g_ctl=0     --last controllers
 g_cs = {}   --camera stack 
 g_objs = {} --objects
end

function stdupdate()
 g_tick = max(0,g_tick+1)
 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()
 updateobjs(g_objs)
end

function updateobjs(objs)
 foreach(objs, function(t)
  if t.update then
   t:update(objs)
  end
 end)
end

function stddraw()
 cls()
 drawobjs(g_objs)
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   local cam_stack = 0

   -- i think the idea here is that if you're only drawing local,
   -- then you only need to push -t.x, -t.y
   -- if you're drawing camera space, then the camera will manage the screen
   -- center offset
   -- if you're drawing screen center 
   local tx = t.x or 0
   local ty = t.y or 0
   if t.space == sp_screen_center then
    pushc(-64, -64)
    cam_stack += 1
   elseif t.space == sp_world and g_cam  then
    pushc(g_cam.x - 64, g_cam.y - 64)
    pushc(-tx, -ty)
    cam_stack += 2
   elseif not t.space or t.space == sp_local then
    pushc(-tx, -ty)
    cam_stack += 1
   elseif t.space == sp_screen_native then
   end

   t:draw(objs)

   for i=1,cam_stack do
    popc()
   end
  end
 end)
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

function getspraddr(n)
 return flr(n/16)*512+(n%16)*4
end

function sprcpy(dst,src,w,h)
 w = w or 1
 h = h or 1
 for i=0,h*8-1 do
  memcpy(getspraddr(dst)+64*i,
     getspraddr(src)+64*i,4*w)
 end
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

function make_menu(
 lbs, --menu lables
 fnc, --chosen callback
 x,y, --pos
 omb, --omit backdrop
 p,   --player
 cfnc --cancel callback
)
 local m={
  --lbs=lbs,
  --f=fnc,
  --fc=cfnc,
  i=0, --item
  s=g_tick,
  e=5,
  x=x or 64,
  y=y or 80,
  h=10*#lbs+4,
  --omb=omb,
  tw=0,--text width
  p=p or -1,
  draw=function(t)
   local e=elapsed(t.s)
   local w=t.tw*4+10
   local x=min(1,e/t.e)*(w+9)/2
   if not omb then
    rectfill(-x,0,x,t.h,0)
    rect(-x,0,x,t.h,1)
   end
   if e<t.e then
    return
   end
   x=w/2+1
   for i,l in pairs(lbs) do
    if not t.off or i==t.i+1 then
     local y=4+(i-1)*10
     print(l,-x+9,y+1,0)
     print(l,-x+9,y,7)
    end
   end
   spr(0,-x,2+10*t.i)
  end,
  update=function(t,s)
   if (t.off) return
   if elapsed(t.s)<(t.e*2) then
    return
   end

   if btnn(5,t.p) then
    if fnc then
     fnc(t,t.i,s)
     --sfx(2)
    end
   end

   --cancel
   if btnn(4,t.p) then
    if cfnc then
     cfnc(t,s)
     --sfx(2)
    end
   end

   if btnn(2,t.p) and
     t.i>0 then
    t.i-=1
    sfx(1)
   end
   if btnn(3,t.p) and
     t.i<(#lbs-1) then
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

function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
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
  x=0,
  y=0,
  update=function(t,s)
   if elapsed(t.e)>10 then
    if (t.f) t:f(s)
    del(s,t)
    if not t.i then
     add(s,
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

function loop_over(numframes)
 return ((g_tick % numframes) / numframes)
end

-- @{ vector library
function vecdrawpt(v, c)
 rectfill(v.x-1, v.y-1, v.x+1, v.y+1, c)
end

function vecdrawline(p1, p2, c)
 line(p1.x, p1.y, p2.x, p2.y, c)
end

function vecdrawrectfill(v1, v2, c)
 rectfill(v1.x, v1.y, v2.x, v2.y, c)
end

function vecdraw(v, c, scale, o)
 o = o or null_v

 local end_point = vecadd(o, vecscale(v, scale or 30))
 line(o.x, o.y, end_point.x, end_point.y, c)
 return
end

function vecatan_noflr(v)
 return atan2(v.x, v.y)
end

function rnd_centered(max_val)
 return rnd(max_val)-(max_val/2)
end

function vecrand(scale, center, yscale)
 local result = vecmake(rnd(scale), rnd(yscale or scale))
 if center then
  result = vecsub(result, vecmake(scale/2, (yscale or scale)/2))
 end
 return result
end

function vecperp(v)
 return vecmake(v.y, -v.x)
end

function vecmake(xf, yf)
 xf = xf or 0

 return {x=xf, y=(yf or xf)}
end

function veccopy(tgt)
 return vecmake(tgt.x, tgt.y)
end

-- global null vector
null_v = vecmake()

function vecscale(v, m)
 return {x=v.x*m, y=v.y*m}
end

function vecmagsq(v)
 return v.x*v.x+v.y*v.y
end

function vecmag(v, sf)
 if sf then
  v = vecscale(v, sf)
 end
 local result=sqrt(vecmagsq(v))
 if sf then
  result=result/sf
 end
 return result
end

function vecnormalized(v)
 return vecscale(v, 1/vecmag(v))
end

function vecdot(a, b)
 return (a.x*b.x+a.y*b.y)
end

function vecadd(a, b)
 return {x=a.x+b.x, y=a.y+b.y}
end

function vecsub(a, b)
 return {x=a.x-b.x, y=a.y-b.y}
end

function vecflr(a)
 return vecmake(flr(a.x), flr(a.y))
end

function vecset(target, source)
 target.x = source.x
 target.y = source.y
end

-- function vecminvec(target, minvec)
--  target.x = min(target.x, minvec.x)
--  target.y = min(target.y, minvec.y)
--  return target
-- end

-- function vecmaxvec(target, maxvec)
--  target.x = max(target.x, maxvec.x)
--  target.y = max(target.y, maxvec.y)
--  return target
-- end

function vecfromangle(angle, mag)
 mag = mag or 1.0
 return vecmake(mag*cos(angle), mag*sin(angle))
end

function veclerp(v1, v2, amount, clamp)
 -- tokens: can compress this with ternary
 local result = vecadd(vecscale(vecsub(v2,v1),amount),v1)
 if clamp and vecmag((vecsub(result,v2))) < clamp then
  result = v2
 end
 return result
end

function clamp(v, min_v, max_v)
 return min(max(v, min_v or 0), max_v or 1)
end

function vecclamp(v, min_v, max_v)
 return vecmake(
  clamp(v.x, min_v.x, max_v.x),
  clamp(v.y, min_v.y, max_v.y)
 )
end
-- @}

__gfx__
00600000101221010000000033000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0066000000088000000c000030000030000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000
0066600010033001000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000
00666600283083820cc8cc0000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000
0066650028380382000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000000000000
0066500010033001000c0000300000300000000000aaaaa0aaa000aa000aaaa00000000000010000000000000000000000000000000000000111100000000000
00650000000880000000000033000330000000000000a000a0000aa00000a0000000000000111000000000000000000000000000000000000111101000000000
00500000101221010000000000000000000000000000a000aaa000aaa000a0000000000000111010001000000000000010000000000001001111111000000000
00000000000000000000000000000000000000000000a000a0000000a000a0000000000001111110001100000000000011000000000011001111111000000000
00000000000000000000000000000000000000000000a000aaa00aaaa000a0000000000000111111001100100000000111010000000011101111111000000001
00000000000000000000000000000000000000000000a00000000000000000000000000000111111111101100000000111011000000111101111111100000001
00000000000000000000000000000000000000000000000000000000000000000000000001111110011101110010001111111000000111111111111100100011
00000000000000000000000000000000000000000000000000000000000000000000000001111111011111110111001111111100001111111111111101110011
00000000000000000000000000000000000000000000000000000000000000000000800001111111111111110111011111111111001111111111111101110111
00000000000000000000000000000000000000000000000088888880000000000000800011111111111111111111111111111111011111111111111111111111
00000000000000000000000000000000000000000000000000008888000000000000800011111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000008000000000000000800011000000000000001100000000000000100000000000000011100100
00000000000000000000000000000000000000000000000000008000000000000000800011111001000000001111000000000000110000000000000011111100
00000000000000000000000000000000000000000000000000008088880000000888888011111111110000001111100000000000111100000000000011111111
00000000000000000000000000000000000000000000000000008080080088800000800011111111111000001111000000000000111111000000000011111111
00000000000000000000000000000000000000000000000000008088880080000000800011111111110000001100000000000000111111110000000011110000
00000000000000000000000000000000000000000000000000000088000088888000880011111111000000001110000000000000111111111000000011111100
00000000000000000000000000000000000000000000000000000008800000888000080011111111100000001111100000000000111111100000000011111110
0000000000000000000000000000000000000000000000e000000000000000000000000011110110000000001111111000000000111110000000000011111000
0000000000000000000000000000000000000000000000e000000000000000000000000011100100000000001111111110000000111111111000000011000000
0000000000000000000000000000000000000000000eeeeee000000000e000000000000011111100000000001111111100000000111111111111000011110000
0000000000000000000000000000000000000000000000e00ee00eee00e000000000000011111111100000001111100000000000111111111111111011111000
0000000000000000000000000000000000000000000000e0eee00e000eee00000000000011111111000000001111111000000000111111111111110011110000
0000000000000000000000000000000000000000000000e0eee00ee000e000000000000011110000000000001111110000000000111111111110000011000000
0000000000000000000000000000000000000000000000e0e0000eee00e000000000000011111100000000001111000000000000111111111000000011100000
000000000000000000000000000000000000000000000000eeee0000000000000000000011111110000000001110000000000000111111111100000011111000
00000000000000000000000000000000000000000000000000000000000000000000000011111000000000001110000000000000111111000000000011111110
__music__
00 01424344

