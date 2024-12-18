using CSV
using DataFrames
using LinearAlgebra

directory_path = "data/forecasts_cmip6"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

function percentage_difference_to_first(v::Vector{T}) where {T}
    first_element = v[1]
    percentage_differences = ((v) ./ first_element)
    return percentage_differences
end

function sum_every_n_consecutive(v::Vector{T}) where {T}
    n = 365 * 4

    # Compute the number of full windows of size n
    num_windows = div(length(v), n)

    # Initialize an array to store the sums
    sums = Vector{T}(undef, num_windows)

    # Compute the sums
    for i = 1:num_windows
        start_index = (i - 1) * n + 1
        end_index = i * n
        sums[i] = sum(v[start_index:end_index])
    end

    return sums
end

ssp126_turbines = data_frames["0021_ssp126_r1"].vector
ssp126_orig = data_frames["0021_ssp126_r1_orig"].vector
ssp245_turbines = data_frames["0021_ssp245_r1"].vector
ssp245_orig = data_frames["0021_ssp245_r1_orig"].vector
ssp585_turbines = data_frames["0021_ssp585_r1"].vector
ssp585_orig = data_frames["0021_ssp585_r1_orig"].vector
ssp370_turbines = data_frames["0017_ssp370_r1"].vector
ssp370_orig = data_frames["0017_ssp370_r1_orig"].vector

true_generation[end] / true_generation[1]
tsos = CSV.read(
    "data/power_gen/tso_power_generation.csv",
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
        1:10,
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
    1:length(true_generation[1:365*4:end])-1,
    percentage_difference_to_first(sum_every_n_consecutive(true_generation)),
    color = "black",
)
x = 1:9
X = hcat(ones(length(x)), x)  # Design matrix with a column of ones for the intercept
β =
    X \
    (percentage_difference_to_first(sum_every_n_consecutive(true_generation)))  # Solve the normal equations
intercept, slope = β  # Extract the intercept and slope
#=
lines!(
    ax,
    intercept .+ slope .* x,
    label = "Fitted Line",
    color = "black",
    linestyle = :dot,
)
=#
ssp126t = lines!(
    ax,
    1:length(ssp126_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp126_turbines) / factor_ssp126_turbines,
    ),
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp126_turbines) / factor_ssp126_turbines,
    ))  # Solve the normal equations
intercept, slope = β  # Extract the intercept and slope
#=
lines!(
    ax,
    intercept .+ slope .* x,
    label = "Fitted Line",
    color = "black",
    linestyle = :dot,
)
=#
ssp126 = lines!(
    ax,
    1:length(ssp126_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp126_orig) / factor_ssp126_orig,
    ),
    linestyle = :dot,
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp126_orig) / factor_ssp126_orig,
    ))  # Solve the normal equations
intercept, slope = β
lines!(
    ax,
    intercept .+ slope .* x,
    label = "Fitted Line",
    color = "black",
    linestyle = :dot,
)
ssp245t = lines!(
    ax,
    1:length(ssp245_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp245_turbines) / factor_ssp245_turbines,
    ),
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp245_turbines) / factor_ssp245_turbines,
    ))  # Solve the normal equations
intercept, slope = β
ssp245 = lines!(
    ax,
    1:length(ssp245_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp245_orig) / factor_ssp245_orig,
    ),
    linestyle = :dot,
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp245_orig) / factor_ssp245_orig,
    ))  # Solve the normal equations
intercept, slope = β
ssp370t = lines!(
    ax,
    1:length(ssp370_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp370_turbines) / factor_ssp370_turbines,
    ),
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp370_turbines) / factor_ssp370_turbines,
    ))  # Solve the normal equations
intercept, slope = β
ssp370 = lines!(
    ax,
    1:length(ssp370_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp370_orig) / factor_ssp370_orig,
    ),
    linestyle = :dot,
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp370_orig) / factor_ssp370_orig,
    ))  # Solve the normal equations
intercept, slope = β
ssp585t = lines!(
    ax,
    1:length(ssp585_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp585_turbines) / factor_ssp585_turbines,
    ),
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp585_turbines) / factor_ssp585_turbines,
    ))  # Solve the normal equations
intercept, slope = β
ssp585 = lines!(
    ax,
    1:length(ssp585_turbines[1:365*4:end])-1,
    percentage_difference_to_first(
        sum_every_n_consecutive(ssp585_orig) / factor_ssp585_orig,
    ),
    linestyle = :dot,
)
β =
    X \ (percentage_difference_to_first(
        sum_every_n_consecutive(ssp585_orig) / factor_ssp585_orig,
    ))  # Solve the normal equations
intercept, slope = β
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
        L"\mathrm{True\;(+7,89%)}",
        L"\mathrm{126t\;(+3,24%)}",
        L"\mathrm{126\;(-1,54%)}",
        L"\mathrm{245t\;(+8,19%)}",
        L"\mathrm{245\;(+1,10%)}",
        L"\mathrm{370t\;(+5,40%)}",
        L"\mathrm{370\;(-0.21%)}",
        L"\mathrm{585t\;(+8.62%)}",
        L"\mathrm{585\;(+1,30%)}",
    ],
    labelsize = 15,
)
hlines!(
    ax,
    [1],
    label = "y = 1",
    linestyle = :dash,
    color = :black,
    linewidth = 2,
)

save("plots/paper/pdfs/lin_reg_power_generation_cmip6_percentage_diff.pdf", f)
f


# perform linear regression 
x = 1:10
y = x  # y = 2.5x + 3 with some noise
X = hcat(ones(length(x)), x)  # Design matrix with a column of ones for the intercept
β = X \ y  # Solve the normal equations
intercept, slope = β  # Extract the intercept and slope
scatter(x, y, label = "Data", legend = :top)
plot!(x, intercept .+ slope .* x, label = "Fitted Line", lw = 2)
slope
display(plot)

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