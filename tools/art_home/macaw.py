import json
from PIL import Image
PAL={".":None,"k":"#1b1420","d":"#3b2a22","m":"#6b4e36","l":"#9c7a54","c":"#d9c49c","f":"#2e2a3a","F":"#3d3850","w":"#5a5468","W":"#7e7892","g":"#3e7a3a","G":"#7fb24a","r":"#b13e53","y":"#e8b04a","b":"#3b5dc9","t":"#f4efe2"}
# 32x24, flying LEFT. Frame 0 wings up, frame 1 wings down.
BASE=[
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"....rrr.........................",
"...rttrr........................",
"..crtkrrr.......................",
".ccrrrrrrr......................",
"cck.rrrrrrrr....................",
".k...rrrrrrrrrr.................",
".....rrrrrrrrrrrr...............",
"......rrrrrrrrrrrbb.............",
".......rrrrrrrrrrbbyy...........",
"........rrrrrrrr...bbyy.........",
".........kk..k.......bbyy.......",
".......................bbyy.....",
".........................bbyy...",
"...........................byy..",
"................................",
"................................",
"................................",]
UP=[(8,6),(9,5),(10,4),(11,3),(12,2),(13,1),(14,0),
    (9,6),(10,5),(11,4),(12,3),(13,2),(14,1),(15,0),
    (10,6),(11,5),(12,4),(13,3),(14,2),(15,1),(16,0),
    (11,6),(12,5),(13,4),(14,3),(15,2),(16,1),(17,0),
    (12,6),(13,5),(14,4),(15,3),(16,2),
    (13,6),(14,5),(15,4)]
DOWN=[(9,17),(10,18),(11,19),(12,20),(13,21),(14,22),
      (10,17),(11,18),(12,19),(13,20),(14,21),(15,22),
      (11,17),(12,18),(13,19),(14,20),(15,21),(16,22),
      (12,17),(13,18),(14,19),(15,20),(16,21),
      (13,17),(14,18),(15,19)]
def frame(pts, up):
    if up: pts=[(x+2,y+6) for (x,y) in pts]
    g=[list(r) for r in BASE]
    for (x,y) in pts:
        tip = (y<=8) if up else (y>=20)
        g[y][x]='y' if tip else 'b'
    # outline
    out=[r[:] for r in g]
    for y in range(24):
        for x in range(32):
            if g[y][x]=='.':
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    X,Y=x+dx,y+dy
                    if 0<=X<32 and 0<=Y<24 and g[Y][X] not in '.k': out[y][x]='k'; break
    return [''.join(r) for r in out]
P=json.load(open("props.json"))
P['macaw_0']=frame(UP,True); P['macaw_1']=frame(DOWN,False)
json.dump(P,open("props.json","w"))
def render(rws,s):
    h=len(rws); w=len(rws[0]); im=Image.new("RGBA",(w,h),(0,0,0,0))
    for y,r in enumerate(rws):
        for x,ch in enumerate(r):
            if PAL.get(ch):
                hx=PAL[ch].lstrip('#'); im.putpixel((x,y),tuple(int(hx[i:i+2],16) for i in (0,2,4))+(255,))
    return im.resize((w*s,h*s),Image.NEAREST)
sheet=Image.new("RGBA",(420,150),(61,56,80,255))
a=render(P['macaw_0'],6); b=render(P['macaw_1'],6); sheet.paste(a,(10,0),a); sheet.paste(b,(220,0),b); sheet.save("macaw_preview.png")
