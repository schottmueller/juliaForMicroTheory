#to check: Stimmt es, dass der "Nenner" in den QUalitätsberichten das ist was in späteren Jahren  "Grundgesamtheit ist und  "Zaehler" das ist was später "Beobachtete Ereignisse" sind?
#note: keine "Erwartete Ereignisse"

using DataFrames, CSV

########for testing purposes

s = open("/home/christoph/sid/data/GBA2018/Berichte-Teile-A-B-C/260100023-01-2018-xml.xml") do file
        read(file, String);
end;


dftest = DataFrame(name=String[],strasse=String[],hnr=String[],plz=String[],ort=String[],ik=String[],Standortnr=String[],traeger=String[],tArt=String[],betten=Int64[],faelleVollStationaer=Int64[],fealleTeilStationaer=Int64[],faelleAmbulant=Int64[],fullAdress=String[],icd1=Int64[],icd2=Int64[],ops1=Int64[],ops2=Int64[])

dftest2 = DataFrame(name=String[],strasse=String[],hnr=String[],plz=String[],ort=String[],ik=String[],Standortnr=String[],traeger=String[],tArt=String[],betten=Int64[],faelleVollStationaer=Int64[],fealleTeilStationaer=Int64[],faelleAmbulant=Int64[],fullAdress=String[],icd1=Int64[])

#onefile("260100023-01-2018-xml.xml",dftest,["S72.01"],["3-202"])
#allfiles(["S72.01"],["3-202"])


########file management#################

function allfiles(icds,opss;savePath="./",filename="data",dataDirectory="/home/christoph/sid/data/GBA2015/Berichte-Teile-A-B-C2ff/")
    relevantFiles = filter(x -> endswith(x, "xml.xml"), readdir(dataDirectory))
    df = DataFrame(name=String[],strasse=String[],hnr=String[],plz=String[],ort=String[],institutionenkennzeichen=String[],Standortnr=String[],traeger=String[],tArt=String[],betten=Int64[],faelleVollStationaer=Int64[],fealleTeilStationaer=Int64[],faelleAmbulant=Int64[],fullAdress=String[])
    for icd in icds
        df[!,Symbol(icd)] = Int64[]
    end
    for ops in opss
        df[!,Symbol(ops)] = Int64[]
    end
    for f in relevantFiles
        try
            onefile!(dataDirectory*f,df,icds,opss)
        catch
            try
                noname!(dataDirectory*f,df,icds,opss)
                println("in file ",f," the name of the hospital or its owner could not be read. These names are missing in the dataset.")
            catch
                println("error occurred in file ",f,". This file is not represented in the dataset.")
            end
        end
    end
    CSV.write(savePath*filename*".csv",df;delim=";",quotestrings=true)
    return df
end

function onefile!(f,df,icds,opss)
    """
    onefile(f,df,icds,opss)

    Adds a row to the Dataframe df with the data of the hospital in file with filename f.
    the added data consists of address data and the specified icds and opss. Note that icds and opss are of type Array{String} and use an empty Array if e.g. for opss if no opss are searched for.
    """
    s = open(f) do file
        read(file, String);
    end;
    addressData = getaddress(s)
    addressData = reshape(addressData,(1,length(addressData)))
    fullAddress = [addressData[2]*" "*addressData[3]*", "*addressData[4]*" "*addressData[5]]
    infoData = getinfo(s)
    infoData = reshape(infoData,(1,length(infoData)))
    fallzahlen = [getFallzahlICD(s,icd) for icd in icds]
    fallzahlen = reshape(fallzahlen,(1,length(fallzahlen)))
    anzahlen = [getAnzahlOPS(s,ops) for ops in opss]
    anzahlen = reshape(anzahlen,(1,length(anzahlen)))
    push!(df,hcat(addressData,infoData,fullAddress,fallzahlen,anzahlen))
end


#############get addresses############

