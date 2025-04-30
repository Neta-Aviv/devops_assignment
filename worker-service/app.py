import os
import time
import boto3

sqs = boto3.client('sqs')
s3 = boto3.client('s3')

SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")
S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME")

def process_messages():
    while True:
        messages = sqs.receive_message(QueueUrl=SQS_QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=10)
        if 'Messages' in messages:
            for msg in messages['Messages']:
                content = msg['Body']
                filename = f"message-{int(time.time())}.txt"
                s3.put_object(Bucket=S3_BUCKET_NAME, Key=filename, Body=content.encode('utf-8'))

                # Delete message after processing
                sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
                print(f"Processed and saved: {filename}")
        else:
            print("No messages...")

        time.sleep(1)

if __name__ == "__main__":
    print("Starting worker...")
    process_messages()

