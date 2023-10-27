import base64
import json
import os

import boto3
import requests

def handle(event, context):
    session = boto3.session.Session()
    s3 = getS3Client(session)
    sqs = getSqsClient(session)

    for message in event["messages"]:
        bucket_id = message["details"]["bucket_id"]
        object_id = message["details"]["object_id"]

        key = bucket_id + "/" + object_id
        print("looking for object {}".format(key))

        if not object_id.endswith("jpg"):
            print("object {} is not a jpg file".format(key))
            continue

        file = s3.get_object(Bucket=bucket_id, Key=object_id)

        response = requests.post(
            url = "https://vision.api.cloud.yandex.net/vision/v1/batchAnalyze",
            headers = {
                "Content-Type": "application/json",
                "Authorization": "Bearer {}".format(context.token["access_token"])
            },
            json = {
                "folderId": os.environ["FOLDER_ID"],
                "analyze_specs": [{
                    "content": encode_file(file["Body"]).decode('utf-8'),
                    "features": [{
                        "type": "CLASSIFICATION",
                        "classificationConfig": {
                            "model": "moderation"
                        }
                    }]
                }]
            }
        )

        stats = json.loads(response.text)
        msg = json.dumps(obj = {
            "id": key,
            "stats": stats
        })

        print("sending data to a queue")

        sqs.send_message(MessageBody=msg, QueueUrl=os.environ["YC_QUEUE_URL"])

    return {
        'statusCode': 200,
        'body': json.dumps(
            {
                'event': event,
                'context': context,
            },
            default=vars,
        )
    }


def getS3Client(session):
    return session.client(service_name='s3', endpoint_url=os.environ["S3_ENDPOINT"])


def getSqsClient(session):
    return session.client(
        service_name='sqs',
        endpoint_url=os.environ["YC_QUEUE_ENDPOINT"],
        region_name=os.environ["AWS_DEFAULT_REGION"]
    )


def encode_file(file):
    file_content = file.read()
    return base64.b64encode(file_content)

if __name__ == "__main__":
    handle(None, None)
