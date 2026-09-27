import random, math, json
from PIL import Image
PAL={"k":"#1b1420","d":"#3b2a22","m":"#6b4e36","l":"#9c7a54","c":"#d9c49c","f":"#2e2a3a","F":"#3d3850","w":"#5a5468","W":"#7e7892","g":"#3e7a3a","G":"#7fb24a","r":"#b13e53","y":"#e8b04a","b":"#3b5dc9","t":"#f4efe2"}
W,H=480,270
rnd=random.Random(7)
C=[['F']*W for _ in range(H)]
def px(x,y,c):
    if 0<=x<W and 0<=y<H: C[y][x]=c
def rect(x0,y0,x1,y1,c):
    for y in range(max(0,y0),min(H,y1)):
        for x in range(max(0,x0),min(W,x1)): C[y][x]=c
def hline(x0,x1,y,c): rect(x0,y,x1,y+1,c)
def vline(x,y0,y1,c): rect(x,y0,x+1,y1,c)
def ellipse(cx,cy,rx,ry,c):
    for y in range(int(cy-ry)-1,int(cy+ry)+2):
        for x in range(int(cx-rx)-1,int(cx+rx)+2):
            if ((x-cx)/rx)**2+((y-cy)/ry)**2<=1: px(x,y,c)
# --- dusk sky: bands with dithered edges
bands=[(0,'f'),(60,'F'),(120,'w'),(175,'W')]
for y in range(H):
    c='f'
    for y0,cc in bands:
        if y>=y0: c=cc
    for x in range(W): C[y][x]=c
    for y0,cc in bands[1:]:
        if y0-4<=y<y0 :
            for x in range(W):
                if (x+y)%2==0 and rnd.random()<(y-(y0-4))/4: C[y][x]=cc
# stars + moon
for i in range(40):
    x=rnd.randrange(W); y=rnd.randrange(0,110)
    px(x,y,'t' if rnd.random()<0.4 else 'W')
ellipse(420,40,13,13,'c'); ellipse(425,36,12,12,'F') ; ellipse(418,42,10,10,'c')
# distant hills
for x in range(W):
    h=int(200+10*math.sin(x/37)+6*math.sin(x/13+1))
    for y in range(h,H): C[y][x]='w' if y<h+3 else 'F'
# --- ground
GY=232
rect(0,GY,W,H,'d')
for x in range(W):
    for y in range(GY,GY+3): C[y][x]='g' if y>GY else 'G'
    if rnd.random()<0.35: px(x,GY-1,'G')
    if rnd.random()<0.15: px(x,GY-2,'g')
for i in range(260):
    x=rnd.randrange(W); y=rnd.randrange(GY+4,H); px(x,y,'m')
for i in range(80):
    x=rnd.randrange(W); y=rnd.randrange(GY+6,H); px(x,y,'k')
# --- tree trunk (cutaway room lives inside)
TX0,TX1=140,352
for y in range(40,GY+2):
    for x in range(TX0,TX1):
        C[y][x]='m'
    # bark shading
    for x in range(TX0,TX0+6): C[y][x]='d'
    for x in range(TX1-8,TX1): C[y][x]='d'
for i in range(900):
    x=rnd.randrange(TX0+2,TX1-2); y=rnd.randrange(40,GY)
    L=rnd.randrange(3,9)
    for j in range(L): px(x,y+j,'d' if rnd.random()<0.8 else 'l')
# roots
for (rx,dirn) in [(TX0,-1),(TX0+30,-1),(TX1,1),(TX1-40,1)]:
    for i in range(22):
        x=rx+dirn*i; y=GY-2+int(i*0.25)
        rect(x-2,y,x+3,y+3,'m'); px(x,y+3,'d')
