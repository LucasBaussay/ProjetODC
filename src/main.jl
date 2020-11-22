
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
    nbShuttles = 1

    stations = [Station("Station "*string(i), rand(), rand()) for i = 1:nbStations]
    distStations = Array{Float64, 2}(undef, nbStations, nbStations)

    distStations[1,2] = 750
    distStations[2,3] = 1000
    distStations[2,1] = 750
    distStations[3,2] = 1000

    T, E, A_run, A_dwell, A_thr, A_head, A_reg, L, U = parserPESP(T, nbStations, nbShuttles, stations, distStations)
    m = PESP_model(T, E, A_run, A_dwell, A_thr, A_head, A_reg, L, U)

    return m
end

"""
Pour Jules :

La fonction PESP_model te renvoie le modèle JuMP oprimisé.

Fonctions utiles dessus :

Récuperer le modèle :

m = testDidactic()

Les contraintes liées aux variables

- JuMP.all_constraints(m, JuMP.VariableRef, MOI.GreaterThan{Float64})
- JuMP.all_constraints(m, JuMP.VariableRef, MOI.LessThan{Float64})
- JuMP.all_constraints(m, JuMP.VariableRef, MOI.ZeroOne)

Les réels contraintes

- JuMP.all_constraints(m, JuMP.GenericAffExpr{Float64, VariableRef}, MOI.Interval{Float64})

La fonction objectif

- JuMP.objective_function(m)

Le numéro d'indicage des contraintes est le numéro du sommet associé, l'ordre de construction est montré (si c'est lisible) sur le graphique que je t'ai envoyé sur Messenger.

Cordialement
"""
