justintimeoutproxy 

All of the acmeair directories are pulled from the IBM fork of AcmeAir.  I put in a few small fixes.

The .gitlab-ci.yml builds all of the acme Docker containers and pushes them to Gitlab's built in Docker registry.
(I also wrote .gitlab-ci.yml for Yash's client.)

The entire Kubernetes system is defined in acmeair-mainservice-java/manifests-istio
  "deploy-acmeair-istio.yml" defines the entire Kubernetes deployments for AcmeAir, Our Brokers and Services, and Yash's client.
  "jaeger-all-in-one-template.yml" defines the customized Jaeger setup that dumps data into InfluxDB.

TODO
1. Extract All Response data from Influx directly instead of relying on the Python sampling
2. Write an analysis program that accepts the Python sampler data (.csv) + Raw data to automatically compute the underprediction percentage and RMSE (based on full Raw data)


Steps To Use:

1. Establish a Kubernetes Cluster
2. Build Docker Images and push to a registry - example GitLab CI build definition available as .gitlab-ci.yml
  1. Update images in acmeair-mainservice-java/manifests-istio/deploy-acmeair-istio.yml to point at your registry
  2. Add your registry secret and update registry credential in acmeair-mainservice-java/manifests-istio/deploy-acmeair-istio.yml
3. Activate Istio - on GKE it's a checkbox when you create the Cluster - Azure, AWS may be different.  Istio also offers an Operator here: https://istio.io/docs/setup/getting-started/

4. Activate Jaeger/Influx
`kubectl apply -f acmeair-mainservice-java/manifests-istio/jaeger-all-in-one-template.yml`
!Note - In a production environment, don't use the All-In-One

5. Activate Acme-Air + Our Brokers and Client
`kubectl apply -f acmeair-mainservice-java/manifests-istio/deploy-acmeair-istio.yml`

6. ProbBroker needs a CQ as below setup on Influx - 
Once Influx comes up, login and run the below 
`CREATE CONTINUOUS QUERY "cq_20s_max" ON "tracing" BEGIN SELECT max("duration") INTO "max_duration" FROM "span" GROUP BY time(20s), service_name END`

7. Steps to setup RNNbroker can be found in the README files inside RNNbroker.

8. Run a JMeter script of your choice while YClient Deployment is scaled to 1 replica. See results/* for examples
  1. Note - place the `results/jmeter/acmeair-jmeter-2.0.0-SNAPSHOT.jar` in your JMeter into the lib/ext for your JMeter installation directory
  
9. To manually rebuild and run acme air client with the client shim locally, refer the README in client and acme-client directories

10. Run `python3 plot.py` from (justintimoutclient repo!) src/main/resources on your local node to gather the performance data and visualize.