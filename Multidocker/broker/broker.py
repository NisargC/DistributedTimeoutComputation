"""The broker is responsible for providing a rest api which can be used to get the most recently predicted endpoint
(collected from endpoints.config).
The computation for various endpoints is done in parallel and multiprocess sync is
done here """

__version__ = '1.4'
__author__ = 'Nisarg Chokshi'

from datetime import datetime, timedelta
from flask import Flask, request, abort
from apscheduler.schedulers.background import BackgroundScheduler
from multiprocessing import Process, Manager
import math
import requests
import time


# This method is called in the background to compute timeouts
def init():
    print("Recomputing values", flush=True)
    start = datetime.now()
    text = open('endpoints.config', 'r+')
    content = text.read()
    text.close()

    strings = content.split('\n')

    manager = Manager()
    return_dict = manager.dict()
    for i in strings:
        return_dict[i] = dur_mean

    generate_request(strings, return_dict)
    for i in strings:
        if i in dict:
            return_dict[i] = float(return_dict[i])
            if return_dict[i] > 5 * dict[i]:
                dict[i] = dict[i] * 2
            else:
                dict[i] = return_dict[i]
        else:
            dict[i] = return_dict[i]
    job.modify(next_run_time=(datetime.now() + timedelta(seconds=5)))
    end = datetime.now() - start
    print("Computation runtime: " + str(end), flush=True)
    print(dict, flush=True)


sched = BackgroundScheduler(daemon=True)
job = sched.add_job(init, 'interval', minutes=10)
sched.start()

app = Flask(__name__)

# Default timeout values
dur_mean = 100000000
dur_stddev = 100000000
dict = {}
server = []


# This method is responsible for calling the various workers registered to the system and aggregating their results back
def generate_request(strings, return_dict):
    print(server, flush=True)
    manager = Manager()
    return_list = manager.list()

    i = 0
    while True:
        processes = []
        if not server:
            print("No workers registered. Call /register from worker", flush=True)
            time.sleep(2)
            break
        for ip in server:
            p = Process(target=call_compute, args=(ip, strings.__getitem__(i), return_dict, return_list))
            processes.append(p)
            p.start()
            i += 1
            if len(server) == 0:
                break
            if i == len(strings):
                break
        for process in processes:
            process.join()
        for i in return_list:
            unregisterip(i)
        if i == len(strings):
            break
        if len(server) == 0:
            break


# This method is responsible for calling the worker pods for timeout computation and handling various failures
def call_compute(ip, url, return_dict, return_list):
    try:
        r = requests.get('http://' + ip + ':7000/computetimeout?url=' + url)
        print("Received response from " + ip + " with status code " + str(r.status_code), flush=True)
        if r.status_code != 200:
            return_dict[url] = dict[url]
        else:
            return_dict[url] = r.text
    except requests.exceptions.ConnectionError as e:
        return_list.append(ip)
        print("Caught a connection error", flush=True)
        print("Connection error: ", e, flush=True)
    except requests.exceptions.Timeout as errt:
        return_list.append(ip)
        print("Caught a timeout error", flush=True)
        print("Timeout Error:", errt, flush=True)
    except Exception as err:
        return_list.append(ip)
        print("Caught an error", flush=True)
        print("Error:", err, flush=True)


# Worker pods call this endpoint to deregister themselves for timeout computation.
# Sample usage: http://127.0.0.1:5000/unregister
@app.route('/unregister', methods=['GET'])
def unregister():
    if str(request.remote_addr) not in server:
        return str(0)
    server.remove(str(request.remote_addr))
    print("Removed worker " + request.remote_addr, flush=True)
    print("Remaining registered workers are " + str(server), flush=True)
    return str(0)


# Programmatic way to deregister workers if the requests to them times out.
def unregisterip(ip):
    if str(ip) in server:
        server.remove(str(ip))
        print("Removed worker " + ip, flush=True)
        print("Remaining registered workers are " + str(server), flush=True)
        return str(0)
    return str(0)


# Potential worker pods call this endpoint to register themselves for timeout computation.
# Sample usage: http://127.0.0.1:5000/register
@app.route('/register', methods=['GET'])
def register():
    if str(request.remote_addr) in server:
        return str(0)
    server.append(str(request.remote_addr))
    print("Registered workers are " + str(server), flush=True)
    return str(0)


# Clients can call this to get a list of urls the server knows about
# Sample usage: http://127.0.0.1:5000/getendpoints
@app.route('/getendpoints', methods=['GET'])
def getKeys():
    print(list(dict.keys()))
    return str(list(dict.keys()))


# This is the endpoint exposed to the rest of the system where clients connect to get the latest computed timeout for
# the endpoints configured.
# Sample usage: http://127.0.0.1:5000/gettimeout?url=customer
@app.route('/gettimeout', methods=['GET'])
def gettimeoutvalue():
    url = request.args['url']
    if len(dict) > 0:
        if url in dict:
            if dict[url] == dur_mean:
                return str(int(dict[url] / 1000000))
            x = dict[url]
            x = float(x)
            if x > 5:
                x = x + x / 10
            else:
                x = x + 1
            return str(math.ceil(x))
        else:
            abort(422, description="Endpoint Invalid")
    else:
        print("Initialization not completed yet", flush=True)
        return str(int(dur_mean / 1000000))


# If we're running in stand alone mode, run the application
if __name__ == '__main__':
    init()
    app.run(debug=True, use_reloader=False, host='0.0.0.0')
if __name__ != '__main__':
    init()
