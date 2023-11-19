import json
import boto3
import decimal
import logging
import time
from json import JSONEncoder

# Custom JSONEncoder that converts Decimals to floats
class DecimalEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

# Create a logger object
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # Set the logging level

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('genericDataTable')

    try:
        response = table.scan()

        items = response.get('Items', [])
        if items.length < 1:
            items = [lat=-33.0, lon=151.0, timestamp=1700267130]
            return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(items, cls=DecimalEncoder)
        }
            
        logger.info("Items retrieved: %s", items)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(items, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error("Error during DynamoDB scan: %s", e)
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal Server Error'})
        }
