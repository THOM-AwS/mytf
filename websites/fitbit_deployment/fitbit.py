import os
import boto3
import requests
import json
from datetime import datetime, timedelta

FITBIT_CLIENT_ID = os.environ.get("FITBIT_CLIENT_ID")
ssm_client = boto3.client("ssm", region_name="us-east-1")

def lambda_handler(event, context):
    payload_response = []
    current_access_token = get_latest_access_token(ssm_client)
    endpoints = [
        "activities/heart/date/today/30d.json",
        "activities/heart/date/today/30d/15min.json"
        # "activities/activityCalories/date/today/7d.json",
        "activities/steps/date/today/30d.json",
        # "activities/calories/date/today/7d.json",
        # "activities/distance/date/today/7d.json",
        # "activities/floors/date/today/7d.json",
        # "activities/elevation/date/today/7d.json",
    ]

    for endpoint in endpoints:
        data = auth(current_access_token, endpoint)
        payload_response.append(data)
    
    api_gateway_response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(payload_response)
    }
    
    print(api_gateway_response)
    return api_gateway_response

def get_data(current_access_token, endpoint):
    headers = {"Authorization": f"Bearer {current_access_token}"}
    response = requests.get(
        f"https://api.fitbit.com/1/user/-/{endpoint}", headers=headers
    )
    return response


def auth(current_access_token, endpoint):
    response = get_data(current_access_token, endpoint)

    if response.status_code == 200:
        return {"statusCode": 200, "body": response.json()}
    elif response.status_code == 401:  # Token expired
        new_access_token = refresh_access_token(ssm_client)

        if new_access_token:
            response = get_data(new_access_token, endpoint)

            if response.status_code == 200:
                return {"statusCode": 200, "body": response.json()}

    return {"statusCode": response.status_code, "body": response.text}

# Store the access token in parameter store using a function
def store_access_token(ssm_client, access_token):
    print("store_access_token")
    # Store the access token in SSM Parameter Store
    ssm_client.put_parameter(
        Name="access_token",  # Replace with your parameter name
        Value=access_token,  # Replace with your access token value
        Type="String",  # Set the parameter type to SecureString
        Overwrite=True,  # Overwrite the existing parameter if it exists
    )
    print("Access token stored in SSM Parameter Store")
    print(access_token)
    # Return a success message to the caller
    return {"statusCode": 200, "body": "Access token stored in SSM Parameter Store"}


# Store the access token in parameter store using a function
def store_refresh_token(ssm_client, refresh_token):
    print("store_refresh_token")
    # Store the access token in SSM Parameter Store
    ssm_client.put_parameter(
        Name="refresh_token",  # Replace with your parameter name
        Value=refresh_token,  # Replace with your access token value
        Type="String",  # Set the parameter type to SecureString
        Overwrite=True,  # Overwrite the existing parameter if it exists
    )
    print("Refresh token stored in SSM Parameter Store")
    print(refresh_token)
    # Return a success message to the caller
    return {"statusCode": 200, "body": "Refresh token stored in SSM Parameter Store"}


# Get the latest refresh token from parameter store using a function
def get_latest_refresh_token(ssm_client):
    print("get_latest_refresh_token")
    # Retrieve the refresh token from SSM Parameter Store
    try:
        response = ssm_client.get_parameter(
            Name="refresh_token",  # Replace with your parameter name
        )
        return response["Parameter"]["Value"]
    except ssm_client.exceptions.ParameterNotFound:
        return None  # Parameter not found


# Get the latest access token from parameter store using a function
def get_latest_access_token(ssm_client):
    print("get_latest_access_token")
    # Retrieve the refresh token from SSM Parameter Store
    try:
        response = ssm_client.get_parameter(
            Name="access_token",  # Replace with your parameter name
            # WithDecryption=True  # Decrypt SecureString parameter
        )
        return response["Parameter"]["Value"]
    except ssm_client.exceptions.ParameterNotFound:
        return None  # Parameter not found


def refresh_access_token(ssm_client):
    print("refresh_access_token")
    current_refresh_token = get_latest_refresh_token(ssm_client)

    if current_refresh_token:
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        data = {
            "grant_type": "refresh_token",
            "client_id": FITBIT_CLIENT_ID,
            "refresh_token": current_refresh_token,
        }
        response = requests.post(
            "https://api.fitbit.com/oauth2/token", headers=headers, data=data
        )

        if response.status_code == 200:
            new_access_token = response.json()["access_token"]
            store_access_token(ssm_client, new_access_token)
            store_refresh_token(ssm_client, response.json()["refresh_token"])
            return new_access_token

    return None


# if __name__ == "__main__":
#     lambda_handler()
