pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

t=0

function _update60()
 cls(0)

 a=15
 jy=70
 x=24 --t%(128+16)-16
 y=sin(t*0.01)*a+jy
 spr(1,x,y,2,2)

 x=56 --t%(128+16)-16
 y=sin((t+10)*0.01)*a+jy
 spr(1,x,y,2,2)

 x=88 --t%(128+16)-16
 y=sin(t*0.01)*a+jy
 spr(1,x,y,2,2)

 wiggle("         join us for...    ",
        0,12,0.01,-10,5,1,9)
 wiggle("the jam!    ",
        0.5,40,0.01,-10,5,40,7)
 wiggle("         nov 30 & dec 1",
        0,112,0.01,-5,5,1,13)

 t=(t+1)%(60*30)
end

function wiggle(text,x,y,f,p,a,r,c)
 local px=-t*x
 local z=t
 for rep=1,r do
  for i=1,#text do
   local wig=sin(z*f)*a
   print(sub(text,i,i),px,y+wig,c)
   px+=4
   z+=p
  end
 end
end

__gfx__
00000000778877887788778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000778877887788778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700066666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077667766776677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000087888788788887000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000877717717717177800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000877717171711177800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000877717111711177800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000871717171717177800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000871177171717177800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000999009900000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000099900000000000000000000000000000900090909990000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009000000000000000000000000000000990090909090000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009000000000000000000000000000000900090909900000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009000990000000000000000000000000900099009090000000000000000000000000000000000000000000000000
00000000000000000000000000000000000099009090000000000000000009900000000000009090000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009090000000000000000090000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009090999000000000000099900000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009900090000000000909000900000000000000000090000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000090099000000909099000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000090090900000909000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000999090900000909000000000000000000000000009000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000090900000099000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000090900000000000000000000000000000000000000900000000000000000000000000000000000000
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
07770000000000000000000000000000000000000777000000000000000000000000000000000707077700000000000000000000000000000000000007770000
07770070000000000000000000000000000000000070077700000000000000000000000000000707070000000000000000000000000000000000000000700707
07070070000000000000000000000000077700000070070700000000000000000000000007770777077000000000000000000000000000000000000000700707
07070070000000000000000000000000070000000070077700000000000000000000000000700707070000000000000000000000000000000000000000700777
07070000000000000000000000000000077000000770070707770000000000000000000000700707077700000777000000000000000000000000000000700707
00000070000000000000000000000707070000000000070707770000000000000000000000700000000000000070000000000000000000000000000000000707
00000000000000000000000000000707077700000000000007070000000000000000000000700000000000000070000000000000000000000000000000000000
00000000000000000000000000000777000000000000000007070070000000000000000000000000000000000070077700000000000000000000000000000000
00000000000000000000000007770707000000000000000007070070000000000000000000000000000000000770070700000000000000000000000000000000
00000000000000000000000000700707000000000000000000000070000000000000000000000000000000000000077707770070000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000070707770070000000000000000000000000
00000000000000000000000000700000000000000000000000000070000000000000000000000000000000000000070707070070000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000007070000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000778877887788778800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000778877887788778800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000066666666666666000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000077667766776677000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000087888788788887000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000888888888888888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000888888888888888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000887777777777778800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000877717717717177800000000000000000000000000000000000000000000000000000000
00000000000000000000000077887788778877880000000000000000877717171711177800000000000000007788778877887788000000000000000000000000
00000000000000000000000077887788778877880000000000000000877717111711177800000000000000007788778877887788000000000000000000000000
00000000000000000000000006666666666666600000000000000000871717171717177800000000000000000666666666666660000000000000000000000000
00000000000000000000000007766776677667700000000000000000871177171717177800000000000000000776677667766770000000000000000000000000
00000000000000000000000008788878878888700000000000000000887777777777778800000000000000000878887887888870000000000000000000000000
00000000000000000000000088888888888888880000000000000000888888888888888800000000000000008888888888888888000000000000000000000000
00000000000000000000000088888888888888880000000000000000088888888888888000000000000000008888888888888888000000000000000000000000
00000000000000000000000088777777777777880000000000000000000000000000000000000000000000008877777777777788000000000000000000000000
00000000000000000000000087771771771717780000000000000000000000000000000000000000000000008777177177171778000000000000000000000000
00000000000000000000000087771717171117780000000000000000000000000000000000000000000000008777171717111778000000000000000000000000
00000000000000000000000087771711171117780000000000000000000000000000000000000000000000008777171117111778000000000000000000000000
00000000000000000000000087171717171717780000000000000000000000000000000000000000000000008717171717171778000000000000000000000000
00000000000000000000000087117717171717780000000000000000000000000000000000000000000000008711771717171778000000000000000000000000
00000000000000000000000088777777777777880000000000000000000000000000000000000000000000008877777777777788000000000000000000000000
00000000000000000000000088888888888888880000000000000000000000000000000000000000000000008888888888888888000000000000000000000000
00000000000000000000000008888888888888800000000000000000000000000000000000000000000000000888888888888880000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000ddd00000dd00000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000ddd0d0d00000dd000000dd000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000d0d0d000000dd00000d0d00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000d0d000000dd0d0d00000d0d00000d0d0ddd0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000d0d0000000d0ddd00000ddd00000d0d0d0000dd000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000dd0d0d00000ddd00000000000000000ddd0dd00d00000000000000000000000000000000000000000000000
000000000000000000000000000000000000dd00d0d0ddd00000000000000000000000000000d000d00000000000000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d00d000000000000000000000000000000ddd0d0000000dd00000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d00000000000000000000000000000000000000dd000000d00000000000000000000000000000000000000
000000000000000000000000000000000000d0d0dd00000000000000000000000000000000000000000000000d00000000000000000000000000000000000000
000000000000000000000000000000000000d0d00000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
