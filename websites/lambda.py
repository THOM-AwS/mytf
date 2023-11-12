import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("Received event: %s", json.dumps(event, indent=2))
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('locations')
    table.put_item(Item=event)
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Payload logged successfully!'})
    }
