import os
import time
import logging
import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

sqs = boto3.client('sqs')
s3  = boto3.client('s3')

SQS_QUEUE_URL   = os.environ.get("SQS_QUEUE_URL")
S3_BUCKET_NAME  = os.environ.get("S3_BUCKET_NAME")

if not SQS_QUEUE_URL or not S3_BUCKET_NAME:
    logger.error("Missing SQS_QUEUE_URL or S3_BUCKET_NAME")
    raise SystemExit(1)

logger.info(f"SQS_QUEUE_URL={SQS_QUEUE_URL}")
logger.info(f"S3_BUCKET_NAME={S3_BUCKET_NAME}")

def process_messages():
    while True:
        try:
            resp = sqs.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=5,
                WaitTimeSeconds=10
            )
        except Exception as e:
            logger.error(f"Error receiving SQS messages: {e}")
            time.sleep(5)
            continue

        msgs = resp.get("Messages", [])
        if not msgs:
            logger.info("No messages...")
        for msg in msgs:
            body = msg["Body"]
            filename = f"message-{int(time.time())}.txt"
            try:
                s3.put_object(Bucket=S3_BUCKET_NAME, Key=filename, Body=body.encode('utf-8'))
                logger.info(f"Uploaded {filename} to S3")
            except Exception as e:
                logger.error(f"Failed to upload to S3: {e}")
                # do not delete from queue so it can retry
                continue

            # Only delete if upload succeeded
            try:
                sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
                logger.info(f"Deleted message {msg['MessageId']} from SQS")
            except Exception as e:
                logger.error(f"Failed to delete SQS message: {e}")

        time.sleep(1)

if __name__ == "__main__":
    logger.info("Starting worker...")
    process_messages()
