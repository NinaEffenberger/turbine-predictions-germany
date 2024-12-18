using AbstractGPs
using KernelFunctions
using Plots, Plots.PlotMeasures
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
using DelimitedFiles
using CSV
using FFMPEG

nc = Dataset("data/ERA5/germany_wind_2014.nc", "r")
#nc = Dataset("/Users/ninaeffenberger/Downloads/data-long-2.nc", "r")
#nc = Dataset("data/data.nc")
print(nc["time"][:])
lon = nc["longitude"][:]
lat = nc["latitude"][:]
lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))
lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
#=

for j in collect(1:20)
    u = nc["u100"][:, :, j]
    v = nc["v100"][:, :, j]
    f = Figure()
    ax = Axis(f[1, 1])
    u = collect(Iterators.flatten(transpose(u)))
    v = collect(Iterators.flatten(transpose(v)))
    strength = vec(sqrt.(u .^ 2 .+ v .^ 2))

    #Makie.scatter!(longitudes, latitudes, markersize = 10, color = "black")

    plot = arrows!(
        ax,
        lons,
        lats,
        u,
        v,
        arrowsize = 10,
        lengthscale = 0.2,
        arrowcolor = strength,
        #linecolor = strength,
        normalize = true,
        colorrange = (0.0, 34.0),
    )
    Colorbar(f[1, 2], plot, label = "Wind speed", width = 10, ticklabelsize = 8)
    folder_path = "plots_TAC/normal"
    filename = joinpath(folder_path, "plot_$(j).png")
    Makie.save(filename, f, px_per_unit = 4)
end

=#
nc = Dataset("data/ERA5/germany_wind_2011.nc", "r")
loc_mean_speeds = Vector{Vector{Float64}}()
yearly_turbines =
    CSV.read("data/turbine_locations/turbines_in_2011.csv", DataFrame)
latitudes_turbines_2011 = yearly_turbines.y_coordinates
longitudes_turbines_2011 = yearly_turbines.x_coordinates
lons_turbines_2011 =
    (longitudes_turbines_2011 .- minimum(longitudes_turbines_2011)) ./
    (maximum(longitudes_turbines_2011) - minimum(longitudes_turbines_2011))
lats_turbines_2011 =
    (latitudes_turbines_2011 .- minimum(latitudes_turbines_2011)) ./
    (maximum(latitudes_turbines_2011) - minimum(latitudes_turbines_2011))
j = 1
u = nc["u10"][:, :, j]
v = nc["v10"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
old_X = Vector{Vector{Float64}}(undef, size(lats))
for i in eachindex(lats)
    old_X[i] = [lats[i], lons[i]]
end
k1 = k2 = k3 = Matern32Kernel()
kron_kernel = IndependentMOKernel(k1)
Y = Vector{Vector{Float64}}(undef, size(u))
for i in eachindex(u)
    Y[i] = [u[i], v[i]]
end
Y = ColVecs(reduce(hcat, Y))
X, Y = prepare_isotopic_multi_output_data(old_X, Y)
gp = GP(kron_kernel)
fx = gp(X, 0.0001)
p_fx = posterior(fx, Y)
new_X = Vector{Vector{Float64}}(undef, size(lons_turbines_2011))
for i in eachindex(lons_turbines_2011)
    new_X[i] = [lats_turbines_2011[i], lons_turbines_2011[i]]
end
speeds = mean(p_fx, MOInput(new_X, 2))
speeds = reshape(speeds, Int(length(speeds) / 2), 2)
u_2011 = speeds[:, 1]
v_2011 = speeds[:, 2]
speeds_timepoint_2011 = vec(sqrt.(u_2011 .^ 2 .+ v_2011 .^ 2))

nc = Dataset("data/ERA5/germany_wind_2023.nc", "r")
loc_mean_speeds = Vector{Vector{Float64}}()
yearly_turbines =
    CSV.read("data/turbine_locations/turbines_in_2023.csv", DataFrame)
latitudes_turbines_2023 = yearly_turbines.y_coordinates
longitudes_turbines_2023 = yearly_turbines.x_coordinates
lons_turbines_2023 =
    (longitudes_turbines_2023 .- minimum(longitudes_turbines_2023)) ./
    (maximum(longitudes_turbines_2023) - minimum(longitudes_turbines_2023))
lats_turbines_2023 =
    (latitudes_turbines_2023 .- minimum(latitudes_turbines_2023)) ./
    (maximum(latitudes_turbines_2023) - minimum(latitudes_turbines_2023))
j = 1
u = nc["u10"][:, :, j]
v = nc["v10"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
old_X = Vector{Vector{Float64}}(undef, size(lats))
for i in eachindex(lats)
    old_X[i] = [lats[i], lons[i]]
end
k1 = k2 = k3 = Matern32Kernel()
kron_kernel = IndependentMOKernel(k1)
Y = Vector{Vector{Float64}}(undef, size(u))
for i in eachindex(u)
    Y[i] = [u[i], v[i]]
end
Y = ColVecs(reduce(hcat, Y))
X, Y = prepare_isotopic_multi_output_data(old_X, Y)
gp = GP(kron_kernel)
fx = gp(X, 0.0001)
p_fx = posterior(fx, Y)
new_X = Vector{Vector{Float64}}(undef, size(lons_turbines_2023))
for i in eachindex(lons_turbines_2023)
    new_X[i] = [lats_turbines_2023[i], lons_turbines_2023[i]]
end
speeds = mean(p_fx, MOInput(new_X, 2))
speeds = reshape(speeds, Int(length(speeds) / 2), 2)
u_2023 = speeds[:, 1]
v_2023 = speeds[:, 2]
speeds_timepoint_2023 = vec(sqrt.(u_2023 .^ 2 .+ v_2023 .^ 2))
T = Theme(fontsize = 17, size = (500, 300))

with_theme(T) do
    f = Figure()
    ax1 = Axis(
        f[1, 1],
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    plot = Makie.scatter!(
        ax1,
        longitudes_turbines_2011,
        latitudes_turbines_2011,
        color = speeds_timepoint_2011,
        markersize = 3,
        #normalize = true,
        colorrange = (0.0, 18.0),
    )
    Colorbar(
        f[1, 3],
        plot,
        label = L"Wind\;speed\;(\frac{m}{s})",
        width = 10,
        #ticklabelsize = 8,
    )
    f
    ax2 = Axis(
        f[1, 2],
        xticks = (6:4:15, ["6E", "10E", "14E"]),
        yticks = (47.5:2:55, ["48N", "50N", "52N", "54N"]),
    )
    plot = Makie.scatter!(
        ax2,
        longitudes_turbines_2023,
        latitudes_turbines_2023,
        color = speeds_timepoint_2023,
        markersize = 3,
        #normalize = true,
        colorrange = (0.0, 18.0),
    )
    hideydecorations!(ax2)
    f
    folder_path = "plots/pdfs"
    filename =
        joinpath(folder_path, "arrows_at_turbine_locations_new_legend.pdf")
    Makie.save(filename, f, px_per_unit = 4)
end
#display(current_figure())
folder_path = "plots/paper/pdfs"
filename = joinpath(folder_path, "arrows_at_turbine_locations.pdf")
Makie.save(filename, f, px_per_unit = 4)


# Run ffmpeg command to create the animated GIF
ffmpeg_path = "/opt/homebrew/bin/ffmpeg"

input_files_pattern = joinpath(input_folder, "plot_%d.png")

# Run ffmpeg command to create the animated GIF
run(`$ffmpeg_path -framerate 2 -i $input_files_pattern $output_gif`)