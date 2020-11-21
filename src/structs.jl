
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
struct Townsite
    name::String
    latitude::Float64
    longitude::Float64
    density::Int
    nearStations::Array{Station,1}
end

Base.show(io::IO, x::Townsite) = print(io, x.name)

getDensity(townsite::Townsite) = townsite.density

# objet Node modélisant un état du graphe Graphe
struct Node
    name::String
    shuttle::Int
    station::Station
end

struct Graph
    name::String
    nbNodes::Int
    nbArcs::Int
    
end