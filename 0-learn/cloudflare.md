# Cloudflare

Cloudflare is a global cloud services provider that offers a range of performance and security solutions for websites and applications. In VibeStack, Cloudflare provides CDN, DNS management, and security features.

## Core Cloudflare Services for VibeStack

### Content Delivery Network (CDN)

Cloudflare's CDN caches content at edge locations worldwide, reducing latency and improving load times:

```javascript
// Example of using Cloudflare CDN URLs in Next.js
const imageLoader = ({ src, width, quality }) => {
  // Use Cloudflare's Image Resizing service
  return `https://cdn.yourvibestackapp.com/cdn-cgi/image/width=${width},quality=${quality || 75}/${src}`;
};

// In your Image component
import Image from 'next/image';

export function OptimizedImage(props) {
  return <Image {...props} loader={imageLoader} />;
}
```

Configuration best practices:
- Enable Brotli compression for better performance
- Configure appropriate cache TTLs based on content type
- Use Cache-Control headers to optimize caching
- Enable Auto Minify for HTML, CSS, and JavaScript

### DNS Management

Cloudflare provides authoritative DNS services with advanced features:

```bash
# Example DNS records for a VibeStack application
# A record for apex domain
example.com   A     192.0.2.1
# CNAME for www subdomain
www           CNAME example.com
# CNAME for API subdomain
api           CNAME yourvibestack.vercel.app
# MX records for email
@             MX    10 mail.protonmail.ch
@             MX    20 mailsec.protonmail.ch
# TXT for SPF
@             TXT   "v=spf1 include:_spf.protonmail.ch ~all"
# TXT for DKIM
protonmail._domainkey  TXT   "v=DKIM1; k=rsa; p=MIIBI..."
```

Key DNS features:
- **Proxy status** (orange cloud) for CDN and protection
- **DNS-only** (gray cloud) for services managed elsewhere
- **DNSSEC** for enhanced DNS security
- **CNAME Flattening** for apex domains

### Security Features

#### Web Application Firewall (WAF)

Protects against common web vulnerabilities and attacks:

```javascript
// Example of handling Cloudflare headers in a Next.js API route
export default function handler(req, res) {
  // Get Cloudflare-specific headers
  const cfCountry = req.headers['cf-ipcountry'];
  const cfRay = req.headers['cf-ray'];
  const cfConnectingIP = req.headers['cf-connecting-ip'];
  
  // Log or use these values for security decisions
  console.log(`Request from ${cfCountry} with ray ID ${cfRay}`);
  
  // Block requests from specific countries if needed
  if (cfCountry === 'XX') {
    return res.status(403).json({ error: 'Access denied from your region' });
  }
  
  // Continue with normal request handling
  res.status(200).json({ success: true });
}
```

WAF configuration options:
- **Managed Rulesets**: Pre-configured protection against OWASP Top 10
- **Custom Rules**: Create specific security rules using Cloudflare's expression language
- **Rate Limiting**: Prevent brute force and DDoS attacks
- **JS Challenge**: Challenge suspicious visitors with JavaScript challenges

#### DDoS Protection

Automatic protection against distributed denial-of-service attacks:

- **Layer 3/4 Protection**: Defends against network-level attacks
- **Layer 7 Protection**: Protects against application-layer attacks
- **Always Online**: Serves cached content even when origin is down
- **Under Attack Mode**: Enhanced protection during active attacks

### Cloudflare Workers

Serverless JavaScript execution at the edge:

```javascript
// Example Cloudflare Worker for API response modification
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  // Get the original response from your origin
  const originalResponse = await fetch(request);
  
  // Read the original body
  const originalBody = await originalResponse.json();
  
  // Modify the response
  const modified = {
    ...originalBody,
    // Add additional data
    processed_by: 'cloudflare_worker',
    region: request.cf.colo,
    timestamp: new Date().toISOString()
  };
  
  // Return modified response
  return new Response(JSON.stringify(modified), {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=60',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
```

Worker use cases:
- **A/B Testing**: Route traffic to different origins
- **Response Transformation**: Modify HTML, CSS, or JSON responses
- **Authentication**: Add auth logic at the edge
- **Geolocation**: Serve content based on user location
- **Edge API**: Create serverless API endpoints

### Cloudflare Pages

Jamstack platform for frontend deployment:

```yaml
# Example wrangler.toml configuration for Cloudflare Pages
name = "vibestack-app"
type = "javascript"
account_id = "your-account-id"
workers_dev = true
route = "app.vibestack.com/*"
zone_id = "your-zone-id"

[site]
bucket = ".next/static"
entry-point = "."

[build]
command = "npm run build"
upload.format = "service-worker"

[build.environment]
NODE_VERSION = "16"
```

Deployment workflow:
1. Connect GitHub/GitLab repository
2. Configure build settings
3. Deploy to Cloudflare's edge network
4. Set up custom domains and environment variables

### Cloudflare Access

Zero-trust access control for applications and resources:

```javascript
// Example middleware to validate Cloudflare Access JWT
import { NextResponse } from 'next/server';
import jwt from '@tsndr/cloudflare-worker-jwt';

export async function middleware(request) {
  // Get the JWT token from the CF-Access-JWT-Assertion header
  const token = request.headers.get('CF-Access-JWT-Assertion');
  
  if (!token) {
    return new NextResponse(
      JSON.stringify({ error: 'Authentication required' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    );
  }
  
  try {
    // Verify the token
    const { payload } = await jwt.decode(token);
    
    // Check if token is valid and has the right audience
    if (payload.aud !== 'your-application-audience') {
      throw new Error('Invalid token audience');
    }
    
    // Token is valid, proceed
    return NextResponse.next();
  } catch (error) {
    console.error('Access token validation failed:', error);
    return new NextResponse(
      JSON.stringify({ error: 'Invalid authentication token' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

export const config = {
  matcher: '/api/protected/:path*',
};
```

Access features:
- **Identity Provider Integration**: Connect with Google, GitHub, or your SSO
- **Access Policies**: Define who can access specific applications
- **Service Tokens**: For authenticated machine-to-machine communication
- **Zero Trust Network Access**: Secure private networks without VPN

## Cloudflare and Next.js Integration

### Environment Setup

```typescript
// types/environment.d.ts
namespace NodeJS {
  interface ProcessEnv {
    NEXT_PUBLIC_CLOUDFLARE_TURNSTILE_SITE_KEY: string;
    CLOUDFLARE_TURNSTILE_SECRET_KEY: string;
    CLOUDFLARE_ZONE_ID: string;
    CLOUDFLARE_API_TOKEN: string;
  }
}
```

### Image Optimization with Cloudflare Images

```typescript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    loader: 'custom',
    loaderFile: './lib/cloudflare-image-loader.js',
    // List domains that can serve images
    domains: ['cdn.yourvibestackapp.com'],
  },
  // Other Next.js configuration options
};

module.exports = nextConfig;
```

```typescript
// lib/cloudflare-image-loader.js
export default function cloudflareLoader({ src, width, quality }) {
  const params = [`width=${width}`];
  if (quality) {
    params.push(`quality=${quality}`);
  }
  return `https://cdn.yourvibestackapp.com/cdn-cgi/image/${params.join(',')}/${src}`;
}
```

### Turnstile (CAPTCHA Alternative)

```typescript
// components/TurnstileWidget.tsx
import { useEffect, useRef } from 'react';

interface TurnstileWidgetProps {
  onVerify: (token: string) => void;
  onError?: (error: Error) => void;
  siteKey?: string;
}

export function TurnstileWidget({
  onVerify,
  onError,
  siteKey = process.env.NEXT_PUBLIC_CLOUDFLARE_TURNSTILE_SITE_KEY
}: TurnstileWidgetProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const container = containerRef.current;
    if (!container || !siteKey) return;
    
    // Load Turnstile script if not already loaded
    if (!window.turnstile) {
      const script = document.createElement('script');
      script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
      script.async = true;
      script.defer = true;
      document.head.appendChild(script);
      
      script.onload = renderWidget;
      script.onerror = () => onError?.(new Error('Failed to load Turnstile'));
    } else {
      renderWidget();
    }
    
    function renderWidget() {
      if (!window.turnstile) return;
      
      window.turnstile.render(container, {
        sitekey: siteKey,
        callback: onVerify,
        'error-callback': () => onError?.(new Error('Turnstile verification failed')),
      });
    }
    
    return () => {
      // Cleanup if component unmounts
      if (window.turnstile) {
        window.turnstile.reset(container);
      }
    };
  }, [siteKey, onVerify, onError]);
  
  return <div ref={containerRef} />;
}

// Add to window type
declare global {
  interface Window {
    turnstile?: {
      render: (container: HTMLElement, options: any) => string;
      reset: (container: HTMLElement) => void;
    };
  }
}
```

Server-side validation:

```typescript
// pages/api/validate-turnstile.ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { token } = req.body;
  
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }
  
  try {
    // Validate token with Cloudflare
    const formData = new URLSearchParams();
    formData.append('secret', process.env.CLOUDFLARE_TURNSTILE_SECRET_KEY);
    formData.append('response', token);
    formData.append('remoteip', req.headers['x-forwarded-for'] as string || '');
    
    const result = await fetch(
      'https://challenges.cloudflare.com/turnstile/v0/siteverify',
      {
        method: 'POST',
        body: formData,
      }
    );
    
    const outcome = await result.json();
    
    if (outcome.success) {
      return res.status(200).json({ success: true });
    } else {
      return res.status(400).json({ 
        error: 'Verification failed', 
        errorCodes: outcome['error-codes'] 
      });
    }
  } catch (error) {
    console.error('Turnstile validation error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
```

## Performance Optimization with Cloudflare

### Cache Rules

Best practices for caching:

```typescript
// Example Next.js API route with cache headers
export default function handler(req, res) {
  // Process request
  const data = { /* your data */ };
  
  // Set cache headers
  res.setHeader('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=600');
  res.status(200).json(data);
}
```

Cache header strategies:
- **Static assets**: `Cache-Control: public, max-age=31536000, immutable`
- **API responses**: `Cache-Control: public, s-maxage=60, stale-while-revalidate=600`
- **HTML pages**: `Cache-Control: public, s-maxage=10, stale-while-revalidate=59`

### Argo Smart Routing

Optimizes traffic routing between Cloudflare edge and origin server:

Benefits:
- Reduces latency by ~30% on average
- Avoids network congestion automatically
- No configuration required, just enable in dashboard

### Cache Reserve

Global cache for large files and infrequently accessed content:

Use cases:
- Hosting large media files (videos, PDFs)
- Retaining rarely accessed historical content
- Improving cache hit ratio for global audience

## Security Best Practices

### SSL/TLS Configuration

Recommended settings:
- **TLS Version**: Minimum TLS 1.2, ideally TLS 1.3
- **Cipher Suites**: Modern, secure ciphers only
- **HSTS**: Enable with long max-age (1 year)
- **Certificate**: Use Cloudflare Origin CA certificate for origin

### Firewall Rules

Example rules for common scenarios:

1. **Block suspicious user agents**:
```
(http.user_agent contains "nikto" or http.user_agent contains "sqlmap")
```

2. **Rate limit API endpoints**:
```
(http.request.uri.path contains "/api/" and http.request.uri.path contains "/auth/")
```

3. **Country blocking for compliance**:
```
(ip.geoip.country in {"RU" "BY" "IR" "CU" "KP"})
```

4. **Block automated scan tools**:
```
(http.request.uri.path contains "/wp-login.php" or http.request.uri.path contains "/administrator/")
```

## Monitoring and Analytics

### Web Analytics

Cloudflare Web Analytics provides:
- **Page views and visitors**: Real-time and historical data
- **Performance metrics**: Core Web Vitals and more
- **Location data**: Geographic visitor distribution
- **Privacy-focused**: No cookies or tracking

Implementation:

```html
<!-- Add to your _document.js for Next.js -->
<script defer src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{"token": "your-token"}'></script>
```

### Workers Analytics

For custom edge analytics:

```javascript
// Example Worker for API analytics
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event));
});

async function handleRequest(event) {
  const request = event.request;
  const url = new URL(request.url);
  
  // Record analytics data
  const analyticsData = {
    path: url.pathname,
    method: request.method,
    country: request.cf.country,
    timezone: request.cf.timezone,
    clientTcpRtt: request.cf.clientTcpRtt,
    timestamp: Date.now()
  };
  
  // Clone the request for the fetch
  const requestClone = new Request(request);
  
  // Send analytics data to your backend (fire and forget)
  event.waitUntil(
    fetch('https://analytics-api.yourvibestackapp.com/collect', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(analyticsData)
    }).catch(err => console.error('Analytics error:', err))
  );
  
  // Continue with the original request
  return fetch(requestClone);
}
```

## Cost Management

### Bandwidth Usage Optimization

Strategies to reduce bandwidth costs:
- Enable Brotli compression
- Use appropriate image formats (WebP, AVIF)
- Implement lazy loading for images and videos
- Set correct Cache-Control headers
- Use Cloudflare Image Resizing for responsive images

### Plan Selection Guide

| Feature | Free | Pro | Business | Enterprise |
|---------|------|-----|----------|------------|
| CDN/DNS | ✓ | ✓ | ✓ | ✓ |
| DDoS Protection | Limited | Advanced | Advanced | Custom |
| Page Rules | 3 | 20 | 50 | Custom |
| Workers | 100K req/day | 10M req/month | 50M req/month | Custom |
| WAF | Basic | Standard | Advanced | Custom |
| Analytics | Basic | Extended | Full | Custom |
| Support | Community | 24/7 Email | 24/7 Phone/Email | Dedicated |

Recommendation for VibeStack:
- **Startup**: Pro plan
- **Growth stage**: Business plan
- **Enterprise**: Enterprise plan with custom contract

## Resources

- [Cloudflare Developer Documentation](https://developers.cloudflare.com/)
- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Cloudflare API Documentation](https://api.cloudflare.com/)
- [Cloudflare Community](https://community.cloudflare.com/)
- [Cloudflare Status Page](https://www.cloudflarestatus.com/)
