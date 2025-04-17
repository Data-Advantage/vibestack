# DNS (Domain Name System)

The Domain Name System (DNS) is a critical internet infrastructure component that translates human-friendly domain names (like example.com) into IP addresses that computers use to identify each other. Understanding DNS is essential for deploying and managing VibeStack applications.

## Introduction to DNS

DNS functions as the internet's phone book, providing several essential services:

- **Name Resolution**: Translates domain names to IP addresses
- **Load Distribution**: Distributes traffic across multiple servers
- **Service Location**: Identifies mail servers, API endpoints, etc.
- **Domain Management**: Handles domain ownership and delegation

## Key DNS Concepts

### DNS Records

DNS records are instructions that live in authoritative DNS servers and provide information about a domain:

| Record Type | Purpose | Example |
|-------------|---------|---------|
| A | Maps domain to IPv4 address | `example.com. 3600 IN A 192.0.2.1` |
| AAAA | Maps domain to IPv6 address | `example.com. 3600 IN AAAA 2001:db8::1` |
| CNAME | Creates domain alias | `www.example.com. 3600 IN CNAME example.com.` |
| MX | Specifies mail servers | `example.com. 3600 IN MX 10 mail.example.com.` |
| TXT | Stores text information | `example.com. 3600 IN TXT "v=spf1 include:_spf.example.com -all"` |
| NS | Defines authoritative nameservers | `example.com. 3600 IN NS ns1.exampledns.com.` |
| SOA | Start of Authority (domain info) | `example.com. 3600 IN SOA ns1.example.com. admin.example.com. (2022010101 7200 1800 1209600 86400)` |
| CAA | Certificate Authority Authorization | `example.com. 3600 IN CAA 0 issue "letsencrypt.org"` |

### DNS Propagation

When you make changes to DNS records, these changes take time to propagate across the internet. This period, known as DNS propagation time, can range from minutes to 48 hours, though typically it's resolved within a few hours.

### TTL (Time to Live)

TTL specifies how long (in seconds) DNS resolvers should cache a record before requesting an update:

- **High TTL** (e.g., 86400 seconds/1 day): Reduces DNS server load but slows down propagation
- **Low TTL** (e.g., 300 seconds/5 minutes): Speeds up propagation but increases server load
- **TTL Strategy**: Lower TTL before planned DNS changes, then increase after changes propagate

## DNS Setup for VibeStack

### Using Vercel DNS

Vercel provides DNS management for domains:

1. Add your domain in the Vercel dashboard
2. Configure nameservers at your registrar to point to Vercel:
   ```
   ns1.vercel-dns.com
   ns2.vercel-dns.com
   ```
3. Manage DNS records through the Vercel dashboard

### Using Cloudflare DNS (Recommended)

Cloudflare offers enhanced DNS with security benefits:

1. Add your domain to Cloudflare
2. Update nameservers at your registrar to Cloudflare's nameservers
3. Configure DNS records in Cloudflare dashboard
4. For Vercel deployment, use a CNAME record:
   ```
   Type: CNAME
   Name: www
   Target: cname.vercel-dns.com
   Proxy status: Proxied
   ```
5. For apex domains (example.com), use:
   ```
   Type: A
   Name: @
   Target: 76.76.21.21 (Vercel's global IP)
   Proxy status: Proxied
   ```

### Using Other DNS Providers

With other DNS providers:

1. Create an A record pointing to Vercel's IP (76.76.21.21)
2. Create CNAME records for subdomains pointing to `cname.vercel-dns.com`
3. Set up proper CAA records if using SSL certificates

## Common DNS Configurations

### Subdomain Setup

```
# Main site
Type: A
Name: @
Value: 76.76.21.21

# www subdomain
Type: CNAME
Name: www
Value: cname.vercel-dns.com

# API subdomain
Type: CNAME
Name: api
Value: cname.vercel-dns.com

# App subdomain
Type: CNAME
Name: app
Value: cname.vercel-dns.com
```

### Email Configuration

```
# Mail server
Type: MX
Name: @
Priority: 10
Value: mail.provider.com

# SPF record (helps prevent email spoofing)
Type: TXT
Name: @
Value: v=spf1 include:_spf.provider.com -all

# DKIM record (email authentication)
Type: TXT
Name: provider._domainkey
Value: v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA...

# DMARC record (email authentication policy)
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com
```

### SSL/TLS Verification

```
# Domain verification
Type: TXT
Name: @
Value: vercel-verification=abc123

# Let's Encrypt verification
Type: TXT
Name: _acme-challenge
Value: provided-challenge-string

# Certificate Authority Authorization
Type: CAA
Name: @
Value: 0 issue "letsencrypt.org"
```

## Subdomain Strategies

When building a multi-part VibeStack application, consider these subdomain strategies:

| Strategy | Example | Use Case |
|----------|---------|----------|
| Marketing site on root | example.com | Main marketing website |
| App on subdomain | app.example.com | Main application |
| API on subdomain | api.example.com | Backend API endpoints |
| Documentation | docs.example.com | Developer documentation |
| Customer portals | [customer].example.com | Customer-specific portals |

## DNS Troubleshooting

### Common DNS Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Incorrect A/CNAME records | Website unreachable | Verify record values and update if needed |
| DNS propagation delay | Changes not visible everywhere | Wait for propagation, temporarily lower TTL |
| Nameserver misconfiguration | Inconsistent DNS resolution | Verify nameserver settings at registrar |
| SSL/TLS validation failure | Certificate errors | Check DNS verification records |
| CAA record conflicts | Certificate issuance failures | Review CAA records for permitted CAs |

### DNS Checking Tools

- **dig**: Command-line tool for querying DNS servers
  ```bash
  dig example.com A +short
  dig www.example.com CNAME +short
  ```

- **nslookup**: Alternative to dig
  ```bash
  nslookup example.com
  nslookup -type=MX example.com
  ```

- **Online Tools**:
  - [DNS Checker](https://dnschecker.org/)
  - [MxToolbox](https://mxtoolbox.com/)
  - [Cloudflare DNS Tracer](https://www.cloudflare.com/dns-tracer/)

## DNS Security

### DNSSEC (DNS Security Extensions)

DNSSEC adds cryptographic signatures to DNS records, helping prevent DNS spoofing and cache poisoning attacks:

1. Enable DNSSEC at your DNS provider
2. Add DS (Delegation Signer) records at your domain registrar
3. Verify DNSSEC is working with online tools

### DNS Privacy

- Consider using DNS over HTTPS (DoH) or DNS over TLS (DoT)
- Use privacy-focused DNS resolvers for development

## Resources

- [DNS & CNAME Configuration Guide](https://vercel.com/docs/concepts/projects/custom-domains)
- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/)
- [DNS Best Practices](https://www.cloudflare.com/learning/dns/dns-security/)
- [Mozilla DNS Documentation](https://developer.mozilla.org/en-US/docs/Web/API/DNS)
- [ICANN Learn DNS](https://www.icann.org/resources/pages/dns-basics-2014-01-02-en)
