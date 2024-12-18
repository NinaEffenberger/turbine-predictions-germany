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

py"""
import windpowerlib

def compute_windpower(weather, hub_heigt, turbine):
    enercon_e126 = {
        #"nominal_power": 6e6,
        "turbine_type": turbine,  # turbine type as in register
        "hub_height": hub_heigt,  # in m
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power

"""


coordinates = CSV.read("data/coordinates/mpi.csv", DataFrame)
coordinates.lats_index
data_u = Dataset(
    "data/generated_data/MPI/ssp370/uas_r1/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_v = Dataset(
    "data/generated_data/MPI/ssp370/vas_r1/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

# Filter the DataFrame for a specific year, for example, 2021
lon = data_u["lon"][:]
lat = data_u["lat"][:]

lats = repeat(lat, size(lon)[1])
#lats = coordinates.lats
len_orig = length(lats)
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
#lons = coordinates.lons
#z = convert(Vector{Float64}, z_orig)
lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))
#lon = (lon .- minimum(lon)) ./ (maximum(lon) - minimum(lon))
#lat = (lat .- minimum(lat)) ./ (maximum(lat) - minimum(lat))

#latitudes and longitudes of turbines 

most_common_turbine = mode(filtered_df.turbine_name)

j = 1
u = data_u["uas"][:, :, j-1+starting_point_cmip6]
v = data_v["vas"][:, :, j-1+starting_point_cmip6]
strength_orig = py"compute_windpower"(transpose(sqrt.(u .^ 2 .+ v .^ 2)))
strength_orig = (transpose(sqrt.(u .^ 2 .+ v .^ 2)))
coordinates.lats_index
lons
strength_orig = [
    strength_orig[i, j] for
    (i, j) in zip(coordinates.lons_index, coordinates.lats_index)
]
speed = vec(transpose(sqrt.(u .^ 2 .+ v .^ 2)))
f = Figure()
ax1 = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Longitude}",
    #ylabel = L"Latitude",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 30,
    xlabelsize = 30,
)
arrows = Makie.heatmap!(ax1, coordinates.lons, coordinates.lats, strength_orig)
#turbines = GeoMakie.scatter!(lons_turbines, lats_turbines; color = "black")
f

j = 1


length_time_dimension = length(data_u["uas"][1, 1, :])

orig_mean_speeds = Vector{Vector{Float64}}()
loc_mean_speeds = Vector{Vector{Float64}}()
for j in collect(1:length_time_dimension)
    u = data_u["uas"][:, :, j]
    v = data_v["vas"][:, :, j]
    u = collect(Iterators.flatten(transpose(u)))
    v = collect(Iterators.flatten(transpose(v)))
    strength_orig = (vec(sqrt.(u .^ 2 .+ v .^ 2)))
    push!(orig_mean_speeds, strength_orig)
end

years = collect(2020:2024)
for i in years
    indices_per_year = findall(x -> x == i, year.(data_u["time"][:]))
    orig_mean_speeds = Vector{Vector{Float64}}()
    for j in collect(1:length(indices_per_year))
        u = data_u["uas"][:, :, indices_per_year[1]-1+j]
        v = data_v["vas"][:, :, indices_per_year[1]-1+j]
        u = collect(Iterators.flatten(transpose(u)))
        v = collect(Iterators.flatten(transpose(v)))
        strength_orig = (vec(sqrt.(u .^ 2 .+ v .^ 2)))
        push!(orig_mean_speeds, strength_orig)
    end
    df2 = DataFrame(orig_mean_speeds, :auto)
    CSV.write(
        "data/extracted_wind_speeds/MPI/ssp370/yearly/r1_orig_wind_speeds_" *
        string(i) *
        ".csv",
        df2,
    )
end

years = collect(2020:2024)

for i in years
    indices_per_year = findall(x -> x == i, year.(data_u["time"][:]))
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
        u = data_u["uas"][:, :, indices_per_year[1]-1+j]
        v = data_v["vas"][:, :, indices_per_year[1]-1+j]
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
        "data/extracted_wind_speeds/MPI/ssp370/yearly/r1_wind_speeds_turbines" *
        string(i) *
        ".csv",
        df,
    )
