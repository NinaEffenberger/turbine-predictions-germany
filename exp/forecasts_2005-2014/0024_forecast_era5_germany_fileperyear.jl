using AbstractGPs
using KernelFunctions
using Plots, Plots.PlotMeasures
using NCDatasets     # open and manipulate NetCDFs
using Plots          # generate simple plots
using Dates          # to work with dates and time indices
using KernelDensity

using PyCall
windpowerlib = pyimport("windpowerlib")

using Random
using Impute
using Missings
using LinearAlgebra
using GeoJSON, DataFrames
using Statistics
using GeoMakie, CairoMakie
using DelimitedFiles
using FFMPEG
using CSV
using Suppressor
using LinearAlgebra
using StatsBase


coordinates = CSV.read("data/coordinates/mpi.csv", DataFrame)
coordinates.lats_index
data_u = Dataset(
    "data/generated_data/MPI/" *
    pathway *
    "/uas_r1/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_v = Dataset(
    "data/generated_data/MPI/" *
    pathway *
    "/vas_r1/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

nc = Dataset("data/ERA5/germany_wind_2014.nc", "r")
year.(nc["time"][:])

years = collect(2011:2023)
for i in years
    nc = Dataset("data/ERA5/germany_wind_" * string(i) * ".nc", "r")
    indices_per_year = findall(x -> x == i, year.(nc["time"][:]))
    orig_mean_speeds = Vector{Vector{Float64}}()
    for j in collect(1:length(indices_per_year))
        u = nc["u10"][:, :, j]
        v = nc["v10"][:, :, j]
        u = collect(Iterators.flatten(transpose(u)))
        v = collect(Iterators.flatten(transpose(v)))
        strength_orig = (vec(sqrt.(u .^ 2 .+ v .^ 2)))
        push!(orig_mean_speeds, strength_orig)
    end
    df2 = DataFrame(orig_mean_speeds, :auto)
    CSV.write(
        "data/extracted_wind_speeds/ERA5/yearly/orig_wind_speeds_" *
        string(i) *
        ".csv",
        df2,
    )
end

nc = Dataset("data/ERA5/germany_wind_2014.nc", "r")

# Filter the DataFrame for a specific year, for example, 2021
lon = nc["longitude"][:]
lat = nc["latitude"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))

years = collect(2022:2023)
for i in years
    nc = Dataset("data/ERA5/germany_wind_" * string(i) * ".nc", "r")
    indices_per_year = findall(x -> x == i, year.(nc["time"][:]))
    loc_mean_speeds = Vector{Vector{Float64}}()
    yearly_turbines = CSV.read(
        "data/turbine_locations/turbines_in_" * string(i) * ".csv",
        DataFrame,
    )
    latitudes_turbines = yearly_turbines.y_coordinates
    longitudes_turbines = yearly_turbines.x_coordinates
    lons_turbines =
        (longitudes_turbines .- minimum(longitudes_turbines)) ./
        (maximum(longitudes_turbines) - minimum(longitudes_turbines))
    lats_turbines =
        (latitudes_turbines .- minimum(latitudes_turbines)) ./
        (maximum(latitudes_turbines) - minimum(latitudes_turbines))
    for j in collect(1:length(indices_per_year))
        print(j)
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
        new_X = Vector{Vector{Float64}}(undef, size(lons_turbines))
        for i in eachindex(lons_turbines)
            new_X[i] = [lats_turbines[i], lons_turbines[i]]
        end
        speeds = mean(p_fx, MOInput(new_X, 2))
        speeds = reshape(speeds, Int(length(speeds) / 2), 2)
        u = speeds[:, 1]
        v = speeds[:, 2]
        speeds_timepoint = vec(sqrt.(u .^ 2 .+ v .^ 2))
        push!(loc_mean_speeds, speeds_timepoint)
    end
    df = DataFrame(loc_mean_speeds, :auto)
    CSV.write(
        "data/extracted_wind_speeds/ERA5/yearly/wind_speeds_turbines" *
        string(i) *
        ".csv",
        df,
    )
end


