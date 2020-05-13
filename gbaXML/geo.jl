using HTTP
using JSON
using DataFrames
using CSV

df = DataFrame(CSV.read("./data.csv"));

addressList = df.fullAdress;

#nominatim requires a user agent and will block you otherwise
HTTP.setuseragent!("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.120 Safari/537.36")



function simplePlace(place)
    """simplePlace(place::String)

    cuts off additional information like "am Rhein" from a place name
    """
    out = split(place,['/','('])[1]
    out = split(out," i.")[1]
    out = split(out," a.")[1]
    out = split(out," OT ")[1]
    out = split(out," am ")[1]
    out = split(out," im ")[1]
    out = replace(out,"Hansestadt "=>"")
    out = replace(out,"Dr."=>"Doktor")
    out = replace(out,"Bgm."=>"Bürgermeister")
    return out
end

function getCoordinates(addressList)
    """
    getCoordinates(addressList)

    input: typically Array{String,1}
    returns a Vector of coordinates in (lat,lon) format as well as a data Array that contains all the data returned by nominatim
    """
    coordinatesList = Array{Tuple{Float64,Float64},1}(undef, length(addressList)) # will contain (lat,lon) of addresses in addressList
    data = Array{Any,1}(undef,length(addressList)) # will contain all data nominatim gives for each request
    for (i,address) in enumerate(addressList)
        addressFormatted = join(split(address),"+")
        rawdata = HTTP.get(string("https://nominatim.openstreetmap.org/search?q=",addressFormatted,"&format=json&limit=1"))
        try
            data[i]=JSON.parse(String(rawdata.body))[1]
            coordinatesList[i] = parse(Float64,data[i]["lat"]),parse(Float64,data[i]["lon"])
        catch
            println("catch 1 in line ",i)
            addressFormatted = join(split(simplePlace(address)),"+")
            sleep(1)
            rawdata = HTTP.get(string("https://nominatim.openstreetmap.org/search?q=",addressFormatted,"&format=json&limit=1"))
            try
                data[i]=JSON.parse(String(rawdata.body))[1]
                coordinatesList[i] = parse(Float64,data[i]["lat"]),parse(Float64,data[i]["lon"])
            catch
                println("catch 2 in line ",i)
                sleep(1)
                simpleAddress = simplePlace(df.strasse[i])*", "*string(df.plz[i])*" "*simplePlace(df.ort[i])
                addressFormatted = join(split(simpleAddress),"+")
                rawdata = HTTP.get(string("https://nominatim.openstreetmap.org/search?q=",addressFormatted,"&format=json&limit=1"))
                try length(rawdata.body)>0
                    data[i]=JSON.parse(String(rawdata.body))[1]
                    coordinatesList[i] = parse(Float64,data[i]["lat"]),parse(Float64,data[i]["lon"])
                catch
                    println("Could not find coordinates for ",address, " in line ",i)
                end
            end
        end
        sleep(1) #nominatim will block you if you have more than 1 request per second
    end
    return coordinatesList, data
end


coordinates = getCoordinates(addressList)[1]

