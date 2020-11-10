
"""
JuMPModels.jl gère les modèles JuMP et leur résolution
"""

using GLPK

function MCP_model(I::Int,J::Int,p::Int,h::Array{Float64,1})
    m = Model(GLPK.Optimizer)
    @variable(m, x[1:I], Bin)
    @variable(m, x[1:J], Bin)
    @objective(ip, Max, dot(C, x))
end