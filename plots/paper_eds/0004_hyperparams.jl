using AbstractGPs
using KernelFunctions
using NCDatasets
using CSV
using DataFrames
using LinearAlgebra
using Datesp
using GeoMakie, CairoMakie
using ParameterHandling  # for nested and constrained parameters
using Optim  # optimization
using Zygote
using Random
using Printf


savepath = "data/hyperparams/"
θ_opt_k1_params_σ =
    CSV.read(savepath * "θ_opt_k1_params_σ.csv", DataFrame).value
θ_opt_k2_params_σ =
    CSV.read(savepath * "θ_opt_k2_params_σ.csv", DataFrame).value
θ_opt_k1_params_ℓ =
    CSV.read(savepath * "θ_opt_k1_params_ℓ.csv", DataFrame).value
θ_opt_k2_params_ℓ =
    CSV.read(savepath * "θ_opt_k2_params_ℓ.csv", DataFrame).value


T = Theme(fontsize = 17, size = (500, 400))

with_theme(T) do
    fig = Figure()
    ax1 = Axis(fig[1, 1], ylabel = L"\lambda")
    ax2 = Axis(fig[1, 2])
    ax3 = Axis(
        fig[2, 1],
        ylabel = L"\ell",
        xticklabelrotation = pi / 4,
        xticks = (0:1460:1460, ["Jan", "Dec"]),
    )
    ax4 = Axis(
        fig[2, 2],
        xticklabelrotation = pi / 4,
        xticks = (0:1460:1460, ["Jan", "Dec"]),
    )
    lines!(ax1, 1:1460, θ_opt_k1_params_σ, linewidth = 2)
    lines!(ax2, 1:1460, θ_opt_k2_params_σ, linewidth = 2)
    lines!(ax3, 1:1460, θ_opt_k1_params_ℓ, linewidth = 2)
    lines!(ax4, 1:1460, θ_opt_k2_params_ℓ, linewidth = 2)
    hidexdecorations!(ax1, grid = false)
    hidexdecorations!(ax2, grid = false)
    hideydecorations!(ax4, grid = false)
    hideydecorations!(ax2, grid = false)
    save("plots/paper_eds/0004_parameters_optim.pdf", fig)
    fig
end
