
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")

function jules()
    stations = getStations("stations.dat")
    println(stations)
end

function lucas()
    
end