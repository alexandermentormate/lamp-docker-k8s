from socket import gethostname, gethostbyname

from flask import Flask, jsonify, render_template, redirect

app = Flask(__name__)


def fetch_details():
    host_name = gethostname()
    host_ip = gethostbyname(host_name)
    return host_name, host_ip


@app.route("/")
def hello_world():
    return redirect("/details")


@app.route("/health")
def health():
    return jsonify(
        status="UP"
    )


@app.route("/details")
def details():
    host_name, host_ip = fetch_details()
    return render_template("index.html", HOST_NAME=host_name, HOST_IP=host_ip)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
