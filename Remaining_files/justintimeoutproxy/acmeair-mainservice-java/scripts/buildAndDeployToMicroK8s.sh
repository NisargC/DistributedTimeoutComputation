# Copyright (c) 2018 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

MANIFESTS=manifests

cd "$(dirname "$0")"
cd ..
microk8s.kubectl delete -f ${MANIFESTS}
mvn clean package
docker build --pull -t acmeair-mainservice-java .
microk8s.kubectl apply -f ${MANIFESTS}

cd ../acmeair-authservice-java
microk8s.kubectl delete -f ${MANIFESTS}
mvn clean package
docker build --pull -t acmeair-authservice-java .
microk8s.kubectl apply -f ${MANIFESTS}

cd ../acmeair-bookingservice-java
microk8s.kubectl delete -f ${MANIFESTS}
mvn clean package
docker build --pull -t acmeair-bookingservice-java .
microk8s.kubectl apply -f ${MANIFESTS}

cd ../acmeair-customerservice-java
microk8s.kubectl delete -f ${MANIFESTS}
mvn clean package
docker build --pull -t acmeair-customerservice-java .
microk8s.kubectl apply -f ${MANIFESTS}

cd ../acmeair-flightservice-java
microk8s.kubectl delete -f ${MANIFESTS}
mvn clean package
docker build --pull -t acmeair-flightservice-java .
microk8s.kubectl apply -f ${MANIFESTS}


