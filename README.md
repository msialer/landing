# Mauricio Sialer — Professional Landing Page

Single-page landing page for Mauricio Sialer, Head of Digital Commerce and P&L Owner.

## URLs

- **Canonical:** https://mauricio.sialer.com
- **Short:** https://m.sialer.com
- **Vercel project:** https://vercel.com/msialer/landing

## Stack

- Single `index.html` file.
- Tailwind CSS via CDN.
- Google Fonts: Playfair Display + Inter.
- Designed with [Kimi Websites](https://www.kimi.com/features/websites).
- Hosted on Vercel free tier with custom domain.

## Local preview

Open `index.html` in any modern browser, or serve locally:

```bash
python3 -m http.server 8080
# open http://localhost:8080
```

## Deploy

Vercel deploys automatically on every push to `main` (GitHub integration).

To deploy manually from the VM:

```bash
cd /home/ubuntu/projects/landing
npx vercel@latest --prod --token=$(cat /home/ubuntu/.config/landing/vercel-token) --yes
```

The Vercel token is stored at `/home/ubuntu/.config/landing/vercel-token`.

## Update the headshot photo

The hero image is `mauricio-sialer.jpg` (square, 1000×1000 px recommended).

If the new photo is in Google Drive:

1. Get the Drive file ID from the share link (`id=...` or `/open?id=...`).
2. Download it with rclone using the existing `gdrive` remote:

```bash
FILE_ID="1_mGny-CD6GqE8TwVmdJY_nSGnb3SkeIF"
rclone backend copyid gdrive:"$FILE_ID" /tmp/
```

3. Convert to optimized JPEG (if needed) and replace the current image:

```bash
python3 - <<'PY'
from PIL import Image
import os

src = '/tmp/<downloaded-file>.png'  # adjust filename
# or src = '/tmp/<downloaded-file>.jpg'
dst = '/home/ubuntu/projects/landing/mauricio-sialer.jpg'

img = Image.open(src)
if img.mode in ('RGBA', 'P'):
    bg = Image.new('RGB', img.size, (255, 255, 255))
    if img.mode == 'P':
        img = img.convert('RGBA')
    bg.paste(img, mask=img.split()[3])
    img = bg
else:
    img = img.convert('RGB')

img.save(dst, 'JPEG', quality=90, optimize=True)
print(f'Saved {dst}: {os.path.getsize(dst)} bytes, size {img.size}')
PY
```

4. Commit, push and deploy:

```bash
git add mauricio-sialer.jpg
git commit -m "assets(hero): update headshot photo"
git push origin main
npx vercel@latest --prod --token=$(cat /home/ubuntu/.config/landing/vercel-token) --yes
```

## Debug layout / scroll overflow

Use Puppeteer + headless Chrome to measure the exact document height and detect extra whitespace below the footer.

Install Puppeteer in a temp directory (no project dependency needed):

```bash
mkdir -p /tmp/puppeteer-test
cd /tmp/puppeteer-test
npm init -y
npm install puppeteer --no-save
```

Serve the landing locally and measure:

```javascript
const puppeteer = require('puppeteer');
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = '/home/ubuntu/projects/landing';
const PORT = 8765;

const server = http.createServer((req, res) => {
  const filePath = path.join(ROOT, req.url === '/' ? 'index.html' : req.url);
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200);
    res.end(data);
  });
});

server.listen(PORT, async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    executablePath: '/usr/bin/chromium-browser',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0' });
  await new Promise(r => setTimeout(r, 1000));

  const dims = await page.evaluate(() => {
    const html = document.documentElement;
    const footer = document.querySelector('footer');
    const rect = footer.getBoundingClientRect();
    return {
      scrollHeight: html.scrollHeight,
      clientHeight: html.clientHeight,
      footerBottom: rect.bottom + window.scrollY,
      gapBelowFooter: html.scrollHeight - (rect.bottom + window.scrollY),
    };
  });
  console.log(dims);

  await browser.close();
  server.close();
});
```

A `gapBelowFooter` close to `0` means the page ends exactly at the footer.

## CV sync

The latest CV is synced daily from Google Drive via a systemd timer running on the Personal Server. See `scripts/sync-cv.sh` and `systemd/cv-sync.*` in the Personal Server repo.
