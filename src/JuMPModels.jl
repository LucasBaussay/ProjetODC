
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

# PESP JuMP Model
function PESP_model(T::Int,E::Array{Node,1},A_run::Array{Tuple{Int,Int},1},A_dwell::Array{Tuple{Int,Int},1},A_thr::Array{Tuple{Int,Int},1},A_head::Array{Tuple{Int,Int},1},A_reg::Array{Tuple{Int,Int},1},L::Array{Int,2},U::Array{Int,2})
    A = merge([A_run,A_dwell,A_head,A_thr,A_reg]) # fusionne les arrêtes

    nbNodes = length(E) # nombre de sommets
    nbArcs = length(A) # nombre d'arcs

    # déclaration du modèle
    m = Model(GLPK.Optimizer)

    # déclaration des variables
    @variable(m, 0 <= x[1:nbNodes] <= T) # temps d'arrivée à chaque sommet du graph
    @variable(m, z[1:nbNodes,1:nbNodes], Bin) # modulo

    # déclaration des contraintes
    @constraint(m, valid[arc in A], L[arc[1],arc[2]] <= x[arc[2]] - x[arc[1]] + z[arc[1],arc[2]]*T <= U[arc[1],arc[2]])

    # déclaration de l'objectif
    @objective(m, Min, sum(x[arc[2]] - x[arc[1]] +z[arc[1], arc[2]] * T for arc in A_dwell) + sum(x[arc[2]] - x[arc[1]] +z[arc[1], arc[2]] * T for arc in A_run))

    optimize!(m)

    # Ce qu'il faut renvoyer : pour chaque Navette un Tableau pour chaque station (horaireDépart, horaireArrivé)
    return m
end

# retourne le tableau de fusion résultante entre les cinq tableaux donnés de Tuple{Int,Int}
function merge(T::Array{Array{Tuple{Int,Int},1}})
    # calcul du nombre total de tuples
    nbTuples = 0
    for array in T
        nbTuples += length(array)
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

