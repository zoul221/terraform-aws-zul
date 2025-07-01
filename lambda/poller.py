import boto3
import requests
import json
import os
import time
from requests.exceptions import RequestException

kinesis = boto3.client('kinesis')
stream_name = os.environ['STREAM_NAME']
google_api_key = os.environ['GOOGLE_API_KEY']

def lambda_handler(event, context):
    query = "restaurant in kajang"
    api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    max_retries = 3
    backoff_factor = 2

    # Retry logic
    for attempt in range(1, max_retries + 1):
        try:
            response = requests.get(api_url, params={"query": query, "key": google_api_key}, timeout=10)
            response.raise_for_status()
            data = response.json()

            results = data.get("results", [])
            print(f"[INFO] Retrieved {len(results)} places from Google Places.")

            for record in results:
                kinesis.put_record(
                    StreamName=stream_name,
                    Data=json.dumps(record),
                    PartitionKey="partition-key"
                )

            return {
                "statusCode": 200,
                "body": f"Successfully pushed {len(results)} records to Kinesis."
            }

        except RequestException as e:
            print(f"[WARNING] Attempt {attempt} failed: {e}")
            if attempt < max_retries:
                sleep_time = backoff_factor ** attempt
                print(f"[INFO] Retrying in {sleep_time} seconds...")
                time.sleep(sleep_time)
            else:
                print("[ERROR] Max retries reached. Aborting.")
                return {
                    "statusCode": 500,
                    "body": "Failed to retrieve data from Google Places API after multiple attempts."
                }

        except Exception as e:
            print(f"[ERROR] Unexpected error: {e}")
            return {
                "statusCode": 500,
                "body": "Unexpected error occurred."
            }
