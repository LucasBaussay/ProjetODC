
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")

const CostOpenStation = 1900000
const CostBridge = 28600000
const NewLinePerKm = 5900000
const CostVehicles = 250000
const CostMAintenanceVehiclesPerYear = 35000

function jules()
    stations = getStations("stations.dat")
    println(stations)
    subdivisions = getSubdivisions("subdivisions.dat",stations)
    println("subdivisions = ",subdivisions)
end

function lucas()

end
