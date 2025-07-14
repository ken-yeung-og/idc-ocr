import json
import boto3
import os
import uuid
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import base64
from urllib.parse import unquote_plus
import mimetypes

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
bedrock_client = boto3.client('bedrock-runtime')
bedrock_agent_client = boto3.client('bedrock-agent-runtime')

# Environment variables
DYNAMODB_TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
BEDROCK_MODEL_ID = os.environ['BEDROCK_MODEL_ID']
S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']

# Initialize DynamoDB table
table = dynamodb.Table(DYNAMODB_TABLE_NAME)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for processing document uploads from S3.
    
    Args:
        event: S3 event containing bucket and object information
        context: Lambda context object
        
    Returns:
        Dict containing processing results
    """
    try:
        logger.info(f"Processing event: {json.dumps(event, default=str)}")
        
        # Process each record in the event
        results = []
        for record in event['Records']:
            if record['eventSource'] == 'aws:s3':
                result = process_s3_record(record)
                results.append(result)
        
        logger.info(f"Processing completed. Results: {results}")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Documents processed successfully',
                'results': results
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }


def process_s3_record(record: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process a single S3 record (uploaded document).
    
    Args:
        record: S3 event record
        
    Returns:
        Dict containing processing results for this record
    """
    try:
        # Extract S3 information
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        logger.info(f"Processing document: {key} from bucket: {bucket}")
        
        # Generate unique document ID
        document_id = str(uuid.uuid4())
        
        # Get document metadata
        document_metadata = get_document_metadata(bucket, key)
        
        # Extract text from document
        extracted_text = extract_text_from_document(bucket, key)
        
        # Generate summary using Bedrock
        summary = generate_summary_with_bedrock(extracted_text)
        
        # Store document data and summary in DynamoDB
        store_document_data(
            document_id=document_id,
            bucket=bucket,
            key=key,
            metadata=document_metadata,
            raw_text=extracted_text,
            summary=summary
        )
        
        return {
            'document_id': document_id,
            'bucket': bucket,
            'key': key,
            'status': 'processed',
            'text_length': len(extracted_text),
            'summary_length': len(summary)
        }
        
    except Exception as e:
        logger.error(f"Error processing S3 record: {str(e)}")
        return {
            'bucket': record['s3']['bucket']['name'],
            'key': unquote_plus(record['s3']['object']['key']),
            'status': 'error',
            'error': str(e)
        }


def get_document_metadata(bucket: str, key: str) -> Dict[str, Any]:
    """
    Get metadata for the uploaded document.
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        
    Returns:
        Dict containing document metadata
    """
    try:
        response = s3_client.head_object(Bucket=bucket, Key=key)
        
        # Get file type
        content_type = response.get('ContentType', '')
        if not content_type:
            content_type, _ = mimetypes.guess_type(key)
        
        return {
            'content_type': content_type,
            'content_length': response.get('ContentLength', 0),
            'last_modified': response.get('LastModified', datetime.now()).isoformat(),
            'etag': response.get('ETag', '').strip('"'),
            'metadata': response.get('Metadata', {})
        }
        
    except Exception as e:
        logger.error(f"Error getting document metadata: {str(e)}")
        return {
            'content_type': 'unknown',
            'content_length': 0,
            'last_modified': datetime.now().isoformat(),
            'etag': '',
            'metadata': {}
        }


def extract_text_from_document(bucket: str, key: str) -> str:
    """
    Extract text from document using AWS Bedrock Data Automation.
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        
    Returns:
        Extracted text from the document
    """
    try:
        logger.info(f"Extracting text from document: {key}")
        
        # Get file extension to determine processing method
        file_extension = key.lower().split('.')[-1]
        
        if file_extension in ['pdf', 'png', 'jpg', 'jpeg', 'tiff', 'gif', 'bmp']:
            # Use Bedrock Data Automation for image and PDF files
            return extract_text_with_bedrock_data_automation(bucket, key)
        else:
            # For other file types, try to read directly
            return extract_text_directly(bucket, key)
            
    except Exception as e:
        logger.error(f"Error extracting text: {str(e)}")
        return f"Error extracting text: {str(e)}"