end

loc_mean_speeds
length(orig_mean_speeds)



df2 = DataFrame(orig_mean_speeds, :auto)
CSV.write("data/extracted_wind_speeds/MPI/ssp370/r1_orig_wind_speeds.csv", df2)

repeat(["E-53/800"], 110)

power_mean = map(
    (x, y) -> py"compute_windpower"(x, y),
    orig_mean_speeds,
    repeat(["E-53/800"], length(orig_mean_speeds)),
)
power_mean_time = [sum(i) for i in power_mean]

filtered_df.hub_height

power = map(
    (x, hub_height, y) -> py"compute_windpower"(x, hub_height, y),
    loc_mean_speeds,
    (filtered_df.hub_height) .- 10,
    filtered_df.turbine_name,
)
location_time = [mean(i) for i in power] * length(lats_turbines)

data
loc_mean_speeds
orig_mean_speeds

orig_low_res_vector = convert(Vector{Float64}, orig_low_res)
orig_mean_speeds_vector = convert(Vector{Float64}, orig_mean_speeds)
loc_mean_speeds_vector = convert(Vector{Float64}, loc_mean_speeds)

tsos = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly.csv",
    delim = ';',
    DataFrame,
)

true_generation = tsos[!, "power"]
location_time[1:365*16]


tsos_forecast = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly-forecast.csv",
    delim = ';',
    DataFrame,
)

true_generation = tsos[!, "power"]
forecasted_gernation = tsos_forecast[!, "power"]

power_mean_time_mw = power_mean_time ./ 1e4
location_time_mw = location_time ./ 1e4
factor1 = cumsum(power_mean_time_mw)[365*4] / cumsum(true_generation)[365*4]
factor2 = cumsum(location_time_mw)[365*4] / cumsum(true_generation)[365*4]

factors1 = Vector{Float64}()
factors2 = Vector{Float64}()
for i in collect(1:365*16)
    factor1 = cumsum(power_mean_time_mw)[i] / cumsum(true_generation)[i]
    factor2 = cumsum(location_time_mw)[i] / cumsum(true_generation)[i]
    push!(factors1, factor1)
    push!(factors2, factor2)
end


f = Figure()
ax = Axis(f[1, 1])
lines!(collect(1:365*16), factors1 ./ maximum(factors1), color = "red")
#lines!(collect(1:365), abs.(cumsum(orig_low_res_vector)/factor-cumsum(forecasted_gernation[1:365]), color = "blue"))
lines!(collect(1:365*16), factors2 ./ maximum(factors2), color = "green")
#lines!(collect(1:365), cumsum(true_generation[1:365]), color = "black")
#lines!(collect(1:365), cumsum(forecasted_gernation[1:365]), color = "gray")
f

f = Figure()
ax = Axis(f[1, 1])
lines!(
    collect(1:365*16),
    (
        cumsum(power_mean_time_mw[1:365*16]) ./ mean(factors1[365*12:365*16]) .-
        cumsum(true_generation[1:365*16])
    ),
    color = "red",
)
lines!(
    collect(1:365*16),
    (
        cumsum(location_time_mw[1:365*16]) ./ mean(factors2[365*12:365*16]) .-
        cumsum(true_generation[1:365*16])
    ),
    color = "green",
)
#lines!(collect(1:365*16), cumsum(true_generation[1:365*16]), color = "black")
f

mean((
    cumsum(power_mean_time_mw[1:365*16]) ./ mean(factors1[365*12:365*16]) .-
    cumsum(true_generation[1:365*16])
))
mean(
    cumsum(location_time_mw[1:365*16]) ./ mean(factors2[365*12:365*16]) .-
    cumsum(true_generation[1:365*16]),
)

