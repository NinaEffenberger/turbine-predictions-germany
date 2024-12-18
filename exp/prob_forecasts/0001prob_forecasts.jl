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
fx = gp(X, 0.00001)
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
orig = Makie.heatmap!(ax1, lons, lats, speed1, colorrange = (0, 11))
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = speeds_timepoint,
    colorrange = (0, 11),
)
Colorbar(f[1, 2], orig, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f


j = 1
u = data_u["uas"][:, :, j]
v = data_v["vas"][:, :, j]
u2 = data_u_2["uas"][:, :, j]
v2 = data_v_2["vas"][:, :, j]
u = collect(Iterators.flatten(transpose(u)))
v = collect(Iterators.flatten(transpose(v)))
u2 = collect(Iterators.flatten(transpose(u2)))
v2 = collect(Iterators.flatten(transpose(v2)))
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
variance_u = var(hcat(u, u2), dims = 2)[:, 1]
variance_v = var(hcat(v, v2), dims = 2)[:, 1]
var_total = vcat(variance_u, variance_v)
fx = gp(X, diagm(var_total))
fx = gp(X, 0.00001)
p_fx = posterior(fx, Y)
new_X = Vector{Vector{Float64}}(undef, size(lons))
for i in eachindex(lons)
    new_X[i] = [lats[i], lons[i]]
end
speeds = mean(p_fx, MOInput(new_X, 2))
speeds = reshape(speeds, Int(length(speeds) / 2), 2)
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
orig = Makie.heatmap!(ax1, lons, lats, speed1)
f
orig = Makie.heatmap!(ax1, lons, lats, speed2)
f
orig = Makie.heatmap!(ax1, lons, lats, variance_speeds)
f
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = speeds_timepoint,
    colorrange = (0, 11),
)
Colorbar(f[1, 2], orig, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f

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

data_v["vas"][:, :, :] .- data_v_2["vas"][:, :, :]
var(hcat(1, 13), dims = 2)[:, 1]
vars_test = collect(
    Iterators.flatten(
        transpose(
            var((data_u["uas"][:, :, :] .- data_u_2["uas"][:, :, :]), dims = 3)[
                :,
                :,
                1,
            ],
        ),
    ),
)
vars_test ./ speed1
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
#arrows = Makie.heatmap!(ax1, coordinates.lons, coordinates.lats, strength_orig)
turbines = Makie.heatmap!(
    ax1,
    lons,
    lats,
    vars_test ./ speed1,
    #colorrange = (0.0, 15),
)
Colorbar(f[1, 2], turbines, label = "Colorbar")
f

speeds = mean(p_fx, MOInput(new_X, 2))
speeds = reshape(speeds, Int(length(speeds) / 2), 2)
u = speeds[:, 1]
v = speeds[:, 2]
speeds_timepoint = vec(sqrt.(u .^ 2 .+ v .^ 2))
final_var = var(p_fx, MOInput(new_X, 2))
final_var = reshape(final_var, Int(length(final_var) / 2), 2)
finale_var_u = final_var[:, 1]
finale_var_v = final_var[:, 2]

sigma =
    sqrt.(
        (u .^ 2 .* finale_var_u + v .^ 2 .* finale_var_v) ./ (u .^ 2 + v .^ 2)
    )


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
orig = Makie.heatmap!(
    ax1,
    lons,
    lats,
    sqrt.(variance_speeds),
    colorrange = (0, 5.5),
)
f
turbines = GeoMakie.scatter!(
    lons_turbines,
    lats_turbines;
    color = sigma,
    colorrange = (0, 1),
)
Colorbar(f[1, 2], turbines, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f