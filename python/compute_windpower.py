import windpowerlib
import pandas as pd
from windpowerlib import data as wt
df = pd.read_csv('data/turbine_data.csv')
def remove_semicolon_and_convert_to_float(input_string):
    before_semicolon = input_string.partition(';')[0]
    return float(before_semicolon)
 # Output: example

all_hubheights = df[df["turbine_type"].str.contains("V100/1800")].hub_height.values
print(all_hubheights)
#hubheight = remove_semicolon_and_convert_to_float(all_hubheights[0])
#print(hubheight)

def compute_windpower(weather, turbine):
    try:
        all_hubheights = df[df["turbine_type"].str.contains(turbine)].hub_height.values
        hubheight = remove_semicolon_and_convert_to_float(all_hubheights[0])
    #if there's no info regarding hub height in the database
    except:
        hubheight=100
    enercon_e126 = {
        "turbine_type": turbine,  # turbine type as in register
        "hub_height": hubheight,  # in m
        #"rotor_diameter":5
    }
    e126 = windpowerlib.WindTurbine(**enercon_e126)
    mc_e126 = windpowerlib.ModelChain(e126)
    # write power output time series to WindTurbine object
    power = mc_e126.calculate_power_output(weather, 1)
    return power

print(compute_windpower([1,2], "V100/1800"))
