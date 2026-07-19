# Mauricio Sialer — Professional Landing Page

Single-page landing page for Mauricio Sialer, Head of Digital Commerce and P&L Owner.

## URLs

- **Canonical:** https://mauricio.sialer.com
- **Short:** https://m.sialer.com
- **Vercel preview:** https://landing-97vedd0ut-msialer.vercel.app

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

Vercel deploys automatically on every push to `main`.

To deploy manually:

```bash
npm i -g vercel
vercel --prod
```

## CV sync

The latest CV is synced daily from Google Drive via a systemd timer running on the Personal Server. See `scripts/sync-cv.sh` and `systemd/cv-sync.*` in the Personal Server repo.
