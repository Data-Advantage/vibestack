# Sitemaps in VibeStack

A sitemap is a file that provides information about the pages, videos, and other files on your website, and the relationships between them. In VibeStack, sitemaps are crucial for helping search engines discover and crawl your website efficiently, which can improve your SEO performance.

## Why Sitemaps Matter

Sitemaps serve several important purposes:

- **Improved Discoverability**: Help search engines find all the important pages on your site
- **Better Indexing**: Provide metadata that helps search engines index your content properly
- **Faster Discovery**: Speed up the discovery of new or updated content
- **Enhanced SEO**: Support your overall search engine optimization strategy
- **User Navigation**: Can also be used to help users navigate complex websites

## Types of Sitemaps

### XML Sitemaps

The most common format, used primarily for search engines:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://yourvibestackapp.com/</loc>
    <lastmod>2023-09-10</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://yourvibestackapp.com/features</loc>
    <lastmod>2023-09-05</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://yourvibestackapp.com/pricing</loc>
    <lastmod>2023-09-01</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
</urlset>
```

### Sitemap Index

For large sites with multiple sitemaps:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap>
    <loc>https://yourvibestackapp.com/sitemap-pages.xml</loc>
    <lastmod>2023-09-10</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://yourvibestackapp.com/sitemap-products.xml</loc>
    <lastmod>2023-09-08</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://yourvibestackapp.com/sitemap-blog.xml</loc>
    <lastmod>2023-09-12</lastmod>
  </sitemap>
</sitemapindex>
```

### HTML Sitemaps

Human-readable sitemaps designed for website visitors:

```html
<div class="sitemap">
  <h2>Site Navigation</h2>
  <ul>
    <li><a href="/">Home</a></li>
    <li>
      <a href="/products">Products</a>
      <ul>
        <li><a href="/products/feature1">Feature 1</a></li>
        <li><a href="/products/feature2">Feature 2</a></li>
      </ul>
    </li>
    <li><a href="/pricing">Pricing</a></li>
    <li><a href="/blog">Blog</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</div>
```

### Image Sitemaps

Specifically for image content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
  <url>
    <loc>https://yourvibestackapp.com/gallery</loc>
    <image:image>
      <image:loc>https://yourvibestackapp.com/images/sample1.jpg</image:loc>
      <image:title>Sample Image 1</image:title>
      <image:caption>This is a caption for sample image 1</image:caption>
    </image:image>
    <image:image>
      <image:loc>https://yourvibestackapp.com/images/sample2.jpg</image:loc>
      <image:title>Sample Image 2</image:title>
      <image:caption>This is a caption for sample image 2</image:caption>
    </image:image>
  </url>
</urlset>
```

### Video Sitemaps

For websites featuring video content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">
  <url>
    <loc>https://yourvibestackapp.com/videos/tutorial</loc>
    <video:video>
      <video:thumbnail_loc>https://yourvibestackapp.com/thumbnails/tutorial.jpg</video:thumbnail_loc>
      <video:title>Getting Started with VibeStack</video:title>
      <video:description>A beginner's guide to using VibeStack</video:description>
      <video:content_loc>https://yourvibestackapp.com/videos/tutorial.mp4</video:content_loc>
      <video:duration>360</video:duration>
    </video:video>
  </url>
</urlset>
```

## Implementing Sitemaps in Next.js

### Static Sitemap Generation

For websites with static routes, create a sitemap.xml file in the public directory:

```typescript
// scripts/generate-sitemap.ts
import fs from 'fs';
import { globby } from 'globby';
import prettier from 'prettier';

async function generateSitemap() {
  const prettierConfig = await prettier.resolveConfig('./.prettierrc.js');
  const pages = await globby([
    'pages/**/*.tsx',
    'pages/*.tsx',
    '!pages/_*.tsx',
    '!pages/api',
  ]);

  const baseUrl = 'https://yourvibestackapp.com';
  const currentDate = new Date().toISOString();

  // Create sitemap items for each page
  const sitemap = `
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      ${pages
        .map((page) => {
          const path = page
            .replace('pages', '')
            .replace('.tsx', '')
            .replace('/index', '');
          const route = path === '' ? '' : path;
          
          return `
            <url>
              <loc>${baseUrl}${route}</loc>
              <lastmod>${currentDate}</lastmod>
              <changefreq>monthly</changefreq>
              <priority>${route === '' ? '1.0' : '0.8'}</priority>
            </url>
          `;
        })
        .join('')}
    </urlset>
  `;

  const formatted = prettier.format(sitemap, {
    ...prettierConfig,
    parser: 'html',
  });

  fs.writeFileSync('public/sitemap.xml', formatted);
  console.log('Sitemap generated successfully!');
}

generateSitemap();
```

Add this script to your package.json:

```json
{
  "scripts": {
    "build": "next build",
    "generate-sitemap": "ts-node --project tsconfig.json ./scripts/generate-sitemap.ts",
    "prebuild": "npm run generate-sitemap"
  }
}
```

### Dynamic Sitemap Generation

For websites with dynamic routes, create an API endpoint:

