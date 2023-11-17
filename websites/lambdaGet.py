import json
import boto3
import decimal
import logging
from json import JSONEncoder

# Custom JSONEncoder that converts Decimals to floats
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
        items = response.get('Items', [])
    
        test_data = {'value': decimal.Decimal('10.5')}
        print(json.dumps(test_data, cls=DecimalEncoder))

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Handle CORS
            },
            'body': json.dumps(items, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error("error message: %s", e)

