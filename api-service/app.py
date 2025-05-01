# api-service/app.py
import os
import boto3
from flask import Flask, request, jsonify

app = Flask(__name__)
ssm = boto3.client('ssm')
sqs = boto3.client('sqs')

SSM_TOKEN_NAME = os.environ.get("SSM_TOKEN_NAME")
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")

@app.route("/", methods=["GET"])
def root():
    return """
    <html>
        <head>
            <title>Check Point API Service</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    text-align: center;
                    margin-top: 100px;
                    background-color: #f0f4f8;
                    color: #333;
                }
                .container {
                    display: inline-block;
                    padding: 30px;
                    border: 1px solid #ccc;
                    border-radius: 10px;
                    background-color: #fff;
                    box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                }
                code {
                    background-color: #f9f9f9;
                    padding: 2px 4px;
                    border-radius: 4px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Welcome to the Check Point API Service</h1>
                <p>Status: <strong>Running</strong></p>
                <p>This service accepts POST requests at <code>/message</code></p>
                <p>Include an <code>Authorization</code> header and JSON body like:</p>
                <pre>{
  "message": "Hello from Neta!"
}</pre>
            </div>
        </body>
    </html>
    """, 200


@app.route("/message", methods=["POST"])
def send_message():
    incoming_token = request.headers.get("Authorization")
    if not incoming_token:
        return jsonify({"error": "Missing Authorization token"}), 401

    expected_token = ssm.get_parameter(Name=SSM_TOKEN_NAME, WithDecryption=True)['Parameter']['Value']
    if incoming_token != expected_token:
        return jsonify({"error": "Invalid token"}), 403

    data = request.get_json()
    message = data.get("message")
    if not message:
        return jsonify({"error": "Missing message body"}), 400

    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=message)
    return jsonify({"status": "Message sent to SQS"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

