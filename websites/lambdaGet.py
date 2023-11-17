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

# Create a logger object
logger = logging.getLogger(__name__)

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('genericDataTable')
    try:
        response = table.scan()
        logger.info("message: %s", response)
        print(response)
        items = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(items, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error("error message: %s", e)

