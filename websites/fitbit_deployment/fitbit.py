from calendar import c
import os
from weakref import ref
import boto3
import requests
import json
import base64

FITBIT_CLIENT_ID = os.environ.get("FITBIT_CLIENT_ID")
FITBIT_CLIENT_SECRET = os.environ.get("FITBIT_CLIENT_SECRET")

ssm_client = boto3.client("ssm", region_name="us-east-1")


def lambda_handler(event, context):
    payload_response = []
    print("running...")
    current_access_token = get_latest_access_token(
        ssm_client
    )
    # electrocardiogram social activity weight temperature sleep settings cardio_fitness respiratory_rate location profile oxygen_saturation heartrate
    electrocardiogram = auth(current_access_token, "activities/heart/date/today/1d.json")
    payload_response.append(electrocardiogram)
    activity = auth(current_access_token, "activities/activityCalories/date/today/1d.json")
    payload_response.append(activity)
    weight = auth(current_access_token, "body/log/weight/date/today/1d.json")
    payload_response.append(weight)
    temperature = auth(current_access_token, "body/temperature/date/today/1d.json")
    payload_response.append(temperature)
    sleep = auth(current_access_token, "sleep/date/today.json")
    payload_response.append(sleep)
    cardio_fitness = auth(current_access_token, "activities/heart/date/today/1d.json")
    payload_response.append(cardio_fitness)
    respiratory_rate = auth(current_access_token, "activities/heart/date/today/1d.json")
    payload_response.append(respiratory_rate)
    location = auth(current_access_token, "activities/heart/date/today/1d.json")
    payload_response.append(location)
    steps = auth(current_access_token, "activities/steps/date/today/1d.json")
    payload_response.append(steps)
    calories = auth(current_access_token, "activities/calories/date/today/1d.json")
    payload_response.append(calories)
    distance = auth(current_access_token, "activities/distance/date/today/1d.json")
    payload_response.append(distance)
    floors = auth(current_access_token, "activities/floors/date/today/1d.json")
    payload_response.append(floors)
    elevation = auth(current_access_token, "activities/elevation/date/today/1d.json")
    payload_response.append(elevation)
    heart_rate = auth(current_access_token, "activities/heart/date/today/1d.json")
    payload_response.append(heart_rate)

    return payload_response


# function to retreive the data from the fitbit api
def get_data(current_access_token, endpoint):
    print("get_data")
    # make a request to the Fitbit API to get the user's data
    headers = {"Authorization": f"Bearer {current_access_token}"}
    response = requests.get(
        f"https://api.fitbit.com/1/user/-/{endpoint}", headers=headers
    )
    if response.status_code == 200:
        print("User data:", response.json())
        return {"statusCode": 200, "body": response.json()}
    else:
        print("Error while requesting user data:", response.text,response.status_code, response.raw)
        raise Exception("Error while requesting user data:", response.text, response.status_code, response.raw)


# make a request for data using the access token
def auth(current_access_token, endpoint):
    print("auth")
    try:
        print("trying access token")
        response = get_data(current_access_token, endpoint)
        return response  # return the response from the get_data function if the current access token is valid
    except:
        print("access token not valid")
        # if the current acccess code is not valid, get a new one with the refresh token
        current_refresh_token = get_latest_refresh_token(ssm_client)
        if current_refresh_token != None:
            # Make a POST request to the Fitbit API to exchange the refresh token for an access token
            headers = {
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": f"Basic {base64.b64encode(f'{FITBIT_CLIENT_ID}:{FITBIT_CLIENT_SECRET}'.encode('utf-8'))}",
            }
            data = {
                "grant_type": "refresh_token",
                "refresh_token": current_refresh_token,
            }
            response = requests.post(
                "https://api.fitbit.com/oauth2/token", headers=headers, data=data
            )

            # Check if the request was successful
            if response.status_code != 200:
                print("Error while requesting access token:", response.text)
                return {
                    "statusCode": 500,
                    "body": "Error while requesting access token",
                }

            # Extract the access token from the response
            access_token = response.json()["access_token"]
            print("Access token:", access_token)

            # Store the access token in parameter store
            store_access_token(ssm_client, access_token)

            # Store the refresh token in parameter store
            store_refresh_token(ssm_client, response.json()["refresh_token"])

            data = get_data(current_access_token, endpoint)
            return data  # return the response from the get_data function if the current access token is valid
        else:
            print("Refresh token not found in SSM Parameter Store")
            return {
                "statusCode": 500,
                "body": "Refresh token not found in SSM Parameter Store",
            }


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


if __name__ == "__main__":
    lambda_handler(None, None)
