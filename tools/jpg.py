import sys
data = open(sys.argv[1],'rb').read(); out=sys.argv[2]
bounds=[513786,560697,587142,615926]
for i in range(3):
    seg=data[bounds[i]:bounds[i+1]]
    end=seg.rfind(b'\xff\xd9')+2
    open(f'{out}/jpg_{bounds[i]}.jpg','wb').write(seg[:end]); print(bounds[i], end, len(seg)-end)
