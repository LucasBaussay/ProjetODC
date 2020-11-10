
"""
structs.jl déclare les nouveaux types utilisés dans ce projet.
"""

# objet Station modélisant une station de navette
struct Station
    name::String
    latitude::Float64
    longitude::Float64
end

# objet Subdivision modélisant un lotissement urbain
struct Subdivision
    name::String
    latitude::Float64
    longitude::Float64
    density::Int
    nearStations::Array{Station,1}
end
