
"""
JuMPModels.jl gère les modèles JuMP et leur résolution
"""

function MCP_model_Lucas(stations::Array{Station,1},townsites::Array,p::Int; verbose::Bool = true)
    m = Model(GLPK.Optimizer)
    nbStations = length(stations)
    nbTownsites = length(townsites)
    h::Vector{Float64} = getDensity.(townsites)

    @variable(m, x[stations], Bin) # xi = 1 si la station i est construite, 0 sinon
    @variable(m, s[townsites], Bin) # si = 1 si la demande du lotissement i est satisfaite, 0 sinon

    @constraint(m, activation[townsite in townsites], sum(x[station]  for station in townsite.nearStations) - s[townsite] >= 0)
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

# PESP JuMP Model
#=function PESP_model(T::Int,E::Array{Int,1},A_run::Array{Tuple{Int,Int},1},A_dwell::Array{Tuple{Int,Int},1},A_thr::Array{Tuple{Int,Int},1},A_head::Array{Tuple{Int,Int},1},A_reg::Array{Tuple{Int,Int},1},L::Array{Int,2},U::Array{Int,2})
    arraysOfTuples = [A_run,A_dwell,A_head,A_thr,A_reg]
    A = merge(arraysOfTuples) # fusionne les arrêtes

    nbNodes = length(E) # nombre de sommets
    nbArcs = length(A) # nombre d'arcs

    # déclaration du modèle
    m = Model(GLPK.Optimizer)

    # déclaration des variables
    @variable(m, 0 <= x[nbNodes] <= T) # temps d'arrivée à chaque sommet du graph
    @variable(m, z[nbNodes,nbNodes], Bin) # modulo

    # déclaration des contraintes
    @constraint(m, valid[arc in A], L[arc[1],arc[2]] <= x[arc[2]] - x[arc[1]] + z[arc[1],arc[2]]*T <= U[arc[1],arc[2]])

    # déclaration de l'objectif
    @objective(m, Min, )
end

# retourne le tableau de fusion résultante entre les cinq tableaux donnés de Tuple{Int,Int}
function merge(T::Array{Array{Tuple{Int,Int},1}})
    # calcul du nombre total de tuples
    nbTuples = 0
    for array in T
        nbTuples += legnth(array)
    end
    # allocation du vecteur à retourner
    result = Vector{Tuple{Int,Int}}(undef,nbTuples)
    indexResult = 1 # tête d'écriture
    # remplissage du vecteur résultat
    for array in T
        for tuple in array
            result[indexResult] = tuple
            indexResult += 1
        end
    end
    return result
end

# retourne un objet à passer au modèle JuMP PESP
function parserPESP(T::Int,nbStations::Int,nbShuttles::Int,stations::Array{Station,1})
    nbNodes = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
    nbNodesPerShuttle = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
    nbArcs = 2*nbShuttles*(nbStation-1)*(nbShuttles+1) # nombre d'arcs
    # sommets du graph
    E = Array{Node,1}(undef,nbNodes)
    # arrêtes du graph
    A = Array{Tuple{Int,Int},1}(undef,nbArcs)
    # borne inférieure pour chaque couple de sommets du graph
    L = Array{Int,2}(undef,nbNodes,nbNodes)
    # borne supérieure pour chaque couple de sommets du graph
    U = Array{Int,2}(undef,nbNodes,nbNodes)
    
    # Calcul des sommets du graph
end=#

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
