FROM python:3
EXPOSE 7000
ADD timeoutcomputation.py /
RUN pip install matplotlib
RUN pip install tensorflow
RUN pip install keras
RUN pip install flask
RUN pip install APScheduler
RUN pip install influxdb
RUN pip install statistics
RUN pip install numpy

ENV FLASK_APP=timeoutcomputation.py
CMD ["flask", "run", "-p 7000", "--host=0.0.0.0"]
