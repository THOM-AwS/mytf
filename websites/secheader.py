def add_cors_headers(headers):
    """ Add CORS headers to the response """
    headers['access-control-allow-origin'] = [{
        'key': 'Access-Control-Allow-Origin',
        'value': '*'
    }]
    headers['access-control-allow-methods'] = [{
        'key': 'Access-Control-Allow-Methods',
        'value': 'GET, POST, OPTIONS'
    }]
    headers['access-control-allow-headers'] = [{
        'key': 'Access-Control-Allow-Headers',
        'value': 'Content-Type'
    }]

STATIC_HEADERS_TO_ADD = {
    'x-frame-options': [{
        'key': 'X-Frame-Options',
        'value': 'DENY'
    }],
    'content-security-policy': [{
        'key': 'Content-Security-Policy',
        'value': ("default-src 'self' data: *.googleapis.com https://www.google-analytics.com https://analytics.google.com https://api.hamer.cloud https://*.datahub.io; "
                  "base-uri 'self'; "
                  "img-src * 'self' data: https: 'unsafe-inline'; "
                  "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com https://maps.gstatic.com https://www.youtube.com *.google.com https://*.gstatic.com https://www.googletagmanager.com https://cdn.jsdelivr.net https://github.com data: https://www.google-analytics.com; "
                  "style-src 'self' 'unsafe-inline' *.googleapis.com https://fonts.googleapis.com data:; "
                  "font-src 'self' 'unsafe-inline' *.gstatic.com *.googleapis.com; "
                  "frame-src https://youtube.com https://www.youtube.com *.google.com https://cdn.jsdelivr.net; "
                  "connect-src 'self' https://www.google-analytics.com https://maps.googleapis.com https://*.hamer.cloud https://analytics.google.com https://api.openweathermap.org https://datahub.io/core/geo-countries/r/countries.geojson https://pkgstore.datahub.io/core/geo-countries/countries/archive/* https://cdn.jsdelivr.net https://api.github.com; "
                  "object-src 'none'")
    }],
    'strict-transport-security': [{
        'key': 'Strict-Transport-Security',
        'value': 'max-age=63072000; includeSubdomains; preload'
    }],
    'x-content-type-options': [{
        'key': 'X-Content-Type-Options',
        'value': 'nosniff'
    }],
    'x-xss-protection': [{
        'key': 'X-XSS-Protection',
        'value': '1; mode=block'
    }],
    'referrer-policy': [{
        'key': 'Referrer-Policy',
        'value': 'same-origin'
    }],
}

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    response = event['Records'][0]['cf']['response']

    # Add or update security headers
    headers = response.get('headers', {})
    for key, value in STATIC_HEADERS_TO_ADD.items():
        headers[key.lower()] = value  # Header names are case-insensitive

    # Add CORS headers
    add_cors_headers(headers)

    # Handle OPTIONS preflight requests
    if request['method'] == 'OPTIONS':
        return {
            'status': '204',
            'statusDescription': 'No Content',
            'headers': headers,
            'body': '',
        }

    response['headers'] = headers
    return response
