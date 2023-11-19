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
        items = [{"lat": -33.8688, "lon": 151.2093, "timestamp": 1700267130}]
        logger.info("Using fallback location")

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(items, cls=DecimalEncoder)
    }