def extract_text_with_bedrock_data_automation(bucket: str, key: str) -> str:
    """
    Extract text using AWS Bedrock Data Automation.
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        
    Returns:
        Extracted text
    """
    try:
        # Use Bedrock Data Automation to extract document text
        # First, we'll use a vision-capable model to extract text from the document
        
        # Get the document content
        document_response = s3_client.get_object(Bucket=bucket, Key=key)
        document_content = document_response['Body'].read()
        
        # Encode document content to base64 for Bedrock
        import base64
        document_b64 = base64.b64encode(document_content).decode('utf-8')
        
        # Determine the media type based on file extension
        file_extension = key.lower().split('.')[-1]
        media_type_map = {
            'pdf': 'application/pdf',
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'tiff': 'image/tiff',
            'gif': 'image/gif',
            'bmp': 'image/bmp'
        }
        media_type = media_type_map.get(file_extension, 'application/octet-stream')
        
        # Create a prompt for text extraction
        prompt = """
        Please extract all text content from this document. 
        Provide the extracted text in a clean, readable format.
        Maintain the original structure and formatting where possible.
        If there are tables, preserve their structure.
        If there are multiple sections, clearly separate them.
        
        Return only the extracted text content, without any additional commentary.
        """
        
        # Prepare the request for Claude 3 with vision capabilities
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 8000,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": document_b64
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.1,
            "top_p": 0.9
        }
        
        # Use the environment variable for model ID
        model_id = BEDROCK_MODEL_ID
        
        # Call Bedrock
        response = bedrock_client.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body),
            contentType='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        if 'content' in response_body and response_body['content']:
            extracted_text = response_body['content'][0]['text']
            logger.info(f"Successfully extracted text using Bedrock Data Automation: {len(extracted_text)} characters")
            return extracted_text.strip()
        else:
            logger.warning("Empty response from Bedrock Data Automation")
            return "Unable to extract text - empty response from Bedrock"
            
    except Exception as e:
        logger.error(f"Error with Bedrock Data Automation: {str(e)}")
        # Fallback to direct reading
        return extract_text_directly(bucket, key)


def extract_text_directly(bucket: str, key: str) -> str:
    """
    Extract text directly from S3 object for text-based files.
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        
    Returns:
        Extracted text
    """
    try:
        # Get the file from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read()
        
        # Try to decode as text
        try:
            text = content.decode('utf-8')
        except UnicodeDecodeError:
            try:
                text = content.decode('latin-1')
            except UnicodeDecodeError:
                text = content.decode('utf-8', errors='ignore')
        
        return text
        
    except Exception as e:
        logger.error(f"Error reading file directly: {str(e)}")
        return f"Unable to extract text from file: {str(e)}"


def generate_summary_with_bedrock(text: str) -> str:
    """
    Generate a summary of the extracted text using AWS Bedrock.
    
    Args:
        text: The extracted text to summarize
        
    Returns:
        Generated summary
    """
    try:
        if not text or len(text.strip()) < 50:
            return "Text too short to summarize effectively."
        
        # Prepare the prompt for Claude
        prompt = f"""
        Please provide a comprehensive summary of the following document. 
        Include the main topics, key points, and any important details.
        Keep the summary clear and well-structured.
        
        Document text:
        {text[:8000]}  # Limit text to avoid token limits
        
        Summary:
        """
        
        # Prepare the request body for Claude
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.3,
            "top_p": 0.9
        }
        
        # Call Bedrock
        response = bedrock_client.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body),
            contentType='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        if 'content' in response_body and response_body['content']:
            summary = response_body['content'][0]['text']
            return summary.strip()
        else:
            return "Unable to generate summary - empty response from model."
            
    except Exception as e:
        logger.error(f"Error generating summary with Bedrock: {str(e)}")
        return f"Error generating summary: {str(e)}"


def store_document_data(document_id: str, bucket: str, key: str, 
                       metadata: Dict[str, Any], raw_text: str, 
                       summary: str) -> None:
    """
    Store document data and summary in DynamoDB.
    
    Args:
        document_id: Unique document identifier
        bucket: S3 bucket name
        key: S3 object key
        metadata: Document metadata
        raw_text: Extracted raw text
        summary: Generated summary
    """
    try:
        # Prepare DynamoDB item
        item = {
            'document_id': document_id,
            'bucket': bucket,
            'object_key': key,
            'upload_timestamp': int(datetime.now().timestamp()),
            'metadata': metadata,
            'raw_text': raw_text,
            'summary': summary,
            'processed_at': datetime.now().isoformat(),
            'text_length': len(raw_text),
            'summary_length': len(summary)
        }
        
        # Store in DynamoDB
        table.put_item(Item=item)
        
        logger.info(f"Document data stored successfully: {document_id}")
        
    except Exception as e:
        logger.error(f"Error storing document data: {str(e)}")
        raise


def get_document_by_id(document_id: str) -> Optional[Dict[str, Any]]:
    """
    Retrieve document data by ID (utility function for testing).
    
    Args:
        document_id: Document identifier
        
    Returns:
        Document data or None if not found
    """
    try:
        response = table.get_item(Key={'document_id': document_id})
        return response.get('Item')
    except Exception as e:
        logger.error(f"Error retrieving document: {str(e)}")
        return None 