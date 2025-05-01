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
            <title>Neta Aviv API Service</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    background-color: #f4f4f4;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }
                .container {
                    background-color: white;
                    padding: 40px;
                    border-radius: 10px;
                    box-shadow: 0 4px 10px rgba(0,0,0,0.1);
                    max-width: 500px;
                    text-align: center;
                }
                h2 {
                    color: #2c3e50;
                }
                p, pre {
                    color: #34495e;
                }
                pre {
                    background-color: #ecf0f1;
                    padding: 10px;
                    border-radius: 5px;
                    text-align: left;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Neta Aviv API Service</h2>
                <p>Status: ✅ Running</p>
                <p>Send a <strong>POST</strong> request to <code>/message</code></p>
                <p>Include the header: <code>Authorization</code></p>
                <p>And a JSON body like:</p>
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