###entries added by hand 
coordinates[51]=(54.16436,10.54774) #typo street name
df.strasse[51]="Diekseepromenade"
coordinates[101]=(53.81253,10.36405) #typo street name
df.strasse[101]="Schützenstraße"
coordinates[170]=(53.55375,9.98875) #typo street
df.strasse[170]="Hohe Bleichen"
coordinates[179]=(53.54850,9.98506) #typo street
df.strasse[179]="Admiralitätstr."
coordinates[226]=(52.61069,8.37685) # typo street
df.strasse[226]="Eschfeldstraße"
coordinates[375]=(52.08817,7.61072) # typo plz
df.plz[375]=48268
coordinates[384]=(51.96115,7.59448) # Gebäude nr extra
df.strasse[384]="Albert-Schweitzer-Campus"
coordinates[504]=(51.28629,7.09294) #typo street
df.strasse[504]="Erfurthweg"
coordinates[513]=(51.30079,6.73412) #typo street
df.strasse[513]="An St. Swidbert"
coordinates[685]=(51.69113,7.18269) #typo street
df.strasse[685]="Halterner Str."
coordinates[805]= (51.54679,7.31540)#typo place
df.ort[805]="Castrop-Rauxel"
coordinates[814]=(51.61812,7.63059) #typo street
df.strasse[814]="Erich-Ollenhauer-Str."
coordinates[823]=(51.84213,8.31533) #typo place
df.ort[823]="Rheda-Wiedenbrück"
coordinates[855]=(51.14424,8.32438) # typo place
df.ort[855]="Schmallenberg"
coordinates[872]=(51.05962,8.40825) #typo street
df.strasse[872]="Sählingstraße"
coordinates[908]=(51.69844,7.76370) # typo place
df.ort[908]="Hamm"
coordinates[1047]=(50.50664,9.10420) # unclear 
coordinates[1074]=(51.61559,9.58890) #district instead of city name
df.ort[1074]="Wesertal"
coordinates[1080]=(50.75554,8.48629) #typo place
df.ort[1080]="Bad Endbach"
coordinates[1184]=(49.64596,7.15966) #unclear
coordinates[1220]=(50.42132,7.57646) #wrong street and house number
df.strasse[1220]="Entengasse"
df.hnr[1220]="4"
coordinates[1255] = (49.48724,8.38865) #unclear
coordinates[1387]=(49.49221,8.46579) # bad street spelling
df.strasse[1387]="J5"
coordinates[1535]=(47.76524,9.59843) #typo street
df.strasse[1535]="Weingartshofer Straße"
coordinates[1543]=(47.69192,9.84418) # typo plz
df.plz[1543]=88239
coordinates[1590]=(48.04828,10.85568) #abbreviated street name
df.strasse[1590]="Bürgermeister-Doktor-Hartmann-Straße"
coordinates[1591]=(48.73943,11.43608) #typo street
df.strasse[1591]="Münchener Straße"
coordinates[1592]=(48.11368,11.58287) # typo street
df.strasse[1592]="Deisenhofener Straße"
coordinates[1642]=(48.04799,10.85651) #abbreviated street name
df.strasse[1642]="Bürgermeister-Doktor-Hartmann-Straße"
coordinates[1671]=(47.93841,11.29338) #street name unknown to openstreetmap
coordinates[1702]=(47.91462,12.90738) #unknown streetname
coordinates[1715]=(48.73943,11.43608) #typo street
df.strasse[1715]="Bürgermeister-Doktor-Hartmann-Straße"
coordinates[1731]=(48.35093,11.78504) #hard to interpret street name
coordinates[1814]=(49.20353,12.03555) #abbreviated streetname
df.strasse[1814]="Doktor-Sauerbruch-Straße"
coordinates[1857]=(50.11823,11.61302) #wrong streetname
df.strasse[1857]="Adlerhütte"
coordinates[1877]=(49.03426,10.98480) #openstreetmap unaware of house number
coordinates[1904]=(49.51398,11.43641) #typo place
df.ort[1904]="Hersbruck"
coordinates[1909]=(49.03426,10.98480) #openstreetmap unaware of house number
coordinates[2028]=(49.35466,6.73152) #typo street
df.strasse[2028]="Werkstraße"
coordinates[2151]=(52.29563,13.62534) #typo place
df.ort[2151]="Königs Wusterhausen"
coordinates[2152]=(51.78882,14.08067) #typo street
df.strasse[2152]="Bahnhofstraße"
coordinates[2219]=(52.43312,12.51286) #typo street
df.strasse[2219]="Brahmsstraße"
coordinates[2237]=(53.70889,11.82770) # typo street
df.strasse[2237]="Vor dem Pastiner Tor"
coordinates[2367]=(51.14239,13.03314) # pobox instead of street
coordinates[2372]=(51.34294,12.32161)#typo street
df.strasse[2372]="Georg-Schwarz-Straße"
coordinates[2401]=(50.95428,13.75457) #typo street
df.strasse[2401]="Zscheckwitz"
coordinates[2409]=(51.77234,10.79030)#typo place
df.ort[2409]="Elbingerode"
coordinates[2464]=(52.28476,11.37674) #typo street
df.strasse[2464]="Kiefholzstraße"
coordinates[2467]=(51.86930,12.63554) #bad place name
df.ort[2467]="Wittenberg"
coordinates[2480]=(52.08448,11.78025) #typo street
df.strasse[2480]="Sophie-von-Boetticher-Straße"
coordinates[2508]=(51.20868,10.40573) #typo street
df.strasse[2508]="Pfafferode"
coordinates[2518]=(51.10547,10.64914) #typo street
df.strasse[2518]="Rudolf-Weiss_Straße"
coordinates[2583]=(48.74242,9.31920) #typo street
df.strasse[2583]="Mülbergerstraße"
coordinates[2588]=(48.06532,8.49290) #badly typed place
df.ort[2588]="Villingen"