# retourne un objet à passer au modèle JuMP PESP, avec nbStations > 0
function parserPESP(T::Int,nbStations::Int,nbShuttles::Int,stations::Array{Station,1}, distStations::Array{Float64, 2})

    dwellMax = 60 # en seconde
    dwellMin = 30 # en seconde
    vehicle_speed = 20 / 3.6 # en metre/seconde

    nbNodes = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
    nbNodesPerShuttle = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
    nbArcsRun = 2*nbShuttles*(nbStations-1) # nombre d'arcs run
    nbArcsDwell = 2*nbShuttles*(nbStations-1) - nbShuttles # nombre d'arcs Dwell
    nbArcsReg = 2*nbShuttles*(nbStations-1)*(nbShuttles-1) # nombre d'arcs Reg
    # sommets du graph
    E = Array{Node,1}(undef,nbNodes)
    # arrêtes du graph
    A_run = Array{Tuple{Int,Int},1}(undef,nbArcsRun)
    A_dwell = Array{Tuple{Int,Int},1}(undef,nbArcsDwell)
    A_reg = Array{Tuple{Int,Int},1}(undef,nbArcsReg)
    # borne inférieure pour chaque couple de sommets du graph
    L = Array{Int,2}(undef,nbNodes,nbNodes)
    # borne supérieure pour chaque couple de sommets du graph
    U = Array{Int,2}(undef,nbNodes,nbNodes)

    iterEps = 0
    iterARun = 0
    iterADwell = 0
    iterAReg = 0
    for shuttle = 1:nbShuttles
        # L'aller de la navette
        iterEps += 1
        E[iterEps] = Node(getNameNode(iterEps), shuttle, 1, departure, forth)
        for iterStation = 2:nbStations-1
            iterEps += 1
            E[iterEps] = Node(getNameNode(iterEps), shuttle, iterStation, arrival, forth)

            # Trajet entre une station et une autre
            iterARun += 1
            A_run[iterARun] = (iterEps-1, iterEps)
            L[iterEps-1, iterEps] = Int(floor(0.95*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))
            U[iterEps-1, iterEps] = Int(ceil(1.05*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))

            iterEps += 1
            E[iterEps] = Node(getNameNode(iterEps), shuttle, iterStation, departure, forth)

            # Attente sur une station du trajet
            iterADwell += 1
            A_dwell[iterADwell] = (iterEps -1, iterEps)
            L[iterEps-1, iterEps] = dwellMin
            U[iterEps-1, iterEps] = dwellMax
        end
        iterEps += 1
        E[iterEps] = Node(getNameNode(iterEps), shuttle, nbStations, arrival, forth)


        iterARun += 1
        A_run[iterARun] = (iterEps - 1, iterEps)
        L[iterEps-1, iterEps] = Int(floor(0.95*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))
        U[iterEps-1, iterEps] = Int(ceil(1.05*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))

        # Le retour de la navette
        iterEps += 1
        E[iterEps] = Node(getNameNode(iterEps), shuttle, nbStations, departure, back)

        iterADwell += 1
        A_dwell[iterADwell] = (iterEps - 1, iterEps)
        L[iterEps-1, iterEps] = dwellMin + 10
        U[iterEps-1, iterEps] = dwellMax + 10

        for iterStation = 1:nbStations-2
            iterEps += 1
            E[iterEps] = Node(getNameNode(iterEps), shuttle, nbStations - iterStation, arrival, back)

            iterARun += 1
            A_run[iterARun] = (iterEps - 1, iterEps)
            L[iterEps-1, iterEps] = Int(floor(0.95*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))
            U[iterEps-1, iterEps] = Int(ceil(1.05*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))

            iterEps += 1
            E[iterEps] = Node(getNameNode(iterEps), shuttle, nbStations - iterStation, departure, back)

            iterADwell += 1
            A_dwell[iterADwell] = (iterEps - 1, iterEps)
            L[iterEps-1, iterEps] = dwellMin
            U[iterEps-1, iterEps] = dwellMax
        end
        iterEps += 1
        E[iterEps] = Node(getNameNode(iterEps), shuttle, 1, arrival, back)

        iterARun += 1
        A_run[iterARun] = (iterEps -1, iterEps)
        L[iterEps-1, iterEps] = Int(floor(0.95*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))
        U[iterEps-1, iterEps] = Int(ceil(1.05*distStations[ E[iterEps-1].indStation, E[iterEps].indStation] / vehicle_speed))

        # iterADwell += 1
        # A_dwell[iterADwell] = (iterEps, iterEps - 4*(nbStations - 1) +1)
        # L[iterEps , (iterEps - 4*(nbStations - 1) +1)] = dwellMin + 10
        # U[iterEps , (iterEps - 4*(nbStations - 1) +1)] = dwellMax + 10
    end

    for node = 1:(2*(nbStations-1))
        for shuttle = 1:nbShuttles
            for nextShuttle = (shuttle+1):nbShuttles
                iterAReg += 1
                A_reg[iterAReg] = (node + (shuttle - 1)*(4*(nbStations - 1)) , node + (nextShuttle - 1)*(4*(nbStations - 1)) )
                L[node + (shuttle - 1)*(4*(nbStations - 1)), (node + (nextShuttle - 1)*(4*(nbStations - 1)))] = Int(floor(T/nbStations))
                U[node + (shuttle - 1)*(4*(nbStations - 1)), (node + (nextShuttle - 1)*(4*(nbStations - 1)))] = typemax(Int)

                iterAReg += 1
                A_reg[iterAReg] = (node + (2*(nbStations-1)) + (shuttle - 1)*(4*(nbStations - 1)) , node + 2*(nbStations-1) + (nextShuttle - 1)*(4*(nbStations - 1)) )
                L[node + (2*(nbStations-1)) + (shuttle - 1)*(4*(nbStations - 1)), (node + 2*(nbStations-1) + (nextShuttle - 1)*(4*(nbStations - 1)))] = Int(floor(T/nbStations))
                U[node + (2*(nbStations-1)) + (shuttle - 1)*(4*(nbStations - 1)), (node + 2*(nbStations-1) + (nextShuttle - 1)*(4*(nbStations - 1)))] = typemax(Int)
            end
        end
    end

    return T, E, A_run, A_dwell, Vector{Tuple{Int, Int}}(), Vector{Tuple{Int, Int}}(), A_reg, L, U

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

# # retourne un objet à passer au modèle JuMP PESP
# function parserPESP(T::Int,nbStations::Int,nbShuttles::Int,stations::Array{Station,1})
#     nbNodes = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
#     nbNodesPerShuttle = 4*(nbStations-1)*nbShuttles # nombre de sommets du graph
#     nbArcs = 2*nbShuttles*(nbStation-1)*(nbShuttles+1) # nombre d'arcs
#     # sommets du graph
#     E = Array{Node,1}(undef,nbNodes)
#     # arrêtes du graph
#     A = Array{Tuple{Int,Int},1}(undef,nbArcs)
#     # borne inférieure pour chaque couple de sommets du graph
#     L = Array{Int,2}(undef,nbNodes,nbNodes)
#     # borne supérieure pour chaque couple de sommets du graph
#     U = Array{Int,2}(undef,nbNodes,nbNodes)
#
#     # Calcul des sommets du graph
#     for indexNode in 1:nbNodes/nbShuttles
#         E[indexNode] = Node(getNameNode(indexNode),)
#     end
# end
