using CSV
using DataFrames
using Distributions
using StatsBase
using Distances

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
era5_orig = CSV.read("data/forecasts_era5/0032_era5_orig.csv", DataFrame).vector
era5_turbines =
    CSV.read("data/forecasts_era5/0032_era5_turbines.csv", DataFrame).vector
tsos = CSV.read(
    "data/power_gen/tso_power_generation.csv",
    delim = ';',
    DataFrame,
)

dataframe = DataFrame(
    ssp126_turbines = ssp126_turbines[1:13147],
    #ssp126_orig = ssp126_orig[1:13147],
    ssp245_turbines = ssp245_turbines[1:13147],
    #ssp245_orig = ssp245_orig[1:13147],
    ssp370_turbines = ssp370_turbines[1:13147],
    #ssp370_orig = ssp370_orig[1:13147],
    ssp585_turbines = ssp585_turbines[1:13147],
    #ssp585_orig = ssp585_orig[1:13147],
    era5_turbines = era5_turbines[1:13147],
    #era5_orig = era5_orig[1:13147],
    tsos = tsos.power[1:13147],
)

function standardize(df::DataFrame)
    for col in names(df)
        mean_col = mean(df[!, col])
        std_col = std(df[!, col])
        df[!, col] = (df[!, col] .- mean_col) ./ std_col
    end
    return df
end

data_standardized = standardize(dataframe)
correlation_matrix = cor(Matrix(data_standardized))

fig = Figure(resolution = (600, 400))
ax = Axis(
    fig[1, 1],
    title = "Correlation Matrix of Time Series",
    aspect = DataAspect(),
)

hm = Makie.heatmap!(ax, correlation_matrix, colorrange = (0, 1))

Colorbar(fig[1, 2], hm, label = "Correlation", height = Relative(0.8))

display(fig)


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

f = Figure()
ax = Axis(f[1, 1])
ssp126t = lines!(
    kde(ssp126_turbines / factor_ssp126_turbines).x,
    kde(ssp126_turbines / factor_ssp126_turbines).density .-
    (kde(tsos.power).density),
)
ssp245t = lines!(
    kde(ssp245_turbines / factor_ssp245_turbines).x,
    kde(ssp245_turbines / factor_ssp245_turbines).density .-
    (kde(tsos.power).density),
)
ssp370t = lines!(
    kde(ssp370_turbines / factor_ssp370_turbines).x,
    kde(ssp370_turbines / factor_ssp370_turbines).density .-
    (kde(tsos.power).density),
)
ssp585t = lines!(
    kde(ssp585_turbines / factor_ssp585_turbines).x,
    kde(ssp585_turbines / factor_ssp585_turbines).density .-
    (kde(tsos.power).density),
)
era5t = lines!(
    kde(era5_turbines / factor_era5_turbines).x,
    kde(era5_turbines / factor_era5_turbines).density .-
    (kde(tsos.power).density),
)

Legend(
    f[1, 2],
    [ssp126t, ssp245t, ssp370t, ssp585t, era5t],
    [
        L"\mathrm{126t\;(83,27%)}",
        L"\mathrm{245t\;(105,89%)}",
        L"\mathrm{370t\;(96,64%)}",
        L"\mathrm{585t\;(104,23%)}",
        L"\mathrm{ERA5t\;(93,55%)}",
    ],
    labelsize = 15,
)
f

