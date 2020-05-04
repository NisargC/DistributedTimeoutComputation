FROM python:3
EXPOSE 5000
ADD broker.py /
ADD endpoints.config /
RUN pip install flask
RUN pip install APScheduler
RUN pip install multiprocess
RUN pip install requests

ENV FLASK_APP=broker.py
CMD ["flask", "run", "--host=0.0.0.0"]