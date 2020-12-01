
"""
dataManager.jl s'occupe de l'accès aux données.
"""

const DATAPATH = "../data";

# retourne un Array{Station,1} d'objets Station
function getStations(fileName::String)
    f = openFile(fileName) # ouverture du fichier
    nbStations = parse(Int,readline(f)) # nombre de stations
    stations = Vector{Station}(undef,nbStations)
    for indexStation in 1:nbStations
        line = readline(f)
        splitLine = split(line," ")
        stations[indexStation] = Station(indexStation, splitLine[1],parse(Float64,splitLine[3]),parse(Float64,splitLine[2])) # construction de la station
    end
    return stations
end

# retourne un Array{Townsite,1} d'objets Townsite
function getTownsites(fileName::String,stations::Array{Station,1})
    f = openFile(fileName) # ouverture du fichier
    nbTownsites = parse(Int,readline(f)) # nombre de townsites
    townsites = Vector{Townsite}(undef,nbTownsites)
    for indexTownsite in 1:nbTownsites
        line = readline(f)
        splitLine = split(line," ")
        nbNearStations = length(splitLine) - 4 # nombre de stations proches
        nearStations = Vector{Station}(undef,nbNearStations)
        for indexStation in 1:nbNearStations
            nearStations[indexStation] = getStation(string(splitLine[4+indexStation]),stations) # on les stock dans un vecteur
        end
        townsites[indexTownsite] = Townsite(splitLine[1],parse(Float64,splitLine[3]),parse(Float64,splitLine[2]),parse(Int,splitLine[4]),nearStations)
    end
    return townsites
end

# retourne la station du vecteur stations dont le nom est stationName
function getStation(stationName::String,stations::Array{Station,1})
    found = false
    indexStation = 1
    while !found && indexStation <= length(stations)
        if stations[indexStation].name == stationName # on a trouvé la station
            found = true
        end
        indexStation += 1
    end
    return stations[indexStation-1]
end

# retourne le vecteur des densités des lotissements
function getDensities(townsites::Array{Townsite,1})
    n = length(townsites)
    densities = Vector{Int}(undef,n)
    for indexTownsite in 1:n
        densities[indexTownsite] = townsites[indexTownsite].density
    end
    return densities
end

# retourne le fichier ouvert correspondant au nom donné
function openFile(fileName::String)
    actual_path = pwd()
    cd(joinpath(DATAPATH)) # déplacement dans le repertoire où sont stockés les fichiers source
    f = open(fileName)
    cd(actual_path)
    return f
end
