using Gen
using Gen: get_child
import LinearAlgebra
import CSV
import Random
using Pkg
using Statistics: mean
using DataFrames
using InfluxDB
using Dates
using Printf
# TODO: figure out the correction for the probablity of picking the given node
# in the forward and backward proposal

#########################
# load data set #
#########################


function string2UTC(str::String, dform)
    date = tryparse(DateTime, str, dform)
    #date == nothing ? Missing : convert(Int, datetime2unix( date ) )
    date == nothing ? Missing : convert(Int, datetime2unix(date))
end

function get_current_data(secondsLookBack::Int64, endpoint::String, numPredicted::Int64)
    dform = DateFormat("yyyy-mm-ddTHH:MM:SSZ")
    server = InfluxServer("http://34.74.63.185:8086")
    #server = InfluxServer("http://aa46122d.ngrok.io:80")

    dbname = "tracing"
    lookBack = datetime2unix(Dates.now(Dates.UTC) - Second(secondsLookBack))

    #TODO attempt to filter based on startDate to limit how far back we look
    data = query(server, dbname,
        SELECT(;
            fields=["max", "time"],
            tags=["service_name"],
            measurements=["max_duration"],
            condition=string("\"service_name\" = '",endpoint, "' AND time > ",  @sprintf("%i",lookBack) , " ORDER BY time DESC")
        ),
    )[1]

    #filter out our blacklist
    data = filter(row -> !(row.service_name ∈ ["istio-mixer", "istio-ingressgateway"]), data)
    data[:time_seconds] = string2UTC.( data[:time] , dform)
    #remap
    data[:mean] = data[:max]

    #filter out too old data
    data = filter(row -> row.time_seconds > datetime2unix(Dates.now(Dates.UTC) - Second(secondsLookBack)), data)

    data = filter(row -> row.service_name == endpoint, data)

    if DataFrames.nrow(data) == 0
        println("---> NO DATA")
        return data
    end

    #TODO args -
    intervalSeconds = 10;


    data[:xs] = 3.14
    data[:ys] = 3.14

    for subdf in groupby(data, :service_name)
        #add our future times for prediction
        #NOTE this isn't aligned to our incoming data's x values for now...
        thetime = round(Int64, datetime2unix(Dates.now(Dates.UTC)))
        for i in 1:numPredicted
            newdf = DataFrame(time ="predicted", max = maximum(subdf.mean), mean=maximum(subdf.mean), service_name=subdf.service_name[1], time_seconds=thetime, xs=thetime, ys=round(Int64,maximum(subdf.mean/1000000.)))

            append!(data, newdf)

            thetime += intervalSeconds
        end
    end

    sort!(data, [:service_name, :time_seconds])

    data[:mean_millis] = data.mean / 1000000.
    data[:xs] = data.time_seconds * 1.
    data[:ys] = data.mean_millis / 1000000.

    for subdf in groupby(data, :service_name)


        #this next bit inherited from the example... leaving it in for now
        xs = subdf.xs
        ys = subdf.ys
        xs .-= minimum(xs) # set x minimum to 0.
        xs /= maximum(xs) # scale x so that maximum is at 1.
        ys .-= mean(ys) # set y mean to 0.
        ys *= 4 / (maximum(ys) - minimum(ys))# make it fit in the window [-2, 2]
        subdf[:xs] = xs;
        subdf[:ys] = ys;

        #show(subdf)

    end
    return data
end

################################
# abstract covariance function #
################################

"""
Node in a tree representing a covariance function
"""
abstract type Node end
abstract type LeafNode <: Node end
abstract type BinaryOpNode <: Node end

"""
Constant kernel
"""
struct Constant <: LeafNode
    param::Float64
end

eval_cov(node::Constant, x1, x2) = node.param

function eval_cov_mat(node::Constant, xs::Vector{Float64})
    n = length(xs)
    fill(node.param, (n, n))
end


"""
Linear kernel
"""
struct Linear <: LeafNode
    param::Float64
end

eval_cov(node::Linear, x1, x2) = (x1 - node.param) * (x2 - node.param)

function eval_cov_mat(node::Linear, xs::Vector{Float64})
    xs_minus_param = xs .- node.param
    xs_minus_param * xs_minus_param'
end


"""
Squared exponential kernel
"""
struct SquaredExponential <: LeafNode
    length_scale::Float64
end

function eval_cov(node::SquaredExponential, x1, x2)
    exp(-0.5 * (x1 - x2) * (x1 - x2) / node.length_scale)
end

function eval_cov_mat(node::SquaredExponential, xs::Vector{Float64})
    diff = xs .- xs'
    exp.(-0.5 .* diff .* diff ./ node.length_scale)
end


"""
Periodic kernel
"""
struct Periodic <: LeafNode
    scale::Float64
    period::Float64
end

function eval_cov(node::Periodic, x1, x2)
    freq = 2 * pi / node.period
    exp((-1/node.scale) * (sin(freq * abs(x1 - x2)))^2)
end

