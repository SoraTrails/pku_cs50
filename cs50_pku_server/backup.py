from cs50 import SQL
import redis
import os
import subprocess
def is_float(s):
    s = str(s)
    if s.isdigit():
        return True
    if s.count('.')==1:
        sl = s.split('.')
        left = sl[0]
        right = sl[1]
        if left.isdigit() and right.isdigit():
            return True
    return False

class Task(object):
    def __init__(self):
        self.rcon = redis.StrictRedis(host='localhost', db=5)
        self.queue = 'task:prodcons:queue'
        self.db=SQL("sqlite:///speller.db")

    def listen_task(self):
        while True:
            task = self.rcon.blpop(self.queue, 0)[1]
            print("Task get")
            task=task.decode('utf-8').split()
            path=str(task[0])
            filename=str(task[1])
            md5=str(task[2])
            print(path, filename, md5)
            if not path or not filename or not md5:
                print("error")
                continue
            # print("pasring {} ...".format(os.path.join(path,filename)))
            # print("hash {} ...".format(md5))
            r=filename.split("_")
            if len(r) < 3:
                print("error2")
                continue
            stuid = r[0]
            name = r[1]
            try:
                res=subprocess.check_output("bash ./backup.sh {} {}".format(path,filename), shell=True)
                status = 0
                exe_time = res.decode('utf-8')
                if not is_float(exe_time):
                    status=4
            except subprocess.CalledProcessError as e:
                print("exit code {}".format(e.returncode))
                exe_time = 0
                status = e.returncode
            
            print("INFO SQL:INSERT INTO submit(stuid,name, exe_time,hash,status) VALUES({}, {}, {}, {},{})".format(stuid,name, exe_time, md5,status))
            self.db.execute("INSERT INTO submit(stuid,name, exe_time,hash,status) VALUES(:stuid, :name, :exe_time,:hash,:status)",
                stuid=stuid,name=name, exe_time=exe_time, hash=md5,status=status)
            

if __name__ == '__main__':
    print('listening task queue')
    Task().listen_task()
