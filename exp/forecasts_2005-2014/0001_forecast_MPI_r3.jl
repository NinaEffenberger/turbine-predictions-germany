using AbstractGPs
using KernelFunctions
using Plots, Plots.PlotMeasures
using NCDatasets     # open and manipulate NetCDFs
using Plots          # generate simple plots
using Dates          # to work with dates and time indices

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
py"""
import windpowerlib

def compute_windpower(weather, hub_height):
    enercon_e126 = {
        "turbine_type": "V112/3450",  # turbine type as in register
        "hub_height": 84,  # in m
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power

"""
data_u = Dataset("data/generated_data/MPI/uas_r3/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc", "r")
data_v = Dataset("data/generated_data/MPI/vas_r3/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc", "r")

lon = data_u["lon"][:]
lat = data_u["lat"][:]


starting_point_cmip6 = 365*4*6+4
end_point_cmip6 = length(data_u["time"])-1
data_u["time"][starting_point_cmip6:end_point_cmip6]
lats = repeat(lat, size(lon)[1])
len_orig = length(lats)
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
#z = convert(Vector{Float64}, z_orig)
lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))
lon = (lon .- minimum(lon)) ./ (maximum(lon) - minimum(lon))
lat = (lat .- minimum(lat)) ./ (maximum(lat) - minimum(lat))

#latitudes and longitudes of turbines 
fc = GeoJSON.read("data/Windenergy_Onshore_V20230420.geojson")
df = DataFrame(fc)
filtered_df = filter(row -> row.commissioning_date < "2010-12-31", df)

latitudes_turbines = filtered_df.y_coordinates
longitudes_turbines = filtered_df.x_coordinates

lons_turbines = (longitudes_turbines .- minimum(longitudes_turbines)) ./ (maximum(longitudes_turbines) - minimum(longitudes_turbines))
lats_turbines = (latitudes_turbines .- minimum(latitudes_turbines)) ./ (maximum(latitudes_turbines) - minimum(latitudes_turbines))

j = 1
u = data_u["uas"][:,:,j-1+starting_point_cmip6]
v = data_v["vas"][:,:,j-1+starting_point_cmip6]
strength_orig = py"compute_windpower"(vec(transpose(sqrt.(u .^ 2 .+ v .^ 2))))
speed = vec(sqrt.(u .^ 2 .+ v .^ 2))
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
arrows = Makie.heatmap!(ax1, lons, lats, strength_orig)
turbines = GeoMakie.scatter!(lons_turbines, lats_turbines; color = "black")
f

orig_mean_speeds = []
orig_low_res = []
loc_mean_speeds = []
for j in collect(1:365*4)
    u = data_u["uas"][:,:,j-1+starting_point_cmip6]
    v = data_v["vas"][:,:,j-1+starting_point_cmip6]
    u = collect(Iterators.flatten(transpose(u)))
    v = collect(Iterators.flatten(transpose(v)))
    strength_orig = py"compute_windpower"(vec(sqrt.(u .^ 2 .+ v .^ 2)))
    #strength_low = py"compute_windpower"(vec(sqrt.(u .^ 2 .+ v .^ 2)))
    #speeds_orig = sqrt.(abs2.(u) + abs2.(v))
    #strength = vec(sqrt.(u .^ 2 .+ v .^ 2))
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
    #speed_MO = sqrt.(abs2.(u) + abs2.(v))
    strength_loc = py"compute_windpower"(vec(sqrt.(u .^ 2 .+ v .^ 2)))
    push!(loc_mean_speeds, mean(strength_loc))
    push!(orig_mean_speeds, mean(strength_orig))
    #push!(orig_low_res, mean(strength_low))
end


orig_low_res_vector = convert(Vector{Float64}, orig_low_res)
orig_mean_speeds_vector = convert(Vector{Float64}, orig_mean_speeds)
loc_mean_speeds_vector = convert(Vector{Float64}, loc_mean_speeds)

tsos = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly.csv",
    delim = ';',
    DataFrame,
)

true_generation = tsos[!,"power"]
tsos_forecast = CSV.read(
    "data/power_gen/2011-2014-sum4tso-6hourly-forecast.csv",
    delim = ';',
    DataFrame,
)

true_generation = tsos[!,"power"]
forecasted_gernation = tsos_forecast[!,"power"]
factor1 = cumsum(loc_mean_speeds_vector)[end]/cumsum(true_generation[1:365*4])[end]
factor2 = cumsum(orig_mean_speeds_vector)[end]/cumsum(true_generation[1:365*4])[end]

f = Figure()
ax = Axis(f[1, 1])
lines!(collect(1:365*4), (cumsum(orig_mean_speeds_vector[1:365*4])/factor2-cumsum(true_generation[1:365*4])-cumsum(true_generation[1:365])), color = "red")
#lines!(collect(1:365), abs.(cumsum(orig_low_res_vector)/factor-cumsum(forecasted_gernation[1:365]), color = "blue"))
lines!(collect(1:365*4), (cumsum(loc_mean_speeds_vector[1:365*4])/factor1-cumsum(true_generation[1:365*4])), color = "green")
#lines!(collect(1:365), cumsum(true_generation[1:365]), color = "black")
#lines!(collect(1:365), cumsum(forecasted_gernation[1:365]), color = "gray")
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
