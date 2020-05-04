"""The broker is responsible for providing a rest api which can be used to get the most recently predicted endpoint
(collected from endpoints.config).
The computation for various endpoints is done in parallel and multiprocess sync is
done here """

__version__ = '1.4'
__author__ = 'Nisarg Chokshi'

from datetime import datetime, timedelta

from flask import Flask, request, abort
from influxdb import InfluxDBClient
import keras.backend.tensorflow_backend as tb
from statistics import mean, stdev
from timeoutcomputation import computeTimeout
from apscheduler.schedulers.background import BackgroundScheduler
from multiprocessing import Process, Manager
import math
import os

tb._SYMBOLIC_SCOPE.value = True

try:
    influx_ip = os.environ['INFLUX_IP']
except KeyError:
    print('Database url not found, provide using INFLUX_IP', flush=True)
    quit()

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
    processes = []

    for i in strings:
        p = Process(target=compute, args=(i, return_dict))
        processes.append(p)
        p.start()
        print('New process spawned with pid = ' + str(p.pid), flush=True)

    for process in processes:
        process.join()
    for i in strings:
        if i in dict:
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

window_size = 48
dummy = False

# Default timeout values
dur_mean = 100000000
dur_stddev = 100000000
dict = {}


# The method responsible to connect to InfluxDB with the url requested and call computation to compute timeout.
def compute(url, return_dict):
    now = datetime.now() - timedelta(hours=window_size)

    current_time = now.strftime("%Y-%m-%dT%H:%M:%SZ")

    if not dummy:
        dbclient = InfluxDBClient(host=influx_ip,
                                  username='root', password='root',
                                  port=8086, database='tracing'
                                  # path='query'
                                  )

        result = dbclient.query(
            'SELECT "duration" FROM span'
            ' WHERE time>={} AND "http.url"=~{} ORDER BY time DESC LIMIT 5000'.format("'" + current_time + "'",
                                                                                      "/" + url + "/")
            # ' WHERE "http.url"=~{}'.format("/" + url + "/")
        )
        points = result.get_points()
        duration_list = []
        for item in points:
            duration_list.append(item['duration'])
        duration_list = duration_list[-5000:]
        duration_list.reverse()
    else:
        duration_list = [17646837000, 17839743000, 34143000, 33931000, 234000, 216000, 60000, 66000, 17804321000,
                         17611580000, 1741000, 24739000, 221000, 71000, 263000, 101000, 1437955000, 1436859000,
                         1437041000,
                         1544000, 1436056000, 1316000, 225000, 84000, 149000, 57000, 19590000, 19058000, 17952000,
                         17492000,
                         43757000, 42842000, 43796000, 42913000, 46676000, 45713000, 46730000, 45178000, 1355301000,
                         3963000, 638000, 278000, 1350108000, 4448000, 437000, 155000, 1176911000, 1176182000, 18088000,
                         19341000, 17512000, 18706000, 1434000, 252000, 92000, 22628000, 21955000, 26242000, 25349000,
                         13799000, 13288000, 14554000, 14059000, 27792000, 26671000, 22654000, 21679000, 427179000,
                         426257000, 8680000, 429286000, 427733000, 7813000, 1076000, 288000, 664000, 90000, 15531262000,
                         15399801000, 15399008000, 15529870000, 17803000, 17819000, 17307000, 17357000, 34735000,
                         33907000,
                         37895000, 37018000, 30642000, 29734000, 2634000, 461000, 163000, 38465000, 37529000, 39977000,
                         39047000, 22902000, 22335000, 38261000, 3046000, 432000, 148000, 34144000, 2741000, 482000,
                         156000,
                         35390000, 3409000, 840000, 309000, 30972000, 18420000, 17308000, 18995000, 18229000, 26823000,
                         25878000, 2694000, 444000, 157000, 13335000, 12759000, 14172000, 13668000, 1073000, 195000,
                         69000,
                         10893000, 10341000, 166167000, 1298000, 154000, 52000, 164150000, 1090000, 148000, 54000,
                         15332000,
                         14499000, 12803000, 11955000, 9819000, 9289000, 8903000, 7954000, 55295000, 54439000, 1441000,
                         273000, 91000, 67501000, 65623000, 60648000, 58005000, 1325069000, 2477000, 264000, 86000,
                         1321684000, 5013000, 463000, 166000, 80593000, 61021000, 124386000, 122367000, 2616000, 375000,
                         152000, 1261536000, 1259354000, 1253753000, 1252967000, 29196000, 28411000, 15715000, 14713000,
                         36755000, 36126000, 23671000, 22975000, 36717000, 35831000, 39641000, 2991000, 224000, 73000,
                         35777000, 481000, 370000, 19893000, 18659000, 570000, 351000, 483000, 327000, 27034000,
                         8912000,
                         26278000, 8315000, 50240000, 49610000, 942577000, 941419000, 2645200000, 2644649000, 119938000,
                         119375000, 7293000, 6733000, 1363236000, 1362748000, 435065000, 434523000, 95663000, 95061000,
                         11304000, 10693000, 9837000, 9014000, 5301000, 4862000, 46318000, 45025000, 6345000, 5707000,
                         40628000, 39527000, 70100000, 67725000, 17085000, 16580000, 32906000, 31951000, 12324000,
                         11852000,
                         14629000, 14099000, 13699000, 13161000, 19234000, 18697000, 15107000, 1041000, 253000, 87000,
                         13554000, 7913000, 6992000, 16120000, 15560000, 5796000, 5310000, 16438000, 15815000, 1150000,
                         205000, 55000, 73011000, 72440000, 23490000, 22958000, 1181000, 176000, 59000, 4061000,
                         3653000,
                         12374000, 8712000, 7970000, 919000, 180000, 55000, 6538000, 1059000, 235000, 116000, 27462000,
                         26225000, 3230000, 819000, 299000, 59447000, 58870000, 875000, 144000, 50000, 18013000,
                         17490000,
                         1059000, 189000, 73000, 17804000, 1216000, 163000, 55000, 16045000, 887000, 156000, 55000,
                         28056000, 27026000, 12286000, 11640000, 33527000, 32618000, 36460000, 35159000, 32673000,
                         31773000,
                         20209000, 19524000, 37857000, 36757000, 13159000, 12641000, 39992000, 2475000, 506000, 148000,
                         36507000, 7114000, 6518000, 1139000, 235000, 99000, 15213000, 13706000, 15367000, 14088000,
                         16872000, 3260000, 797000, 295000, 12536000, 75363000, 74865000, 20717000, 20171000, 74110000,
                         72910000, 1639000, 315000, 102000, 18350000, 17766000, 19900000, 19246000, 16792000, 16208000,
                         1192000, 247000, 80000, 16984000, 16085000, 14896000, 14357000, 16307000, 15739000, 15550000,
                         15009000, 7262000, 919000, 180000, 65000, 5831000, 11666000, 11175000, 12088000, 11638000,
                         12396000, 799000, 147000, 49000, 11095000, 829000, 201000, 57000, 4504000, 4126000, 3999000,
                         3577000, 20386000, 2579000, 599000, 258000, 16479000, 2722000, 540000, 191000, 4441000,
                         3902000,
                         73884000, 72705000, 15217000, 14645000, 1301000, 259000, 105000, 55096000, 54623000, 16025000,
                         15269000, 30671000, 28904000, 3123000, 658000, 260000, 15025000, 14561000, 22486000, 20896000,
                         2441000, 529000, 179000, 12629000, 12226000, 34427000, 33469000, 11906000, 11448000, 72539000,
                         71160000, 14122000, 814000, 161000, 57000, 12866000, 28386000, 27290000, 10996000, 10560000,
                         35504000, 34656000, 3048000, 764000, 321000, 4537000, 4088000, 18700000, 18126000, 18986000,
                         17814000, 2887000, 672000, 215000, 11137000, 9647000, 80246000, 79365000, 4987000, 646000,
                         241000,
                         12510000, 11974000, 15693000, 14400000, 28626000, 27728000, 73354000, 3239000, 731000, 247000,
                         69043000, 3094000, 735000, 305000, 13185000, 12720000, 1029000, 180000, 62000, 35689000,
                         2592000,
                         517000, 174000, 31945000, 2704000, 610000, 246000, 25687000, 24676000, 31061000, 2553000,
                         521000,
                         175000, 27581000, 11483000, 10905000, 32131000, 31324000, 33719000, 32744000, 36473000,
                         35553000,
                         26612000, 25701000, 17257000, 15952000, 20202000, 15425000, 14204000, 13039000, 5827000,
                         5359000,
                         1054000, 253000, 59000, 60620000, 1800000, 390000, 112000, 58102000, 9196000, 8660000,
                         21689000,
                         2768000, 454000, 145000, 17197000]
    i = len(duration_list)
    if i != 0:
        dur_mean = mean(duration_list)
        dur_stddev = stdev(duration_list)
    else:
        dur_mean = 100000000
        dur_stddev = 100000000

    if i < 50:
        print("Values too less to get proper predictions from model", flush=True)
        predicted_val = dur_mean + 2 * dur_stddev
    else:
        regularized_data = [(elem - dur_mean) / 100000000 for elem in duration_list]
        print("Computing timeout for " + str(url))
        predicted_val = (computeTimeout(regularized_data) * 100000000) + dur_mean

    print("Predicted value from RNN for " + url + " endpoint: " + str(predicted_val / 1000000) + "ms", flush=True)
    print("99th percentile value: " + str((dur_mean + 2 * dur_stddev) / 1000000) + "ms", flush=True)

    if predicted_val < 0:
        return_dict[url] = (((dur_mean + 2 * dur_stddev) / 1000000) + (predicted_val / 1000000)) / 2
        while return_dict[url] < 0:
            return_dict[url] = (((dur_mean + 2 * dur_stddev) / 1000000) + (return_dict[url])) / 2
    else:
        return_dict[url] = predicted_val / 1000000


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
            if dict[url] == 100000000:
                return str(int(dict[url] / 1000000))
            x = dict[url]
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
