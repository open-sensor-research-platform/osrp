# DNS Setup for osrp.io

## Overview

The landing page is now deployed to GitHub Pages and configured to use the custom domain **osrp.io**.

**Current Status**: ✅ GitHub Pages enabled, awaiting DNS configuration

## DNS Configuration Required

You need to add the following DNS records at your domain registrar (where you purchased osrp.io):

### A Records (for apex domain: osrp.io)

Add **all four** A records pointing to GitHub's servers:

```
Type: A
Name: @
Value: 185.199.108.153
TTL: 3600 (or automatic)

Type: A
Name: @
Value: 185.199.109.153
TTL: 3600

Type: A
Name: @
Value: 185.199.110.153
TTL: 3600

Type: A
Name: @
Value: 185.199.111.153
TTL: 3600
```

### CNAME Record (for www subdomain)

```
Type: CNAME
Name: www
Value: open-sensor-research-platform.github.io.
TTL: 3600
```

**Note**: The trailing dot (.) in the CNAME value is important!

## Step-by-Step Instructions

### 1. Log into Your Domain Registrar

Go to the website where you purchased osrp.io and log in.

### 2. Find DNS Management

Look for sections like:
- "DNS Management"
- "DNS Settings"
- "Name Servers"
- "Advanced DNS"

### 3. Add the Records

1. **Add A Records**:
   - Click "Add Record" or similar
   - Type: A
   - Host/Name: @ (or leave blank for apex domain)
   - Value/Points to: 185.199.108.153
   - Save
   - Repeat for the other 3 IP addresses

2. **Add CNAME Record**:
   - Click "Add Record"
   - Type: CNAME
   - Host/Name: www
   - Value: open-sensor-research-platform.github.io.
   - Save

### 4. Wait for DNS Propagation

- DNS changes can take 24-48 hours to propagate globally
- Usually takes 1-4 hours for most regions
- You can check status using:
  ```bash
  dig osrp.io +short
  dig www.osrp.io +short
  ```

### 5. Enable HTTPS (After DNS Propagates)

Once DNS is working:

1. Go to GitHub repository settings: https://github.com/open-sensor-research-platform/osrp/settings/pages
2. Check "Enforce HTTPS"
3. GitHub will automatically issue an SSL certificate (takes up to 24 hours)

## Verification Commands

Check if DNS is configured correctly:

```bash
# Check A records (should show 4 GitHub IPs)
dig osrp.io +short

# Check CNAME (should show open-sensor-research-platform.github.io)
dig www.osrp.io +short

# Check from Google's DNS
dig @8.8.8.8 osrp.io

# Full DNS lookup
nslookup osrp.io

# Check SSL certificate (after HTTPS enabled)
openssl s_client -connect osrp.io:443 -servername osrp.io < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

## Common Domain Registrars

### Namecheap
1. Log in → Domain List → Manage
2. Advanced DNS tab
3. Add records as specified above

### GoDaddy
1. Log in → My Products → Domains
2. Click DNS next to your domain
3. Add records in the "Records" section

### Google Domains
1. Log in → My domains
2. Click DNS
3. Add custom records

### Cloudflare
1. Log in → Select domain
2. DNS tab
3. Add records (turn off proxy for testing)

## Troubleshooting

### DNS Not Resolving

**Problem**: `dig osrp.io` returns nothing or wrong IP

**Solutions**:
- Wait longer (DNS can take 24-48 hours)
- Double-check record values (especially trailing dots)
- Ensure Name/Host is "@" or blank for A records
- Contact domain registrar support

### www Not Working

**Problem**: www.osrp.io doesn't resolve

**Solutions**:
- Verify CNAME record is correct
- Ensure value ends with a dot: `open-sensor-research-platform.github.io.`
- Wait for DNS propagation

### SSL Certificate Not Issued

**Problem**: Site shows "Not Secure" or certificate error

**Solutions**:
- Ensure DNS is fully propagated first
- Wait up to 24 hours after DNS propagates
- In GitHub Settings > Pages:
  - Remove custom domain
  - Wait 1 minute
  - Re-add custom domain
  - Check "Enforce HTTPS"

### Site Shows 404

**Problem**: osrp.io shows GitHub 404 page

**Solutions**:
- Verify CNAME file exists in docs/ folder
- Check GitHub Pages is enabled in repo settings
- Ensure source is set to "main branch /docs folder"
- Wait a few minutes for GitHub to rebuild

## Current Configuration

✅ **GitHub Pages**: Enabled
✅ **Source**: main branch, /docs folder
✅ **CNAME File**: docs/CNAME contains "osrp.io"
✅ **Landing Page**: docs/index.html deployed
⏳ **DNS**: Awaiting configuration at domain registrar
⏳ **HTTPS**: Will be enabled after DNS propagates

## Expected Timeline

| Step | Status | Time |
|------|--------|------|
| GitHub Pages enabled | ✅ Complete | Done |
| Landing page deployed | ✅ Complete | Done |
| Configure DNS | ⏳ Pending | You do this now |
| DNS propagation | ⏳ Pending | 1-48 hours |
| SSL certificate issued | ⏳ Pending | 1-24 hours after DNS |
| Site live at osrp.io | ⏳ Pending | After SSL enabled |

## Next Steps

1. **Configure DNS** at your domain registrar (add records above)
2. **Wait** for DNS to propagate (check with `dig osrp.io`)
3. **Enable HTTPS** in GitHub Settings > Pages
4. **Verify** site is live at https://osrp.io

## Testing While DNS Propagates

You can preview the site at:
- https://open-sensor-research-platform.github.io/osrp/

This is the GitHub Pages default URL and works immediately.

## Questions?

- [GitHub Pages Documentation](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [DNS Checker Tool](https://dnschecker.org)
- GitHub Repository: https://github.com/open-sensor-research-platform/osrp/settings/pages

---

**Last Updated**: January 15, 2026
**Status**: Awaiting DNS configuration
