const http = require('http');
const https = require('https');

const PORT = 3001;
const ACCESS_KEY = '51da132509fa4a6fe84206c59d0b26fa';
const SECRET_KEY = '97b07b4ea7b73175c887730ff6f04b56';
const BUCKET = 'stardust-photos';
// Yandex Cloud Object Storage endpoint
const ENDPOINT = 'storage.yandexcloud.net';

console.log('Starting proxy server on port', PORT);

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  if (req.method !== 'POST') {
    res.writeHead(405);
    res.end('Method not allowed');
    return;
  }
  
  let body = '';
  req.on('data', chunk => { body += chunk.toString(); });
  req.on('end', () => {
    try {
      const data = JSON.parse(body);
      const { fileName, fileBase64, contentType } = data;
      
      if (!fileName || !fileBase64) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Missing parameters' }));
        return;
      }
      
      const objectKey = 'avatars/' + fileName;
      const uploadUrl = 'https://' + BUCKET + '.' + ENDPOINT + '/' + objectKey;
      
      const buffer = Buffer.from(fileBase64, 'base64');
      
      const options = {
        hostname: BUCKET + '.' + ENDPOINT,
        path: '/' + objectKey,
        method: 'PUT',
        headers: {
          'Content-Type': contentType || 'image/jpeg',
          'Authorization': 'AWS ' + ACCESS_KEY + ':' + SECRET_KEY,
          'Content-Length': buffer.length
        }
      };
      
      const uploadReq = https.request(options, (uploadRes) => {
        let uploadBody = '';
        uploadRes.on('data', chunk => uploadBody += chunk);
        uploadRes.on('end', () => {
          if (uploadRes.statusCode === 200 || uploadRes.statusCode === 201) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, url: uploadUrl }));
          } else {
            res.writeHead(500);
            res.end(JSON.stringify({ error: 'Upload failed: ' + uploadBody }));
          }
        });
      });
      
      uploadReq.on('error', (error) => {
        res.writeHead(500);
        res.end(JSON.stringify({ error: error.message }));
      });
      
      uploadReq.write(buffer);
      uploadReq.end();
      
    } catch (error) {
      res.writeHead(500);
      res.end(JSON.stringify({ error: error.message }));
    }
  });
});

server.listen(PORT, () => {
  console.log('Proxy server running at http://localhost:', PORT);
});