corrected_vals_average = power_mean_time_mw[1:365*16] ./ mean(factors1)
corrected_vals_location = location_time_mw[1:365*16] ./ mean(factors2)
cumsum(corrected_vals_average)[365*4] / cumsum(true_generation)[365*4]
cumsum(corrected_vals_average)[365*8] / cumsum(true_generation)[365*8]
cumsum(corrected_vals_average)[365*12] / cumsum(true_generation)[365*12]
cumsum(corrected_vals_average)[365*16] / cumsum(true_generation)[365*16]
cumsum(corrected_vals_location)[365*4] / cumsum(true_generation)[365*4]
cumsum(corrected_vals_location)[365*8] / cumsum(true_generation)[365*8]
cumsum(corrected_vals_location)[365*12] / cumsum(true_generation)[365*12]
cumsum(corrected_vals_location)[365*16] / cumsum(true_generation)[365*16]


true_density = kde(true_generation)
location_density = kde(corrected_vals_location)
average_density = kde(corrected_vals_average)

f = Figure()
ax = Axis(f[1, 1])
#lines!(true_density.x,true_density.density, color = "red")
lines!(
    location_density.x,
    location_density.density - true_density.density,
    color = "green",
)
lines!(
    average_density.x,
    average_density.density - true_density.density,
    color = "black",
)
f



f = Figure()
time = nc["time"][1:365*4]
ax = Axis(f[1, 1])
#lines!(collect(1:100), zs_mean_speeds_vector, color = "black")
num_plot_elements = 10
zs = lines!(
    collect(1:365*4/num_plot_elements),
    zs_mean_speeds_vector[num_plot_elements:num_plot_elements:end] -
    orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end],
    color = "red",
)
low_res = lines!(
    collect(1:365*4/num_plot_elements),
    orig_low_res_vector[num_plot_elements:num_plot_elements:end] -
    orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end],
    color = "blue",
)
loc = lines!(
    collect(1:365*4/num_plot_elements),
    (
        loc_mean_speeds_vector[num_plot_elements:num_plot_elements:end] -
        orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end]
    ),
    color = "green",
)
Legend(f[1, 2], [zs, low_res, loc], ["zs", "low res", "loc"])
save("plots/germany_one_year_diff.pdf", f)
display(f)
f

zs_diff =
    zs_mean_speeds_vector[num_plot_elements:num_plot_elements:end] -
    orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end]
orig_low_diff =
    orig_low_res_vector[num_plot_elements:num_plot_elements:end] -
    orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end]
loc_diff =
    loc_mean_speeds_vector[num_plot_elements:num_plot_elements:end] -
    orig_mean_speeds_vector[num_plot_elements:num_plot_elements:end]

mean(loc_diff)
mean(zs_diff)
mean(orig_low_diff)

Plots.plot(
    time[num_plot_elements:num_plot_elements:end],
    [zs_diff orig_low_diff loc_diff],
    label = ["zs" "orig low res" "loc"],
)


f = Figure()
ax = Axis(f[1, 1])
zs = lines!(
    collect(1:365*4),
    cumsum(zs_mean_speeds_vector),
    color = "black",
    label = "zs",
)
orig = lines!(
    collect(1:365*4),
    cumsum((orig_mean_speeds_vector)),
    color = "red",
    label = "orig",
)
low_res = lines!(
    collect(1:365*4),
    cumsum((orig_low_res_vector)),
    color = "blue",
    label = "low res",
)
loc = lines!(collect(1:365*4), cumsum((loc_mean_speeds_vector)), label = "loc")
Legend(f[1, 2], [zs, orig, low_res, loc], ["zs", "orig", "low res", "loc"])
save("plots/germany_one_year.pdf", f)
display(f)

final_z = cumsum((zs_mean_speeds_vector))[end]
final_orig = cumsum((orig_mean_speeds_vector))[end]
final_low = cumsum((orig_low_res_vector))[end]
final_loc = cumsum((loc_mean_speeds_vector))[end]

final_z / final_orig
final_low / final_orig
final_loc / final_orig
