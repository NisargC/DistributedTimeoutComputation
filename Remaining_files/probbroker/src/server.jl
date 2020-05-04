using HTTP
using Sockets
using Printf
#include("shared.jl")
include("incremental.jl")

# function getTimeout(req::HTTP.Request)
#
#     endpoints =  ["auth" , "booking", "flight", "customer"]
#     found = false
#     final = "4000"
#     println("HERE IS WHAT I GOT: ", req.target)
#     url = HTTP.URIs.queryparams(req.target)["/gettimeout?url"]
#
#      for endpoint ∈ endpoints
#           if occursin(endpoint, url)
#              z = run_predictions(1, string(endpoint,".default"), 600, 400)
#              z = max(1, z)
#              final = @sprintf("%i", z)
#              found =true
#              break
#           end
#       end
#       if found
#           println(final)
#           return HTTP.Response(200, final)
#      end
#     return HTTP.Response(400, "unsupported")
# end

println("DEBUG A")
#const ROUTER = HTTP.Router()
println("DEBUG B")
#HTTP.@register(ROUTER, "GET", "/*", getTimeout)

try
   print("Warmup : " , run_predictions(1, "booking.default", 600, 400))
catch e
   println("Error in warmup ", e)
end


println("DEBUG C ", getipaddr())
#HTTP.serve(ROUTER, getipaddr(), 5000)
HTTP.serve("0.0.0.0", 5000) do req::HTTP.Request
#HTTP.listen() do http
    #@show http.message
    #@show HTTP.header(http, "Content-Type")
    #req = http.request

    endpoints =  ["auth" , "booking", "flight", "customer"]
    found = false
    final = "4000"
    println("HERE IS WHAT I GOT: ", req.target)
    url = HTTP.URIs.queryparams(req.target)["/probtimeout?url"]
    #
     for endpoint ∈ endpoints
           if occursin(endpoint, url)
             z = run_predictions(1, string(endpoint,".default"), 600, 400)
             if isnothing(z) || z == Nothing
                 z = 999
             end
             z = max(1, z)
             final = @sprintf("%i", z)
             return HTTP.Response(final)
          end
      end

#    return HTTP.Response( "Hello World")
      return HTTP.Response(400, "Nope")



end
