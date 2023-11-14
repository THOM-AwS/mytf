import json
import boto3
import decimal
from json import JSONEncoder

# Custom JSONEncoder that converts Decimals to floats
class DecimalEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('genericDataTable')
    response = table.scan()
    items = response.get('Items', [])

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'  # Handle CORS
        },
        'body': json.dumps(items, cls=DecimalEncoder)  # Use the custom encoder
    }
