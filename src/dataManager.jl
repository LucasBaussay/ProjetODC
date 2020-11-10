
"""
dataManager.jl s'occupe de l'accès aux données.
"""

dataPath() = "../data";

# retourne un Array{Station,1} d'objets Station
function getStations(fileName::String)
    f = openFile(fileName)
    nbStations = parse(Int,readline(f))
    stations = Vector{Station}(undef,nbStations)
    for indexStation in 1:nbStations
        line = readline(f)
        splitLine = split(line," ")
        stations[indexStation] = Station(splitLine[1],parse(Float64,splitLine[2]),parse(Float64,splitLine[3]))
    end
    return stations
end

# retourne un Array{Subdivision,1} d'objets Subdivision
function getSubdivisions(fileName::String)
    f = openFile(fileName)
    nbStations = parse(Int,readline(f))
    stations = Vector{Station}(undef,nbStations)
    for indexStation in 1:nbStations
        line = readline(f)
        splitLine = split(line," ")
        stations[indexStation] = Station(splitLine[1],parse(Float64,splitLine[2]),parse(Float64,splitLine[3]))
    end
    return stations
end

# retourne le fichier ouvert correspondant au nom donné
function openFile(fileName::String)
    actual_path = pwd()
    cd(joinpath(dataPath())) # déplacement dans le repertoire où sont stockés les fichiers source
    f = open(fileName)
    cd(actual_path)
    return f
end