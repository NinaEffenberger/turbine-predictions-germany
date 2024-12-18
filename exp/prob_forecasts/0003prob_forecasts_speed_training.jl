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
function build_finite_gp(θ)
    f = build_gp_prior(θ)
    #return f(X, 0.0001)
    return f(X, diagm(variance_y))
end

function build_posterior_gp(θ)
    fx = build_finite_gp(θ)
    return posterior(fx, Y)
end

fpost_init = build_posterior_gp(ParameterHandling.value(θ_init))

function loss(θ)
    fx = build_finite_gp(θ)
    lml = logpdf(fx, Y)  # this computes the log marginal likelihood
    return -lml
end

default_optimizer = GradientDescent(;
    alphaguess = Optim.LineSearches.InitialStatic(; scaled = true),
    linesearch = Optim.LineSearches.BackTracking(),
)

function optimize_loss(
    loss,
    θ_init;
    optimizer = default_optimizer,
    maxiter = 1_000,
)
    options = Optim.Options(; iterations = maxiter, show_trace = false)

    θ_flat_init, unflatten = ParameterHandling.value_flatten(θ_init)
    loss_packed = loss ∘ unflatten

    ## https://julianlsolvers.github.io/Optim.jl/stable/#user/tipsandtricks/#avoid-repeating-computations
    function fg!(F, G, x)
        if F !== nothing && G !== nothing
            val, grad = Zygote.withgradient(loss_packed, x)
            G .= only(grad)
            return val
        elseif G !== nothing
            grad = Zygote.gradient(loss_packed, x)
            G .= only(grad)
            return nothing
        elseif F !== nothing
            return loss_packed(x)
        end
    end

    result = optimize(
        Optim.only_fg!(fg!),
        θ_flat_init,
        optimizer,
        options;
        inplace = false,
    )

    return unflatten(result.minimizer), result
end


θ_opt, opt_result = optimize_loss(loss, θ_init)

fpost_opt = build_posterior_gp(ParameterHandling.value(θ_opt))

show_params(nt::Union{Dict,NamedTuple}) =
    String(take!(show_params(IOBuffer(), nt)))
function show_params(io, nt::Union{Dict,NamedTuple}, indent::Int = 0)
    for (s, v) in pairs(nt)
        if v isa Union{Dict,NamedTuple}
            println(io, " "^indent, s, ":")
            show_params(io, v, indent + 4)
        else
            println(io, " "^indent, s, " = ", @sprintf("%.3f", v))
        end
    end
    return io
end
new_X = RowVecs(hcat(lats_turbines, lons_turbines))
mean_values = mean(fpost_opt, new_X)
mean_values_2 = mean(fpost_init, new_X)

variance = var(fpost_opt, new_X)
variance_y

f = Figure()
ax1 = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Longitude}",
    #ylabel = L"Latitude",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 30,
    xlabelsize = 30,
    limits = (minimum(lons), maximum(lons), minimum(lats), maximum(lats)),
)
ax2 = Axis(
    f[1, 2],
    xlabel = L"\mathrm{Longitude}",
    #ylabel = L"Latitude",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 30,
    xlabelsize = 30,
    limits = (minimum(lons), maximum(lons), minimum(lats), maximum(lats)),
)
orig = Makie.scatter!(
    ax1,
    lons_turbines,
    lats_turbines,
    color = mean_values_2 - mean_values,
)
turbines = Makie.scatter!(
    ax2,
    lons_turbines,
    lats_turbines,
    color = variance,
    #colorrange = (0, 11),
)
Colorbar(f[1, 3], turbines, label = "Colorbar")
#save("plots/september/0001noisy_input_one_dataset.pdf", f)
f
