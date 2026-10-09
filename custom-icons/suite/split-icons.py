from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parent
APPS = ['photocraft', 'lightcraft', 'filmcraft', 'pdfcraft', 'vectorcraft',
        'effectcraft', 'designcraft', 'wordcraft', 'cadcraft', 'gridcraft',
        'soundcraft', 'deckcraft', 'artcraft', 'artcraftx']
source = Image.open(ROOT / 'craft-icons-sheet.png').convert('RGBA')
alpha = source.getchannel('A')

def runs(values):
    out, start = [], None
    for i, occupied in enumerate(values + [False]):
        if occupied and start is None:
            start = i
        elif not occupied and start is not None:
            if i - start > 100:
                out.append((start, i))
            start = None
    return out

columns = runs([sum(a > 128 for a in alpha.crop((x, 0, x+1, source.height)).getdata()) > 150
                for x in range(source.width)])
rows = runs([sum(a > 128 for a in alpha.crop((0, y, source.width, y+1)).getdata()) > 150
             for y in range(source.height)])
if len(columns) != 4 or len(rows) != 4:
    raise ValueError(f'Expected 4x4 atlas, got {columns=} {rows=}')
manifest = []
for i, app in enumerate(APPS):
    x0, x1 = columns[i % 4]
    y0, y1 = rows[i // 4]
    box = (max(0, x0-2), max(0, y0-2), min(source.width, x1+2), min(source.height, y1+2))
    tile = source.crop(box)
    tile.thumbnail((464, 464), Image.Resampling.LANCZOS)
    icon = Image.new('RGBA', (512, 512))
    icon.alpha_composite(tile, ((512-tile.width)//2, (512-tile.height)//2))
    icon.save(ROOT / f'{app}.png')
    icon.save(ROOT / f'{app}.ico', sizes=[(n,n) for n in (16,24,32,48,64,128,256)])
    with Image.open(ROOT / f'{app}.ico') as check:
        assert check.ico.sizes() == {(n,n) for n in (16,24,32,48,64,128,256)}
    manifest.append({'app': app, 'crop': box, 'png': f'{app}.png', 'ico': f'{app}.ico'})
(ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(f'Extracted and verified {len(manifest)} PNG/ICO pairs.')
