FROM julia:1.4.0-buster

ENV JULIA_PATH /usr/local/julia
ENV PATH $JULIA_PATH/bin:$PATH


RUN julia -e "using Pkg; Pkg.add(PackageSpec(url=\"https://github.com/probcomp/Gen\"))" && \
    julia -e "using Pkg; Pkg.add(\"HTTP\")" && \
    julia -e "using Pkg; Pkg.add(PackageSpec(url=\"https://github.com/staticfloat/InfluxDB.jl\"))" && \
    julia -e "using Pkg; Pkg.add(\"Distributions\")" && \
    julia -e "using Pkg; Pkg.add(\"StatsBase\")" && \
    julia -e "using Pkg; Pkg.add(\"DataFrames\")" && \
    julia -e "using Pkg; Pkg.add(\"CSV\")" && \
    julia -e "using Pkg; Pkg.API.precompile()"

COPY src/* ./

CMD ["julia" , "server.jl"]