# --- canopy: many overlapping leaf clumps, dark underside, light tops
clumps=[]
for (cx,cy,rx,ry) in [(150,60,75,42),(250,32,95,42),(345,62,75,40),(250,80,110,36)]:
    for i in range(int(rx*ry/60)):
        a=rnd.random()*math.tau; r=math.sqrt(rnd.random())
        clumps.append((cx+math.cos(a)*r*rx, cy+math.sin(a)*r*ry, rnd.randint(9,16)))
clumps.sort(key=lambda c:c[1])
for (cx,cy,rr) in clumps: ellipse(cx,cy+2,rr,rr*0.8,'k' if cy>70 else 'g')
for (cx,cy,rr) in clumps:
    ellipse(cx,cy,rr,rr*0.8,'g')
    ellipse(cx-2,cy-2,rr*0.72,rr*0.58,'G')
    # leaf speckle
    for i in range(int(rr*1.5)):
        x=int(cx+rnd.uniform(-rr*0.7,rr*0.7)); y=int(cy+rnd.uniform(-rr*0.5,rr*0.5))
        if 0<=x<W and 0<=y<H and C[y][x]=='G': px(x,y,'g')
for i in range(70):
    x=rnd.randrange(80,420); y=rnd.randrange(0,110)
    if C[y][x]=='G': px(x,y,'t' if rnd.random()<0.2 else 'y')
# --- room (cutaway) inside trunk
RX0,RX1,RY0,RFLOOR=160,336,110,194
rect(RX0-4,RY0-4,RX1+4,RFLOOR+8,'k')  # cut edge
rect(RX0,RY0,RX1,RFLOOR,'l')          # back wall
for x in range(RX0,RX1,12):           # wall planks
    vline(x,RY0,RFLOOR,'m')
for y in range(RY0,RFLOOR):
    if (y-RY0)%3==0:
        for x in range(RX0,RX1):
            if rnd.random()<0.05: px(x,y,'m')
