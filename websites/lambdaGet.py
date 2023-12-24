import json
import boto3
import decimal
import logging
from json import JSONEncoder

class DecimalEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('genericDataTable')

    try:
        response = table.scan()
        items = response.get('Items', [])
        logger.info("Items retrieved: %s", items)
    except Exception as e:
        logger.error("Error during DynamoDB scan: %s", e)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Internal Server Error'})
        }

    # Fallback item if no items are found
    if len(items) < 1:
        items = [
            {
                "lat": -33.87076,
                "lon": 151.20219, 
                "timestamp": 1700000000
            },
            {
                "lat": -33.87070,
                "lon": 151.20140, 
                "timestamp": 1700000001
            },
            {
                "lat": -33.87045,
                "lon": 151.19999,
                "timestamp": 1700000002
            },
            {
                "lat": -33.87022,
                "lon": 151.19917, 
                "timestamp": 1700000003
            },
            {
                "lat": -33.87105,
                "lon": 151.19921,
                "timestamp": 1700000004
            },
            {
                "lat": -33.871271,
                "lon": 151.199504,
                "timestamp": 1700000005
            },
            {
                "lat": -33.87220,
                "lon": 151.19944,
                "timestamp": 1700000006
            },
            
            {
                "lat": -33.87310,
                "lon": 151.20000,
                "timestamp": 1700000006
            },
            
            {
                "lat": -33.87350,
                "lon": 151.20000,
                "timestamp": 1700000007
            },
            
            {
                "lat": -33.87349,
                "lon": 151.20050,
                "timestamp": 1700000008
            },
            {
                "lat": -33.873310,
                "lon": 151.2012261,
                "timestamp": 1700000008
            },
            
            {
                "lat": -33.87317,
                "lon": 151.20187,
                "timestamp": 1700000008
            },
            {
                "lat": -33.87215,
                "lon": 151.20190, 
                "timestamp": 1700000009
            },
            {
                "lat": -33.8713138,
                "lon": 151.2020507, 
                "timestamp": 1700000010
            },
            {
                "lat": -33.87076,
                "lon": 151.20219, 
                "timestamp": 1700000011
            },
        ]

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(items, cls=DecimalEncoder)
    }
