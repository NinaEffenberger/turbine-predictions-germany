using AbstractGPs
using KernelFunctions
using NCDatasets
using CSV
using DataFrames
using LinearAlgebra
using Dates
using GeoMakie, CairoMakie
using ParameterHandling  # for nested and constrained parameters
using Optim  # optimization
using Zygote
using Random
using Printf

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

data_u["time"][:]

lon = data_u["lon"][:]
lat = data_u["lat"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))

yearly_turbines = CSV.read("data/turbines_in_2023.csv", DataFrame)
lats_turbines = Array(yearly_turbines.y_coordinates)
lons_turbines = Array(yearly_turbines.x_coordinates)

j = 5
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

# noise from model inputs
k1 = k2 = Matern32Kernel()
kron_kernel = KernelTensorProduct(k1, k2)
#kron_kernel = ScaledKernel(kron_kernel, 0.5)
#kron_kernel = with_lengthscale(kron_kernel, 0.5)
Y = reduce(vcat, RowVecs(speeds_dataset_1))
X = RowVecs(hcat(lats, lons))
θ_init = (; k1_params = (; σ = 0.7, ℓ = 1.5), k2_params = (; σ = 0.7, ℓ = 1.5))
θ_opt = (;
    k1_params = (; σ = 1.890977, ℓ = 4.491976),
    k2_params = (; σ = 1.890977, ℓ = 10.574873),
)

k(θ) = θ.σ^2 * with_lengthscale(Matern32Kernel(), θ.ℓ)
mean_speeds = (speeds_dataset_1 .+ speeds_dataset_2) ./ 2
variance_y =
    (
        (speeds_dataset_1 .- mean_speeds) .^ 2 .+
        (speeds_dataset_2 .- mean_speeds) .^ 2
    ) ./ 2

function build_gp_prior(θ)
    k1 = k2 = k(θ.k1_params)
    k2 = k(θ.k2_params)
    kernel = KernelTensorProduct(k1, k2)
    return GP(kernel)  # [`ZeroMean`](@ref) mean function by default
end
function build_finite_gp(θ, variance_y)
    f = build_gp_prior(θ)
    #return f(X, 0.0001)
    return f(X, diagm(variance_y))
end

function build_posterior_gp(θ, Y, variance_y)
    fx = build_finite_gp(θ, variance_y)
    return posterior(fx, Y)
end

fpost_init = build_posterior_gp(ParameterHandling.value(θ_init))


fpost_opt = build_posterior_gp(ParameterHandling.value(θ_opt))
new_X = RowVecs(hcat(lats_turbines, lons_turbines))
mean_values = mean(fpost_opt, new_X)
mean_values_2 = mean(fpost_init, new_X)

variance = var(fpost_opt, new_X)
variance_y


years = collect(2015:2015)
for i in years
    print(i)
    indices_per_year = findall(x -> x == i, year.(data_u["time"][:]))
    training_set_size = length(indices_per_year)
    loc_mean_speeds = Vector{Vector{Float64}}()
    yearly_turbines = CSV.read(
        "data/turbine_locations/turbines_in_" * string(i) * ".csv",
        DataFrame,
    )
    lats_turbines = yearly_turbines.y_coordinates
    lons_turbines = yearly_turbines.x_coordinates
    #lons_turbines =
    #    (longitudes_turbines .- minimum(longitudes_turbines)) ./
    #    (maximum(longitudes_turbines) - minimum(longitudes_turbines))
    #lats_turbines =
    #    (latitudes_turbines .- minimum(latitudes_turbines)) ./
    #    (maximum(latitudes_turbines) - minimum(latitudes_turbines))
    for j in collect(1:length(indices_per_year))
        u = data_u["uas"][:, :, indices_per_year[1]-1+j]
        v = data_v["vas"][:, :, indices_per_year[1]-1+j]
        u = collect(Iterators.flatten(transpose(u)))
        v = collect(Iterators.flatten(transpose(v)))
        u2 = data_u_2["uas"][:, :, indices_per_year[1]-1+j]
        v2 = data_v_2["vas"][:, :, indices_per_year[1]-1+j]
        u2 = collect(Iterators.flatten(transpose(u2)))
        v2 = collect(Iterators.flatten(transpose(v2)))
        speeds_dataset_1 = vec(sqrt.(u .^ 2 .+ v .^ 2))
        speeds_dataset_2 = vec(sqrt.(u2 .^ 2 .+ v2 .^ 2))
        X = RowVecs(hcat(lats, lons))
        Y = reduce(vcat, RowVecs(speeds_dataset_1))
        θ_opt = (;
            k1_params = (; σ = 1.890977, ℓ = 4.491976),
            k2_params = (; σ = 1.890977, ℓ = 10.574873),
        )
        k(θ) = θ.σ^2 * with_lengthscale(Matern32Kernel(), θ.ℓ)
        mean_speeds = (speeds_dataset_1 .+ speeds_dataset_2) ./ 2
        variance_y =
            (
                (speeds_dataset_1 .- mean_speeds) .^ 2 .+
                (speeds_dataset_2 .- mean_speeds) .^ 2
            ) ./ 2
        fpost_opt =
            build_posterior_gp(ParameterHandling.value(θ_opt), Y, variance_y)
        new_X = RowVecs(hcat(lats_turbines, lons_turbines))
        speeds = mean(fpost_opt, new_X)
        push!(loc_mean_speeds, speeds)
    end
    df = DataFrame(loc_mean_speeds, :auto)
    CSV.write(
        "data/prob_extracted_mean/MPI/" *
        pathway *
        "/yearly/r1_wind_speeds_turbines" *
        string(i) *
        ".csv",
        df,
    )
end