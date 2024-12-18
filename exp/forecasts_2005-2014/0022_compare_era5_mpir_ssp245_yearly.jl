using CSV
using DataFrames
using PyCall
using LinearAlgebra
using StatsBase
using Makie
using GeoMakie, CairoMakie
using KernelDensity
using Suppressor

directory_path = "data/extracted_wind_speeds/MPI/ssp245/yearly"
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


filtered_df = CSV.read(
    "data/Windenergy_Onshore_V20230420_turbine_name_2011.csv",
    DataFrame,
)

indices = findall(row -> row.hub_height > 50, eachrow(filtered_df))

latitudes_turbines = filtered_df.y_coordinates
longitudes_turbines = filtered_df.x_coordinates
lons_turbines =
    (longitudes_turbines .- minimum(longitudes_turbines)) ./
    (maximum(longitudes_turbines) - minimum(longitudes_turbines))
lats_turbines =
    (latitudes_turbines .- minimum(latitudes_turbines)) ./
    (maximum(latitudes_turbines) - minimum(latitudes_turbines))

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
CSV.write("data/forecasts_cmip6/0021_ssp245_r1_orig.csv", df)

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

power_r3mpi_location_over_time[1]
#save timeseries as csv
power_r3mpi_location_over_time_all = []
for i = 1:length(power_r3mpi_location_over_time)
    push!(power_r3mpi_location_over_time_all, power_r3mpi_location_over_time[i])
end
power_r3mpi_location_over_time_all =
    reshape(collect(Iterators.flatten(power_r3mpi_location_over_time_all)), :)
df = DataFrame(vector = power_r3mpi_location_over_time_all)
CSV.write("data/forecasts_cmip6/0021_ssp245_r1.csv", df)

true_generation = tsos[!, "power"]


factor_era5_mean =
    cumsum(power_era5_mean_over_time)[365*4] / cumsum(true_generation)[365*4]
factor_era5_location =
    cumsum(power_era5_location_over_time)[365*4] /
    cumsum(true_generation)[365*4]
factor_r3mpi_mean =
    cumsum(power_r3mpi_mean_over_time)[365*4] / cumsum(true_generation)[365*4]
factor_r3mpi_location =
    cumsum(power_r3mpi_location_over_time_all)[365*4] /
    cumsum(true_generation)[365*4]

f = Figure()
ax = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Time}",
    ylabel = L"\mathrm{Generated\;power\;(MW)}",
    xticklabelrotation = pi / 4,
    xticks = (
        1:365*4:365*4*10,
        [
            "2015",
            "2016",
            "2017",
            "2018",
            "2019",
            "2020",
            "2021",
            "2022",
            "2023",
            "2024",
        ],
    ),
    xlabelsize = 15,
    ylabelsize = 15,
    xticklabelsize = 12,
    yticklabelsize = 12,
)
era5 = lines!(
    collect(1:length(power_era5_mean_over_time)),
    (
        cumsum(power_era5_mean_over_time) ./ factor_era5_mean .-
        cumsum(true_generation[1:length(power_era5_mean_over_time)])
    ),
)
era5_loc = lines!(
    collect(1:length(power_era5_location_over_time)),
    (
        cumsum(power_era5_location_over_time) ./ factor_era5_location .-
        cumsum(true_generation[1:length(power_era5_location_over_time)])
    ),
)
mpi = lines!(
    collect(1:length(power_r3mpi_mean_over_time)),
    (
        cumsum(
            power_r3mpi_mean_over_time[1:length(power_r3mpi_mean_over_time)],
        ) ./ factor_r3mpi_mean
    ),
)
mpi_loc = lines!(
    collect(1:length(power_r3mpi_location_over_time_all)),
    (
        cumsum(
            power_r3mpi_location_over_time_all[1:length(
                power_r3mpi_location_over_time_all,
            )],
        ) ./ factor_r3mpi_location
    ),
)
true_gen = lines!(
    collect(1:length(power_r3mpi_location_over_time_all)),
    (cumsum(true_generation[1:length(power_r3mpi_location_over_time_all)])),
)
#lines!(collect(1:365*16), cumsum(true_generation[1:365*16]), color = "black")
Legend(
    f[1, 2],
    [true_gen, mpi, mpi_loc],
    [
        L"\mathrm{True}",
        #L"\mathrm{ERA5\;GP}",
        L"\mathrm{MPI\;mean}",
        L"\mathrm{MPI\;GP}",
        # L"\mathrm{True\;generation}",
    ],
    labelsize = 15,
)
save("plots/july/0022_cumulative_mpi245.pdf", f)
f

# wind speed KernelDensity
#true_density = kde(true_generation)
era5_orig_wind_speeds_kde = kde(power_era5_mean_over_time)
era5_wind_speeds_gp_turbines_kde = kde(power_era5_location_over_time)
r3_orig_wind_speeds_kde = kde(power_r3mpi_mean_over_time)
r3_wind_speeds_gp_turbines_kde = kde(power_r3mpi_location_over_time)
true_generation_kde = kde(true_generation)

f = Figure()
ax = Axis(f[1, 1])
#lines!(true_density.x,true_density.density, color = "red")
lines!(
    era5_orig_wind_speeds_kde.x,
    era5_orig_wind_speeds_kde.density,
    color = "green",
)
lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density,
    color = "black",
)
lines!(
    r3_orig_wind_speeds_kde.x,
    r3_orig_wind_speeds_kde.density,
    color = "red",
)
lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density,
    color = "blue",
)
lines!(true_generation_kde.x, true_generation_kde.density, color = "orange")
f

