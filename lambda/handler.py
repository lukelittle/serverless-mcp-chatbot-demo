"""
Serverless MCP Chatbot Demo - Main Lambda Handler
Demonstrates agentic tool use with Bedrock and a vinyl collection query tool.
"""

import os
import json
import logging
import csv
from io import StringIO
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
PROJECT_TAG = os.environ.get('PROJECT_TAG', 'serverless-mcp-chatbot-demo')
DATA_BUCKET = os.environ.get('DATA_BUCKET')
DATA_KEY = os.environ.get('DATA_KEY', 'discogs.csv')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-5-sonnet-20241022-v2:0')
FRONTEND_ORIGIN = os.environ.get('FRONTEND_ORIGIN', '*')

# AWS clients
s3_client = boto3.client('s3')
bedrock_client = boto3.client('bedrock-runtime')

# Tool definition for Bedrock
TOOL_DEFINITION = {
    "toolSpec": {
        "name": "query_vinyl_collection",
        "description": "Query Luke's vinyl record collection from his Discogs export. Use this tool when the user asks about specific records, artists, labels, years, or wants to browse the collection. Do NOT use this for general music trivia or questions unrelated to the collection.",
        "inputSchema": {
            "json": {
                "type": "object",
                "properties": {
                    "query_type": {
                        "type": "string",
                        "description": "Type of query to perform",
                        "enum": ["artist", "label", "year", "title", "all"]
                    },
                    "search_term": {
                        "type": "string",
                        "description": "The term to search for (artist name, label, year, or title). Use 'all' for query_type 'all'."
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results to return",
                        "default": 10
                    }
                },
                "required": ["query_type", "search_term"]
            }
        }
    }
}


def query_vinyl_collection(query_type, search_term, limit=10):
    """
    Tool implementation: Query vinyl collection from S3 CSV.
    
    Args:
        query_type: Type of query (artist, label, year, title, all)
        search_term: Term to search for
        limit: Max results to return
        
    Returns:
        Formatted string with results
    """
    try:
        logger.info(f"Querying vinyl collection: type={query_type}, term={search_term}, limit={limit}")
        
        # Download CSV from S3
        response = s3_client.get_object(Bucket=DATA_BUCKET, Key=DATA_KEY)
        csv_content = response['Body'].read().decode('utf-8')
        
        # Parse CSV
        csv_reader = csv.DictReader(StringIO(csv_content))
        records = list(csv_reader)
        
        logger.info(f"Loaded {len(records)} records from CSV")
        
        # Filter records based on query type
        matches = []
        search_lower = search_term.lower()
        
        if query_type == "all":
            matches = records
        elif query_type == "artist":
            matches = [r for r in records if search_lower in r.get('Artist', '').lower()]
        elif query_type == "label":
            matches = [r for r in records if search_lower in r.get('Label', '').lower()]
        elif query_type == "year":
            matches = [r for r in records if search_term in r.get('Released', '')]
        elif query_type == "title":
            matches = [r for r in records if search_lower in r.get('Title', '').lower()]
        
        # Limit results
        matches = matches[:limit]
        
        logger.info(f"Found {len(matches)} matching records")
        
        # Format results
        if not matches:
            return f"No records found matching {query_type}='{search_term}'"
        
        result_lines = [f"Found {len(matches)} record(s):\n"]
        for i, record in enumerate(matches, 1):
            artist = record.get('Artist', 'Unknown')
            title = record.get('Title', 'Unknown')
            label = record.get('Label', '')
            year = record.get('Released', '')
            format_type = record.get('Format', '')
            condition = record.get('Collection Media Condition', '')
            
            result_lines.append(
                f"{i}. {artist} - {title} "
                f"({year}) [{label}] "
                f"Format: {format_type}"
            )
            if condition:
                result_lines[-1] += f" | Condition: {condition}"
        
        return "\n".join(result_lines)
        
    except ClientError as e:
        logger.error(f"S3 error: {e}")
        return f"Error accessing vinyl collection: {str(e)}"
    except Exception as e:
        logger.error(f"Error querying vinyl collection: {e}")
        return f"Error querying collection: {str(e)}"


