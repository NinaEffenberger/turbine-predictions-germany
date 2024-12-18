using CSV
using DataFrames
using Plots
#  real generation: https://www.smard.de/home/downloadcenter/download-marktdaten

# Load the CSV file into a DataFrame
df = CSV.read(
    "/Users/ninaeffenberger/Downloads/Realisierte_Erzeugung_201501010000_201601010000_Woche.csv",
    delim = ';',
    DataFrame,
)

# Display the contents of the DataFrame
names(df)
wind = df[:, :"Wind Onshore [MWh] Berechnete Auflösungen"]  # Access the 'Name' column

wind = replace.(wind, "." => "")
wind = replace.(wind, "," => ".")
wind = parse.(Float64, wind)
#df = CSV.read("output.csv", delim = ',', DataFrame, header = false)
#multi = CSV.read("multi_output.csv", delim = ',', DataFrame, header = false)

Plots.plot(cumsum(wind))

#more wind data from individual providers: https://open-power-system-data.org/data-sources



