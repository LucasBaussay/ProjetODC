
"""
structs.jl déclare les nouveaux types utilisés dans ce projet.
"""

# objet Station modélisant une station de navette
struct Station
    nom::String
    latitude::Float64
    longitude::Float64
end

# objet lotissement modélisant un lotissement urbain
struct Lotissement
    nom::String
    latitude::Float64
    longitude::Float64
end