```typescript
// pages/api/sitemap.xml.ts
import { NextApiRequest, NextApiResponse } from 'next';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Set the response type
  res.setHeader('Content-Type', 'text/xml');
  
  try {
    // Fetch your dynamic page data
    const { data: products, error } = await supabase
      .from('products')
      .select('slug, updated_at')
      .order('updated_at', { ascending: false });
    
    if (error) throw error;
    
    // Create the XML sitemap
    const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://yourvibestackapp.com/</loc>
          <lastmod>${new Date().toISOString()}</lastmod>
          <changefreq>daily</changefreq>
          <priority>1.0</priority>
        </url>
        ${products.map(product => `
          <url>
            <loc>https://yourvibestackapp.com/products/${product.slug}</loc>
            <lastmod>${new Date(product.updated_at).toISOString()}</lastmod>
            <changefreq>weekly</changefreq>
            <priority>0.8</priority>
          </url>
        `).join('')}
      </urlset>`;
    
    // Send the sitemap
    res.status(200).send(sitemap);
  } catch (error) {
    console.error('Error generating sitemap:', error);
    res.status(500).send('Error generating sitemap');
  }
}
```

Then configure your `next.config.js` to rewrite requests:

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/sitemap.xml',
        destination: '/api/sitemap.xml',
      },
    ];
  },
};

module.exports = nextConfig;
```

### Using next-sitemap Package

For an easier implementation, use the `next-sitemap` package:

```bash
npm install next-sitemap
```

Create `next-sitemap.config.js` in your project root:

```javascript
/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: 'https://yourvibestackapp.com',
  generateRobotsTxt: true,
  changefreq: 'weekly',
  priority: 0.7,
  exclude: ['/admin/*', '/dashboard/*'],
  robotsTxtOptions: {
    additionalSitemaps: [
      'https://yourvibestackapp.com/server-sitemap.xml',
    ],
  },
};
```

Add to `package.json`:

```json
{
  "scripts": {
    "build": "next build",
    "postbuild": "next-sitemap"
  }
}
```

## Sitemap Best Practices

1. **Keep Your Sitemap Updated**: Regenerate regularly as you add or modify content
2. **Limit Size**: Keep each sitemap under 50,000 URLs and 50MB
3. **Use Sitemap Index**: For large sites, break into multiple sitemaps
4. **Include Important Pages Only**: Focus on high-quality, crawlable pages
5. **Be Consistent with URLs**: Use the same protocol (https) and domain as your website
6. **Prioritize Properly**: Use the priority attribute thoughtfully
7. **Submit to Search Engines**: Register your sitemap with Google Search Console and Bing Webmaster Tools
8. **Include in robots.txt**: Add a reference to your sitemap in robots.txt

Example robots.txt with sitemap reference:

```
User-agent: *
Allow: /

Sitemap: https://yourvibestackapp.com/sitemap.xml
```

## Validating Your Sitemap

Before submitting your sitemap to search engines, validate it:

1. **XML Validation**: Ensure it follows the sitemap protocol
2. **URL Check**: Verify all URLs are accessible and return 200 status codes
3. **Mobile Friendliness**: Confirm mobile URLs are correct if using mobile sitemaps
4. **Canonical Verification**: Ensure URLs match your canonical URLs

## Sitemap Analytics and Monitoring

Track how search engines are crawling your sitemap:

1. **Google Search Console**: Monitor coverage and indexing issues
2. **Server Logs**: Check for search engine bot activity
3. **Regular Testing**: Periodically test URLs in your sitemap

## Sitemap Design Patterns for VibeStack

### Multi-tenant SaaS Pattern

For VibeStack applications with multiple customer accounts:

```typescript
// Separate sitemaps for public content and customer-specific content
async function generateSitemapIndex() {
  const publicSitemap = 'https://yourvibestackapp.com/public-sitemap.xml';
  const customerSitemaps = await getCustomerDomains().map(
    domain => `https://${domain}/customer-sitemap.xml`
  );
  
  return `
    <?xml version="1.0" encoding="UTF-8"?>
    <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <sitemap>
        <loc>${publicSitemap}</loc>
        <lastmod>${new Date().toISOString()}</lastmod>
      </sitemap>
      ${customerSitemaps.map(url => `
        <sitemap>
          <loc>${url}</loc>
          <lastmod>${new Date().toISOString()}</lastmod>
        </sitemap>
      `).join('')}
    </sitemapindex>
  `;
}
```

### Localized Content Pattern

For multi-language VibeStack applications:

```typescript
// Generate language-specific sitemaps
const languages = ['en', 'fr', 'es', 'de'];

const languageSitemaps = languages.map(lang => {
  return `
    <sitemap>
      <loc>https://yourvibestackapp.com/sitemaps/sitemap-${lang}.xml</loc>
      <lastmod>${new Date().toISOString()}</lastmod>
    </sitemap>
  `;
}).join('');

const sitemapIndex = `
  <?xml version="1.0" encoding="UTF-8"?>
  <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    ${languageSitemaps}
  </sitemapindex>
`;
```

## Resources

- [Sitemaps.org](https://www.sitemaps.org/): Official sitemap protocol documentation
- [Google Search Central: Build and submit a sitemap](https://developers.google.com/search/docs/advanced/sitemaps/build-sitemap)
- [next-sitemap](https://github.com/iamvishnusankar/next-sitemap): Easy sitemap generation for Next.js
- [XML Sitemap Validator](https://www.xml-sitemaps.com/validate-xml-sitemap.html): Free tool to check your sitemap
- [Schema.org](https://schema.org/): Enhance your sitemap with structured data
