using CSV
using DataFrames
using Makie
using GeoMakie, CairoMakie
using OrderedCollections
using PyCall

T = Theme(fontsize = 17, size = (500, 300))

py"""
import windpowerlib

def compute_windpower(weather, hub_height):
    enercon_e126 = {
        "turbine_type": "V112/3450",  # turbine type as in register
        "hub_height": 84,  # in m
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power

"""

cutin = 3.5
rated = 12.5
cutoff = 25
data = range(0, 30, 100)
power = py"compute_windpower"(data, 100)
with_theme(T) do

    f = Figure()
    ax = Axis(
        f[1, 1],
        xlabel = L"\mathrm{Wind\;speed\;(\frac{m}{s})}",
        ylabel = L"\mathrm{Power\;(MW)}",
        xticklabelrotation = pi / 4,
        xticks = (0:100/6:100, string.(collect(range(0, 30, 7)))),
    )
    x1 = 0
    x2 = 100 / (30 / cutin)
    x3 = 100 / (30 / rated)
    x4 = 100 / (30 / cutoff)
    x5 = 100
    y_min, y_max = 0, 3.5

    # Define the coordinates for the shaded region
    x_coords = [x1, x2, x2, x1]
    y_coords = [y_min, y_min, y_max, y_max]
    poly!(ax, Point2f.(x_coords, y_coords), color = ("#440154FF", 0.3))
    x_coords = [x2, x3, x3, x2]
    poly!(ax, Point2f.(x_coords, y_coords), color = ("#2A788EFF", 0.3))
    x_coords = [x3, x4, x4, x3]
    poly!(ax, Point2f.(x_coords, y_coords), color = ("#7AD151FF", 0.3))
    x_coords = [x4, x5, x5, x4]
    poly!(ax, Point2f.(x_coords, y_coords), color = ("#440154FF", 0.3))

    lines!(ax, 1:length(power), power / 10^6, color = :black)
    # Draw the shaded region
    save("plots/pdfs/power_cruve.pdf", f)
    f
end