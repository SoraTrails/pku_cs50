from cs50 import SQL
import redis
import os

class Task(object):
    def __init__(self):
        self.rcon = redis.StrictRedis(host='localhost', db=5)
        self.queue = 'task:prodcons:queue'

    def listen_task(self):
        while True:
            task = self.rcon.blpop(self.queue, 0)[1]
            print("Task get")
            path=task[0]
            filename=task[1]
            md5=task[2]
            print("pasring {} ...".format(os.path.join(path,filename)))
            print("hash {} ...".format(md5))

if __name__ == '__main__':
    print('listening task queue')
    Task().listen_task()
