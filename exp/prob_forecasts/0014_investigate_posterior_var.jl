using CSV
using DataFrames
using Statistics
using NCDatasets
using Makie
using CSV
using DataFrames
using NCDatasets     # open and manipulate NetCDFs
using Plots          # generate simple plots
using Dates          # to work with dates and time indices
using Random
using Impute
using Missings
using LinearAlgebra
using GeoJSON, DataFrames
using Statistics
using GeoMakie, CairoMakie
using CSV
using Colors

directory_path = "data/prob_extracted_var/MPI/ssp245"
files = readdir(directory_path, join = true)
data_frames_variances = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames_variances[base_name] = df
end

wind_speeds_gp_turbines_variance =
    data_frames_variances["r1_wind_speeds_turbines2050"]

yearly_turbines = CSV.read("data/turbines_in_2024.csv", DataFrame)
lats_turbines = yearly_turbines.y_coordinates
lons_turbines = yearly_turbines.x_coordinates

mean_var_per_loc = mean.(eachrow(wind_speeds_gp_turbines_variance))

f = Figure()
ax1 = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Longitude}",
    ylabel = L"\mathrm{Latitude}",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 20,
    xlabelsize = 20,
)
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = sqrt.(mean_var_per_loc),
    colorrange = (0.3, 0.5),
)
Colorbar(f[1, 2], turbines)
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f

pathway = "ssp370"
path = "data/original/past/"
data_u = Dataset(
    path *
    pathway *
    "/r1/u/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_v = Dataset(
    path *
    pathway *
    "/r1/v/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_u_2 = Dataset(
    path *
    pathway *
    "/r2/u/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_v_2 = Dataset(
    path *
    pathway *
    "/r2/v/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

us = data_u["uas"][:, :, 1:365*4]
vs = data_v["vas"][:, :, 1:365*4]
wind_speeds_1 = sqrt.(us .^ 2 + vs .^ 2)

us2 = data_u_2["uas"][:, :, 1:365*4]
vs2 = data_v_2["vas"][:, :, 1:365*4]
wind_speeds_2 = sqrt.(us2 .^ 2 + vs2 .^ 2)

mean_speeds = (wind_speeds_1 .+ wind_speeds_2) ./ 2
avrg_mean = vec(transpose(mean(mean_speeds, dims = 3)[:, :, 1]))
variance =
    (
        (wind_speeds_1 .- mean_speeds) .^ 2 .+
        (wind_speeds_2 .- mean_speeds) .^ 2
    ) ./ 2
avrg_var = (vec(transpose(mean(variance, dims = 3)[:, :, 1])))

lon = data_u["lon"][:]
lat = data_u["lat"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
ax3 = Axis(
    f[1, 3],
    xlabel = L"\mathrm{Longitude}",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 20,
    xlabelsize = 20,
)
linkyaxes!(ax1, ax3)
linkxaxes!(ax1, ax3)
orig = Makie.heatmap!(ax3, lons, lats, avrg_var ./ avrg_mean)
Colorbar(f[1, 4], orig)
save("plots/september/0014posterior_var_data_var_2015.pdf", f)
f