function extractVariable(fieldName,dataString)
    """
    extractVariable(fieldName,dataString)

    returns the (first) value between <fieldName> and </fieldName> in the string dataString
    """
    #variable = dataString[collect(findfirst("<"*fieldName*">",dataString))[end]+1 : collect(findfirst("</"*fieldName*">",dataString))[1]-1]
    variable = dataString[nextind(dataString,collect(findfirst("<"*fieldName*">",dataString))[end],1) : prevind(dataString,collect(findfirst("</"*fieldName*">",dataString))[1],1)]
    return variable
end

function getaddress(filestring,vars = ["Name","Strasse","Hausnummer","Postleitzahl","Ort","IK","Standortnummer"])
    """
    getaddress(filestring,vars = ["Name","Strasse","Hausnummer","Postleitzahl","Ort","IK","Standortnummer"])

    returns an Array with the values of the variables specified in vars (default is "Name","Strasse","Hausnummer","Postleitzahl","Ort") where the values have to be written in filestring such that the value is between <var> and </var> for each var in vars. Also adds information on owner and capacity.
    """
    if findfirst("<Kontaktdaten>",filestring)!=nothing
        kontaktStart = collect(findfirst("<Kontaktdaten>",filestring))[end]+1
        kontaktEnd = collect(findnext("</Kontaktdaten>",filestring,kontaktStart))[1]-1
        kontaktData = filestring[kontaktStart:kontaktEnd]
    else
        kontaktStart = collect(findfirst("<Krankenhauskontaktdaten>",filestring))[end]+1
        kontaktEnd = collect(findnext("</Krankenhauskontaktdaten>",filestring,kontaktStart))[1]-1
        kontaktData = filestring[kontaktStart:kontaktEnd]
    end
    return extractVariable.(vars,kontaktData)
end

function getinfo(filestring;name=true)
    """
    getinfo(filestring;name=true)

    returns an Array with information on owner and capacity. If name=false the name of the owner is not returned.
    """
    if findfirst("<Krankenhaustraeger>",filestring)!=nothing
        traegerStart = collect(findfirst("<Krankenhaustraeger>",filestring))[end]+1
        traegerEnd = collect(findnext("</Krankenhaustraeger>",filestring,traegerStart))[1]-1
        traegerData = filestring[traegerStart:traegerEnd]
        if typeof(findfirst("<Art>",traegerData))!=Nothing #different software uses different field names for "Art"
            if name
                traegerInfo = extractVariable.(["Name","Art"],traegerData)
            else
                traegerInfo = vcat([""],extractVariable.(["Art"],traegerData))
            end
        else
            if name
                traegerInfo = extractVariable.(["Name","Krankenhaustraeger_Art"],traegerData)
            else
                traegerInfo = vcat([""],extractVariable.(["Krankenhaustraeger_Art"],traegerData))
            end
        end        
    else
        traegerInfo = ["";""]
    end
    if findfirst("<Anzahl_Betten>",filestring)!=nothing
        capStart = collect(findfirst("<Anzahl_Betten>",filestring))[1]
        capEnd = collect(findnext("</Fallzahlen>",filestring,capStart))[1]-1
        capData = filestring[capStart:capEnd]
        capInfo = parse.(Int64,extractVariable.(["Anzahl_Betten","Vollstationaere_Fallzahl","Teilstationaere_Fallzahl","Ambulante_Fallzahl"],capData))
    else
        capInfo = Array{Union{Int64,Missing}}(missing,4,1)
    end
    return vcat(traegerInfo,capInfo)
end


###########get case numbers#############

function getFallzahlICD(filestring,icd)
    """
    getFallzahlICD(fileLines,icd)

    returns the Fallzahl given an ICD_10 code (adds the Fallzahl of all departments if the same ICD is treated at several)
    Note that (i) icd is a string and (ii) fileLines is an Array that has each line of the xml file (in string format) as an element. The original file is assumed to have a structure like:
        <ICD_10>S72.01</ICD_10>
        <Fallzahl>157</Fallzahl>
    """
    out = 0
    allpositions = findall("<ICD_10>"*icd,filestring)
    for k in allpositions
        startinfo = collect(findnext("<Fallzahl",filestring,collect(k)[end]))[end]+1
        if filestring[startinfo]=='>' #to rule out <Fallzahl_Datenschutz/>
            endinfo = collect(findnext("</Fallzahl>",filestring,startinfo))[1]-1
            if startinfo<endinfo
                out += parse(Int64,filestring[startinfo+1:endinfo])
            end
        end
    end
    return out
