using CSV
using DataFrames
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
using CSV
using Colors

# Accessing the first color

T = Theme(fontsize = 17, size = (500, 500))

directory_path = "/Users/ninaeffenberger/phd/2023-09-gp-julia/power-forecasts-gp/data/forecasts_cmip6"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

ssp370_prob_trained_r2 =
    CSV.read(
        "data/power_forecasts/historical/0009_historical_ssp370_r2.csv",
        DataFrame,
    ).vector
ssp370_prob_trained =
    CSV.read(
        "data/power_forecasts/historical/0006_historical_ssp370.csv",
        DataFrame,
    ).vector
ssp370_prob_trained_pos =
    CSV.read(
        "data/power_forecasts/historical/0012_historical_ssp370_pos_uncertainty_1std.csv",
        DataFrame,
    ).vector
ssp370_prob_trained_neg =
    CSV.read(
        "data/power_forecasts/historical/0012_historical_ssp370_neg_uncertainty_1std.csv",
        DataFrame,
    ).vector
num_turbines = data_frames["0017_ssp370_r1_orig_numturbines"].vector
ssp126_turbines = data_frames["0021_ssp126_r1"].vector
ssp126_orig = data_frames["0021_ssp126_r1_orig"].vector
ssp245_turbines = data_frames["0021_ssp245_r1"].vector
ssp245_orig = data_frames["0021_ssp245_r1_orig"].vector
ssp585_turbines = data_frames["0021_ssp585_r1"].vector
ssp585_orig = data_frames["0021_ssp585_r1_orig"].vector
ssp370_turbines = data_frames["0017_ssp370_r1"].vector
ssp370_orig = data_frames["0017_ssp370_r1_orig"].vector
era5_orig =
    CSV.read(
        "/Users/ninaeffenberger/phd/2023-09-gp-julia/power-forecasts-gp/data/forecasts_era5/0032_era5_orig.csv",
        DataFrame,
    ).vector
era5_turbines =
    CSV.read(
        "/Users/ninaeffenberger/phd/2023-09-gp-julia/power-forecasts-gp/data/forecasts_era5/0032_era5_turbines.csv",
        DataFrame,
    ).vector

tsos = CSV.read("data/tso_power_generation.csv", delim = ';', DataFrame)
true_generation = tsos[!, "power"]

