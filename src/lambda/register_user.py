import json
import boto3
import os
import logging
from datetime import datetime

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    try:
        logger.info(f"Event received: {json.dumps(event)}")
        
        # Check if environment variable is set
        table_name = os.environ.get('DYNAMODB_TABLE')
        logger.info(f"DynamoDB table name: {table_name}")
        
        if not table_name:
            raise Exception("DYNAMODB_TABLE environment variable not set")
        
        table = dynamodb.Table(table_name)
        
        # Extract userId from query parameters
        query_params = event.get('queryStringParameters', {})
        logger.info(f"Query parameters: {query_params}")
        
        if not query_params or 'userId' not in query_params:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Missing userId parameter'})
            }
        
        user_id = query_params['userId'].strip()
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Empty userId value'})
            }
        
        # Check if user already exists
        try:
            response = table.get_item(Key={'userId': user_id})
            if 'Item' in response:
                logger.info(f"User {user_id} already exists")
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'message': f'User {user_id} already registered',
                        'userId': user_id,
                        'timestamp': datetime.now().isoformat()
                    })
                }
        except Exception as e:
            logger.error(f"Error checking existing user: {str(e)}")
            raise
        
        # Register new user
        timestamp = datetime.now().isoformat()
        table.put_item(Item={
            'userId': user_id,
            'registeredAt': timestamp
        })
        
        logger.info(f"User {user_id} registered successfully")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': f'User {user_id} registered successfully',
                'userId': user_id,
                'timestamp': timestamp
            })
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        } 