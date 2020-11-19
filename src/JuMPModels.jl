
"""
JuMPModels.jl gère les modèles JuMP et leur résolution
"""

function MCP_model_Lucas(stations::Array{Station,1},townsites::Array,p::Int, verbose::Bool = true)
    m = Model(GLPK.Optimizer)
    nbStations = length(stations)
    nbTownsites = length(townsites)
    h::Vector{Float64} = getDensity.(townsites)

    @variable(m, x[stations], Bin) # xi = 1 si la station i est construite, 0 sinon
    @variable(m, s[townsites], Bin) # si = 1 si la demande du lotissement i est satisfaite, 0 sinon

    @constraint(m, activation[townsite in townsites], sum(x[station] - s[townsite] for station in townsite.nearStations) >= 0)
    @constraint(m, limit, sum(x[station] for station in stations) == p)

    @objective(m, Max, dot(h,s))

    optimize!(m)

    activateStation = Vector{Station}(undef, nbStations)
    indFinActivateStation = 0


    verbose && println("Nombre d'habitant déservi par cette solution : $(JuMP.objective_value(m))")
    verbose && print("Les stations suivantes sont activées : ")
    for iter in stations
        val = JuMP.value(x[iter])
        if val != 0
            indFinActivateStation += 1
            activateStation[indFinActivateStation] = iter
            verbose && print(iter, " ")
        end
    end
    verbose && println()


    return activateStation[1:indFinActivateStation], JuMP.objective_value(m)
end

function stationActivateGraph(listStations::Vector{Station}, listTownsites::Vector{Townsite})
    listP = collect(1:length(listStations))
    valuesP = Vector{Float64}(undef, length(listStations))

    for p = 1:length(listStations)
        etc, z = MCP_model_Lucas(listStations, listTownsites, p, false)
        valuesP[p] = z
    end

    plot(listP, valuesP, "b", marker = "o")
    grid()
    xlabel("Nombre de stations ouverte")
    ylabel("Densité maximale couvrable")
    title("Nombre d'habitants touchés par nombre de stations ouverte sur la ligne")
end
