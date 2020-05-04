import random
from itertools import count
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import time
import os
import threading
import sys

data = [[], [], [], []]
fig, axs = plt.subplots(2, 2)
lock = threading.Lock()
titles = ['Auth', 'Booking', 'Customer', 'Flight']
client = 'yclient-7647dd9ddf-59vd5'
if len(sys.argv) > 1:
    client = sys.argv[1]
lines = []
for i in range(0, 4):
    #(axs.flat)[i].set_ylim([0, 1500])
    (axs.flat)[i].set_title(titles[i])
    (axs.flat)[i].set(xlabel='Time',
                      ylabel='Response Time (ms)')
    # (axs.flat)[i].label_outer()
    l, = (axs.flat)[i].plot_date([], [], linestyle='dashed', marker='None',label='P1 w/ L', color='b', lw=1, alpha=0.3)
    lines.append(l)
    l, = (axs.flat)[i].plot_date([], [], linestyle='solid', marker='None', label='P1', color='b', lw=1, alpha=1)
    lines.append(l)
    l, = (axs.flat)[i].plot_date([], [], linestyle='dashed', marker='None',label='P2 w/ L', color='red', lw=1, alpha=0.3)
    lines.append(l)
    l, = (axs.flat)[i].plot_date([], [], linestyle='solid', marker='None',label='P2', color='red', lw=1, alpha=1)
    lines.append(l)
    l, = (axs.flat)[i].plot_date([], [], label='A', color='black', marker='.', lw=0.5, alpha=0.6)
    lines.append(l)
handles, labels = (axs.flat)[0].get_legend_handles_labels()
fig.legend(handles, labels, loc='upper center', fancybox=True, ncol=5, shadow=True)


def copy_files():
    while(True):
        with lock:
            os.system('kubectl cp '+client+':/data_auth.csv ./data_auth.csv')
        time.sleep(5)
        with lock:
            os.system('kubectl cp '+client+':/data_booking.csv ./data_booking.csv')
        time.sleep(5)
        with lock:
            os.system('kubectl cp '+client+':/data_customer.csv ./data_customer.csv')
        time.sleep(5)
        with lock:
            os.system('kubectl cp '+client+':/data_flight.csv ./data_flight.csv')
        time.sleep(5)

def animate(j):
    try:
        with lock:
            data[0] = pd.read_csv('./data_auth.csv')
            data[1] = pd.read_csv('./data_booking.csv')
            data[2] = pd.read_csv('./data_customer.csv')
            data[3] = pd.read_csv('./data_flight.csv')

        for i in range(0, 4):
            x = [pd.to_datetime(time.strftime('%Y-%m-%d %H:%M:%S', time.localtime((int)(ts/1000))))
                for ts in data[i]['time'].values]
            y1 = data[i]['predicted'].values
            y2 = data[i]['actual'].values
            y3 = data[i]['predictedlat'].values
            y4 = data[i]['predicted1'].values
            y5 = data[i]['predictedlat1'].values

            lines[5*i].set_data(x, y3)
            lines[5*i+1].set_data(x, y1)
            lines[5*i+2].set_data(x, y5)
            lines[5*i+3].set_data(x, y4)
            lines[5*i+4].set_data(x, y2)
            plt.style.use('fivethirtyeight')
            plt.tight_layout()
            (axs.flat)[i].set_yscale('log')
            (axs.flat)[i].relim()
            (axs.flat)[i].autoscale_view()
        return lines
    except:
        return lines


x = threading.Thread(target=copy_files, daemon=True)
x.start()
ani = FuncAnimation(fig, animate, interval=5010, repeat=True)

plt.tight_layout()
plt.show()
