import json


def lambda_handler(event, context):
    try:
        record = event['Records'][0]
        request = record['cf']['request']
        response = record['cf']['response'] if 'response' in record['cf'] else None

        response_headers = response['headers'] if response else request['headers']

        # hamer.cloud-specific security headers
        security_headers = [
            {'key': 'content-security-policy', 'value': (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com https://www.google.com https://static.doubleclick.net https://www.youtube.com https://s.ytimg.com https://cdn.jsdelivr.net https://unpkg.com https://maps.googleapis.com; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://www.youtube.com https://cdnjs.cloudflare.com; "
                "img-src 'self' data: https://avatars.githubusercontent.com https://i.ytimg.com https://yt3.ggpht.com https://www.googletagmanager.com https://www.google.com.au https://www.google-analytics.com https://analytics.google.com https://stats.g.doubleclick.net https://maps.googleapis.com https://maps.gstatic.com https://khms0.googleapis.com https://khms1.googleapis.com https://www.google.co.jp; "
                "font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; "
                "connect-src 'self' https://www.googletagmanager.com https://www.google.com https://www.google.com.au https://www.google-analytics.com https://analytics.google.com https://stats.g.doubleclick.net https://www.youtube.com https://play.google.com https://api.hamer.cloud https://api.github.com https://maps.googleapis.com https://raw.githubusercontent.com; "
                "frame-src 'self' https://www.youtube.com https://cdn.jsdelivr.net; "
                "object-src 'none'; "
                "form-action 'self'; "
                "frame-ancestors 'self'; "
                "upgrade-insecure-requests"
            )},
            {'key': 'strict-transport-security', 'value': 'max-age=63072000; includeSubdomains; preload'},
            {'key': 'x-content-type-options', 'value': 'nosniff'},
            {'key': 'referrer-policy', 'value': 'strict-origin-when-cross-origin'},
            {'key': 'permissions-policy', 'value': (
                "accelerometer=(), "
                "geolocation=(), "
                "microphone=(), "
                "camera=(), "
                "fullscreen=(self), "
                "payment=(), "
                "interest-cohort=(), "
                "usb=(), "
                "magnetometer=(), "
                "gyroscope=()"
            )},
        ]
        for header in security_headers:
            key = header['key'].lower()
            value = header['value']
            response_headers[key] = [{'key': key, 'value': value}]

        if response:
            return response
        else:
            return request

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'status': '500',
            'statusDescription': 'Internal Server Error',
            'body': json.dumps({'message': f"Error: {str(e)}"}),
            'headers': {
                'content-type': [{'key': 'content-type', 'value': 'application/json'}],
            },
        }
