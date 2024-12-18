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

T = Theme(fontsize = 17, size = (500, 400))

directory_path = "data/power_forecasts/past"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

num_turbines = data_frames["SSP370_r1_orig_numturbines"].vector
ssp126_turbines = data_frames["SSP126_r1_turbines"].vector
ssp126_orig = data_frames["SSP126_r1_orig"].vector
ssp245_turbines = data_frames["SSP245_r1_turbines"].vector
ssp245_orig = data_frames["SSP245_r1_orig"].vector
ssp585_turbines = data_frames["SSP585_r1_turbines"].vector
ssp585_orig = data_frames["SSP585_r1_orig"].vector
ssp370_turbines = data_frames["SSP370_r1_turbines"].vector
ssp370_orig = data_frames["SSP370_r1_orig"].vector
era5_orig = CSV.read("data/forecasts_era5/0032_era5_orig.csv", DataFrame).vector
era5_turbines =
    CSV.read("data/forecasts_era5/0032_era5_turbines.csv", DataFrame).vector

tsos = CSV.read(
    "data/power_gen/2015-2023-sum4tso-6hourly.csv",
    delim = ';',
    DataFrame,
)
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


#with_theme(T) do
f = Figure()
ax = Axis(
    f[1, 1],
    #xlabel = L"\mathrm{}",
    ylabel = L"\mathrm{Generated\;power\;(MW)}",
    xticklabelrotation = pi / 4,
    xticks = (
        1:365*4:365*4*10,
        [
            "2015",
            "2016",
            "2017",
            "2018",
            "2019",
            "2020",
            "2021",
            "2022",
            "2023",
            "2024",
        ],
    ),
    #xlabelsize = 15,
    #ylabelsize = 15,
    #xticklabelsize = 12,
    #yticklabelsize = 12,
)
true_gen = lines!(
    ax,
    1:length(true_generation),
    cumsum(true_generation),
    color = "black",
)
ssp126t = lines!(
    ax,
    1:length(ssp126_turbines),
    cumsum(ssp126_turbines) / factor_ssp126_turbines,
)
ssp126 = lines!(
    ax,
    1:length(ssp126_turbines),
    cumsum(ssp126_orig) / factor_ssp126_orig,
    linestyle = :dot,
)
ssp245t = lines!(
    ax,
    1:length(ssp245_turbines),
    cumsum(ssp245_turbines) / factor_ssp245_turbines,
)
ssp245 = lines!(
    ax,
    1:length(ssp245_turbines),
    cumsum(ssp245_orig) / factor_ssp245_orig,
    linestyle = :dot,
)
ssp370t = lines!(
    ax,
    1:length(ssp370_turbines),
    cumsum(ssp370_turbines) / factor_ssp370_turbines,
)
ssp370 = lines!(
    ax,
    1:length(ssp370_turbines),
    cumsum(ssp370_orig) / factor_ssp370_orig,
    linestyle = :dot,
)
ssp585t = lines!(
    ax,
    1:length(ssp585_turbines),
    cumsum(ssp585_turbines) / factor_ssp585_turbines,
)
ssp585 = lines!(
    ax,
    1:length(ssp585_turbines),
    cumsum(ssp585_orig) / factor_ssp585_orig,
    linestyle = :dot,
)
era5t = lines!(
    ax,
    1:length(era5_turbines),
    cumsum(era5_turbines) / factor_era5_turbines,
)
era5 = lines!(ax, 1:length(era5_orig), cumsum(era5_orig) / factor_era5_orig)
num_tur =
    lines!(ax, 1:length(num_turbines), cumsum(num_turbines) / factor_turbines)
Legend(
    f[1, 2],
    [
        true_gen,
        ssp126t,
        ssp126,
        ssp245t,
        ssp245,
        ssp370t,
        ssp370,
        ssp585t,
        ssp585,
        era5t,
        era5,
        num_tur,
    ],
    [
        L"\mathrm{True\;(100%)}",
        L"\mathrm{126t\;(83,27%)}",
        L"\mathrm{126\;(63,32%)}",
        L"\mathrm{245t\;(105,89%)}",
        L"\mathrm{245\;(77,50%)}",
        L"\mathrm{370t\;(96,64%)}",
        L"\mathrm{370\;(72,75%)}",
        L"\mathrm{585t\;(104,23%)}",
        L"\mathrm{585\;(77,44%)}",
        L"\mathrm{ERA5t\;(93,55%)}",
        L"\mathrm{ERA5\;(70,57%)}",
        L"\mathrm{SSP370}",
    ],
    #labelsize = 15,
)
#save("plots/paper/pdfs/numtur_power_generation_cmip6_era5.pdf", f)
f
#end

