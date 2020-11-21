
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")

using JuMP, GLPK, LinearAlgebra, PyPlot

include("structs.jl")
include("dataManager.jl")
include("JuMPModels.jl")
include("tools.jl")

const COST_OPEN_STATION = 1900000
const COST_BRIDGE = 28600000
const COST_NEW_LINE_PER_KM = 5900000
const COST_VEHICLES = 250000
const COST_MAINTENANCE_VEHICLES_PER_YEAR = 35000
const MAX_VEHICLES = 2
const MAX_CAPAVEHICLE = 20
const SPEED_VEHICLE = 20

const STOP_TIME_STATION = 3



function main()
    stations = getStations("stations.dat")
    townsites = getTownsites("townsites.dat",stations)
    h = getDensities(townsites)
    Z = Vector{Int}(undef,length(stations))
    for p in 1:length(stations)
        x,z = MCP_model_Lucas(stations,townsites,p,verbose=false)
        Z[p] = z
        println("x = ",x)
    end
    plot(Z)
    return Z
end

function jules(p::Int)
    stations = getStations("stations.dat")
    println(stations)
    townsites = getTownsites("townsites.dat",stations)
    println("townsites = ",townsites)

    h = getDensities(townsites)
    println("h = ",h)
    x,z = MCP_model_Lucas(stations,townsites,p,verbose=true)
    println("z = ",z)
    println("x = ",x)
end

function lucas()
    stations = getStations("stations.dat")
    townsites = getTownsites("townsites.dat", stations)

    return stations, townsites
end
