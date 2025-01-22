"""
Predict wind power per turbine location for Germany with SSP370 including the first and second run of the MPI model, wind speeds are extracted in 0003prob_forcasts_speed_optim_ssp370.jl. Predictions are from 2025 to 2050. Turbine data is generated in other/0002_find_turbine.jl.  
"""
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
directory_path = "data/extracted_wind_speeds/MPI/" * pathway
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

data_frames["r1_orig_wind_speeds_2025"]


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

filtered_df = CSV.read("data/turbines_in_2024.csv", DataFrame)
lats_turbines = filtered_df.y_coordinates


years = collect(2025:2050)
for year_var in years
    r3_orig_wind_speeds = data_frames["r1_orig_wind_speeds_"*string(year_var)]
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

    power_r3mpi_location_over_time =
        DataFrame(vector = power_r3mpi_mean_over_time)
    CSV.write(
        "data/power_forecasts/" *
        pathway *
        "/orig/wind_power" *
        string(year_var) *
        ".csv",
        power_r3mpi_location_over_time,
    )
end


years = collect(2025:2050)
#power_r3mpi_location_over_time = []
for year in years
    print(year)
    #indices = findall(row -> row.hub_height > 50, eachrow(filtered_df))
    r3_wind_speeds_gp_turbines = CSV.read(
        "data/prob_extracted_mean/MPI/" *
        pathway *
        "/yearly/r1/r1_wind_speeds_turbines" *
        string(year) *
        ".csv",
        DataFrame,
    )
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
    power_r3mpi_location_over_time =
        mean(power_r3mpi_location) * nrow(filtered_df) ./ 1e4
    power_r3mpi_location_over_time =
        DataFrame(value = power_r3mpi_location_over_time)
    CSV.write(
        "data/power_forecasts/" *
        pathway *
        "/turbines/wind_power" *
        string(year) *
        ".csv",
        power_r3mpi_location_over_time,
    )
end
