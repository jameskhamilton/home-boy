import json
from PIL import Image
PAL={".":None,"k":"#1b1420","d":"#3b2a22","m":"#6b4e36","l":"#9c7a54","c":"#d9c49c","f":"#2e2a3a","F":"#3d3850","w":"#5a5468","W":"#7e7892","g":"#3e7a3a","G":"#7fb24a","r":"#b13e53","y":"#e8b04a","b":"#3b5dc9","t":"#f4efe2"}
def blank(w,h): return [['.']*w for _ in range(h)]
def rect(g,x0,y0,x1,y1,c):
    for y in range(y0,y1):
        for x in range(x0,x1):
            if 0<=y<len(g) and 0<=x<len(g[0]): g[y][x]=c
def rows(g): return [''.join(r) for r in g]
P={}
# HAMMOCK 52x60: ropes from ceiling beam (y0) to a slung cloth
g=blank(52,60)
for y in range(0,46):
    g[y][2]='d'; g[y][49]='d'
    if y%4==0: g[y][2]='m'; g[y][49]='m'
for x in range(2,50):
    sag=int(8*(1-((x-26)/24)**2))
    for dy in range(0,5):
        y=44+sag+dy-4
        if 0<=y<60: g[y][x]='r' if dy<3 else 'd'
    y=44+sag-4
    if 0<=y<60: g[y][x]='t' if x%6<3 else 'r'
    g[min(59,44+sag+1)][x]='k'
P['hammock']=rows(g)
# LAMP 12x30: floor lamp, shade + warm glow
g=blank(12,30)
rect(g,1,0,11,7,'y'); rect(g,0,6,12,8,'m'); rect(g,2,0,10,1,'c')
for y in range(1,6): g[y][1]='m'; g[y][10]='m'
rect(g,5,8,7,27,'d'); rect(g,2,27,10,30,'k'); rect(g,3,27,9,28,'m')
P['lamp']=rows(g)
# RUG 56x5 seen edge-on on the floor, stripes
g=blank(56,5)
rect(g,0,0,56,5,'r')
for x in range(0,56,6): rect(g,x,1,x+3,4,'y')
rect(g,0,4,56,5,'d')
for x in (0,55):
    for y in range(5): g[y][x]='c'
P['rug']=rows(g)
# BOOKSHELF 26x44
g=blank(26,44)
rect(g,0,0,26,44,'d'); rect(g,2,2,24,42,'k')
cols='rbGyctWl'
import random; rnd=random.Random(3)
for shelf_y in (12,24,36):
    rect(g,1,shelf_y,25,shelf_y+2,'m')
    x=3
    while x<23:
        w=rnd.choice((2,2,3)); h=rnd.randint(7,9); c=rnd.choice(cols)
        rect(g,x,shelf_y-h,x+w,shelf_y,c); g[shelf_y-h][x]='t' if c not in 'tc' else 'W'
        x+=w+ (1 if rnd.random()<0.3 else 0)
