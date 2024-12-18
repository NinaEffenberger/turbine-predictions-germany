using AbstractGPs
using KernelFunctions
using NCDatasets
using CSV
using DataFrames
using LinearAlgebra
using Dates
using GeoMakie, CairoMakie

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

lon = data_u["lon"][:]
lat = data_u["lat"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
#lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
#lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))

yearly_turbines = CSV.read("data/turbines_in_2023.csv", DataFrame)
lats_turbines = Array(yearly_turbines.y_coordinates)
lons_turbines = Array(yearly_turbines.x_coordinates)
#lons_turbines =
#    (longitudes_turbines .- minimum(longitudes_turbines)) ./
#    (maximum(longitudes_turbines) - minimum(longitudes_turbines))
#lats_turbines =
#    (latitudes_turbines .- minimum(latitudes_turbines)) ./
#   (maximum(latitudes_turbines) - minimum(latitudes_turbines))

j = 15
u = data_u["uas"][:, :, j]
v = data_v["vas"][:, :, j]
u2 = data_u_2["uas"][:, :, j]
v2 = data_v_2["vas"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
u2 = collect(Iterators.flatten(transpose(u2)))
v2 = collect(Iterators.flatten(transpose(v2)))
speeds_dataset_1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
speeds_dataset_2 = vec(sqrt.(u .^ 2 .+ v .^ 2))

# constant noise
k1 = k2 = Matern32Kernel()
kron_kernel = KernelTensorProduct(k1, k2)
#kron_kernel = ScaledKernel(kron_kernel, 0.5)
#kron_kernel = with_lengthscale(kron_kernel, 0.5)
Y = reduce(vcat, RowVecs(speeds_dataset_1))
X = RowVecs(hcat(lats, lons))
#Y = ColVecs(reduce(hcat, speeds_dataset_1))
#X, Y = prepare_isotopic_multi_output_data(old_X, Y)
gp = GP(kron_kernel)
fx = gp(X, 0.00001)
p_fx = posterior(fx, Y)
new_X = Vector{Vector{Float64}}(undef, size(lons_turbines))
for i in eachindex(lons_turbines)
    new_X[i] = [lats_turbines[i], lons_turbines[i]]
end
new_X = RowVecs(hcat(lats_turbines, lons_turbines))
speeds_timepoint = mean(p_fx, new_X)
var_timepoint = var(p_fx, new_X)
#speeds = reshape(speeds, Int(length(speeds) / 2), 2)
u = speeds[:, 1]
v = speeds[:, 2]
speeds_timepoint = vec(sqrt.(u .^ 2 .+ v .^ 2))


u = data_u["uas"][:, :, j]
v = data_v["vas"][:, :, j]
u2 = data_u_2["uas"][:, :, j]
v2 = data_v_2["vas"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
u2 = collect(Iterators.flatten(transpose(u2)))
v2 = collect(Iterators.flatten(transpose(v2)))
speed1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
speed2 = vec(sqrt.(u2 .^ 2 .+ v2 .^ 2))
variance_speeds = var(hcat(speed1, speed2), dims = 2)[:, 1]

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
#orig = Makie.heatmap!(ax1, lons, lats, speed1, colorrange = (0, 11))
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = var_timepoint,
    #colorrange = (0, 11),
)
Colorbar(f[1, 2], turbines, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f

# covariance
j = 2
u = data_u["uas"][:, :, j]
v = data_v["vas"][:, :, j]
u2 = data_u_2["uas"][:, :, j]
v2 = data_v_2["vas"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
u2 = collect(Iterators.flatten(transpose(u2)))
v2 = collect(Iterators.flatten(transpose(v2)))
speeds_dataset_1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
speeds_dataset_2 = vec(sqrt.(u2 .^ 2 .+ v2 .^ 2))
k1 = k2 = Matern32Kernel()
kron_kernel = KernelTensorProduct(k1, k2)
#kron_kernel = ScaledKernel(kron_kernel, 0.5)
#kron_kernel = with_lengthscale(kron_kernel, 0.5)
mean_speeds = (speeds_dataset_1 .+ speeds_dataset_2) ./ 2
Y = reduce(vcat, RowVecs(speeds_dataset_1))
X = RowVecs(hcat(lats, lons))
#Y = ColVecs(reduce(hcat, speeds_dataset_1))
#X, Y = prepare_isotopic_multi_output_data(old_X, Y)
gp = GP(kron_kernel)
variance_model_runs =
    var(hcat(speeds_dataset_1, speeds_dataset_2), dims = 2)[:, 1]
variance_y =
    (
        (speeds_dataset_1 .- mean_speeds) .^ 2 .+
        (speeds_dataset_2 .- mean_speeds) .^ 2
    ) ./ 2
fx = gp(X, diagm(mean_vector))
fx = gp(X, 0.00001)
p_fx = posterior(fx, Y)
new_X = Vector{Vector{Float64}}(undef, size(lons_turbines))
for i in eachindex(lons_turbines)
    new_X[i] = [lats_turbines[i], lons_turbines[i]]
end
new_X = RowVecs(hcat(lats_turbines, lons_turbines))
#new_X = RowVecs(hcat(lats, lons))
speeds_timepoint = mean(p_fx, new_X)
var_timepoint = var(p_fx, new_X)
#speeds = reshape(speeds, Int(length(speeds) / 2), 2)

u = data_u["uas"][:, :, j]
v = data_v["vas"][:, :, j]
u2 = data_u_2["uas"][:, :, j]
v2 = data_v_2["vas"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
u2 = collect(Iterators.flatten(transpose(u2)))
v2 = collect(Iterators.flatten(transpose(v2)))
speed1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
speed2 = vec(sqrt.(u2 .^ 2 .+ v2 .^ 2))
variance_speeds = var(hcat(speed1, speed2), dims = 2)[:, 1]

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
orig = Makie.heatmap!(ax1, lons, lats, speeds_dataset_1, colorrange = (0, 11))
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = speeds_timepoint,
    colorrange = (0, 11),
)
Colorbar(f[1, 2], turbines, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f

# compute average variance
variances_speed = Vector{Vector{Float64}}(undef, size(data_u["uas"][1, 1, :]))
for j in eachindex(data_u["uas"][1, 1, :])
    u = data_u["uas"][:, :, j]
    v = data_v["vas"][:, :, j]
    u2 = data_u_2["uas"][:, :, j]
    v2 = data_v_2["vas"][:, :, j]
    u = collect(Iterators.flatten(transpose(u)))
    v = collect(Iterators.flatten(transpose(v)))
    u2 = collect(Iterators.flatten(transpose(u2)))
    v2 = collect(Iterators.flatten(transpose(v2)))
    speed1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
    speed2 = vec(sqrt.(u2 .^ 2 .+ v2 .^ 2))
    variance_speeds = var(hcat(speed1, speed2), dims = 2)[:, 1]
    variances_speed[j] = variance_speeds
end
variances_speed
data_matrix = hcat(variances_speed...)
mean_values = mean(data_matrix, dims = 2)
mean_vector = sqrt.(vec(mean_values))