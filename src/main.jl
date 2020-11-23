
"""
main.jl est le fichier principal.
"""

println("Precompiling packages...")


using JuMP, GLPK, LinearAlgebra, PyPlot

@enum Sense forth back
@enum State departure arrival

include("structs.jl")
include("dataManager.jl")
include("JuMPModels.jl")
include("tools.jl")

const COST_OPEN_STATION = 1900000
const COST_BRIDGE = 28600000
const COST_NEW_LINE_PER_KM = 5900000
const COST_VEHICLES = 250000
const COST_MAINTENANCE_VEHICLES_PER_YEAR = 35000
const MAX_VEHICLES = 2
const MAX_CAPAVEHICLE = 20
const SPEED_VEHICLE = 20

const STOP_TIME_STATION = 3

function main()
    stations = getStations("stations.dat")
    townsites = getTownsites("townsites.dat",stations)
    h = getDensities(townsites)
    Z = Vector{Int}(undef,length(stations))
    for p in 1:length(stations)
        x,z = MCP_model_Lucas(stations,townsites,p,false)
        println("z = ",z)
        Z[p] = z
    end
    plot(Z,marker=".",label="Nombre d'habitants qui ont au moins une station accessible")
    legend()
end

function jules()
    stations = getStations("stations.dat")
    println(stations)
    townsites = getTownsites("townsites.dat",stations)
    println("townsites = ",townsites)

    h = getDensities(townsites)
    println("h = ",h)
    x,z = MCP_model_Lucas(stations,townsites,10,true)
    println("z = ",z)
    println("x = ",x)
end

function lucas()
    stations = getStations("stations.dat")
    townsites = getTownsites("townsites.dat", stations)

    return stations, townsites
end

function testDidactic()
    T = 1 * 60 * 60
    nbStations = 3
    nbShuttles = 2

    stations = [Station("Station "*string(i), rand(), rand()) for i = 1:nbStations]
    distStations = Array{Float64, 2}(undef, nbStations, nbStations)

    distStations[1,2] = 750
    distStations[2,3] = 1000
    distStations[2,1] = 750
    distStations[3,2] = 1000

    T, E, A_run, A_dwell, A_term, A_thr, A_head, A_reg, L, U = parserPESP(T, nbStations, nbShuttles, stations, distStations)
    m = PESP_model(T, E, A_run, A_dwell, A_term, A_thr, A_head, A_reg, L, U)

    if JuMP.termination_status(m) == OPTIMAL

    nbNodes = length(E)
    nbNodesPerShuttle = Int(nbNodes/nbShuttles)

    zValues = JuMP.value.(JuMP.all_variables(m)[(nbNodes+1):end]) #Acces a z[i, j] : zValues[i + (j-1)*nbNodes] et Acces z[i-1, i] = zValues[ (i - 1) * (nbNodes + 1)]

    for shuttle = 1:nbShuttles

        values = JuMP.value.(JuMP.all_variables(m)[1 + (shuttle - 1)*(4 * (nbStations - 1)):(Int(length(E)/nbShuttles) + (shuttle - 1)*(4 * (nbStations - 1)))])

        iter = 0
        Y = Vector{Int}(undef, Int(length(E)/nbShuttles)) # Idée : Juste les vider genre empty!(X)
        X = Vector{Int}(undef, Int(length(E)/nbShuttles))

        for iterNode = (1 + nbNodesPerShuttle * (shuttle -1)):(nbNodesPerShuttle * (shuttle))
            iter += 1
            Y[iter] = E[iterNode].indStation

            if iter != 1
                X[iter] = values[iter] + zValues[(iterNode-1)*(nbNodes+1)] * T
            else
                X[iter] = values[iter]
            end

        end

        plot(X, Y)
    end

    # if nbShuttles == 1
    #
    #     values = JuMP.value.(JuMP.all_variables(m)[1:nbNodes])
    #     Y = Vector{Int}(undef, Int(length(E)/nbShuttles))
    #     X = Vector{Int}(undef, Int(length(E)/nbShuttles))
    #
    #     for iter = 1:nbNodes
    #         X[iter] = values[iter]
    #         Y[iter] = E[iter].indStation
    #     end
    #     plot(X, Y)
    #
    # elseif nbShuttles == 2
    #
    #     nbNodesPerShuttle = Int(nbNodes/2)
    #
    #     values1 = JuMP.value.(JuMP.all_variables(m)[1:nbNodesPerShuttle])
    #     values2 = JuMP.value.(JuMP.all_variables(m)[nbNodesPerShuttle+1:nbNodes])
    #
    #     zValues = JuMP.value.(JuMP.all_variables(m)[(nbNodes+1):end]) #Acces a z[i, j] : zValues[i + (j-1)*nbNodes]
    #
    #     Y1 = Vector{Int}(undef, nbNodesPerShuttle)
    #     X1 = Vector{Int}(undef, nbNodesPerShuttle)
    #     Y2 = Vector{Int}(undef, nbNodesPerShuttle)
    #     X2 = Vector{Int}(undef, nbNodesPerShuttle)
    #
    #     for iter = 1:nbNodesPerShuttle
    #
    #         if iter%nbNodes != 1
    #
    #             X1[iter] = values1[iter] + (zValues[(iter-1)*(nbNodes+1)] != 0. ? T : 0)
    #             Y1[iter] = E[iter].indStation
    #
    #             X2[iter] = values2[iter] + (zValues[(iter + nbNodesPerShuttle -1)*(nbNodes + 1)] != 0. ? T : 0)
    #             Y2[iter] = E[iter].indStation
    #
    #         else
    #             X1[iter] = values1[iter]
    #             Y1[iter] = E[iter].indStation
    #             X2[iter] = values2[iter]
    #             Y2[iter] = E[iter].indStation
    #         end
    #
    #     end
    #
    #     plot(X1, Y1)
    #     plot(X2, Y2)
    # end
    return m
end
#
# """
# Pour Jules :
#
# La fonction PESP_model te renvoie le modèle JuMP oprimisé.
#
# Fonctions utiles dessus :
#
# Récuperer le modèle :
#
# m = testDidactic()
#
# Les contraintes liées aux variables
#
# - JuMP.all_constraints(m, JuMP.VariableRef, MOI.GreaterThan{Float64})
# - JuMP.all_constraints(m, JuMP.VariableRef, MOI.LessThan{Float64})
# - JuMP.all_constraints(m, JuMP.VariableRef, MOI.ZeroOne)
#
# Les réels contraintes
#
# - JuMP.all_constraints(m, JuMP.GenericAffExpr{Float64, VariableRef}, MOI.Interval{Float64})
#
# La fonction objectif
#
# - JuMP.objective_function(m)
#
# Le numéro d'indicage des contraintes est le numéro du sommet associé, l'ordre de construction est montré (si c'est lisible) sur le graphique que je t'ai envoyé sur Messenger.
#
# Cordialement
#
# Le problème vient des terminus sur le retour : En effet, quand on verifie les temps π_j - π_i, pour le terminus du retour on vient à faire :
#
# π_{premier de la navette} - π_{dernier de la navette} :
#
# Dans les faits on calcul : 40 <= 0 - 820 + z * 3600 <= 70
#
# Tu peux prendre z = 1 ou 0 ca ne satisfait pas la contrainte donc le problème est infaisable ! Je crois qu'on a mal compris une partie du sujet
# Donc si tu trouves l'erreur je t'appel maitre ! (Car l'erreur ne vient pas du code parce qu'il fait exactement tout ce que je veux mais plutôt de la comprehension du problème.)
# """