end

function getAnzahlOPS(filestring,ops)
    """
    getAnzahlOPS(fileLines,ops)

    returns the Fallzahl for all OPS301 codes starting ops (adds the Fallzahl of all departments if the same OPS is treated at several)
    Note that (i) ops is a string and (ii) fileLines is an Array that has each line of the xml file (in string format) as an element. The original file is assumed to have a structure like:
        <OPS_301>3-202</OPS_301>
        <Anzahl>18</Anzahl>
    """
    out = 0
    allpositions = findall("<OPS_301>"*ops,filestring)
    for k in allpositions
        startinfo = collect(findnext("<Anzahl",filestring,collect(k)[end]))[end]+1
        if filestring[startinfo]=='>' #to rule out <Anzahl_Datenschutz/>
            endinfo = collect(findnext("</Anzahl>",filestring,startinfo))[1]-1
            if startinfo<endinfo
                out += parse(Int64,filestring[startinfo+1:endinfo])
            end
        end
    end
    return out
    return out
end


############handling of error cases (no longer necessary)##########

function noname!(f,df,icds,opss)
    s = open(f) do file
        read(file, String);
    end;
    addressData = getaddress(s, ["Strasse","Hausnummer","Postleitzahl","Ort","IK","Standortnummer"])
    pushfirst!(addressData,"")
    addressData = reshape(addressData,(1,length(addressData)))
    fullAddress = [addressData[2]*" "*addressData[3]*", "*addressData[4]*" "*addressData[5]]
    infoData = getinfo(s,name=false)
    infoData = reshape(infoData,(1,length(infoData)))
    fallzahlen = [getFallzahlICD(s,icd) for icd in icds]
    fallzahlen = reshape(fallzahlen,(1,length(fallzahlen)))
    anzahlen = [getAnzahlOPS(s,ops) for ops in opss]
    anzahlen = reshape(anzahlen,(1,length(anzahlen)))
    push!(df,hcat(addressData,infoData,fullAddress,fallzahlen,anzahlen))
end


###usage to produce datafile#####
@time allfiles(["O80","O81","O82","Z38.0","Z38.1","Z38.2","Z38.3","Z38.4","Z38.5","Z38.6"],["5-72","5-724","5-73","5-732.2","5-740","5-741","5-742","5-749","5-749.0"];savePath="./",filename="data",dataDirectory="/home/christoph/sid/data/GBA2015/Berichte-Teile-A-B-C2ff/");






#################################################################
######### Qualitätsindikatoren, i.e. "...Land.xml"Dateien #######
#################################################################

##auxilliary functions

function extractVariableQI(fieldName,dataString; emptyIfMissing=false)
    """
    extractVariable(fieldName,dataString)

    returns the (first) value between <fieldName> and </fieldName> in the string dataString and missing if there is no such entry
    """
    starter = findfirst("<"*fieldName*">",dataString)
    closing = findfirst("</"*fieldName*">",dataString)
    #println(fieldName," ; starter: ",starter,"; closing: ",closing)
    if (starter!=nothing) & (closing!=nothing)
        return dataString[nextind(dataString,collect(starter)[end],1) : prevind(dataString,collect(closing)[1],1)]
    elseif emptyIfMissing
        return " "
    else
        return missing
    end
end

function parseExtended(t)
    if t===missing
        return missing
    elseif t==""
        return missing
    else
        return parse(Float64,replace(t,","=>"."))
    end
end


function refBereich(t)
    if t===missing
        return missing
    elseif '%' in t
        temp = split(t,['%','='])[2]
        temp = replace(temp,"_"=>"")
        return parse(Float64,replace(temp,","=>"."))
    elseif '=' in t
        temp = split(t,['=','('])[2]
        temp = replace(temp,"_"=>"")
        return parse(Float64,replace(temp,","=>"."))
    else
        return missing
    end
