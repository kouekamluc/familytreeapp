"""Bundle and verify font variants referenced by the installed google_fonts package."""
import concurrent.futures
import argparse
import hashlib
from pathlib import Path
import re
import urllib.request

root = Path(__file__).resolve().parent.parent
package = Path.home() / 'AppData/Local/Pub/Cache/hosted/pub.dev/google_fonts-6.3.3/lib/src/google_fonts_parts'
output = root / 'flutter_frontend/assets/fonts'
output.mkdir(exist_ok=True)
weights = {100:'Thin',200:'ExtraLight',300:'Light',400:'Regular',500:'Medium',600:'SemiBold',700:'Bold',800:'ExtraBold',900:'Black'}
jobs = []
families = [('cinzel','Cinzel','c'),('inter','Inter','i'),('jetBrainsMono','JetBrainsMono','j'),('nunito','Nunito','n')]
parser = argparse.ArgumentParser()
parser.add_argument('--family', choices=[entry[0] for entry in families])
selected = parser.parse_args().family
for method, family, part in families:
    if selected and method != selected: continue
    text = (package / f'part_{part}.g.dart').read_text()
    start = text.index(f'static TextStyle {method}(')
    section = text[start:text.index('return googleFontsTextStyle(', start)]
    for weight, style, digest, size in re.findall(r"fontWeight: FontWeight.w(\d+),\s*fontStyle: FontStyle.(\w+),\s*\): GoogleFontsFile\(\s*'([a-f0-9]+)',\s*(\d+)", section):
        suffix = weights[int(weight)]
        if style == 'italic': suffix = 'Italic' if suffix == 'Regular' else suffix+'Italic'
        jobs.append((family+'-'+suffix+'.ttf', digest, int(size)))
def fetch(job):
    name,digest,size=job
    data=urllib.request.urlopen(f'https://fonts.gstatic.com/s/a/{digest}.ttf', timeout=30).read()
    if len(data)!=size or hashlib.sha256(data).hexdigest()!=digest: raise ValueError('Font checksum mismatch')
    (output/name).write_bytes(data)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    list(pool.map(fetch,jobs))
for family,directory in [('Cinzel','cinzel'),('Inter','inter'),('JetBrainsMono','jetbrainsmono'),('Nunito','nunito')]:
    if selected and directory.lower() != selected.lower(): continue
    data=urllib.request.urlopen(f'https://raw.githubusercontent.com/google/fonts/main/ofl/{directory}/OFL.txt',timeout=30).read()
    (output/(family+'-OFL.txt')).write_bytes(data)
print(f'Bundled {len(jobs)} verified font variants and licenses.')
