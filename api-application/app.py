"""Code for a flask API to showcase GET and POST methods"""
import os
from flask import jsonify, request, Flask, redirect, url_for

app = Flask(__name__)




@app.route("/")
def index():
    return "Hello, world!"


@app.route("/customuri", methods=["POST"])
def customuri():
    jsons = request.get_json()
    # return jsons
    key = jsons['key']
    return "Received POST request"

if __name__ == "__main__":
    app.run( host="0.0.0.0", port=5000)
