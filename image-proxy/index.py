import urllib.request
import urllib.error
import json

def handler(event, context):
    # Получаем URL из параметров запроса
    url = event.get('queryStringParameters', {}).get('url')
    
    if not url:
        return {
            'statusCode': 400,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': 'Missing url parameter'
        }
    
    try:
        # Загружаем изображение
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Stardust-App/1.0'}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            data = response.read()
            content_type = response.headers.get('Content-Type', 'image/jpeg')
            
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': content_type,
                'Cache-Control': 'public, max-age=31536000',
            },
            'body': data.decode('latin-1'),
            'isBase64Encoded': True
        }
    except urllib.error.HTTPError as e:
        return {
            'statusCode': e.code,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': str(e)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': str(e)
        }
