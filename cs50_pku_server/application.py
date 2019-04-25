import os
import re
import redis
import hashlib
import logging
import datetime
import time
from cs50 import SQL
from flask import Flask, flash, redirect, render_template, request, session, url_for, send_from_directory
from flask_session import Session
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename
from helpers import apology, login_required, lookup, usd, check_stuid,Reversinator

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

# # Ensure responses aren't cached
@app.after_request
def after_request(response):
#     response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
#     response.headers["Expires"] = 0
#     response.headers["Pragma"] = "no-cache"
    return response

# Custom filter
# app.jinja_env.filters["usd"] = usd
app.jinja_env.auto_reload = True

# Configure session to use filesystem (instead of signed cookies)
app.config["SESSION_FILE_DIR"] = mkdtemp()
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

@app.route('/robots.txt')
def static_from_root():
    return send_from_directory(app.static_folder, request.path[1:])

# Configure CS50 Library to use SQLite database
db = SQL("sqlite:///speller.db")

pass_num={1:8,2:15,3:9,41:3,42:9,43:10,44:10}
status_list={0:"运行结果正确",1:"编译错误",2:"运行时错误",3:"结果错误",-1:"正在运行"}
hw4_list={41:"4.Hello",42:"4.Mario",43:"4.Cash",44:"4.Credit"}
colloge_list={
"1500012773":"信科",
"1500012883":"信科",
"1500012971":"信科",
"1500014922":"哲学",
"1500015140":"国关",
"1500015492":"经济",
"1500016249":"法学",
"1500018107":"元培",
"1500091102":"生科",
"1600012410":"地空",
"1600012915":"信科",
"1600013533":"环境",
"1600015446":"经济",
"1700011387":"物理",
"1700011785":"化学",
"1700011790":"化学",
"1700013206":"城环",
"1700092824":"光华",
"1800017717":"元培",
"1800017720":"元培",
"1800017852":"元培",
"1800022735":"软微",
"1800091815":"新闻",
"1800920576":"光华",
"1801213672":"信科",
"1802010793":"光华",
"1810301325":"医学",
"1810305201":"医学",
"1234567890":"test",
"1234567891":"test",
"1234567892":"test"
}
UPLOAD_FOLDER = os.environ.get("UPLOAD_FOLDER")
# UPLOAD_FOLDER = 'submited_works'
ALLOWED_EXTENSIONS = set(['zip'])
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 8 * 1024 * 1024

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

def get_time():
    i = datetime.datetime.now()
    return "{}/{}/{} {}:{}:{}".format(i.year, i.month, i.day, i.hour, i.minute, i.second)

@app.route("/")
def red():
    # app.logger.info(request.remote_addr+" GET /")
    time.sleep(2)
    return redirect("homework3")

@app.route("/hackathon")
def index():
    time.sleep(2)
    return redirect("homework3")

@app.route("/homework2")
def homework2():
    session["status"]="hw2"
    app.logger.info(request.remote_addr+" "+get_time()+" GET /homework2")
    rows = db.execute("SELECT stuid,name,time,hash,correct_num FROM submit where status=0 AND work=2 GROUP BY stuid HAVING MAX(time) ORDER BY correct_num DESC, time ASC")
    result=[]
    for res in rows:
        stuid=str(res["stuid"])
        colloge=colloge_list.get(stuid)
        if not colloge:
            colloge="Unknown"
        tmp=[stuid, colloge, res["name"], res["time"], res["hash"], res["correct_num"]]
        result.append(tmp)
    return render_template("homework2.html", result=result)

@app.route("/homework3")
def homework3():
    session["status"]="hw3"
    app.logger.info(request.remote_addr+" "+get_time()+" GET /homework3")
    result=[]
    ids = db.execute("select distinct stuid from submit where work=3")
    for id in ids:
        rows = db.execute("SELECT stuid,name,time,exe_time,hash,correct_num,status FROM submit where work=3 and stuid=:stuid ORDER BY correct_num desc, status asc, exe_time asc, time asc", stuid=id["stuid"])
        if rows:
            res=rows[0]
            stuid=str(res["stuid"])
            colloge=colloge_list.get(stuid)
            if not colloge:
                colloge="Unknown"
            status = status_list.get(res["status"])
            if not status:
                status="其他错误"
            if int(res["status"]) == 0:
                status_order=0
            else:
                status_order=1
            tmp=[stuid, colloge, res["name"],res["exe_time"],res["time"],res["hash"],int(res["correct_num"]),status,status_order]
            result.append(tmp)
    result.sort(key=lambda x: (-x[6], x[8], x[3], Reversinator(x[4])))
    return render_template("homework3.html", result=result)

@app.route("/homework4/<name>")
def homework4(name):
    dic={"hello":41,"mario":42,"cash":43,"credit":44}
    work = dic.get(name)
    if not work:
        return '<h1>Unknown homework</h1>', 400
    session["status"]=name[0].upper()+name[1:]
    app.logger.info(request.remote_addr+" "+get_time()+" GET /homework4/"+name)

    rows = db.execute("SELECT stuid,name,time,hash,correct_num FROM submit where status=0 AND work=:work GROUP BY stuid HAVING MAX(time) ORDER BY correct_num DESC, time ASC", work=work)
    result=[]
    for res in rows:
        stuid=str(res["stuid"])
        colloge=colloge_list.get(stuid)
        if not colloge:
            colloge="Unknown"
        tmp=[stuid,colloge, res["name"], res["time"], res["hash"], res["correct_num"]]
        result.append(tmp)
    return render_template("homework4.html", result=result, pass_num=pass_num.get(work), name=name)