(cumsum(ssp585_turbines)[end] / factor_ssp585_turbines) /
cumsum(true_generation)[end]
(cumsum(ssp585_orig)[end] / factor_ssp585_orig) / cumsum(true_generation)[end]
(cumsum(ssp370_turbines)[end] / factor_ssp370_turbines) /
cumsum(true_generation)[end]
(cumsum(ssp370_orig)[end] / factor_ssp370_orig) / cumsum(true_generation)[end]
(cumsum(ssp245_turbines)[end] / factor_ssp245_turbines) /
cumsum(true_generation)[end]
(cumsum(ssp245_orig)[end] / factor_ssp245_orig) / cumsum(true_generation)[end]
(cumsum(ssp126_turbines)[end] / factor_ssp126_turbines) /
cumsum(true_generation)[end]
(cumsum(ssp126_orig)[end] / factor_ssp126_orig) / cumsum(true_generation)[end]
(cumsum(era5_turbines)[end] / factor_era5_turbines) /
cumsum(true_generation)[end]
(cumsum(era5_orig)[end] / factor_era5_orig) / cumsum(true_generation)[end]
(cumsum(num_turbines)[end] / factor_turbines) / cumsum(true_generation)[end]
[
    #L"\mathrm{126t\;(83,27%)}",
    L"\mathrm{SSP126\;(63.32%,\;80.05%)}",
    #L"\mathrm{245t\;(105,89%)}",
    L"\mathrm{SSP245\;(77.33%,\;108.14%)}",
    #L"\mathrm{370t\;(96,64%)}",
    L"\mathrm{SSP370\;(72.28%,\;96.52%)}",
    # L"\mathrm{585t\;(104,23%)}",
    L"\mathrm{SSP585\;(77.44%,\;102.68%)}",
    # L"\mathrm{ERA5t\;(93,55%)}",
    L"\mathrm{ERA5\;(70.57%,\;93,55%)}",
    L"\mathrm{SSP370#t\;(88.47%)}",
]


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
    num_tur = lines!(
        ax,
        1:length(num_turbines[365*4:end]),
        ((cumsum(
            num_turbines,
        )/factor_turbines)./cumsum(true_generation[1:end-1]))[365*4:end],
        color = "#D55E00",
    )
    lines!(
        ax,
        [0, length(num_turbines[365*4:end])],
        [1, 1],
        color = :black,
        linewidth = 1,
    )
    Makie.ylims!(ax, (0.6, 1.25))
    lg = Legend(
        f[0, 1],
        [ssp126t, ssp245t, ssp370t, ssp585t, era5t, num_tur],
        [
            #L"\mathrm{126t\;(83,27%)}",
            L"\mathrm{SSP126\;(63.32%,\;80.05%)}",
            #L"\mathrm{245t\;(105,89%)}",
            L"\mathrm{SSP245\;(77.33%,\;108.14%)}",
            #L"\mathrm{370t\;(96,64%)}",
            L"\mathrm{SSP370\;(72.28%,\;96.52%)}",
            # L"\mathrm{585t\;(104,23%)}",
            L"\mathrm{SSP585\;(77.44%,\;102.68%)}",
            # L"\mathrm{ERA5t\;(93,55%)}",
            L"\mathrm{ERA5\;(70.57%,\;93,55%)}",
            L"\mathrm{SSP370#t\;(88.47%)}",
        ],
        halign = :left,
        valign = :top,
        orientation = :horizontal,
        nbanks = 3,
        labelsize = 17,
        framecolor = :white,
        padding = (-35, 0, 0, 0),
    )
    f
    save("plots/pdfs/0003_power_generation_cmip6_era5_relative.pdf", f)
    f
end


# MAEs for SSPs vs ERA5
mean(
    abs.(
        ((cumsum(
            ssp126_turbines,
        )/factor_ssp126_turbines)./cumsum(true_generation[1:end-1]))[365*4:end] .-
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end-1]
    ),
)

mean(
    abs.(
        ((cumsum(
            ssp245_turbines,
        )/factor_ssp245_turbines)./cumsum(true_generation[1:end-1]))[365*4:end] .-
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end-1]
    ),
)

mean(
    abs.(
        ((cumsum(
            ssp370_turbines,
        )/factor_ssp370_turbines)./cumsum(true_generation[1:end-1]))[365*4:end] .-
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end-1]
    ),
)

mean(
    abs.(
        ((cumsum(
            ssp585_turbines,
        )/factor_ssp585_turbines)./cumsum(true_generation[1:end-1]))[365*4:end] .-
        ((cumsum(
            era5_turbines,
        )/factor_era5_turbines)./cumsum(true_generation[1:end]))[365*4:end-1]
    ),
)