end

#work on files/data

function allfilesQI(ids,lbs;savePath="./",filename="dataQI",dataDirectory="/home/christoph/sid/data/GBA2015/Berichte-Teil-C1/",varsString = ["EntwErg","QualBew","QualVgl","EmpBew"],varsFloat=["BErg","Erg","GG","BeobEreig","ErwEreig","RefBereich","VBBlow","VBBhigh","VBKlow","VBKhigh"])
    relevantFiles = filter(x -> endswith(x, "and.xml"), readdir(dataDirectory))
    #create empty dataset and add variables to dataset
    df = DataFrame(institutionenkennzeichen=Union{String,Missing}[],Standortnr=Union{String,Missing}[],year=Union{String,Missing}[])
    for id in ids
        for var in varsString
            df[!,Symbol(id*var)] = Union{String,Missing}[]
        end
        for var in varsFloat
            df[!,Symbol(id*var)] = Union{Float64,Missing}[]
        end
    end
    for lb in lbs
        df[!,Symbol(lb*"_DokRate")] = Union{Float64,Missing}[]
        df[!,Symbol(lb*"_Fallzahl")] = Union{Float64,Missing}[]
    end
    #iterate through files
    for f in relevantFiles
        onefileQI!(dataDirectory*f,df,ids,varsString,varsFloat,lbs)
    end
    #write data to hard disk
    CSV.write(savePath*filename*".csv",df;delim=";",quotestrings=true)
    return df
end

function onefileQI!(f,df,ids,varsString,varsFloat,lbs=Float64[])
    """
    onefile(f,df,ids)

    Adds a row to the Dataframe df with the data of the hospital in file with filename f.
    the added data consists of the vars for all quality indicators in ids. Note that ids and lbs are of type Array{String}. If no information on Leistungsbereiche is wanted, enter [] for lbs or leave it out.
    """
    s = open(f) do file
        read(file, String);
    end;
    s = filter(x->!isspace(x),s)#remove whitespaces
    #get data from file
    identifData = getIdentifQI(s)
    identifData = reshape(identifData,(1,length(identifData)))
    qiData = vcat([getQIData(s,id,varsString,varsFloat) for id in ids]...)
    qiData = reshape(qiData,(1,length(qiData)))
    if lbs!=[]
        lbData = getLBData(s,lbs)
        lbData = reshape(lbData,(1,length(lbData)))
        #put data into dataframe
        #println([length(i) for i in [identifData,qiData,lbData]],"   ",size(df))
        push!(df,hcat(identifData,qiData,lbData))
    else
        push!(df,hcat(identifData,qiData))
    end
end

function getIdentifQI(s)
    extractVariableQI.(["IK_Krankenhaus","Standort","Berichtsjahr"],s)
end

function getQIData(s,id,varsString,varsFloat)
    #dictionary mapping abbreviations as used in variablenames to names in data file
    abbreviations = Dict("EntwErg"=>"Entwicklung_Ergebnis_zum_vorherigen_Berichtsjahr","QualBew"=>"Ergebnis_Berichtsjahr","QualVgl"=>"Vergleich_vorheriges_Berichtsjahr","DokRate"=>"Dokumentationsrate","BErg"=>"Bundesdurchschnitt","VBBlow"=>"Vertrauensbereich_Untere_Grenze","VBBhigh"=>"Vertrauensbereich_Obere_Grenze","Erg"=>"Ergebnis","VBKlow"=>"Vertrauensbereich_Untere_Grenze","VBKhigh"=>"Vertrauensbereich_Obere_Grenze","GG"=>"Grundgesamtheit","BeobEreig"=>"Beobachtete_Ereignisse","ErwEreig"=>"Erwartete_Ereignisse","RefBereich"=>"Referenzbereich","EmpBew"=>"Empirisch_Statistische_Bewertung")
    #determine point where Dokumentationsraten end and actual quality indicators start
    temp0 = findfirst("<Ergebnis>",s)
    if temp0!=nothing #this is the case if the hospital reported some quality indicators
        endDokRates = collect(temp0)[end]
        #println("EndDokRates: ",endDokRates, " id:",id)
        #find part of file with the quality indicator id
        temp = findnext("<Kuerzel_Qualitaetsindikator>"*id,s,endDokRates)
        #println("temp: ",temp)
        if temp!=nothing #is the case if the id is found in the file
            position = collect(temp)[end]
            #println("Pos1: ",findprev("<QS-Ergebnis>",s,position))
            startpoint = collect(findprev("<Qualitaetsindikator>",s,position))[end]
            #println("Pos2: ",findnext("</QS-Ergebnis>",s,position))
            endpoint = collect(findnext("</Qualitaetsindikator>",s,position))[1]
            relevantString = s[startpoint:endpoint]
            #get the variables connected tot he quality indicator
            out1 = [extractVariableQI(abbreviations[var],relevantString) for var in varsString]
            out2 = parseExtended.([extractVariableQI(abbreviations[var],relevantString) for var in varsFloat[1:end-5]])
            out3 = [refBereich(extractVariableQI("Referenzbereich",relevantString))]
            out4 = parseExtended.(extractVariableQI.(["Vertrauensbereich_Untere_Grenze","Vertrauensbereich_Obere_Grenze"],extractVariableQI("Vertrauensbereich_Bundesweit",relevantString;emptyIfMissing=true)))
            out5 = parseExtended.(extractVariableQI.(["Vertrauensbereich_Untere_Grenze","Vertrauensbereich_Obere_Grenze"],extractVariableQI("Vertrauensbereich_Krankenhaus",relevantString;emptyIfMissing=true)))
            #LB = extractVariableQI("Kuerzel_Leistungsbereich",relevantString)
            return vcat(out1,out2,out3,out4,out5)
        else #is the case if id is not in file
            return [missing for i in 1:length(varsString)+length(varsFloat)]
        end
    else #in case the hospital reported no quality indicators
        return [missing for i in 1:length(varsString)+length(varsFloat)]
    end
end

function getLBData(s,lbs)
    #dokRateString = extractVariableQI("Dokumentationsraten",s;emptyIfMissing=true)
    temp0 = findfirst("<Ergebnis>",s)
    if temp0!=nothing
        dokRateString = s[1:collect(temp0)[1]]
    else
        dokRateString = s
    end
    out = Array{Union{Float64,Missing},1}(undef,2*length(lbs))
    for (i,lb) in enumerate(lbs)
        temp = findfirst("<Kuerzel>"*lb,dokRateString)
        if temp!=nothing #is the case of the file contains information on this lbs code
            dokStart = collect(temp)[1]
            dokEnd = collect(findnext("</Leistungsbereich",dokRateString,dokStart))[1]
            out[2*i-1]=parseExtended(extractVariableQI("Dokumentationsrate",dokRateString[dokStart:dokEnd]))
            if out[2*i-1]===missing #very few hospitals report bounds for Dokumentationsrate instead of points
                temp1 = parseExtended(extractVariableQI("Dokumentationsrate_Untere_Grenze",dokRateString[dokStart:dokEnd]))
                temp2 = parseExtended(extractVariableQI("Dokumentationsrate_Obere_Grenze",dokRateString[dokStart:dokEnd]))
                if !(temp1===missing)
                    out[2*i-1]=(temp1+temp2)/2
                end
            end
            out[2*i] = parseExtended(extractVariableQI("Fallzahl",dokRateString[dokStart:dokEnd]))
        end
   end
   return out
end


#####usage to produce data file
@time allfilesQI(["52249","50722"],["09/3","PNEU"];savePath="./",filename="dataQI",dataDirectory="/home/christoph/sid/data/GBA2015/Berichte-Teil-C1/",varsString = ["EntwErg","QualBew","QualVgl","EmpBew"],varsFloat=["BErg","Erg","GG","BeobEreig","ErwEreig","RefBereich","VBBlow","VBBhigh","VBKlow","VBKhigh"]);