era5_orig_wind_speeds_kde = kde(vcat(era5_orig_wind_speeds...))
era5_wind_speeds_gp_turbines_kde = kde(vcat(era5_wind_speeds_gp_turbines...))
r3_orig_wind_speeds_kde = kde(vcat(r3_orig_wind_speeds...))
r3_wind_speeds_gp_turbines_kde = kde(vcat(r3_wind_speeds_gp_turbines...))
f = Figure()
ax = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Wind\;speed\;}(\frac{m}{s})",
    ylabel = L"\mathrm{Density}",
    xlabelsize = 15,
    ylabelsize = 15,
    xticklabelsize = 12,
    yticklabelsize = 12,
)
era5 = lines!(era5_orig_wind_speeds_kde.x, era5_orig_wind_speeds_kde.density)
era5_loc = lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density,
)
mpi = lines!(r3_orig_wind_speeds_kde.x, r3_orig_wind_speeds_kde.density)
mpi_loc = lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density,
)
Legend(
    f[1, 2],
    [era5, era5_loc, mpi, mpi_loc],
    [
        L"\mathrm{ERA5\;mean}",
        L"\mathrm{ERA5\;GP}",
        L"\mathrm{MPI\;mean}",
        L"\mathrm{MPI\;GP}",
    ],
    labelsize = 15,
)
f
save("plots/probnum/0010_kde_wind.pdf", f)
# subtract true generation from KDE
era5_orig_wind_speeds_kde = kde(power_era5_mean_over_time)
era5_wind_speeds_gp_turbines_kde = kde(power_era5_location_over_time)
r3_orig_wind_speeds_kde = kde(power_r3mpi_mean_over_time)
r3_wind_speeds_gp_turbines_kde = kde(power_r3mpi_location_over_time)
f = Figure()
ax = Axis(f[1, 1])
lines!(
    era5_orig_wind_speeds_kde.x,
    era5_orig_wind_speeds_kde.density - true_generation_kde.density,
)
lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density - true_generation_kde.density,
)
lines!(
    r3_orig_wind_speeds_kde.x,
    r3_orig_wind_speeds_kde.density - true_generation_kde.density,
)
lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density - true_generation_kde.density,
)
Legend(
    f[1, 2],
    [era5, era5_loc, mpi, mpi_loc],
    [
        L"\mathrm{ERA5\;mean}",
        L"\mathrm{ERA5\;GP}",
        L"\mathrm{MPI\;mean}",
        L"\mathrm{MPI\;GP}",
    ],
    labelsize = 15,
)
f
save("plots/probnum/0010_difference_power.pdf", f)


# linear debiasing
era5_orig_wind_speeds_kde = kde(power_era5_mean_over_time ./ factor_era5_mean)
era5_wind_speeds_gp_turbines_kde =
    kde(power_era5_location_over_time ./ factor_era5_location)
r3_orig_wind_speeds_kde = kde(power_r3mpi_mean_over_time ./ factor_r3mpi_mean)
r3_wind_speeds_gp_turbines_kde =
    kde(power_r3mpi_location_over_time ./ factor_r3mpi_location)
f = Figure()
ax = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Wind\;power\; (MW)}",
    ylabel = L"\mathrm{Density}",
    xlabelsize = 15,
    ylabelsize = 15,
    xticklabelsize = 12,
    yticklabelsize = 12,
)
era5 = lines!(
    era5_orig_wind_speeds_kde.x,
    era5_orig_wind_speeds_kde.density - true_generation_kde.density,
)
era5_loc = lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density - true_generation_kde.density,
)
mpi = lines!(
    r3_orig_wind_speeds_kde.x,
    r3_orig_wind_speeds_kde.density - true_generation_kde.density,
)
mpi_loc = lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density - true_generation_kde.density,
)
Legend(
    f[1, 2],
    [era5, era5_loc, mpi, mpi_loc],
    [
        L"\mathrm{ERA5\;mean}",
        L"\mathrm{ERA5\;GP}",
        L"\mathrm{MPI\;mean}",
        L"\mathrm{MPI\;GP}",
    ],
    labelsize = 15,
)
f
save("plots/probnum/0010_difference_power.pdf", f)

# linear debiasing
era5_orig_wind_speeds_kde = kde(power_era5_mean_over_time ./ factor_era5_mean)
era5_wind_speeds_gp_turbines_kde =
    kde(power_era5_location_over_time ./ factor_era5_location)
r3_orig_wind_speeds_kde = kde(power_r3mpi_mean_over_time ./ factor_r3mpi_mean)
r3_wind_speeds_gp_turbines_kde =
    kde(power_r3mpi_location_over_time ./ factor_r3mpi_location)
f = Figure()
ax = Axis(f[1, 1])
lines!(
    era5_orig_wind_speeds_kde.x,
    era5_orig_wind_speeds_kde.density,
    color = "green",
)
lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density,
    color = "black",
)
lines!(
    r3_orig_wind_speeds_kde.x,
    r3_orig_wind_speeds_kde.density,
    color = "red",
)
lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density,
    color = "blue",
)
lines!(true_generation_kde.x, true_generation_kde.density, color = "orange")
f

f = Figure()
ax = Axis(f[1, 1])
lines!(
    era5_orig_wind_speeds_kde.x,
    era5_orig_wind_speeds_kde.density .- true_generation_kde.density,
    color = "green",
)
lines!(
    era5_wind_speeds_gp_turbines_kde.x,
    era5_wind_speeds_gp_turbines_kde.density .- true_generation_kde.density,
    color = "black",
)
lines!(
    r3_orig_wind_speeds_kde.x,
    r3_orig_wind_speeds_kde.density .- true_generation_kde.density,
    color = "red",
)
lines!(
    r3_wind_speeds_gp_turbines_kde.x,
    r3_wind_speeds_gp_turbines_kde.density .- true_generation_kde.density,
    color = "blue",
)
f

