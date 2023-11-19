import boto3
import json
import logging
import time
import urllib.parse
from decimal import Decimal
from json import JSONEncoder

class DecimalEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("Received event: %s", json.dumps(event, indent=2))

    # Parse the URL-encoded body
    parsed_body = urllib.parse.parse_qs(event['body'])
    lat = parsed_body.get('lat', [None])[0]
    lon = parsed_body.get('lon', [None])[0]
    timestamp = parsed_body.get('timestamp', [None])[0]

    # Convert lat and lon to Decimal, and ensure timestamp is a string
    try:
        lat = Decimal(lat) if lat is not None else None
        lon = Decimal(lon) if lon is not None else None
    except (ValueError, TypeError):
        logger.error("Invalid data types for lat or lon")
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid data types for lat or lon'})
        }

    if timestamp is None:
        logger.error("Missing timestamp in the event")
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Missing timestamp'})
        }

    # Ensure timestamp is a string
    timestamp = str(timestamp)

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('genericDataTable')

    # Calculate TTL (3 hours from now)
    ttl = int(time.time()) + 10800  # three hours

    item = {
        'timestamp': timestamp,
        'lat': lat,
        'lon': lon,
        'ttl': ttl
    }

    try:
        table.put_item(Item=item)
        logger.info("Logged payload: %s", json.dumps(item, cls=DecimalEncoder))
    
    except Exception as e:
        logger.error("Error putting item in DynamoDB: %s", e)
        print(json.dumps({'message': 'Error putting item in DynamoDB', 'error': str(e)}))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error putting item in DynamoDB'})
        }

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps({'message': 'Payload logged successfully!'})
    }
