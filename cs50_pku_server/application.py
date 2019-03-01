import os
import re
import redis
import hashlib
import logging
from cs50 import SQL
from flask import Flask, flash, redirect, render_template, request, session, url_for, send_from_directory
from flask_session import Session
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename
from helpers import apology, login_required, lookup, usd, check_stuid

# Ensure environment variable is set
if not os.environ.get("API_KEY"):
    raise RuntimeError("API_KEY not set")
if not os.environ.get("UPLOAD_FOLDER"):
    raise RuntimeError("UPLOAD_FOLDER not set")

# Configure application
app = Flask(__name__)
app.secret_key = 'some_secret'

rcon = redis.StrictRedis(host='localhost', db=5)
prodcons_queue = 'task:prodcons:queue'

# Ensure templates are auto-reloaded
app.config["TEMPLATES_AUTO_RELOAD"] = True

# Ensure responses aren't cached
@app.after_request
def after_request(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Expires"] = 0
    response.headers["Pragma"] = "no-cache"
    return response

# Custom filter
# app.jinja_env.filters["usd"] = usd
app.jinja_env.auto_reload = True

# Configure session to use filesystem (instead of signed cookies)
app.config["SESSION_FILE_DIR"] = mkdtemp()
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

# Configure CS50 Library to use SQLite database
db = SQL("sqlite:///finance.db")

UPLOAD_FOLDER = os.environ.get("UPLOAD_FOLDER")
# UPLOAD_FOLDER = 'submited_works'
ALLOWED_EXTENSIONS = set(['zip'])
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 8 * 1024 * 1024

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

@app.route("/hackathon")
def index():
    app.logger.info(request.remote_addr+" GET /hackathon")
    return render_template("index.html")

# @app.route("/")
# def red():
#     return redirect("hackathon")

@app.route("/about")
def about():
    app.logger.info(request.remote_addr+" GET /about")
    return render_template("about.html")

@app.route("/version", methods=["GET", "POST"])
def version():
    if request.method == 'POST':
        stuid = request.form.get("stuid")
        name = request.form.get("name")
        #TODO: check stuid & name (check_stuid 语法上已实现);
        app.logger.info(request.remote_addr+" POST /version : {}_{}".format(stuid,name))
        return send_from_directory(UPLOAD_FOLDER ,"version", as_attachment=True)
    return '<h1>Bad Request</h1>', 400

@app.route("/update", methods=["GET", "POST"])
def update():
    if request.method == 'POST':
        stuid = request.form.get("stuid")
        name = request.form.get("name")
        app.logger.info(request.remote_addr+" POST /update : {}_{}".format(stuid,name))
        return send_from_directory(UPLOAD_FOLDER ,"pku_submit50.c", as_attachment=True)
    return '<h1>Bad Request</h1>', 400

@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == 'POST':
        file = request.files['file']
        if file and allowed_file(file.filename):
            # filename = secure_filename(file.filename)
            stuid = request.form.get("stuid")
            stuname = request.form.get("name")
            work = request.form.get("work")
            #TODO: check stuid & name
            path = os.path.join(app.config['UPLOAD_FOLDER'], work, stuid+"_"+stuname)
            if not os.path.exists(path):
                os.makedirs(path)
            submitted=os.listdir(path)
            # filename=filename.replace(re.findall(r'(_[0-9]+.zip)', filename)[0], "_1.zip")
            filename="{}_{}_{}_1.zip".format(stuid,stuname,work)
            if len(submitted) > 0:
                num=[]
                for p in submitted:
                    num.append(int(re.findall(r'_([0-9]+).zip', p)[0]))
                filename=filename.replace(re.findall(r'(_[0-9]+.zip)', filename)[0], "_"+str(max(num)+1)+".zip")
            if os.path.exists(os.path.join(path,filename)):
                return '<h1>Unknown error</h1>', 405
            file.save(os.path.join(path,filename))
            #TODO: log
            app.logger.info(request.remote_addr+" POST /upload : {}_{}_homework_{}".format(stuid,stuname,work))
            # print("{}_{} submit hw{}".format(stuid, stuname, work))
            if int(work) == 3:
                f=open(os.path.join(path,filename),'rb')
                md5=hashlib.md5(f.read()).hexdigest()
                f.close()
                rcon.lpush(prodcons_queue, "{} {} {}".format(path, filename, md5))
                app.logger.info(request.remote_addr+" INFO pasring : {}".format(os.path.join(path,filename)))
                app.logger.info(request.remote_addr+" INFO hash : {}".format(md5))
                # print("pasring {} ...".format(os.path.join(path,filename)))
                # print("hash {} ...".format(md5))
            return '<h1>Upload Succeeded</h1>', 200
        return '<h1>Bad File</h1>', 400
    return '<h1>Bad Request</h1>', 400

def errorhandler(e):
    """Handle error"""
    return apology(e.name, e.code)


# listen for errors
for code in default_exceptions:
    app.errorhandler(code)(errorhandler)


# TODO: 限制北大ip访问