factor_ssp126_orig = cumsum(ssp126_orig)[365*4] / cumsum(true_generation)[365*4]
factor_ssp126_turbines =
    cumsum(ssp126_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_ssp370_orig = cumsum(ssp370_orig)[365*4] / cumsum(true_generation)[365*4]
factor_ssp370_turbines =
    cumsum(ssp370_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_ssp245_orig = cumsum(ssp245_orig)[365*4] / cumsum(true_generation)[365*4]
factor_ssp245_turbines =
    cumsum(ssp245_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_ssp585_orig = cumsum(ssp585_orig)[365*4] / cumsum(true_generation)[365*4]
factor_ssp585_turbines =
    cumsum(ssp585_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_era5_turbines =
    cumsum(era5_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_era5_orig = cumsum(era5_orig)[365*4] / cumsum(true_generation)[365*4]
factor_turbines = cumsum(num_turbines)[365*4] / cumsum(true_generation)[365*4]
factor_trained_ssp370 =
    cumsum(ssp370_prob_trained)[365*4] / cumsum(true_generation)[365*4]
factor_trained_ssp370_r2 =
    cumsum(ssp370_prob_trained_r2)[365*4] / cumsum(true_generation)[365*4]
factor_trained_ssp370_pos =
    cumsum(ssp370_prob_trained_pos)[365*4] / cumsum(true_generation)[365*4]
factor_trained_ssp370_neg =
    cumsum(ssp370_prob_trained_neg)[365*4] / cumsum(true_generation)[365*4]
((cumsum(
    ssp370_prob_trained,
)/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[end]

with_theme(T) do
    f = Figure()
    ax = Axis(
        f[1, 1],
        #xlabel = L"\mathrm{}",
        ylabel = L"\mathrm{Relative\;generated\;power}",
        xticklabelrotation = pi / 4,
        xticks = (1:365*4*4:365*4*9, [
            "2016",
            #"2017",
            #"2018",
            #"2019",
            "2020",
            #"2021",
            #"2022",
            #"2023",
            "2024",
        ]),
    )
    ssp370t = lines!(
        ax,
        1:length(ssp370_turbines[365*4:end]),
        ((cumsum(
            ssp370_turbines,
        )/factor_ssp370_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#009E73",
    )
    ssp126t = lines!(
        ax,
        1:length(ssp126_turbines[365*4:end]),
        ((cumsum(
            ssp126_turbines,
        )/factor_ssp126_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#0072B2",
    )
    ssp126 = lines!(
        ax,
        1:length(ssp126_turbines[365*4:end]),
        ((cumsum(
            ssp126_orig,
        )/factor_ssp126_orig)./cumsum(true_generation[1:end-1]))[365*4:end],
        linestyle = :dot,
        color = "#0072B2",
    )
    ssp245t = lines!(
        ax,
        1:length(ssp245_turbines[365*4:end]),
        ((cumsum(
            ssp245_turbines,
        )/factor_ssp245_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#E69F00",
    )
    ssp245 = lines!(
        ax,
        1:length(ssp245_turbines[365*4:end]),
        ((cumsum(
            ssp245_orig,
        )/factor_ssp245_orig)./cumsum(true_generation[1:end-1]))[365*4:end],
        linestyle = :dot,
        color = "#E69F00",
    )
    ssp370t = lines!(
        ax,
        1:length(ssp370_turbines[365*4:end]),
        ((cumsum(
            ssp370_turbines,
        )/factor_ssp370_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#009E73",
    )
    ssp370 = lines!(
        ax,
        1:length(ssp370_turbines[365*4:end]),
        ((cumsum(
            ssp370_orig,
        )/factor_ssp370_orig)./cumsum(true_generation[1:end-1]))[365*4:end],
        linestyle = :dot,
        color = "#009E73",
    )
    ssp585t = lines!(
        ax,
        1:length(ssp585_turbines[365*4:end]),
        ((cumsum(
            ssp585_turbines,
        )/factor_ssp585_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#CC79A7",
    )
    ssp585 = lines!(
        ax,
        1:length(ssp585_turbines[365*4:end]),
        ((cumsum(
            ssp585_orig,
        )/factor_ssp585_orig)./cumsum(true_generation[1:end-1]))[365*4:end],
        linestyle = :dot,
        color = "#CC79A7",
    )
    era5t = lines!(
        ax,
        1:length(era5_turbines[365*4:end]),
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end],
        color = "#56B4E9",
    )
    era5 = lines!(
        ax,
        1:length(era5_orig[365*4:end]),
        ((cumsum(era5_orig)/factor_era5_orig)./cumsum(true_generation[1:end]))[365*4:end],
        linestyle = :dot,
        color = "#56B4E9",
    )
    era5t = lines!(
        ax,
        1:length(era5_turbines[365*4:end]),
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end],
        color = "#56B4E9",
    )
    num_tur = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            num_turbines,
        )/factor_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#D55E00",
    )
    ssp370_trained = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#CC79A7",
    )
    ssp370_trained_r2 = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_r2,
        )/factor_trained_ssp370_r2)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#CC79A7",
    )
    ssp370_trained_neg = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_neg,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "black",
    )
    ssp370_trained_pos = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_pos,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "black",
    )
    lines!(
        ax,
        [0, length(num_turbines[365*4:end])],
        [1, 1],
        color = :black,
        linewidth = 1,
    )
    Makie.ylims!(ax, (0.7, 1.3))
    lg = Legend(
        f[0, 1],
        [ssp370t, era5t, ssp370_trained],
        [
            #L"\mathrm{126t\;(83,27%)}",
            #L"\mathrm{SSP126\;(63.32%,\;83.27%)}",
            #L"\mathrm{245t\;(105,89%)}",
            #L"\mathrm{SSP245\;(77.50%,\;105.89%)}",
            #L"\mathrm{370t\;(96,64%)}",
            L"\mathrm{SSP370\;(72.75%,\;96.64%)}",
            # L"\mathrm{585t\;(104,23%)}",
            #L"\mathrm{SSP585\;(77.44%,\;104.23%)}",
            # L"\mathrm{ERA5t\;(93,55%)}",
            L"\mathrm{ERA5\;(70.57%,\;93,55%)}",
            L"\mathrm{SSP370\;trained(96.54%)}",
        ],
        halign = :left,
        valign = :top,
        orientation = :horizontal,
        nbanks = 3,
        labelsize = 17,
        framecolor = :white,
        padding = (-35, 0, 0, 0),
    )
    save("plots/paper/0013_power_generation_cmip6_optim_hyperparams.pdf", f)
    f
end

with_theme(T) do
    f = Figure()
    ax = Axis(
        f[1, 1],
        #xlabel = L"\mathrm{}",
        ylabel = L"\mathrm{Relative\;generated\;power}",
        xticklabelrotation = pi / 4,
        xticks = (1:365*4*4:365*4*9, [
            "2016",
            #"2017",
            #"2018",
            #"2019",
            "2020",
            #"2021",
            #"2022",
            #"2023",
            "2024",
        ]),
    )
    fill_between = fill_between!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_pos,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        ((cumsum(
            ssp370_prob_trained_neg,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = ("#CC79A7", 0.25),
    )
    era5t = lines!(
        ax,
        1:length(era5_turbines[365*4:end]),
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end],
        color = "#56B4E9",
    )
    num_tur = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            num_turbines,
        )/factor_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#D55E00",
    )
    ssp370t = lines!(
        ax,
        1:length(ssp370_turbines[365*4:end]),
        ((cumsum(
            ssp370_turbines,
        )/factor_ssp370_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#009E73",
    )
    ssp370_trained = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#CC79A7",
    )
    ssp370_trained_r2 = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_r2,
        )/factor_trained_ssp370_r2)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#E69F00",
    )
    lines!(
        ax,
        [0, length(num_turbines[365*4:end])],
        [1, 1],
        color = :black,
        linewidth = 1,
    )
    Makie.ylims!(ax, (0.7, 1.3))
    lg = Legend(
        f[0, 1],
        [ssp370_trained, ssp370_trained_r2, ssp370t, num_tur, era5t],
        [
            L"\mathrm{SSP370\;trained}",
            L"\mathrm{SSP370\;trained\;R2}",
            L"\mathrm{SSP370\;previous}",
            L"\mathrm{SSP370\;weighted}",
            L"\mathrm{ERA5\;turbines}",
        ],
        halign = :left,
        valign = :top,
        orientation = :horizontal,
        nbanks = 3,
        labelsize = 17,
        framecolor = :white,
        padding = (-35, 0, 0, 0),
    )
    save("plots/paper/0013_power_generation_cmip6_optim_hyperparams.pdf", f)
    f
end

ssp370_prob_trained_pos .- ssp370_prob_trained_neg
with_theme(T) do
    f = Figure()
    ax = Axis(
        f[1, 1],
        #xlabel = L"\mathrm{}",
        ylabel = L"\mathrm{Relative\;generated\;power}",
        xticklabelrotation = pi / 4,
        xticks = (1:365*4*4:365*4*9, [
            "2016",
            #"2017",
            #"2018",
            #"2019",
            "2020",
            #"2021",
            #"2022",
            #"2023",
            "2024",
        ]),
    )
    #num_tur = lines!(
    #    ax,
    #    1:length(num_turbines[365*4:end]),
    #    ((cumsum(
    #        num_turbines,
    #    )/factor_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
    #    color = "#D55E00",
    #)
    ssp370_trained = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#CC79A7",
    )
    ssp370_trained_neg = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_neg,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "blue",
    )
    ssp370_trained_pos = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            ssp370_prob_trained_pos,
        )/factor_trained_ssp370)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "green",
    )
    lines!(
        ax,
        [0, length(num_turbines[365*4:end])],
        [1, 1],
        color = :black,
        linewidth = 1,
    )
    #Makie.ylims!(ax, (-0.2, 0))
    lg = Legend(
        f[0, 1],
        [ssp370_trained],
        [
            #L"\mathrm{126t\;(83,27%)}",
            #L"\mathrm{SSP126\;(63.32%,\;83.27%)}",
            #L"\mathrm{245t\;(105,89%)}",
            #L"\mathrm{SSP245\;(77.50%,\;105.89%)}",
            #L"\mathrm{370t\;(96,64%)}",
            L"\mathrm{SSP370\;trained(96.54%)}",
        ],
        halign = :left,
        valign = :top,
        orientation = :horizontal,
        nbanks = 3,
        labelsize = 17,
        framecolor = :white,
        padding = (-35, 0, 0, 0),
    )
    save("plots/paper/0013_power_generation_cmip6_optim_hyperparams.pdf", f)
    f
end

((cumsum(num_turbines)/factor_turbines)./cumsum(true_generation[1:end-1]))[365*4:end]