@app.route("/query",methods=["GET", "POST"])
def query():
    session["status"]="query"
    if request.method == 'GET':
        app.logger.info(request.remote_addr+" "+get_time()+" GET /query")
        return render_template("query.html")
    else:
        app.logger.info(request.remote_addr+" "+get_time()+" POST /query")
        stuid = request.form.get("stuid")
        rows = db.execute("SELECT stuid,time,exe_time,hash,status,work,correct_num FROM submit WHERE submit.stuid=:stuid ORDER BY time DESC",stuid=stuid)
        result=[]
        for r in rows:
            # correct_num="\\"
            correct_num=r["correct_num"]
            exe_time="\\"
            status = status_list.get(r["status"])         
            if not status:
                status="其他错误"

            if r["status"] == 0:
                if r["work"] == 3:
                    exe_time=str(r["exe_time"])+"s"
                else:
                    if correct_num != pass_num[r["work"]]:
                        status="部分测试未通过"
            work=r["work"]
            if work >= 41 and work <= 44:
                work=hw4_list[r["work"]]
            tmp=[r["stuid"], work, exe_time, r["time"], r["hash"], correct_num, status]
            result.append(tmp)
        return render_template("queried.html", result=result)


@app.route("/about")
def about():
    session["status"]="about"
    app.logger.info(request.remote_addr+" "+get_time()+" GET /about")
    return render_template("about.html")

@app.route("/version", methods=["GET", "POST"])
def version():
    if request.method == 'POST':
        stuid = request.form.get("stuid")
        name = request.form.get("name")
        #TODO: check stuid & name (check_stuid realized);
        app.logger.info(request.remote_addr+" "+get_time()+" POST /version : {}_{}".format(stuid,name))
        return send_from_directory(UPLOAD_FOLDER ,"version", as_attachment=True)
    return '<h1>Bad Request</h1>', 400

@app.route("/update", methods=["GET", "POST"])
def update():
    if request.method == 'POST':
        stuid = request.form.get("stuid")
        name = request.form.get("name")
        app.logger.info(request.remote_addr+" "+get_time()+" POST /update : {}_{}".format(stuid,name))
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
            correct_num = request.form.get("correct_num")
            if not stuid or not stuname or not work:
                return '<h1>Bad Request</h1>', 400
            #TODO: check stuid & name
            # path = os.path.join(app.config['UPLOAD_FOLDER'], work, stuid+"_"+stuname)
            path = os.path.join(app.config['UPLOAD_FOLDER'], work, str(stuid))
            if not os.path.exists(path):
                os.makedirs(path)
            submitted=os.listdir(path)
            # filename=filename.replace(re.findall(r'(_[0-9]+.zip)', filename)[0], "_1.zip")
            filename="{}_{}_1.zip".format(stuid,work)
            if len(submitted) > 0:
                num=[]
                for p in submitted:
                    num.append(int(re.findall(r'_([0-9]+).zip', p)[0]))
                filename=filename.replace(re.findall(r'(_[0-9]+.zip)', filename)[0], "_"+str(max(num)+1)+".zip")
            if os.path.exists(os.path.join(path,filename)):
                return '<h1>Unknown error</h1>', 405
            file.save(os.path.join(path,filename))
            #TODO: log
            app.logger.info(request.remote_addr+" "+get_time()+" POST /upload : {}_homework_{}".format(stuid,work))
            # print("{}_{} submit hw{}".format(stuid, stuname, work))
            if int(work) in [2, 3, 41, 42, 43, 44]:
                f=open(os.path.join(path,filename),'rb')
                md5=hashlib.md5(f.read()).hexdigest()
                f.close()
                if int(work) == 3:
                    rcon.lpush(prodcons_queue, "{} {} {}".format(path, filename, md5))
                    app.logger.info(request.remote_addr+" "+get_time()+" INFO pasring : {}".format(os.path.join(path,filename)))
                    app.logger.info(request.remote_addr+" "+get_time()+" INFO hash : {}".format(md5))
                    db.execute("INSERT INTO submit(stuid, name, time,work, exe_time,hash,status,correct_num ) VALUES(:stuid,:name,datetime('now','+8 hour'),:work, 0,:hash,-1, :correct_num)",
                        stuid=stuid, name=stuname, work=int(work), hash=md5, correct_num=correct_num)
                else:
                    db.execute("INSERT INTO submit(stuid, name, time,work, exe_time,hash,status,correct_num ) VALUES(:stuid,:name,datetime('now','+8 hour'),:work, 0,:hash,0, :correct_num)",
                        stuid=stuid, name=stuname, work=int(work), hash=md5, correct_num=correct_num)
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


# TODO 是否需要按提交时间倒序排序
# TODO 姓名包含在文件名中带来的问题
