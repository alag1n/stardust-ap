const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = 3000;
const STATIC_DIR = '.';

// Прокси для изображений с Yandex Cloud Storage
function proxyImage(targetUrl, res) {
    const parsedUrl = new URL(targetUrl);
    const options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'GET',
        headers: {
            'User-Agent': 'Stardust-App/1.0'
        }
    };

    const proxyReq = https.request(options, (proxyRes) => {
        // Проверяем статус
        if (proxyRes.statusCode !== 200 && proxyRes.statusCode !== 304) {
            res.writeHead(proxyRes.statusCode || 502, {
                'Access-Control-Allow-Origin': '*'
            });
            res.end();
            return;
        }

        // Передаём заголовки с CORS
        const headers = {
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=31536000',
        };

        // Копируем тип контента
        if (proxyRes.headers['content-type']) {
            headers['Content-Type'] = proxyRes.headers['content-type'];
        }

        res.writeHead(proxyRes.statusCode, headers);

        // Прокидываем данные
        proxyRes.pipe(res, { end: true });
    });

    proxyReq.on('error', (err) => {
        console.error('Proxy error:', err.message);
        res.writeHead(502, { 'Access-Control-Allow-Origin': '*' });
        res.end('Proxy error');
    });

    proxyReq.end();
}

const mimeTypes = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.eot': 'application/vnd.ms-fontobject',
    '.wasm': 'application/wasm',
    '.map': 'application/json',
    '.webmanifest': 'application/manifest+json',
    '.xml': 'application/xml'
};

const server = http.createServer((req, res) => {
    console.log(`${req.method} ${req.url}`);

    // Обработка прокси изображений /proxy-image?url=...
    if (req.url.startsWith('/proxy-image?url=')) {
        try {
            const urlParam = new URL(req.url, `http://localhost:${PORT}`).searchParams.get('url');
            if (urlParam) {
                const decodedUrl = decodeURIComponent(urlParam);
                console.log('Proxying image:', decodedUrl);
                proxyImage(decodedUrl, res);
                return;
            }
        } catch (e) {
            console.error('Proxy error:', e);
        }
        res.writeHead(400, { 'Access-Control-Allow-Origin': '*' });
        res.end('Bad request');
        return;
    }

    let filePath = path.join(__dirname, STATIC_DIR, req.url === '/' ? 'index.html' : req.url);
    
    // Security: prevent directory traversal
    const staticDirPath = path.resolve(__dirname, STATIC_DIR);
    if (!filePath.startsWith(staticDirPath)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                // For SPA, serve index.html for non-file routes
                fs.readFile(path.join(STATIC_DIR, 'index.html'), (err2, content2) => {
                    if (err2) {
                        res.writeHead(404);
                        res.end('Not Found');
                    } else {
                        res.writeHead(200, { 'Content-Type': 'text/html' });
                        res.end(content2);
                    }
                });
            } else {
                res.writeHead(500);
                res.end('Server Error');
            }
        } else {
            res.writeHead(200, { 
                'Content-Type': contentType,
                'Cache-Control': 'no-cache'
            });
            res.end(content);
        }
    });
});

server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}/`);
});
