using CSV
using DataFrames
using PyCall
using LinearAlgebra
using StatsBase
using Makie
using GeoMakie, CairoMakie
using KernelDensity
using Suppressor

pathway = "SSP370"
directory_path = "data/extracted_wind_speeds/MPI/past/" * pathway
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

# Function to rename columns generically
function rename_columns(df::DataFrame, prefix::String)
    new_names = [Symbol(prefix * string(i)) for i = 1:ncol(df)]
    rename!(df, new_names)
end


r3_orig_wind_speeds = hcat(
    rename_columns(data_frames["r1_orig_wind_speeds_2015"], "1"),
    rename_columns(data_frames["r1_orig_wind_speeds_2016"], "2"),
    rename_columns(data_frames["r1_orig_wind_speeds_2017"], "3"),
    rename_columns(data_frames["r1_orig_wind_speeds_2018"], "4"),
    rename_columns(data_frames["r1_orig_wind_speeds_2019"], "5"),
    rename_columns(data_frames["r1_orig_wind_speeds_2020"], "6"),
    rename_columns(data_frames["r1_orig_wind_speeds_2021"], "7"),
    rename_columns(data_frames["r1_orig_wind_speeds_2022"], "8"),
    rename_columns(data_frames["r1_orig_wind_speeds_2023"], "9"),
)

tsos = CSV.read(
    "data/power_gen/2015-2023-sum4tso-6hourly.csv",
    delim = ';',
    DataFrame,
)


py"""
import windpowerlib
import pandas as pd
from windpowerlib import data as wt
df = pd.read_csv('data/turbine_data.csv')
def remove_semicolon_and_convert_to_float(input_string):
    before_semicolon = input_string.partition(';')[0]
    return float(before_semicolon)

def compute_windpower(weather, turbine):
    try:
        all_hubheights = df[df["turbine_type"].str.contains(turbine)].hub_height.values
        hubheight = remove_semicolon_and_convert_to_float(all_hubheights[0])
    #if there's no info regarding hub height in the database
    except:
        hubheight=100
    enercon_e126 = {
        "turbine_type": turbine,  # turbine type as in register
        "hub_height": hubheight,  # in m
        #"rotor_diameter":5
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power
"""

function wind_speed_to_hub_height(wind, hub_height)
    alpha = 1 / 7
    reference_height = 10
    speed_hub_height = wind * (hub_height / reference_height)^alpha
    return speed_hub_height
end

filtered_df = CSV.read(
    "data/Windenergy_Onshore_V20230420_turbine_name_2011.csv",
    DataFrame,
)

lats_turbines = filtered_df.y_coordinates


r3_orig_wind_speeds = [
    Vector{Float64}(r3_orig_wind_speeds[!, col]) for
    col in names(r3_orig_wind_speeds)
]
r3_orig_wind_speeds = map(
    (x, y) -> wind_speed_to_hub_height(x, y),
    r3_orig_wind_speeds,
    repeat([mean(filtered_df.hub_height)], length(r3_orig_wind_speeds)),
)
power_r3mpi_mean = map(
    py"compute_windpower",
    r3_orig_wind_speeds,
    repeat(["E-53/800"], length(r3_orig_wind_speeds)),
)

power_r3mpi_mean_over_time =
    [mean(i) for i in power_r3mpi_mean] * length(lats_turbines) ./ 1e4

df = DataFrame(vector = power_r3mpi_mean_over_time)
CSV.write("data/power_forecasts/past/" * pathway * "_r1_orig.csv", df)


directory_path = "data/prob_extracted_mean/MPI/past/" * pathway * "/"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

years = collect(2015:2023)
power_r3mpi_location_over_time = []
for year in years
    print(year)
    filtered_df = CSV.read(
        "data/turbine_locations/turbines_in_" * (string(year)) * ".csv",
        DataFrame,
    )
    #indices = findall(row -> row.hub_height > 50, eachrow(filtered_df))
    r3_wind_speeds_gp_turbines =
        data_frames["r1_wind_speeds_turbines"*string(year)]
    r3_wind_speeds_gp_turbines =
        [collect(row) for row in eachrow(r3_wind_speeds_gp_turbines)]

    r3_wind_speeds_gp_turbines = map(
        (x, y) -> wind_speed_to_hub_height(x, y),
        r3_wind_speeds_gp_turbines,
        filtered_df.hub_height,
    )
    @suppress begin
        global power_r3mpi_location = map(
            py"compute_windpower",
            r3_wind_speeds_gp_turbines,
            filtered_df.turbine_name,
            #repeat(["E-53/800"], length(r3_wind_speeds_gp_turbines)),
            #filtered_df.hub_height,
        )
    end
    push!(
        power_r3mpi_location_over_time,
        mean(power_r3mpi_location) * nrow(filtered_df) ./ 1e4,
    )
end

power_r3mpi_location_over_time_all = []
for i = 1:length(power_r3mpi_location_over_time)
    push!(power_r3mpi_location_over_time_all, power_r3mpi_location_over_time[i])
end
power_r3mpi_location_over_time_all =
    reshape(collect(Iterators.flatten(power_r3mpi_location_over_time_all)), :)
df = DataFrame(vector = power_r3mpi_location_over_time_all)
CSV.write("data/power_forecasts/past/" * pathway * "_r1_turbines.csv", df)

years = collect(2015:2023)
power_r3mpi_location_over_time = []
for year in years
    print(year)
    filtered_df = CSV.read(
        "data/turbine_locations/turbines_in_" * (string(year)) * ".csv",
        DataFrame,
    )
    #indices = findall(row -> row.hub_height > 50, eachrow(filtered_df))
    r3_wind_speeds_gp_turbines =
        data_frames["r1_orig_wind_speeds_"*string(year)]
    r3_wind_speeds_gp_turbines =
        [collect(row) for row in eachrow(r3_wind_speeds_gp_turbines)]

    r3_wind_speeds_gp_turbines = map(
        (x, y) -> wind_speed_to_hub_height(x, y),
        r3_wind_speeds_gp_turbines,
        mean(filtered_df.hub_height),
    )
    @suppress begin
        global power_r3mpi_location = map(
            py"compute_windpower",
            r3_wind_speeds_gp_turbines,
            #mode(filtered_df.turbine_name),
            repeat(["E-53/800"], length(r3_wind_speeds_gp_turbines)),
            #filtered_df.hub_height,
        )
    end
    push!(
        power_r3mpi_location_over_time,
        mean(power_r3mpi_location) * nrow(filtered_df) ./ 1e4,
    )
end
#save timeseries as csv
power_r3mpi_location_over_time_all = []
for i = 1:length(power_r3mpi_location_over_time)
    push!(power_r3mpi_location_over_time_all, power_r3mpi_location_over_time[i])
end
power_r3mpi_location_over_time_all =
    reshape(collect(Iterators.flatten(power_r3mpi_location_over_time_all)), :)
df = DataFrame(vector = power_r3mpi_location_over_time_all)
CSV.write(
    "data/power_forecasts/past/" * pathway * "_r1_orig_numturbines.csv",
    df,
)