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

pathway = "data/historical"
data_u = Dataset(
    pathway *"_r1_u.nc",
    "r",
)

data_v = Dataset(
    pathway *"_r1_v.nc",
    "r",
)

data_u_2 = Dataset(
    pathway *"_r2_u.nc",
    "r",
)


data_v_2 = Dataset(
    pathway *"_r2_v.nc",
    "r",
)

data_u["time"][:]

lon = data_u["lon"][:]
lat = data_v_2["lat"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))

yearly_turbines = CSV.read("data/turbines_in_2024.csv", DataFrame)
lats_turbines = Array(yearly_turbines.y_coordinates)
lons_turbines = Array(yearly_turbines.x_coordinates)
u = data_u["uas"][:, :, 1]
v = data_v["vas"][:, :, 1]
strength_orig = vec(transpose(sqrt.(u .^ 2 .+ v .^ 2)))

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


i = 2011
indices_per_year = findall(x -> x == i, year.(data_u["time"][:]))
training_set_size = length(indices_per_year)
θ_opt_k1_params_σ = Vector{Float64}(undef, training_set_size)
θ_opt_k2_params_σ = Vector{Float64}(undef, training_set_size)
θ_opt_k1_params_ℓ = Vector{Float64}(undef, training_set_size)
θ_opt_k2_params_ℓ = Vector{Float64}(undef, training_set_size)
for j = 1:training_set_size
    print(j)
    u = data_u["uas"][:, :, indices_per_year[1]-1+j]
    v = data_v["vas"][:, :, indices_per_year[1]-1+j]
    u2 = data_u_2["uas"][:, :, indices_per_year[1]-1+j]
    v2 = data_v_2["vas"][:, :, indices_per_year[1]-1+j]
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
    θ_init =
        (; k1_params = (; σ = 0.7, ℓ = 1.5), k2_params = (; σ = 0.7, ℓ = 1.5))
    k(θ) = θ.σ^2 * with_lengthscale(Matern32Kernel(), θ.ℓ)
    mean_speeds = (speeds_dataset_1 .+ speeds_dataset_2) ./ 2
    variance_y =
        (
            (speeds_dataset_1 .- mean_speeds) .^ 2 .+
            (speeds_dataset_2 .- mean_speeds) .^ 2
        ) ./ 2

    function build_gp_prior(θ)
        k1 = k(θ.k1_params)
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
    θ_opt_k1_params_σ[j] = θ_opt.k1_params.σ
    θ_opt_k2_params_σ[j] = θ_opt.k2_params.σ
    θ_opt_k1_params_ℓ[j] = θ_opt.k1_params.ℓ
    θ_opt_k2_params_ℓ[j] = θ_opt.k2_params.ℓ
end

θ_opt_k1_params_σ
savepath = "data/hyperparams/"
θ_opt_k1_params_σ_df = DataFrame(value = θ_opt_k1_params_σ)
CSV.write(savepath * "θ_opt_k1_params_σ" * ".csv", θ_opt_k1_params_σ_df)
θ_opt_k2_params_σ_df = DataFrame(value = θ_opt_k2_params_σ)
CSV.write(savepath * "θ_opt_k2_params_σ" * ".csv", θ_opt_k2_params_σ_df)
θ_opt_k1_params_ℓ_df = DataFrame(value = θ_opt_k1_params_ℓ)
CSV.write(savepath * "θ_opt_k1_params_ℓ" * ".csv", θ_opt_k1_params_ℓ_df)
θ_opt_k2_params_ℓ_df = DataFrame(value = θ_opt_k2_params_ℓ)
CSV.write(savepath * "θ_opt_k2_params_ℓ" * ".csv", θ_opt_k2_params_ℓ_df)

mean(θ_opt_k1_params_σ)
mean(θ_opt_k2_params_σ)
mean(θ_opt_k1_params_ℓ)
mean(θ_opt_k2_params_ℓ)

mean(θ_opt_k1_params_σ) # 1.890977
mean(θ_opt_k2_params_σ) # 1.890977
mean(θ_opt_k1_params_ℓ) # 4.491976 
mean(θ_opt_k2_params_ℓ) # 10.574873

fig = Figure()
ax1 = Axis(fig[1, 1])
ax2 = Axis(fig[1, 2])
ax3 = Axis(fig[2, 1])
ax4 = Axis(fig[2, 2])
lines!(
    ax1,
    1:training_set_size,
    θ_opt_k1_params_σ,
    color = :blue,
    linewidth = 2,
)
lines!(
    ax2,
    1:training_set_size,
    θ_opt_k2_params_σ,
    color = :blue,
    linewidth = 2,
)
lines!(
    ax3,
    1:training_set_size,
    θ_opt_k1_params_ℓ,
    color = :blue,
    linewidth = 2,
)
lines!(
    ax4,
    1:training_set_size,
    θ_opt_k2_params_ℓ,
    color = :blue,
    linewidth = 2,
)
save("plots/paper_eds/0004_parameters_optim.pdf", fig)
fig


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