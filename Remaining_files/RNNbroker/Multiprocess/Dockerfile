FROM python:3
EXPOSE 5000
ADD broker.py /
ADD timeoutcomputation.py /
ADD endpoints.config /
RUN pip install tensorflow
RUN pip install keras
RUN pip install flask
RUN pip install APScheduler
RUN pip install multiprocess
RUN pip install influxdb
RUN pip install statistics
RUN pip install sklearn
RUN pip install numpy
RUN pip install matplotlib

ENV FLASK_APP=broker.py
CMD ["flask", "run", "--host=0.0.0.0"]