using CSV
using DataFrames

directory_path = "data/forecasts_cmip6"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

ssp126_turbines = data_frames["0021_ssp126_r1"].vector
ssp126_orig = data_frames["0021_ssp126_r1_orig"].vector
ssp245_turbines = data_frames["0021_ssp245_r1"].vector
ssp245_orig = data_frames["0021_ssp245_r1_orig"].vector
ssp585_turbines = data_frames["0021_ssp585_r1"].vector
ssp585_orig = data_frames["0021_ssp585_r1_orig"].vector
ssp370_turbines = data_frames["0017_ssp370_r1"].vector
ssp370_orig = data_frames["0017_ssp370_r1_orig"].vector

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
    xlabelsize = 15,
    ylabelsize = 15,
    xticklabelsize = 12,
    yticklabelsize = 12,
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
    ],
    labelsize = 15,
)
save("plots/paper/pdfs/power_generation_cmip6.pdf", f)
f

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