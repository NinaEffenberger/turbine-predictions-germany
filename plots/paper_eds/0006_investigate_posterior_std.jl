"""
Plot posterior standard deviation for the four pathways in 2050. 
"""
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

T = Theme(fontsize = 17, size = (500, 400))

directory_path = "data/prob_extracted_var/MPI/ssp126"
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

mean_var_per_loc_126 = mean.(eachrow(wind_speeds_gp_turbines_variance))

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

mean_var_per_loc_245 = mean.(eachrow(wind_speeds_gp_turbines_variance))

directory_path = "data/prob_extracted_var/MPI/ssp370"
files = readdir(directory_path, join = true)
data_frames_variances = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames_variances[base_name] = df
end

wind_speeds_gp_turbines_variance =
    data_frames_variances["r1_wind_speeds_turbines2050"]

mean_var_per_loc_360 = mean.(eachrow(wind_speeds_gp_turbines_variance))

directory_path = "data/prob_extracted_var/MPI/ssp585"
files = readdir(directory_path, join = true)
data_frames_variances = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames_variances[base_name] = df
end

wind_speeds_gp_turbines_variance =
    data_frames_variances["r1_wind_speeds_turbines2050"]

mean_var_per_loc_585 = mean.(eachrow(wind_speeds_gp_turbines_variance))

with_theme(T) do
    f = Figure()
    ax1 = Axis(
        f[1, 1],
        xticklabelsize = 20,
        yticklabelsize = 20,
        ylabelsize = 20,
        xlabelsize = 20,
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    turbines = GeoMakie.scatter!(
        lons_turbines,
        lats_turbines;
        color = sqrt.(mean_var_per_loc_126),
        colorrange = (0.3, 0.5),
        markersize = 3,
    )
    #save("plots/september/0001noisy_input_one_dataset.pdf", f)
    ax2 = Axis(
        f[1, 2],
        xticklabelsize = 20,
        yticklabelsize = 20,
        ylabelsize = 20,
        xlabelsize = 20,
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    turbines = GeoMakie.scatter!(
        ax2,
        lons_turbines,
        lats_turbines;
        color = sqrt.(mean_var_per_loc_245),
        colorrange = (0.3, 0.5),
        markersize = 3,
    )
    ax3 = Axis(
        f[2, 1],
        xticklabelsize = 20,
        yticklabelsize = 20,
        ylabelsize = 20,
        xlabelsize = 20,
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    turbines = GeoMakie.scatter!(
        ax3,
        lons_turbines,
        lats_turbines;
        color = sqrt.(mean_var_per_loc_360),
        colorrange = (0.3, 0.5),
        markersize = 3,
    )
    ax4 = Axis(
        f[2, 2],
        xticklabelsize = 20,
        yticklabelsize = 20,
        ylabelsize = 20,
        xlabelsize = 20,
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    turbines = GeoMakie.scatter!(
        ax4,
        lons_turbines,
        lats_turbines;
        color = sqrt.(mean_var_per_loc_585),
        colorrange = (0.3, 0.5),
        markersize = 3,
    )
    hidexdecorations!(ax1, grid = false)
    hidexdecorations!(ax2, grid = false)
    hideydecorations!(ax4, grid = false)
    hideydecorations!(ax2, grid = false)
    Colorbar(f[1:2, 3], turbines)
    save("plots/pdfs/0006_posterior_std.pdf", f)
    f
end