rect(g,1,42,25,44,'m')
P['bookshelf']=rows(g)
# ARMCHAIR 24x22
g=blank(24,22)
rect(g,2,0,20,14,'g'); rect(g,4,2,18,12,'G')           # back
rect(g,0,8,5,20,'g'); rect(g,19,8,24,20,'g')           # arms
rect(g,1,8,4,10,'G'); rect(g,20,8,23,10,'G')
rect(g,4,12,20,18,'G'); rect(g,4,17,20,19,'g')          # seat
rect(g,2,19,4,22,'d'); rect(g,20,19,22,22,'d')          # legs
rect(g,9,4,15,8,'y'); g[5][11]='r'                      # cushion
P['armchair']=rows(g)
# PACKAGE 12x10
g=blank(12,10)
rect(g,0,0,12,10,'k'); rect(g,1,1,11,9,'l'); rect(g,1,1,11,3,'c')
rect(g,5,0,7,10,'y'); rect(g,0,4,12,5,'y')
P['package']=rows(g)
# MACAW 2 frames 20x16 (flying right-to-left, carrying nothing; package drawn separately)
def macaw(up):
    g=blank(20,16)
    body=[(8,6),(9,6),(10,6),(11,6),(7,7),(8,7),(9,7),(10,7),(11,7),(12,7),(7,8),(8,8),(9,8),(10,8),(11,8),(12,8),(13,8),(8,9),(9,9),(10,9),(11,9),(12,9),(13,9),(14,9)]
    for (x,y) in body: g[y][x]='r'
    # head facing left
    for (x,y) in [(4,5),(5,5),(6,5),(4,6),(5,6),(6,6),(7,6),(5,4),(6,4)]: g[y][x]='r'
    g[5][5]='t'; g[5][4]='k'                  # eye patch/eye
    g[6][3]='c'; g[7][3]='k'; g[6][2]='k'     # beak
    # tail long blue/yellow
    for i,(x,y) in enumerate([(14,10),(15,10),(16,11),(17,11),(18,12),(19,12)]): g[y][x]='b' if i%2==0 else 'y'
    # wing
    if up:
        for (x,y) in [(9,5),(10,4),(11,3),(12,2),(13,1),(10,5),(11,4),(12,3),(13,2),(14,1),(11,5),(12,4)]: g[y][x]='y' if y<3 else 'b'
    else:
        for (x,y) in [(9,10),(10,11),(11,12),(12,13),(13,14),(10,10),(11,11),(12,12),(13,13),(11,10),(12,11)]: g[y][x]='b' if y<12 else 'y'
    # feet
    g[10][9]='k'; g[10][11]='k'
    # outline
    out=[r[:] for r in g]
    for y in range(16):
        for x in range(20):
            if g[y][x]=='.':
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    X,Y=x+dx,y+dy
                    if 0<=X<20 and 0<=Y<16 and g[Y][X] not in '.k': out[y][x]='k'; break
    return rows(out)
P['macaw_0']=macaw(True); P['macaw_1']=macaw(False)
json.dump(P,open("props.json","w"))
# map tiles (16x16): ladder up, stairs down; item: crate
T={}
g=blank(16,16)
rect(g,0,0,16,16,'f')
for y in range(16): g[y][3]='l'; g[y][4]='m'; g[y][11]='l'; g[y][12]='m'
for y in (2,6,10,14): rect(g,5,y,11,y+1,'c'); rect(g,5,y+1,11,y+2,'m')
rect(g,0,0,16,1,'y'); 
T['ladder_up']=rows(g)
g=blank(16,16)
rect(g,0,0,16,16,'k')
for i,y in enumerate(range(1,16,3)):
    rect(g,i*2,y,16,y+3,'W' if i%2==0 else 'w'); rect(g,i*2,y,16,y+1,'t' if i==0 else 'W')
T['stairs_down']=rows(g)
g=blank(16,16)
rect(g,2,4,14,15,'k'); rect(g,3,5,13,14,'l'); rect(g,3,5,13,7,'c')
for x in (3,12): rect(g,x,5,x+1,14,'m')
rect(g,3,9,13,10,'m'); rect(g,7,5,9,14,'y')
rect(g,3,15,14,16,'k')
T['crate']=rows(g)
json.dump(T,open("tiles_new.json","w"))
# preview
def render(rws,s=4):
    h=len(rws); w=len(rws[0]); im=Image.new("RGBA",(w,h),(0,0,0,0))
    for y,r in enumerate(rws):
        for x,ch in enumerate(r):
            if PAL.get(ch):
                hx=PAL[ch].lstrip('#'); im.putpixel((x,y),tuple(int(hx[i:i+2],16) for i in (0,2,4))+(255,))
    return im.resize((w*s,h*s),Image.NEAREST)
sheet=Image.new("RGBA",(900,300),(61,56,80,255))
x=5
for k in ['hammock','lamp','rug','bookshelf','armchair','package','macaw_0','macaw_1']:
    im=render(P[k],3); sheet.paste(im,(x,5),im); x+=im.width+8
x=5
for k in ['ladder_up','stairs_down','crate']:
    im=render(T[k],5); sheet.paste(im,(x,200),im); x+=im.width+10
sheet.save("props_preview.png"); print("ok")
