# OSRP Documentation Site

This directory contains the landing page for osrp.io hosted on GitHub Pages.

## Files

- `index.html` - Main landing page
- `styles.css` - Styling for the landing page
- `CNAME` - Custom domain configuration for osrp.io

## Local Development

To preview the landing page locally:

```bash
# Option 1: Using Python
cd docs
python -m http.server 8000

# Option 2: Using Node.js
npx http-server docs -p 8000

# Then visit: http://localhost:8000
```

## Deployment

The site is automatically deployed to GitHub Pages from the `docs/` directory.

### GitHub Pages Configuration

1. Go to repository Settings > Pages
2. Set Source to "Deploy from a branch"
3. Select branch: `main`
4. Select folder: `/docs`
5. Save

### Custom Domain (osrp.io)

The `CNAME` file configures the custom domain. To complete the setup:

1. **Add DNS Records** (at your domain registrar):
   ```
   Type: A
   Name: @
   Value: 185.199.108.153

   Type: A
   Name: @
   Value: 185.199.109.153

   Type: A
   Name: @
   Value: 185.199.110.153

   Type: A
   Name: @
   Value: 185.199.111.153

   Type: CNAME
   Name: www
   Value: open-sensor-research-platform.github.io
   ```

2. **Verify Domain** in GitHub:
   - Go to Settings > Pages
   - Add custom domain: `osrp.io`
   - GitHub will verify DNS configuration

3. **Enable HTTPS**:
   - Check "Enforce HTTPS" in Settings > Pages
   - Wait for SSL certificate to be issued (up to 24 hours)

### DNS Propagation

After adding DNS records, it may take 24-48 hours for DNS to propagate globally.

Check DNS status:
```bash
# Check A records
dig osrp.io +short

# Check CNAME
dig www.osrp.io +short

# Check from specific DNS server
dig @8.8.8.8 osrp.io
```

## Site Structure

```
docs/
├── index.html          # Landing page
├── styles.css          # Stylesheet
├── CNAME              # Custom domain
└── README.md          # This file
```

## Making Updates

1. Edit `index.html` or `styles.css`
2. Commit and push to main branch
3. GitHub Pages will automatically rebuild (takes 1-2 minutes)
4. Changes live at osrp.io

## Troubleshooting

### Custom domain not working
- Verify DNS records are correct
- Wait for DNS propagation (24-48 hours)
- Check GitHub Pages settings
- Ensure CNAME file contains `osrp.io`

### Site not updating
- Check Actions tab for build status
- Clear browser cache
- Wait 2-3 minutes for GitHub Pages to rebuild

### SSL certificate issues
- Ensure DNS is properly configured
- Wait up to 24 hours for certificate issuance
- Remove and re-add custom domain if needed

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Custom Domain Setup](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [DNS Configuration Guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
