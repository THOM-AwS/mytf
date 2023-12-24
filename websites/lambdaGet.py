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
                "lat": -33.8707665, 
                "lon": 151.1996391, 
                "timestamp": 1700000000
            },
            {
                "lat": -33.8702265,
                "lon": 151.1994001, 
                "timestamp": 1700000001
            },
            {
                "lat": -33.8710335,
                "lon": 151.1965441,
                "timestamp": 1700000002
            },
            {
                "lat": -33.8734745,
                "lon": 151.1977241,
                "timestamp": 1700000003
            },
            {
                "lat": -33.8731355, 
                "lon": 151.1990331,
                "timestamp": 1700000004
            },
            {
                "lat": -33.8702154,
                "lon": 151.2009972,
                "timestamp": 1700000005
            },
            {
                "lat": -33.8681989,
                "lon": 151.2007921,
                "timestamp": 1700000006
            },
            {
                "lat": -33.8707665, 
                "lon": 151.1996391, 
                "timestamp": 1700000007
            }
        ]

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(items, cls=DecimalEncoder)
    }
