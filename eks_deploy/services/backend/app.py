import os
from bson import ObjectId
from socket import gethostname, gethostbyname

from flask import Flask, jsonify, render_template, request
from flask_cors import CORS
from pymongo import MongoClient

application = Flask(__name__)
CORS(application)
application.config["MONGO_URI"] = "mongodb://" \
        + os.environ["MONGODB_USERNAME"] \
        + ":" + os.environ["MONGODB_PASSWORD"] \
        + "@" + os.environ["MONGODB_HOSTNAME"] \
        + ":" + os.environ["MONGODB_PORT"] + "/"


client = MongoClient(application.config["MONGO_URI"])
db = client[os.environ["MONGODB_DATABASE"]]


def fetch_details():
    host_name = gethostname()
    host_ip = gethostbyname(host_name)
    return host_name, host_ip


@application.route("/health")
def health():
    return jsonify(
        status="UP"
    )


@application.route("/details")
def details():
    host_name, host_ip = fetch_details()
    return render_template("index.html", HOST_NAME=host_name, HOST_IP=host_ip)


@application.route("/books", methods=["GET", "POST"])
def all_books():
    response_object = {
        "status": "success",
        "container_id": os.uname()[1]
    }
    if request.method == "POST":
        post_data = request.get_json()
        new_book = {
            "title": post_data.get("title"),
            "author": post_data.get("author"),
            "read": post_data.get("read")
        }
        db.books.insert_one(new_book)
        response_object["message"] = "Book added!"
    else:
        response_object["books"] = [{
                "id": str(book["_id"]),
                "title": book["title"],
                "author": book["author"],
                "read": book["read"],
            } for book in db.books.find()]
    return jsonify(response_object)


@application.route("/books/ping", methods=["GET"])
def ping():
    return jsonify({
        "status": "success",
        "message": "pong!",
        "container_id": os.uname()[1]
    })


@application.route("/books/<book_id>", methods=["PUT", "DELETE"])
def single_book(book_id):
    book_id = ObjectId(book_id)
    response_object = {
      "status": "success",
      "container_id": os.uname()[1]
    }
    if request.method == "PUT":
        post_data = request.get_json()
        db.books.update_one({"_id": book_id},  {"$set": {
            "title": post_data.get("title"),
            "author": post_data.get("author"),
            "read": post_data.get("read"),
        }})
        response_object["message"] = "Book updated!"
    if request.method == "DELETE":
        db.books.delete_one({"_id": book_id})
        response_object["message"] = "Book removed!"
    return jsonify(response_object)


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    application.run(host="0.0.0.0", port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
