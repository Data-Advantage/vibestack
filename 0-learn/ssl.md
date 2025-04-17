# SSL (Secure Sockets Layer)

SSL and its successor TLS (Transport Layer Security) are cryptographic protocols designed to provide secure communication over a computer network. For VibeStack applications, implementing proper SSL/TLS is essential for security and user trust.

## Introduction to SSL/TLS

SSL/TLS protocols serve several critical functions:

- **Data Encryption**: Encrypts data transmitted between clients and servers
- **Data Integrity**: Ensures data is not altered during transmission
- **Authentication**: Verifies the identity of communicating parties
- **Trust Signals**: Shows users your site takes security seriously (padlock icon)

> **Note**: While "SSL" is still commonly used, modern websites actually use TLS protocols, as SSL 3.0 was deprecated in 2015 due to security vulnerabilities. However, "SSL" remains the more recognizable term.

## SSL Certificates

An SSL certificate is a digital document that:

- Contains the website's public key
- Confirms the identity of the website
- Is issued by a trusted Certificate Authority (CA)
- Enables HTTPS connections to your website

### Types of SSL Certificates

| Type | Description | Use Case in VibeStack |
|------|-------------|------------------------|
| Domain Validated (DV) | Basic verification of domain ownership | Development environments |
| Organization Validated (OV) | Verifies organization details | Standard production sites |
| Extended Validation (EV) | Rigorous verification of business identity | High-security applications |
| Wildcard | Covers main domain and all subdomains | Multi-tenant applications |
| Multi-Domain (SAN) | Covers multiple specified domains | Applications with multiple domains |

## SSL Implementation in VibeStack

### With Vercel (Recommended)

Vercel automatically provisions and renews SSL certificates for all domains connected to your VibeStack project:

1. Add your custom domain in the Vercel dashboard
2. Verify domain ownership (usually through DNS configuration)
3. Vercel provisions an SSL certificate through Let's Encrypt
4. HTTPS is automatically enabled for your domain

### With Cloudflare

If using Cloudflare for DNS and security:

1. Add your domain to Cloudflare and point nameservers
2. Set SSL/TLS encryption mode (typically "Full" or "Full (strict)")
3. Cloudflare provides SSL between visitors and Cloudflare
4. Ensure secure connection between Cloudflare and Vercel

### Manual Certificate Handling

For applications not hosted on platforms with automatic SSL:

1. Generate a Certificate Signing Request (CSR)
2. Obtain a certificate from a Certificate Authority
3. Install the certificate on your web server
4. Configure the web server to use HTTPS
5. Set up automatic renewal (certificates typically expire in 90 days to 1 year)

## Next.js Security Headers

For a VibeStack application, implementing security headers in `next.config.js` enhances your SSL implementation:

```javascript
// next.config.js
const nextConfig = {
  // Other configuration...
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()'
          }
        ]
      }
    ];
  }
};

module.exports = nextConfig;
```

## HTTPS in Local Development

Setting up HTTPS for local development:

### Using mkcert

```bash
# Install mkcert
npm install -g mkcert

# Create a local certificate authority
mkcert -install

# Generate certificates for localhost
mkcert localhost 127.0.0.1 ::1

# Configure Next.js to use the certificates
# (create a custom server.js or use next-https)
```

### Using next-https package

```bash
# Install next-https
npm install next-https

# Update your package.json scripts
"scripts": {
  "dev": "next-https dev",
  "build": "next build",
  "start": "next-https start"
}
```

## Common SSL Issues and Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Mixed Content | Console warnings, broken resources | Ensure all resources use HTTPS URLs |
| Certificate Expired | Browser security warnings | Renew certificate or fix automatic renewal |
| Invalid Certificate | "Your connection is not private" error | Ensure certificate matches domain name |
| Self-Signed Certificate | Security warnings | Use only for development, not production |
| Cipher Suite Issues | Connection failures for some clients | Configure server to support modern cipher suites |

## Best Practices

1. **Always Force HTTPS**: Redirect HTTP to HTTPS
   ```typescript
   // middleware.ts
   import { NextResponse } from 'next/server';
   import type { NextRequest } from 'next/server';
   
   export function middleware(request: NextRequest) {
     if (process.env.NODE_ENV === 'production' && !request.nextUrl.protocol.includes('https')) {
       return NextResponse.redirect(
         `https://${request.nextUrl.host}${request.nextUrl.pathname}${request.nextUrl.search}`,
         301
       );
     }
     return NextResponse.next();
   }
   ```

2. **Implement HSTS**: Use Strict-Transport-Security header (as shown in the headers configuration)

3. **Update Regularly**: Keep certificates current and implement automatic renewal

4. **Use Strong Ciphers**: Configure servers to use modern, secure cipher suites

5. **Use Content Security Policy**: Restrict which resources can be loaded
   ```html
   <!-- Add to _document.js or via headers() in next.config.js -->
   <meta
     httpEquiv="Content-Security-Policy"
     content="default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://analytics.example.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://cdn.example.com"
   />
   ```

6. **Test SSL Configuration**: Regularly check your SSL setup with tools like SSL Labs

## Resources

- [SSL Labs Test](https://www.ssllabs.com/ssltest/)
- [Let's Encrypt](https://letsencrypt.org/) - Free certificate authority
- [OWASP TLS Guide](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Cloudflare SSL Documentation](https://developers.cloudflare.com/ssl/)
- [Vercel Custom Domains](https://vercel.com/docs/concepts/projects/domains)
