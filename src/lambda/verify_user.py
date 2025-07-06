import json
import boto3
import os
import logging
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        logger.info(f"Event received: {json.dumps(event)}")
        
        # Check if environment variables are set
        table_name = os.environ.get('DYNAMODB_TABLE')
        s3_bucket = os.environ.get('S3_BUCKET')
        
        logger.info(f"DynamoDB table name: {table_name}")
        logger.info(f"S3 bucket name: {s3_bucket}")
        
        if not table_name:
            raise Exception("DYNAMODB_TABLE environment variable not set")
        
        if not s3_bucket:
            raise Exception("S3_BUCKET environment variable not set")
        
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
        
        # Check if user exists in DynamoDB
        try:
            response = table.get_item(Key={'userId': user_id})
            user_exists = 'Item' in response
            
            logger.info(f"User {user_id} exists: {user_exists}")
            
            # Determine which HTML file to serve
            if user_exists:
                html_file = 'index.html'
                logger.info(f"User {user_id} verified successfully, serving index.html")
            else:
                html_file = 'error.html'
                logger.info(f"User {user_id} not found, serving error.html")
            
            # Get HTML content from S3
            try:
                s3_response = s3.get_object(Bucket=s3_bucket, Key=html_file)
                html_content = s3_response['Body'].read().decode('utf-8')
                
                logger.info(f"Successfully retrieved {html_file} from S3")
                
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'text/html',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': html_content
                }
                
            except ClientError as e:
                logger.error(f"Error retrieving {html_file} from S3: {str(e)}")
                raise Exception(f"Failed to retrieve {html_file} from S3")
                
        except ClientError as e:
            logger.error(f"Error checking user in DynamoDB: {str(e)}")
            raise Exception("Failed to check user in DynamoDB")
        
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