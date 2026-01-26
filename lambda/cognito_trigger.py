"""
Cognito Pre-Signup Lambda Trigger
Restricts user registration to specific email domains.
"""

import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ALLOWED_EMAIL_DOMAIN = os.environ.get('ALLOWED_EMAIL_DOMAIN', 'lukelittle.com')


def lambda_handler(event, context):
    """
    Cognito pre-signup trigger handler.
    Validates that the user's email domain matches the allowed domain.
    
    Args:
        event: Cognito trigger event
        context: Lambda context
        
    Returns:
        event: Modified event (or raises exception to prevent signup)
    """
    logger.info(f"Pre-signup trigger invoked for trigger source: {event.get('triggerSource')}")
    
    # Get the email from the request
    email = event['request']['userAttributes'].get('email', '').lower()
    
    logger.info(f"Checking email: {email}")
    
    # Check if email ends with the allowed domain
    if not email.endswith(f"@{ALLOWED_EMAIL_DOMAIN}"):
        logger.warning(f"Signup rejected: {email} does not match @{ALLOWED_EMAIL_DOMAIN}")
        raise Exception(
            f"Invalid email domain. Only @{ALLOWED_EMAIL_DOMAIN} emails are allowed for this demo. "
            f"If you're using this code, update the ALLOWED_EMAIL_DOMAIN variable in Terraform!"
        )
    
    logger.info(f"Signup approved for: {email}")
    
    # Auto-confirm the user (skip email verification for demo purposes)
    event['response']['autoConfirmUser'] = True
    event['response']['autoVerifyEmail'] = True
    
    return event
