# probbroker

Broker using probabilistic programming & Gen for prediction# 
The core of this code is from a Gen example: https://github.com/probcomp/Gen/tree/master/examples/gp_structure

The src folder is used in the official running JustinTimeout System.
.gitlab-ci.yml is used for CI/CD to build the Dockerfile for inclusion in the cluster.

model_development contains various experiments/use cases and data collected for analysis and model development.
use cases (currently about 50-120 minutes):
    high_low_cycle - repeated cycle of heavy load followed by lighter load (run on 3 nodes of GKE @ n1-standard-2)
    long_ramp - a continuously increasing load (run on 3 nodes of GKE @ n1-standard-2)
    random - series of random loads

Setup  InfluxDB For a Run
Required:
CREATE CONTINUOUS QUERY "cq_20s_max" ON "tracing" BEGIN SELECT max("duration") INTO "max_duration" FROM "span" GROUP BY time(20s), service_name END

Optional (or similar depending on what you are doing):
CREATE CONTINUOUS QUERY "cq_20s_mean" ON "tracing" BEGIN SELECT mean("duration") INTO "average_duration_20s" FROM "span" GROUP BY time(20s), service_name END
CREATE CONTINUOUS QUERY "cq_60s_mean" ON "tracing" BEGIN SELECT mean("duration") INTO "average_duration_60s" FROM "span" GROUP BY time(60s), service_name END
CREATE CONTINUOUS QUERY "cq_60s_max" ON "tracing" BEGIN SELECT max("duration") INTO "max_duration_60s" FROM "span" GROUP BY time(60s), service_name END

If needed - update retention policy:
alter RETENTION POLICY "tracing" ON "tracing" DURATION 4h REPLICATION 1 DEFAULT

run jmeter.sh in each folder to run the scenario.

To get raw data:
influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT "duration", "service_name" FROM "span"' -format 'csv' > raw_data_light.csv
influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT * FROM "span"' -format 'csv' > raw_data.csv

Downsamples Continuous Queries
influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT * FROM "max_duration_20s"' -format 'csv' > raw_max_20s.csv

influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT * FROM "average_duration_20s"' -format 'csv' > raw_avg_20s.csv
influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT * FROM "average_duration_60s"' -format 'csv' > raw_avg_60s.csv
influx -host 34.74.63.185 -database 'tracing'  -execute 'SELECT * FROM "max_duration_60s"' -format 'csv' > raw_max_60s.csv


see model_development/incremental.jl for examples of how to run analysis e.g. runpreds_longramp()

TODO/Future directions
1. Unify our experimental setup with what we are doing in the JustinTimeout system
2. Use Uncertainty to add multiplier for output - rather than fixed multiplier
3. Leave the always compute the answer behind and compute regularly and store the answer AND/OR determine how to incrementally update and iterate as new data arrives
4. Make it possible to compute the data from raw instead of relying on Continuous Queries
5. Compute predictions across various granularities and combine
6. Extract evidence of Change Points and offer alarms or trigger horizontal scaling