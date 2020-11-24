
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

function distDidact()
    distStations = Array{Float64, 2}(undef, 3, 3)

    distStations[1,2] = 750
    distStations[2,3] = 1000
    distStations[2,1] = 750
    distStations[3,2] = 1000
    return distStations
end

function formul(lat1::Float64, long1::Float64, lat2::Float64, long2::Float64)
    r = 6378137
    distAng = acos( sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long1 - long2) )

    return r * distAng
end

function calculDistLatLong(stations::Vector{Station})

    nbStations = length(stations)
    distStations = Array{Float64, 2}(undef, nbStations, nbStations)

    for i = 1:nbStations
        for j = i+1:nbStations
            distStations[i, j] = formul(stations[i].latitude, stations[i].longitude, stations[j].latitude, stations[j].longitude)
        end
    end

    return distStations
end

function runPESP(;stations::Vector{Station}, distStations::Array{Float64, 2} = calculDistLatLong(stations), T::Int = 3600, nbShuttles::Int = 2)

    nbStations = length(stations)

    T, E, A_run, A_dwell, A_term, A_thr, A_head, A_reg, L, U = parserPESP(T, nbStations, nbShuttles, stations, distStations)
    m = PESP_model(T, E, A_run, A_dwell, A_term, A_thr, A_head, A_reg, L, U)

    if JuMP.termination_status(m) != MOI.OPTIMAL
        println("La periode est trop courte pour ce nombre de Navette, veuillez diminuer le nombre de Navette ou bien augmenter la periode.")
        return m
    else
        nbNodes = length(E)
        nbNodesPerShuttle = Int(nbNodes/nbShuttles)

        zValues = JuMP.value.(JuMP.all_variables(m)[(nbNodes+1):end]) #Acces a z[i, j] : zValues[i + (j-1)*nbNodes] et Acces z[i-1, i] = zValues[ (i - 1) * (nbNodes + 1)]

        iterNode = 0

        for shuttle = 1:nbShuttles

            values = JuMP.value.(JuMP.all_variables(m)[1 + (shuttle - 1)*(4 * (nbStations - 1)):(Int(length(E)/nbShuttles) + (shuttle - 1)*(4 * (nbStations - 1)))])

            Y = Vector{Int}(undef, Int(length(E)/nbShuttles)) # Idée : Juste les vider genre empty!(X)
            X = Vector{Int}(undef, Int(length(E)/nbShuttles))

            nbAjoutT = 0

            for iter = 1:nbNodesPerShuttle
                iterNode += 1
                Y[iter] = E[iterNode].indStation

                if iter != 1
                    if zValues[(iterNode-1)*(nbNodes+1)] == 1
                        nbAjoutT += 1
                    end
                    X[iter] = (values[iter] + nbAjoutT * T)
                else
                    X[iter] = values[iter]
                end

            end

            plot(X, Y)
        end
        return m
    end
end

function testDidactic(;T::Int = 3600, nbShuttles::Int = 2)

    nbStations = 3
    stations = [Station("Station "*string(i), rand(), rand()) for i = 1:nbStations]

    distStations = distDidact()

    return runPESP(stations, distStations, T = T, nbShuttles = nbShuttles)

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
