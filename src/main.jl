
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")

function jules()
    stations = getStations("stations.dat")
    println(stations)
    subdivisions = getSubdivisions("subdivisions.dat",stations)
    println(subdivisions)
end

function lucas()
    
end