f = Figure()
ax = Axis(f[1, 1])
ssp126 = lines!(
    kde(ssp126_orig / factor_ssp126_orig).x,
    kde(ssp126_orig / factor_ssp126_orig).density .- (kde(tsos.power).density),
)
ssp126t = lines!(
    kde(ssp126_turbines / factor_ssp126_turbines).x,
    kde(ssp126_turbines / factor_ssp126_turbines).density .-
    (kde(tsos.power).density),
)
ssp245 = lines!(
    kde(ssp245_orig / factor_ssp245_orig).x,
    kde(ssp245_orig / factor_ssp245_orig).density .- (kde(tsos.power).density),
)
ssp245t = lines!(
    kde(ssp245_turbines / factor_ssp245_turbines).x,
    kde(ssp245_turbines / factor_ssp245_turbines).density .-
    (kde(tsos.power).density),
)
ssp370 = lines!(
    kde(ssp370_orig / factor_ssp370_orig).x,
    kde(ssp370_orig / factor_ssp370_orig).density .- (kde(tsos.power).density),
)
ssp370t = lines!(
    kde(ssp370_turbines / factor_ssp370_turbines).x,
    kde(ssp370_turbines / factor_ssp370_turbines).density .-
    (kde(tsos.power).density),
)
ssp585 = lines!(
    kde(ssp585_orig / factor_ssp585_orig).x,
    kde(ssp585_orig / factor_ssp585_orig).density .- (kde(tsos.power).density),
)
ssp585t = lines!(
    kde(ssp585_turbines / factor_ssp585_turbines).x,
    kde(ssp585_turbines / factor_ssp585_turbines).density .-
    (kde(tsos.power).density),
)
era5 = lines!(
    kde(era5_orig / factor_era5_orig).x,
    kde(era5_orig / factor_era5_orig).density .- (kde(tsos.power).density),
)
era5t = lines!(
    kde(era5_turbines / factor_era5_turbines).x,
    kde(era5_turbines / factor_era5_turbines).density .-
    (kde(tsos.power).density),
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
        era5t,
        era5,
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
    ],
    labelsize = 15,
)
f

