
"""
Generate files that include power generation for 2011-2014 and 2015-2023 respectively. See README.md for source of original files. 
"""
using CSV
using DataFrames
using Plots
using Glob
#= everything here is in MW
=#

#Amprion
amprion = CSV.read(
    "data/power_gen/amprion/winddaten-01.01.2010 00_00.csv",
    delim = ';',
    DataFrame,
)

names(amprion)
date_amprion = amprion[:, :"Datum"]
time_amprion = amprion[:, :"Uhrzeit"]
forecast_amprion = amprion[:, :"8:00 Uhr Prognose [MW]"]
true_amprion = amprion[:, :"8:00 Uhr Prognose [MW]"]

# data for 2011 to 2014
#-16 IS NOT CORRECCT! JUST DONE TO MATCH THE DIMENSIONS

start_amprion = 365 * 96 - 3 - 16
end_amprion = 365 * 96 * 5 + 76
time_amprion[start_amprion:end_amprion]
date_amprion[start_amprion:end_amprion]


#50Hertz
path = "data/power_gen/50hertz"  # Specify the directory containing your CSV files
files = glob("*.csv", path)  # Load all CSVs from the folder (wildcard pattern)
dfs = DataFrame.(CSV.File.(files))
hertz = reduce(vcat, dfs)
names(hertz)
date_hertz = hertz[:, :"Datum"]
true_hertz = hertz[:, :"MW"]

# Tennet 
tennet = CSV.read(
    "data/power_gen/tennet/tennet_windPowerFeedIn_2005-07-13_2015-12-31.csv",
    delim = ';',
    DataFrame,
)
date_tennet = tennet[:, :"Datum"]
time_tennet = tennet[:, :"Startzeit"]
true_tennet = tennet[:, :"tatsaechlich [MW]"]
true_tennet = replace.(true_tennet, "," => ".")
true_tennet = parse.(Float64, true_tennet)
# data for 2011 to 2014
start_tennet = 365 * 96 * 5 + 673
end_tennet = 365 * 96 * 9 + 672 + 96
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
true_transnet = coalesce.(transnet[:, :"Ist-Wert (MW)"], 0)

all_tsos =
    true_transnet +
    true_amprion[start_amprion:end_amprion] +
    true_hertz +
    true_tennet[start_tennet:end_tennet]

#daily values
chunks = [all_tsos[i:i+95] for i = 1:96:length(all_tsos)-95]
sums = [sum(chunk) for chunk in chunks]
df = DataFrame(power = sums)
file_path = "data/power_gen/2011-2014-sum4tso-daily.csv"
CSV.write(file_path, df)

chunks = [all_tsos[i:i+23] for i = 1:24:length(all_tsos)-23]
sums = [sum(chunk) for chunk in chunks]
df = DataFrame(power = sums)
file_path = "data/power_gen/2011-2014-sum4tso-6hourly.csv"
CSV.write(file_path, df)

# power generation after 2015
amprion = CSV.read(
    "data/power_gen/amprion/winddaten-01.01.2010 00_00.csv",
    delim = ';',
    DataFrame,
)

generation_2015_2023 = CSV.read(
    "data/power_gen/Actual_generation_201501010000_202401010000_Hour.csv",
    delim = ';',
    DataFrame,
)

function swap_dots_and_commas(s)
    s = replace(s, "," => "")
    #s = replace(s, "." => ",")
    return s
end

wind_power =
    generation_2015_2023[!, "Wind onshore [MWh] Calculated resolutions"]
wind_power = map((x) -> swap_dots_and_commas(x), wind_power)
wind_power = parse.(Float64, wind_power)
chunks = [wind_power[i:i+5] for i = 1:6:length(wind_power)-5]
sums = [sum(chunk) for chunk in chunks]
df = DataFrame(power = sums)
file_path = "data/power_gen/2015-2023-sum4tso-6hourly.csv"
CSV.write(file_path, df)