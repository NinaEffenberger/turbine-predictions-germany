using CSV
using DataFrames
using PyCall
using LinearAlgebra
using StatsBase
using Makie
using GeoMakie, CairoMakie
using KernelDensity


r3_orig_wind_speeds = CSV.read(
    "data/extracted_wind_speeds/MPI/ssp370/r1_orig_wind_speeds.csv",
    DataFrame,
)
r3_wind_speeds_gp_turbines = CSV.read(
    "data/extracted_wind_speeds/MPI/ssp370/r1_wind_speeds_gp_turbines.csv",
    DataFrame,
)
era5_orig_wind_speeds_2011 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2015/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2012 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2016/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2013 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2017/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2014 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2018/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2015 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2019/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2016 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2020/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2017 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2021/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2018 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2022/orig_wind_speeds.csv",
    DataFrame,
)
era5_wind_speeds_gp_turbines_2011 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2011/wind_speeds_gp_turbines.csv",
    DataFrame,
)
era5_wind_speeds_gp_turbines_2012 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2012/wind_speeds_gp_turbines.csv",
    DataFrame,
)

era5_wind_speeds_gp_turbines_2013 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2013/wind_speeds_gp_turbines.csv",
    DataFrame,
)

era5_wind_speeds_gp_turbines_2014 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2014/wind_speeds_gp_turbines.csv",
    DataFrame,
)

filtered_df = CSV.read(
    "data/Windenergy_Onshore_V20230420_turbine_name_2011.csv",
    DataFrame,
)

# all turbines that are >50m
indices = findall(row -> row.hub_height > 50, eachrow(filtered_df))

tsos = CSV.read(
    "data/power_gen/tso_power_generation.csv",
    delim = ';',
    DataFrame,
)

# Function to rename columns generically
function rename_columns(df::DataFrame, prefix::String)
    new_names = [Symbol(prefix * string(i)) for i = 1:ncol(df)]
    rename!(df, new_names)
end

# Rename columns of each DataFrame
era5_orig_wind_speeds_2011 = rename_columns(era5_orig_wind_speeds_2011, "col1_")
era5_orig_wind_speeds_2012 = rename_columns(era5_orig_wind_speeds_2012, "col2_")
era5_orig_wind_speeds_2013 = rename_columns(era5_orig_wind_speeds_2013, "col3_")
era5_orig_wind_speeds_2014 = rename_columns(era5_orig_wind_speeds_2014, "col4_")
era5_orig_wind_speeds_2015 = rename_columns(era5_orig_wind_speeds_2015, "col5_")
era5_orig_wind_speeds_2016 = rename_columns(era5_orig_wind_speeds_2016, "col6_")
era5_orig_wind_speeds_2017 = rename_columns(era5_orig_wind_speeds_2017, "col7_")
era5_orig_wind_speeds_2018 = rename_columns(era5_orig_wind_speeds_2018, "col8_")

era5_orig_wind_speeds = hcat(
    era5_orig_wind_speeds_2011,
    era5_orig_wind_speeds_2012,
    era5_orig_wind_speeds_2013,
    era5_orig_wind_speeds_2014,
    era5_orig_wind_speeds_2015,
    era5_orig_wind_speeds_2016,
    era5_orig_wind_speeds_2017,
    era5_orig_wind_speeds_2018,
)

era5_orig_wind_speeds_2011 = nothing
era5_orig_wind_speeds_2012 = nothing
era5_orig_wind_speeds_2013 = nothing
era5_orig_wind_speeds_2014 = nothing

era5_wind_speeds_gp_turbines_2011 =
    rename_columns(era5_wind_speeds_gp_turbines_2011, "col1_")
era5_wind_speeds_gp_turbines_2012 =
    rename_columns(era5_wind_speeds_gp_turbines_2012, "col2_")
era5_wind_speeds_gp_turbines_2013 =
    rename_columns(era5_wind_speeds_gp_turbines_2013, "col3_")
era5_wind_speeds_gp_turbines_2014 =
    rename_columns(era5_wind_speeds_gp_turbines_2014, "col4_")
era5_wind_speeds_gp_turbines = hcat(
    era5_wind_speeds_gp_turbines_2011,
    era5_wind_speeds_gp_turbines_2012,
    era5_wind_speeds_gp_turbines_2013,
    era5_wind_speeds_gp_turbines_2014,
)[
    indices,
    :,
]

era5_orig_wind_speeds_gp_turbines_2011 = nothing
era5_orig_wind_speeds_gp_turbines_2012 = nothing
era5_orig_wind_speeds_gp_turbines_2013 = nothing
era5_orig_wind_speeds_gp_turbines_2014 = nothing

#latitudes and longitudes of turbines 
filtered_df = CSV.read(
    "data/Windenergy_Onshore_V20230420_turbine_name_2011.csv",
    DataFrame,
)
#filtered_df = filter(row -> row.commissioning_date < "2010-12-31", df)

latitudes_turbines = filtered_df.y_coordinates[indices]
longitudes_turbines = filtered_df.x_coordinates[indices]
lons_turbines =
    (longitudes_turbines .- minimum(longitudes_turbines)) ./
    (maximum(longitudes_turbines) - minimum(longitudes_turbines))
lats_turbines =
    (latitudes_turbines .- minimum(latitudes_turbines)) ./
    (maximum(latitudes_turbines) - minimum(latitudes_turbines))