rect(RX0,RY0,RX1,RY0+4,'m'); hline(RX0,RX1,RY0+4,'d')   # ceiling beam
rect(RX0,RFLOOR,RX1,RFLOOR+6,'m')     # floor boards
hline(RX0,RX1,RFLOOR,'c')
for x in range(RX0,RX1,18): vline(x,RFLOOR+1,RFLOOR+6,'d')
hline(RX0,RX1,RFLOOR+6,'d')
# skirting shadow
hline(RX0,RX1,RFLOOR-1,'m')
# window on back wall
WX0,WY0,WX1,WY1=236,124,272,154
rect(WX0-3,WY0-3,WX1+3,WY1+3,'d')
rect(WX0,WY0,WX1,WY1,'F')
for i in range(8): px(rnd.randrange(WX0,WX1),rnd.randrange(WY0,WY1),'t')
ellipse(WX1-8,WY0+8,4,4,'c')
rect(WX0,WY0+ (WY1-WY0)*2//3,WX1,WY1,'g')
vline((WX0+WX1)//2,WY0,WY1,'d'); hline(WX0,WX1,(WY0+WY1)//2,'d')
hline(WX0-4,WX1+4,WY1+3,'m')  # sill
# door opening to porch on right wall
DX0,DX1,DY0=RX1-2,RX1+8,150
rect(DX0,DY0,DX1,RFLOOR,'F'); rect(DX0,DY0-3,DX1,DY0,'d')
# --- porch (right of trunk)
PX0,PX1,PY=RX1+4,440,RFLOOR
rect(PX0,PY,PX1,PY+5,'l'); hline(PX0,PX1,PY,'c'); hline(PX0,PX1,PY+5,'d')
for x in range(PX0,PX1,14): vline(x,PY+1,PY+5,'m')
# porch supports down to ground
for x in (PX0+20,PX1-6):
    rect(x,PY+6,x+4,GY,'m'); vline(x,PY+6,GY,'d')
# railing
hline(PX0,PX1,PY-14,'m'); hline(PX0,PX1,PY-13,'d')
for x in range(PX0+4,PX1,8): vline(x,PY-13,PY,'m')
vline(PX1-1,PY-16,PY,'d')
# lantern on porch post
rect(PX1-6,PY-24,PX1+1,PY-16,'k'); rect(PX1-5,PY-23,PX1,PY-17,'y'); px(PX1-3,PY-21,'t')
# --- ladder from porch opening down to the burrow hole
LX0,LX1=404,420
LOPEN=(LX0-2,LX1+2)
rect(LOPEN[0],PY,LOPEN[1],PY+6,'k')      # hatch in porch floor
for y in range(PY-12,GY+22):
    px(LX0,y,'l'); px(LX0+1,y,'m'); px(LX1-1,y,'l'); px(LX1,y,'m')
for y in range(PY-8,GY+22,6):
    hline(LX0+2,LX1-1,y,'c'); hline(LX0+2,LX1-1,y+1,'m')
# rail gap above ladder
for x in range(LX0-1,LX1+2): C[PY-14][x]='F'; C[PY-13][x]='F'
# burrow hole in ground under ladder
ellipse(412,GY+12,22,9,'k'); ellipse(412,GY+10,24,4,'d')
ellipse(412,GY+13,19,7,'k')
for y in range(GY+2,GY+22):
    px(LX0,y,'l'); px(LX1,y,'m')
for y in range(GY+4,GY+22,6): hline(LX0+2,LX1-1,y,'c')
# --- computer corner (left of room): desk + CRT with cozy glow
DKX0,DKX1,DKY=166,206,172
rect(DKX0,DKY,DKX1,DKY+3,'m'); hline(DKX0,DKX1,DKY,'c'); 
rect(DKX0+2,DKY+3,DKX0+5,RFLOOR,'d'); rect(DKX1-5,DKY+3,DKX1-2,RFLOOR,'d')
# CRT monitor
rect(DKX0+8,DKY-22,DKX0+32,DKY,'k'); rect(DKX0+9,DKY-21,DKX0+31,DKY-1,'c')
rect(DKX0+11,DKY-19,DKX0+29,DKY-6,'F')
rect(DKX0+12,DKY-18,DKX0+28,DKY-7,'b')
for x in range(DKX0+13,DKX0+27,3): px(x,DKY-15,'t'); px(x,DKY-12,'W')
px(DKX0+26,DKY-9,'G')
rect(DKX0+14,DKY-5,DKX0+26,DKY-3,'l')
# keyboard + mug
rect(DKX0+10,DKY-2,DKX0+28,DKY,'W'); hline(DKX0+10,DKX0+28,DKY-2,'t')
rect(DKX0+34,DKY-5,DKX0+38,DKY,'r'); px(DKX0+38,DKY-4,'r'); px(DKX0+35,DKY-7,'W'); px(DKX0+36,DKY-8,'W')
# glow on wall around monitor (dither)
for y in range(DKY-30,DKY+2):
    for x in range(DKX0,DKX0+42):
        if C[y][x]=='l' and (x+y)%2==0 and math.hypot(x-(DKX0+20),y-(DKY-12))<22: C[y][x]='c'
# stool
rect(DKX0+14,DKY+8,DKX0+28,DKY+11,'r'); hline(DKX0+14,DKX0+28,DKY+8,'t'); vline(DKX0+16,DKY+11,RFLOOR,'d'); vline(DKX0+26,DKY+11,RFLOOR,'d')
img=Image.new("RGB",(W,H))
for y in range(H):
    for x in range(W):
        h=PAL[C[y][x]].lstrip('#'); img.putpixel((x,y),tuple(int(h[i:i+2],16) for i in (0,2,4)))
img.save("home_bg.png")
img.resize((W*2,H*2),Image.NEAREST).save("home_bg_2x.png")
json.dump({"room":[RX0,RY0,RX1,RFLOOR],"floor_y":RFLOOR,"porch":[PX0,PX1,PY],"ladder_x":(LX0+LX1)//2,"computer_x":DKX0+20,"door":[DX0,DX1],"ground_y":GY},open("layout.json","w"))
print("ok")
