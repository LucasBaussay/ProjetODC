
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")


using JuMP, GLPK, LinearAlgebra, PyPlot

include("structs.jl")
include("dataManager.jl")
include("JuMPModels.jl")

const COSTOPENSTATION = 1900000
const COSTBRIDGE = 28600000
const COSTNEWLINEPERKM = 5900000
const COSTVEHICLES = 250000
const COSTMAINTENANCEVEHICLESPERYEAR = 35000
const MAXVEHICLES = 2
const MAXCAPAVEHICLE = 20
const SPEEDVEHICLE = 20

const STOPTIMESTATION = 3





function jules()
    stations = getStations("stations.dat")
    println(stations)
    townsites = getTownsites("townsites.dat",stations)
    println("townsites = ",townsites)

    h = getDensities(townsites)
    println("h = ",h)
    m,x,z = MCP_model(stations,townsites,10,h)
    println("z = ",z)
    println("x = ",x)
end

function lucas()
    stations = getStations("stations.dat")
    townsites = getTownsites("townsites.dat", stations)

    return stations, townsites
end
