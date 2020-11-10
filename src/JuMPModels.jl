
"""
JuMPModels.jl gère les modèles JuMP et leur résolution
"""

function MCP_model(stations::Array{Station,1},townsites::Array,p::Int,h::Array{Float64,1})
    m = Model(GLPK.Optimizer)
    nbStations = length(stations)
    nbTownsites = length(townsites)
    @variable(m, x[1:nbStations], Bin) # xi = 1 si la station i est construite, 0 sinon
    @variable(m, s[1:nbTownsites], Bin) # si = 1 si la demande du lotissement i est satisfaite, 0 sinon
    @constraint(m, activation[1:nbTownsites], sum(x[station] - s[townsite] for station=1:nbStations) >= 0)
    @constraint(m, limit, sum(x[station] for station=1:nbStations) == p)
    @objective(m, Max, dot(h,s))
    return m, x
end