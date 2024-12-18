using CSV
using DataFrames

r3_orig_wind_speeds = CSV.read(
    "data/extracted_wind_speeds/MPI/r3_orig_wind_speeds.csv",
    DataFrame,
)
r3_wind_speeds_gp_turbines = CSV.read(
    "data/extracted_wind_speeds/MPI/r3_wind_speeds_gp_turbines.csv",
    DataFrame,
)
era5_orig_wind_speeds_2011 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2011/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2012 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2012/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2013 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2013/orig_wind_speeds.csv",
    DataFrame,
)
era5_orig_wind_speeds_2014 = CSV.read(
    "data/extracted_wind_speeds/ERA5/2014/orig_wind_speeds.csv",
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
tsos = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly.csv",
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

era5_orig_wind_speeds = hcat(
    era5_orig_wind_speeds_2011,
    era5_orig_wind_speeds_2012,
    era5_orig_wind_speeds_2013,
    era5_orig_wind_speeds_2014,
)

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
)

py"""
import windpowerlib

def compute_windpower(weather, turbine):
    enercon_e126 = {
        #"nominal_power": 6e6,
        "turbine_type": turbine,  # turbine type as in register
        "hub_height": 80,  # in m
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power

"""

# year 2011+2012
r3_orig_wind_speeds_2011 = r3_orig_wind_speeds[:, 1:365*16+4]
r3_wind_speeds_gp_turbines_2011 = r3_wind_speeds_gp_turbines[:, 1:365*16+4]

era5_orig_wind_speeds = [
    Vector{Float64}(era5_orig_wind_speeds[!, col]) for
    col in names(era5_orig_wind_speeds)
]
power_era5_mean = map(
    (x, y) -> py"compute_windpower"(x, y),
    era5_orig_wind_speeds,
    repeat(["E-53/800"], length(era5_orig_wind_speeds)),
)
power_era5_mean_over_time =
    [mean(i) for i in power_era5_mean] * length(lats_turbines) ./ 1e4

era5_wind_speeds_gp_turbines = [
    Vector{Float64}(era5_wind_speeds_gp_turbines[!, col]) for
    col in names(era5_wind_speeds_gp_turbines)
]
power_era5_location = map(
    (x, y) -> py"compute_windpower"(x, y),
    era5_wind_speeds_gp_turbines,
    filtered_df.turbine_name,
    #repeat(["E-53/800"], length(r3_orig_wind_speeds_2011)),
)
power_era5_location_over_time =
    [mean(i) for i in power_era5_location] * length(lats_turbines) ./ 1e4


r3_orig_wind_speeds_2011 = [
    Vector{Float64}(r3_orig_wind_speeds_2011[!, col]) for
    col in names(r3_orig_wind_speeds_2011)
]
power_r3mpi_mean = map(
    (x, y) -> py"compute_windpower"(x, y),
    r3_orig_wind_speeds_2011,
    repeat(["E-53/800"], length(r3_orig_wind_speeds_2011)),
)
power_r3mpi_mean_over_time =
    [mean(i) for i in power_r3mpi_mean] * length(lats_turbines) ./ 1e4

r3_wind_speeds_gp_turbines_2011 = [
    Vector{Float64}(r3_wind_speeds_gp_turbines_2011[!, col]) for
    col in names(r3_wind_speeds_gp_turbines_2011)
]
power_r3mpi_location = map(
    (x, y) -> py"compute_windpower"(x, y),
    r3_wind_speeds_gp_turbines_2011,
    filtered_df.turbine_name,
    # repeat(["E-53/800"], length(r3_orig_wind_speeds_2011)),
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
ax = Axis(f[1, 1])
lines!(
    collect(1:length(power_era5_mean_over_time)),
    (
        cumsum(power_era5_mean_over_time) ./ factor_era5_mean .-
        cumsum(true_generation[1:length(power_era5_mean_over_time)])
    ),
    color = "red",
)
lines!(
    collect(1:length(power_era5_location_over_time)),
    (
        cumsum(power_era5_location_over_time) ./ factor_era5_location .-
        cumsum(true_generation[1:length(power_era5_location_over_time)])
    ),
    color = "black",
)
lines!(
    collect(1:length(power_era5_mean_over_time)),
    (
        cumsum(power_r3mpi_mean_over_time) ./ factor_r3mpi_mean .-
        cumsum(true_generation[1:length(power_era5_mean_over_time)])
    ),
    color = "blue",
)
lines!(
    collect(1:length(power_era5_mean_over_time)),
    (
        cumsum(power_r3mpi_location_over_time) ./ factor_r3mpi_location .-
        cumsum(true_generation[1:length(power_era5_mean_over_time)])
    ),
    color = "green",
)
f
lines!(
    collect(1:length(power_era5_mean_over_time)),
    (cumsum(true_generation[1:length(power_era5_mean_over_time)])),
    color = "orange",
)
#lines!(collect(1:365*16), cumsum(true_generation[1:365*16]), color = "black")
f