def invoke_bedrock_with_tools(user_message, conversation_history=None):
    """
    Invoke Bedrock with tool use capability.
    
    Args:
        user_message: User's message
        conversation_history: Previous conversation messages
        
    Returns:
        tuple: (reply_text, tool_used_flag)
    """
    if conversation_history is None:
        conversation_history = []
    
    # Add user message to history
    messages = conversation_history + [
        {
            "role": "user",
            "content": [{"text": user_message}]
        }
    ]
    
    system_prompt = [
        {
            "text": """You are a helpful assistant that can query Luke's vinyl record collection. 
When users ask about records in the collection, use the query_vinyl_collection tool. 
Keep responses concise and demo-friendly (2-3 sentences max).
For general music questions not about the specific collection, answer normally without using the tool."""
        }
    ]
    
    tool_used = False
    max_iterations = 5  # Prevent infinite loops
    
    for iteration in range(max_iterations):
        try:
            logger.info(f"Bedrock iteration {iteration + 1}")
            
            # Call Bedrock Converse API
            response = bedrock_client.converse(
                modelId=BEDROCK_MODEL_ID,
                messages=messages,
                system=system_prompt,
                toolConfig={
                    "tools": [TOOL_DEFINITION]
                },
                inferenceConfig={
                    "maxTokens": 2000,
                    "temperature": 0.7
                }
            )
            
            logger.info(f"Bedrock response stop reason: {response['stopReason']}")
            
            # Get the assistant's response
            assistant_message = response['output']['message']
            messages.append(assistant_message)
            
            # Check if tool use was requested
            if response['stopReason'] == 'tool_use':
                tool_used = True
                
                # Process tool requests
                tool_results = []
                for content_block in assistant_message['content']:
                    if 'toolUse' in content_block:
                        tool_use_block = content_block['toolUse']
                        tool_name = tool_use_block['name']
                        tool_input = tool_use_block['input']
                        tool_use_id = tool_use_block['toolUseId']
                        
                        logger.info(f"Tool requested: {tool_name} with input: {tool_input}")
                        
                        # Execute the tool
                        if tool_name == 'query_vinyl_collection':
                            result = query_vinyl_collection(
                                query_type=tool_input.get('query_type'),
                                search_term=tool_input.get('search_term'),
                                limit=tool_input.get('limit', 10)
                            )
                        else:
                            result = f"Unknown tool: {tool_name}"
                        
                        logger.info(f"Tool result: {result[:200]}...")
                        
                        tool_results.append({
                            "toolResult": {
                                "toolUseId": tool_use_id,
                                "content": [{"text": result}]
                            }
                        })
                
                # Add tool results to conversation
                messages.append({
                    "role": "user",
                    "content": tool_results
                })
                
                # Continue the loop to get the final response
                continue
            
            else:
                # End of turn - extract final text response
                final_response = ""
                for content_block in assistant_message['content']:
                    if 'text' in content_block:
                        final_response += content_block['text']
                
                logger.info(f"Final response: {final_response[:200]}...")
                return final_response, tool_used
        
        except ClientError as e:
            logger.error(f"Bedrock error: {e}")
            return f"Sorry, I encountered an error: {str(e)}", tool_used
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return f"Sorry, something went wrong: {str(e)}", tool_used
    
    return "I reached the maximum number of tool iterations. Please rephrase your question.", tool_used


def lambda_handler(event, context):
    """
    Main Lambda handler for chat endpoint.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    logger.info(f"Request event: {json.dumps(event)}")
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        user_message = body.get('message', '').strip()
        
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': FRONTEND_ORIGIN
                },
                'body': json.dumps({
                    'error': 'Message is required'
                })
            }
        
        logger.info(f"Processing message: {user_message}")
        
        # Invoke Bedrock with tool use
        reply, tool_used = invoke_bedrock_with_tools(user_message)
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': FRONTEND_ORIGIN
            },
            'body': json.dumps({
                'reply': reply,
                'tool_used': tool_used,
                'mode': 'bedrock-converse'
            })
        }
    
    except Exception as e:
        logger.error(f"Handler error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': FRONTEND_ORIGIN
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }
