using CSV
using DataFrames
using Plots
using Glob

#Amprion
amprion = CSV.read(
    "data/power_gen/amprion/winddaten-01.01.2010 00_00.csv",
    delim = ';',
    DataFrame,
)

names(amprion)
date_amprion = amprion[:, :"Datum"]
time_amprion = amprion[:,:"Uhrzeit"]
forecast_amprion = amprion[:, :"8:00 Uhr Prognose [MW]"]  
true_amprion = amprion[:, :"8:00 Uhr Prognose [MW]"]  

# data for 2011 to 2014
#-16 IS NOT CORRECCT! JUST DONE TO MATCH THE DIMENSIONS

start_amprion = 365*96-3-16
end_amprion = 365*96*5+76
time_amprion[start_amprion:end_amprion]
date_amprion[start_amprion:end_amprion]


#50Hertz
path = "data/power_gen/50hertz/forecast"  # Specify the directory containing your CSV files
files = glob("*.csv", path)  # Load all CSVs from the folder (wildcard pattern)
dfs = DataFrame.(CSV.File.(files)) 
hertz = reduce(vcat, dfs)
names(hertz)
date_hertz = hertz[:, :"Datum"]
true_hertz = coalesce.(hertz[:, :"MW"], "0")
true_hertz = replace.(true_hertz, "," => ".")
true_hertz = parse.(Float64, true_hertz)

# Tennet 
tennet = CSV.read(
    "data/power_gen/tennet/tennet_windPowerFeedIn_2005-07-13_2015-12-31.csv",
    delim = ';',
    DataFrame,
)
date_tennet = tennet[:,:"Datum"]
time_tennet = tennet[:,:"Startzeit"]
true_tennet =  coalesce.(tennet[:,:"prognostiziert [MW]"], "0")
true_tennet = replace.(true_tennet, "," => ".")
true_tennet = parse.(Float64, true_tennet)
# data for 2011 to 2014
start_tennet = 365*96*5+673
end_tennet = 365*96*9+672+96
time_tennet[end_tennet]
date_tennet[start_tennet:end_tennet]
true_tennet[start_tennet:end_tennet]

#transnet
path = "data/power_gen/transnet"  # Specify the directory containing your CSV files
files = glob("*.csv", path)  # Load all CSVs from the folder (wildcard pattern)
dfs = DataFrame.(CSV.File.(files)) 
transnet = reduce(vcat, dfs)
names(transnet)
# impute missing values with 0 
true_transnet = coalesce.(transnet[:,:"Prognose (MW)"], 0)

all_tsos = true_transnet+forecast_amprion[start_amprion:end_amprion]+true_hertz+true_tennet[start_tennet:end_tennet]

f = Figure()
ax = Axis(f[1, 1])
line1 = lines!(
    collect(1:length(forecast_amprion[start_amprion:end_amprion])),
    cumsum(forecast_amprion[start_amprion:end_amprion]),
    color = "blue",
    label = "low res",
)
line1 = lines!(
    collect(1:length(true_hertz)),
    cumsum(true_hertz),
    color = "blue",
    label = "low res",
)
line1 = lines!(
    collect(1:length(true_tennet[start_tennet:end_tennet])),
    cumsum(true_tennet[start_tennet:end_tennet]),
    color = "blue",
    label = "low res",
)
line1 = lines!(
    collect(1:length(true_transnet)),
    cumsum(true_transnet),
    color = "blue",
    label = "low res",
)
line1 = lines!(
    collect(1:length(true_transnet)),
    cumsum(all_tsos),
    color = "blue",
    label = "low res",
)
#Legend(f[1, 2], [zs, orig, low_res, loc], ["zs", "orig", "low res", "loc"])
#save("plots/0034southern_germany_8000.pdf", f)
display(f)

#daily values
chunks = [all_tsos[i:i+95] for i in 1:96:length(all_tsos)-95]
sums = [sum(chunk) for chunk in chunks]
df = DataFrame(power = sums)
file_path = "data/power_gen/2011-2014-sum4tso-daily-forecast.csv" 
CSV.write(file_path, df)

chunks = [all_tsos[i:i+23] for i in 1:24:length(all_tsos)-23]
sums = [sum(chunk) for chunk in chunks]
df = DataFrame(power = sums)
file_path = "data/power_gen/2011-2014-sum4tso-6hourly-forecast.csv" 
CSV.write(file_path, df)

