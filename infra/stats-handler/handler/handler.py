import json
import os

import ydb
import ydb.iam

driver = ydb.Driver(
    endpoint=os.getenv('YDB_ENDPOINT').split("/?database=")[0],
    database=os.getenv('YDB_ENDPOINT').split("/?database=")[1],
    credentials=ydb.iam.MetadataUrlCredentials(),
)
driver.wait(fail_fast=True, timeout=5)

pool = ydb.SessionPool(driver)

def execute_query(session, key, value):
    return session.transaction().execute(
        """
        UPSERT INTO stats (`object_id`, `stats`) VALUES (\"{}\", \"{}\");
        """.format(key, value),
        commit_tx=True,
        settings=ydb.BaseRequestSettings().with_timeout(3).with_operation_timeout(2)
    )

def handle(event, context):
    for message in event["messages"]:
        body_string = message["details"]["message"]["body"]

        if not body_string or not body_string.strip():
            print("Empty message body")
            continue

        body = json.loads(body_string)

        print("A message {} is received".format(body_string))
        pool.retry_operation_sync(execute_query, None, body["id"], body["stats"])

    return {
        'statusCode': 200,
        'body': True,
    }