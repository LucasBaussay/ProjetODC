
"""
structs.jl déclare les nouveaux types utilisés dans ce projet.
"""

import Base.show

# objet Station modélisant une station de navette
struct Station
    name::String
    latitude::Float64
    longitude::Float64
end

Base.show(io::IO, x::Station) = print(io, x.name)

# objet Subdivision modélisant un lotissement urbain
struct Subdivision
    name::String
    latitude::Float64
    longitude::Float64
    density::Int
    nearStations::Array{Station,1}
end

Base.show(io::IO, x::Subdivision) = print(io, x.name)
