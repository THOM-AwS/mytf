import boto3
import json
import logging
import urllib.parse  # Import urllib.parse module

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("Received event: %s", json.dumps(event, indent=2))

    # Parse the URL-encoded body
    parsed_body = urllib.parse.parse_qs(event['body'])
    lat = parsed_body.get('lat', [None])[0]
    lon = parsed_body.get('lon', [None])[0]
    timestamp = parsed_body.get('timestamp', [None])[0]

    # Check if lat, lon, and timestamp are present
    if lat is None or lon is None or timestamp is None:
        logger.error("Missing required fields in the event")
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Missing required fields'})
        }

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('locations')

    # Construct the item with the desired structure
    item = {
        'timestamp': timestamp,  # assuming 'timestamp' is your primary key
        'lat': lat,
        'lon': lon
    }

    table.put_item(Item=item)

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Payload logged successfully!'})
    }