df.coordinates = coordinates
CSV.write("./dataCoord.csv",df)

function pointDistance(x,y) 
    """
    pointDistance(x,y) 

    returns distance in km between point x=(latitiude x,longitude x) and y
    (calculation uses the "haversine formula" and an earth radius of 6365 km)
    """
    dlon = deg2rad(y[2] - x[2])
    dlat = deg2rad(y[1] - x[1])
    a = (sin(dlat/2))^2 + cos(deg2rad(x[1])) * cos(deg2rad(y[1])) * (sin(dlon/2))^2
    c = 2 * atan( sqrt(a), sqrt(1-a) )
    return 6365 * c
end

function crowMatrix(coordinates)
    out = zeros(Float64,length(coordinates),length(coordinates))
    for i in 1:length(coordinates)
        for j in i+1:length(coordinates)
            out[i,j]=pointDistance(coordinates[i],coordinates[j])
            out[j,i]=pointDistance(coordinates[i],coordinates[j])
        end
    end
    return out
end

crowMat = crowMatrix(coordinates)
crowDF = convert(DataFrame,crowMat)
crowDF.name=df.name
CSV.write("./crowMat.csv",crowDF)

function distMatrixOSRM(coordinates,radius)
    """
    distMatrix(coordinates)

    returns a matrix of distances (in km) and driving times (in seconds) between all locations closer than "radius" km (as crow flies) in "coordinates" (fastest route) 
    """
    # create output matrices
    distanceMatrix = zeros(Float64,length(coordinates),length(coordinates))
    timeMatrix = zeros(Float64,length(coordinates),length(coordinates))
    #
    #fill output matrices
    for i in 1:length(coordinates)
        for j in 1:length(coordinates)
            if i!=j
                if crowMat[i,j]<=radius
                    rawdata = HTTP.get(string("http://router.project-osrm.org/route/v1/driving/",coordinates[i][2],",",coordinates[i][1],";",coordinates[j][2],",",coordinates[j][1],"?overview=false"))
                    tdistance, ttime = jsonParsing(String(rawdata.body))
                    distanceMatrix[i,j] = tdistance/1000 #as OSRM returns distance in m 
                    timeMatrix[i,j] = ttime
                    sleep(1)
                else
                    distanceMatrix[i,j] = Inf 
                    timeMatrix[i,j] = Inf
                end
            end
        end
    end
    return distanceMatrix, timeMatrix
end

# this function extracts the relevant info from json formatted output
# necessary as JSON package has problems with output (probably with \" )
function jsonParsing(jsonstring)
    #println(kmlstring[35:150])
    numbers = [i for i in "1234567890."]
    isnotcharnumber(x) = !(x in numbers)
    dstart = collect(findfirst("\"distance\":",jsonstring))[end]+1
    dend = findfirst(isnotcharnumber,jsonstring[dstart:end])+dstart-2
    distance = parse(Float64,jsonstring[dstart:dend])
    tstart = collect(findfirst("\"duration\":",jsonstring))[end]+1
    tend = findfirst(isnotcharnumber,jsonstring[tstart:end])+tstart-2
    ttime = parse(Float64,jsonstring[tstart:tend])
    return distance, ttime
end


distMatrixOSRM(coordinates,50.0)
