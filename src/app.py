import os
from socket import gethostname, gethostbyname

from flask import Flask, jsonify, render_template, redirect, request
from flask_pymongo import PyMongo

application = Flask(__name__)
application.config["MONGO_URI"] = 'mongodb://' \
        + os.environ['MONGODB_USERNAME'] \
        + ':' + os.environ['MONGODB_PASSWORD'] \
        + '@' + os.environ['MONGODB_HOSTNAME'] \
        + ':27017/' + os.environ['MONGODB_DATABASE']


mongo = PyMongo(application)
db = mongo.db


def fetch_details():
    host_name = gethostname()
    host_ip = gethostbyname(host_name)
    return host_name, host_ip


@application.route("/")
def hello_world():
    return redirect("/details")


@application.route("/health")
def health():
    return jsonify(
        status="UP"
    )


@application.route("/details")
def details():
    host_name, host_ip = fetch_details()
    return render_template("index.html", HOST_NAME=host_name, HOST_IP=host_ip)


@application.route('/todo')
def todo():
    _todos = db.todo.find()

    item = {}
    data = []
    for todo in _todos:
        item = {
            'id': str(todo['_id']),
            'todo': todo['todo']
        }
        data.append(item)

    return jsonify(
        status=True,
        data=data
    )


@application.route('/todo', methods=['POST'])
def createTodo():
    data = request.get_json(force=True)
    item = {
        'todo': data['todo']
    }
    db.todo.insert_one(item)

    return jsonify(
        status=True,
        message='To-do saved successfully!'
    ), 201


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    application.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