py"""
import windpowerlib

def compute_windpower(weather, turbine, hub_height):
    enercon_e126 = {
        #"nominal_power": 6e6,
        "turbine_type": turbine,  # turbine type as in register
        "hub_height": hub_height,  # in m
        "rotor_diameter":5
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

# year 2011+2012
r3_orig_wind_speeds = r3_orig_wind_speeds[:, :]
r3_wind_speeds_gp_turbines = r3_wind_speeds_gp_turbines[indices, :]



era5_orig_wind_speeds = [
    Vector{Float64}(era5_orig_wind_speeds[!, col]) for
    col in names(era5_orig_wind_speeds)
]

era5_orig_wind_speeds = map(
    (x, y) -> wind_speed_to_hub_height(x, y),
    era5_orig_wind_speeds,
    repeat(
        [mean(filtered_df.hub_height[indices])],
        length(era5_orig_wind_speeds),
    ),
)

power_era5_mean = map(
    (x, y, z) -> py"compute_windpower"(x, y, z),
    era5_orig_wind_speeds,
    repeat(["E-53/800"], length(era5_orig_wind_speeds)),
    repeat(
        [mean(filtered_df.hub_height[indices])],
        length(era5_orig_wind_speeds),
    ),
)
power_era5_mean_over_time =
    [mean(i) for i in power_era5_mean] * length(lats_turbines) ./ 1e4

era5_wind_speeds_gp_turbines = [
    Vector{Float64}(era5_wind_speeds_gp_turbines[!, col]) for
    col in names(era5_wind_speeds_gp_turbines)
]
era5_wind_speeds_gp_turbines = map(
    (x, y) -> wind_speed_to_hub_height(x, y),
    era5_wind_speeds_gp_turbines,
    filtered_df.hub_height[indices],
)
power_era5_location = map(
    (x, y, z) -> py"compute_windpower"(x, y, z),
    era5_wind_speeds_gp_turbines,
    #filtered_df.turbine_name,
    repeat(["E-53/800"], length(era5_wind_speeds_gp_turbines)),
    filtered_df.hub_height,
)
power_era5_location_over_time =
    [mean(i) for i in power_era5_location] * length(lats_turbines) ./ 1e4


r3_orig_wind_speeds = [
    Vector{Float64}(r3_orig_wind_speeds[!, col]) for
    col in names(r3_orig_wind_speeds)
]
r3_orig_wind_speeds = map(
    (x, y) -> wind_speed_to_hub_height(x, y),
    r3_orig_wind_speeds,
    repeat(
        [mean(filtered_df.hub_height[indices])],
        length(r3_orig_wind_speeds),
    ),
)
power_r3mpi_mean = map(
    (x, y, z) -> py"compute_windpower"(x, y, z),
    r3_orig_wind_speeds,
    repeat(["E-53/800"], length(r3_orig_wind_speeds)),
    repeat(
        [mean(filtered_df.hub_height[indices])],
        length(r3_orig_wind_speeds),
    ),
)
power_r3mpi_mean_over_time =
    [mean(i) for i in power_r3mpi_mean] * length(lats_turbines) ./ 1e4

r3_wind_speeds_gp_turbines = [
    Vector{Float64}(r3_wind_speeds_gp_turbines[!, col]) for
    col in names(r3_wind_speeds_gp_turbines)
]
r3_wind_speeds_gp_turbines =
    r3_wind_speeds_gp_turbines = map(
        (x, y) -> wind_speed_to_hub_height(x, y),
        r3_wind_speeds_gp_turbines,
        filtered_df.hub_height[indices],
    )
power_r3mpi_location = map(
    (x, y, z) -> py"compute_windpower"(x, y, z),
    r3_wind_speeds_gp_turbines,
    #filtered_df.turbine_name,
    repeat(["E-53/800"], length(r3_orig_wind_speeds)),
    filtered_df.hub_height,
)
power_r3mpi_location_over_time =
    [mean(i) for i in power_r3mpi_location] * length(lats_turbines) ./ 1e4


true_generation = tsos[!, "power"]


factor_era5_mean =
    cumsum(power_era5_mean_over_time)[365*4] / cumsum(true_generation)[365*4]
factor_era5_location =
    cumsum(power_era5_location_over_time)[365*4] /
    cumsum(true_generation)[365*4]
factor_r3mpi_mean =
    cumsum(power_r3mpi_mean_over_time)[365*4] / cumsum(true_generation)[365*4]
factor_r3mpi_location =
    cumsum(power_r3mpi_location_over_time)[365*4] /
    cumsum(true_generation)[365*4]

f = Figure()
ax = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Time}",
    ylabel = L"\mathrm{Generated\;power\;(MW)}",
    xticklabelrotation = pi / 4,
    xticks = (1:365*4:365*16, ["2011", "2012", "2013", "2014"]),
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
    collect(1:length(true_generation)),
    (
        cumsum(power_r3mpi_mean_over_time[1:length(true_generation)]) ./
        factor_r3mpi_mean .-
        cumsum(true_generation[1:length(true_generation)])
    ),
)
mpi_loc = lines!(
    collect(1:length(true_generation)),
    (
        cumsum(power_r3mpi_location_over_time[1:length(true_generation)]) ./
        factor_r3mpi_location .-
        cumsum(true_generation[1:length(true_generation)])
    ),
)
true_gen = lines!(
    collect(1:length(power_r3mpi_location_over_time)),
    (cumsum(true_generation[1:length(power_r3mpi_location_over_time)])),
)
#lines!(collect(1:365*16), cumsum(true_generation[1:365*16]), color = "black")
Legend(
    f[1, 2],
    [era5, mpi, mpi_loc],
    [
        L"\mathrm{ERA5\;mean}",
        #L"\mathrm{ERA5\;GP}",
        L"\mathrm{MPI\;mean}",
        L"\mathrm{MPI\;GP}",
        # L"\mathrm{True\;generation}",
    ],
    labelsize = 15,
)
save("plots/probnum/0010_cumulative_mpi.pdf", f)
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