f = Figure()
ax = Axis(f[1, 1])
ssp126 = lines!(
    kde(ssp126_orig / factor_ssp126_orig).x,
    kde(ssp126_orig / factor_ssp126_orig).density,
)
ssp126t = lines!(
    kde(ssp126_turbines / factor_ssp126_turbines).x,
    kde(ssp126_turbines / factor_ssp126_turbines).density,
)
ssp245 = lines!(
    kde(ssp245_orig / factor_ssp245_orig).x,
    kde(ssp245_orig / factor_ssp245_orig).density,
)
ssp245t = lines!(
    kde(ssp245_turbines / factor_ssp245_turbines).x,
    kde(ssp245_turbines / factor_ssp245_turbines).density,
)
ssp370 = lines!(
    kde(ssp370_orig / factor_ssp370_orig).x,
    kde(ssp370_orig / factor_ssp370_orig).density,
)
ssp370t = lines!(
    kde(ssp370_turbines / factor_ssp370_turbines).x,
    kde(ssp370_turbines / factor_ssp370_turbines).density,
)
ssp585 = lines!(
    kde(ssp585_orig / factor_ssp585_orig).x,
    kde(ssp585_orig / factor_ssp585_orig).density,
)
ssp585t = lines!(
    kde(ssp585_turbines / factor_ssp585_turbines).x,
    kde(ssp585_turbines / factor_ssp585_turbines).density,
)
era5 = lines!(
    kde(era5_orig / factor_era5_orig).x,
    kde(era5_orig / factor_era5_orig).density,
)
era5t = lines!(
    kde(era5_turbines / factor_era5_turbines).x,
    kde(era5_turbines / factor_era5_turbines).density,
)
true_gen = lines!(kde(tsos.power).x, kde(tsos.power).density)
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
    ],
    labelsize = 15,
)
f

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
era5t = lines!(
    ax,
    1:length(era5_turbines),
    cumsum(era5_turbines) / factor_era5_turbines,
)
era5 = lines!(ax, 1:length(era5_orig), cumsum(era5_orig) / factor_era5_orig)
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
    ],
    labelsize = 15,
)
save("plots/paper/pdfs/power_generation_cmip6_era5.pdf", f)
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
(cumsum(era5_turbines)[end] / factor_era5_turbines) /
cumsum(true_generation)[end]
(cumsum(era5_orig)[end] / factor_era5_orig) / cumsum(true_generation)[end]


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
ssp126t = lines!(
    ax,
    1:length(ssp126_turbines),
    cumsum(ssp126_turbines) / factor_ssp126_turbines .-
    cumsum(true_generation[1:end-1]),
)
ssp126 = lines!(
    ax,
    1:length(ssp126_turbines),
    cumsum(ssp126_orig) / factor_ssp126_orig .-
    cumsum(true_generation[1:end-1]),
    linestyle = :dot,
)
ssp245t = lines!(
    ax,
    1:length(ssp245_turbines),
    cumsum(ssp245_turbines) / factor_ssp245_turbines .-
    cumsum(true_generation[1:end-1]),
)
ssp245 = lines!(
    ax,
    1:length(ssp245_turbines),
    cumsum(ssp245_orig) / factor_ssp245_orig .-
    cumsum(true_generation[1:end-1]),
    linestyle = :dot,
)
ssp370t = lines!(
    ax,
    1:length(ssp370_turbines),
    cumsum(ssp370_turbines) / factor_ssp370_turbines .-
    cumsum(true_generation[1:end-1]),
)
ssp370 = lines!(
    ax,
    1:length(ssp370_turbines),
    cumsum(ssp370_orig) / factor_ssp370_orig .-
    cumsum(true_generation[1:end-1]),
    linestyle = :dot,
)
ssp585t = lines!(
    ax,
    1:length(ssp585_turbines),
    cumsum(ssp585_turbines) / factor_ssp585_turbines .-
    cumsum(true_generation[1:end-1]),
)
ssp585 = lines!(
    ax,
    1:length(ssp585_turbines),
    cumsum(ssp585_orig) / factor_ssp585_orig .-
    cumsum(true_generation[1:end-1]),
    linestyle = :dot,
)
era5t = lines!(
    ax,
    1:length(era5_turbines),
    cumsum(era5_turbines) / factor_era5_turbines .- cumsum(true_generation),
)
era5 = lines!(
    ax,
    1:length(era5_orig),
    cumsum(era5_orig) / factor_era5_orig .- cumsum(true_generation),
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
        era5t,
        era5,
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
    ],
    labelsize = 15,
)
f
save("plots/paper/pdfs/diff_power_generation_cmip6_era5.pdf", f)
f


# Define number of bins
num_bins = 25

# Calculate histograms
hist1 = kde(ssp126_turbines / factor_ssp126_turbines).density
hist2 = kde(ssp245_turbines / factor_ssp245_turbines).density
hist3 = kde(ssp370_turbines / factor_ssp370_turbines).density
hist4 = kde(ssp585_turbines / factor_ssp585_turbines).density
hist5 = kde(era5_turbines / factor_era5_turbines).density
hist6 = kde(tsos.power).density

hist5.weights
# Normalize histograms to get probability distributions
prob_dist1 = hist1.weights / sum(hist1.weights)
prob_dist2 = hist5.weights / sum(hist5.weights)
js_divergence = Distances.js_divergence(prob_dist1, prob_dist2)

prob_dist1 = hist2.weights / sum(hist2.weights)
prob_dist2 = hist5.weights / sum(hist5.weights)
js_divergence = Distances.js_divergence(prob_dist1, prob_dist2)

prob_dist1 = hist3.weights / sum(hist3.weights)
prob_dist2 = hist5.weights / sum(hist5.weights)
js_divergence = Distances.js_divergence(prob_dist1, prob_dist2)

prob_dist1 = hist4.weights / sum(hist4.weights)
prob_dist2 = hist5.weights / sum(hist5.weights)
js_divergence = Distances.js_divergence(hist1, hist1)

prob_dist1 = hist1.weights / sum(hist1.weights)
prob_dist2 = hist5.weights / sum(hist5.weights)
js_divergence = Distances.js_divergence(prob_dist1, prob_dist2)