using CSV
using DataFrames
using PyCall
using Statistics
using GeoJSON
using Makie
using GLMakie, CairoMakie

tsos = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly.csv",
    delim = ';',
    DataFrame,
)

true_generation = tsos[!, "power"]

power_era5_location_over_time =
    CSV.read(
        "data/forecasts_era5/0038_era5_turbines_historical.csv",
        DataFrame,
    ).vector

power_era5_mean_over_time =
    CSV.read("data/forecasts_era5/0038_era5_orig.csv", DataFrame).vector

pathway = "historical/"
directory_path = "data/power_forecasts/" * pathway * "all/"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
df_all = DataFrame()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    append!(df_all, df)
    data_frames[base_name] = df
end
power_r3mpi_location_over_time = df_all.value

power_r3mpi_mean_over_time =
    CSV.read(
        "data/power_forecasts/historical/0021_historical_r1_orig.csv",
        DataFrame,
    ).vector
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

T = Theme(fontsize = 17, size = (500, 400))


with_theme(T) do
    f = Figure()
    ax = Axis(
        f[1, 1],
        #xlabel = L"\mathrm{}",
        ylabel = L"\mathrm{Relative\;generated\;power}",
        xticklabelrotation = pi / 4,
        xticks = (1:365*4:365*4*4, ["2012", "2013", "2014", "2015"]),
    )
    mpi_loc = Makie.lines!(
        collect(1:length(power_r3mpi_location_over_time[365*4:end])),
        ((cumsum(
            power_r3mpi_location_over_time,
        )./factor_r3mpi_location)./(cumsum(
            true_generation[1:length(power_r3mpi_location_over_time)],
        )))[365*4:end],
        color = "#0072B2",
    )
    mpi_mean = Makie.lines!(
        collect(1:length(power_r3mpi_mean_over_time[365*4:end])),
        ((cumsum(
            power_r3mpi_mean_over_time,
        )./factor_r3mpi_mean)./(cumsum(
            true_generation[1:length(power_r3mpi_location_over_time)],
        )))[365*4:end],
        color = "#E69F00",
    )
    f
    length(power_era5_location_over_time[365*4:end])
    era5_loc = Makie.lines!(
        collect(1:length(power_era5_location_over_time[365*4:end])),
        ((cumsum(
            power_era5_location_over_time,
        )./factor_era5_location)./(cumsum(
            true_generation[1:length(power_era5_location_over_time)],
        )))[365*4:end],
        color = "#009E73",
    )
    f
    era5_mean = Makie.lines!(
        collect(1:length(power_era5_mean_over_time[365*4:end])),
        ((cumsum(
            power_era5_mean_over_time,
        )./factor_era5_mean)./(cumsum(
            true_generation[1:length(power_era5_mean_over_time)],
        )))[365*4:end],
        color = "#CC79A7",
    )
    #lines!(collect(1:365*16), cumsum(true_generation[1:365*16]), color = "black")
    f
    Legend(
        f[0, 1],
        [era5_mean, era5_loc, mpi_mean, mpi_loc],
        [
            L"\mathrm{ERA5\;mean\;(90.51%)}",
            L"\mathrm{ERA5\;location\;(105.02%)}",
            L"\mathrm{MPI\;mean\;(87.49%)}",
            L"\mathrm{MPI\;location\;(99.22%)}",
        ],
        halign = :left,
        valign = :top,
        orientation = :horizontal,
        nbanks = 2,
        labelsize = 17,
        framecolor = :white,
        padding = (-35, 0, 0, 0),
    )
    save("plots/pdfs/0001power_generation_historical_relative.pdf", f)
    f
end

(cumsum(power_era5_mean_over_time)[end] / factor_era5_mean) /
cumsum(true_generation)[end]
(cumsum(power_era5_location_over_time)[end] / factor_era5_location) /
cumsum(true_generation)[end]
(cumsum(power_r3mpi_location_over_time)[end] / factor_r3mpi_location) /
cumsum(true_generation)[end]
(cumsum(power_r3mpi_mean_over_time)[end] / factor_r3mpi_mean) /
cumsum(true_generation)[end]