function eval_cov_mat(node::Periodic, xs::Vector{Float64})
    freq = 2 * pi / node.period
    abs_diff = abs.(xs .- xs')
    exp.((-1/node.scale) .* (sin.(freq .* abs_diff)).^2)
end


"""
Plus node
"""
struct Plus <: BinaryOpNode
    left::Node
    right::Node
end

Plus(left, right) = Plus(left, right)

function eval_cov(node::Plus, x1, x2)
    eval_cov(node.left, x1, x2) + eval_cov(node.right, x1, x2)
end

function eval_cov_mat(node::Plus, xs::Vector{Float64})
    eval_cov_mat(node.left, xs) .+ eval_cov_mat(node.right, xs)
end


"""
Times node
"""
struct Times <: BinaryOpNode
    left::Node
    right::Node
end

Times(left, right) = Times(left, right)

function eval_cov(node::Times, x1, x2)
    eval_cov(node.left, x1, x2) * eval_cov(node.right, x1, x2)
end

function eval_cov_mat(node::Times, xs::Vector{Float64})
    eval_cov_mat(node.left, xs) .* eval_cov_mat(node.right, xs)
end


"""
Compute a covariance matrix by evaluating the function on each pair of inputs
"""
function compute_cov_matrix(covariance_fn::Node, noise, xs)
    n = length(xs)
    cov_matrix = Matrix{Float64}(undef, n, n)
    for i=1:n
        for j=1:n
            cov_matrix[i, j] = eval_cov(covariance_fn, xs[i], xs[j])
        end
        cov_matrix[i, i] += noise
    end
    return cov_matrix
end

"""
Compute a covariance function by recursively computing covariance matrices
"""
function compute_cov_matrix_vectorized(covariance_fn, noise, xs)
    n = length(xs)
    eval_cov_mat(covariance_fn, xs) + Matrix(noise * LinearAlgebra.I, n, n)
end

function compute_log_likelihood(cov_matrix::Matrix{Float64}, ys::Vector{Float64})
    n = length(ys)
    logpdf(mvnormal, ys, zeros(n), cov_matrix)
end

"""
Return predictive log likelihood on new input values
"""
function predictive_ll(covariance_fn::Node, noise::Float64,
                       xs::Vector{Float64}, ys::Vector{Float64},
                       new_xs::Vector{Float64}, new_ys::Vector{Float64})
    (conditional_mu, conditional_cov_matrix) = compute_predictive(
        covariance_fn, noise, xs, ys, new_xs)
    Gen.logpdf(mvnormal, new_ys, conditional_mu, conditional_cov_matrix)
end

function compute_predictive(covariance_fn::Node, noise::Float64,
                            xs::Vector{Float64}, ys::Vector{Float64},
                            new_xs::Vector{Float64})
    n_prev = length(xs)
    n_new = length(new_xs)
    means = zeros(n_prev + n_new)
    cov_matrix = compute_cov_matrix(covariance_fn, noise, vcat(xs, new_xs))
    cov_matrix_11 = cov_matrix[1:n_prev, 1:n_prev]
    cov_matrix_22 = cov_matrix[n_prev+1:n_prev+n_new, n_prev+1:n_prev+n_new]
    cov_matrix_12 = cov_matrix[1:n_prev, n_prev+1:n_prev+n_new]
    cov_matrix_21 = cov_matrix[n_prev+1:n_prev+n_new, 1:n_prev]
    @assert cov_matrix_12 == cov_matrix_21'
    mu1 = means[1:n_prev]
    mu2 = means[n_prev+1:n_prev+n_new]
    conditional_mu = mu2 + cov_matrix_21 * (cov_matrix_11 \ (ys - mu1))
    conditional_cov_matrix = cov_matrix_22 - cov_matrix_21 * (cov_matrix_11 \ cov_matrix_12)
    conditional_cov_matrix = 0.5 * conditional_cov_matrix + 0.5 * conditional_cov_matrix'
    (conditional_mu, conditional_cov_matrix)
end

"""
Predict output values for some new input values
"""
function predict_ys(covariance_fn::Node, noise::Float64,
                    xs::Vector{Float64}, ys::Vector{Float64},
                    new_xs::Vector{Float64})
    (conditional_mu, conditional_cov_matrix) = compute_predictive(
        covariance_fn, noise, xs, ys, new_xs)
    mvnormal(conditional_mu, conditional_cov_matrix)
end

function compute_mse(covariance_fn, noise, xs_train, ys_train, xs_test, ys_test)
    (conditional_mu, _) = compute_predictive(covariance_fn, noise, xs_train, ys_train, xs_test)
    mean(sum((conditional_mu .- ys_test) .^ 2))
end

const CONSTANT = 1 # 0.2
const LINEAR = 2 # 0.2
const SQUARED_EXP = 3 # 0.2
const PERIODIC = 4 # 0.2
const PLUS = 5 # binary 0.1
const TIMES = 6 # binary 0.1
const BINARY_OPS = Set{Int}([PLUS, TIMES])

const node_dist = Float64[0.2, 0.2, 0.2, 0.2, 0.1, 0.1]

const node_type_to_num_children = Dict(
    CONSTANT => 0,
    LINEAR => 0,
    SQUARED_EXP => 0,
    PERIODIC => 0,
    PLUS => 2,
    TIMES => 2)

const max_branch = 2

@gen function pick_random_node(node::Node, cur::Int, depth::Int)
    if isa(node, LeafNode)
        (cur, depth)
    elseif @trace(bernoulli(0.5), :done => depth)
        (cur, depth)
    elseif @trace(bernoulli(0.5), :recurse_left => cur)
        @trace(pick_random_node(node.left, get_child(cur, 1, max_branch), depth+1))
    else
        @trace(pick_random_node(node.right, get_child(cur, 2, max_branch), depth+1))
    end
end
