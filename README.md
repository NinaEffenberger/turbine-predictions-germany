## Code structure
Most of the folder names are self-explanatory. `exp` contains all data generating code. `exp/actual_power` contains all code pre-processing actual power generation data. `exp/CMIP6_forecasts_future` generates location-aware and gridded speed and power predictions for 2025 to 2050 using CMIP6. `exp/CMIP6_forecasts_past` generates location-aware and gridded speed and power predictions for 2011 to 2023 with CMIP6 data, the corresponding predictions with ERA5 data are in `exp/ERA5_forecasts`. Code for turbine mapping and hyperparameter optimization is in `exp/others`. 

## Download data
All data is open-source and the corresponding licenses allow for redistribution. You can also download all pre-processed data that was used for the study, except for the actual power generation between 2011 and 2014 on [Zenodo](10.5281/zenodo.14699872). For full transparency and for cases where an analysis of a different region is of interest, we describe how data was downloaded in the following. 

### ERA5
ERA5 data can be downloaded on the [ERA5 website](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download). The data should be stored as one file per year. 

### CMIP6
CMIP6 data can be downloaded using the files in the folder [CMIP6_data_utils](./CMIP6_data_utils)`CMIP6_data_utils`. The scripts in `cmip6_download` were generated using the [ESGF metagrid](https://esgf-metagrid.cloud.dkrz.de/search). The files can be stored under `/data/original/...` See full folder structure for a more detailed description. The files can be pre-processed to only include Germany and to concatenate multiple files. Run `generate_files.sh` first and `extract_subregion.sh` afterwards. The output are smaller files (German region) for all years considered. 

### Wind power data
The wind power data consists of time series data from TSOs and the SMARD database as well as a static wind turbine data set. The code for pre-processing the data can be found in `actual_power/0001_real_power_gen_all.jl`.

The links to all TSO datasets can be found [here](https://open-power-system-data.org/data-sources) under DE clicking on the corresponding links to the individual TSOs Amprion, 50Hertz, Tennet and transnet. 

Actual generation from 2015 onwards can be downloaded from [SMARD] (https://www.smard.de/en/downloadcenter/download-market-data/). 

Turbine locations in Germany are from [Manske and Schmiedt, 2023](https://zenodo.org/records/8188601) and turbines are extracted and matched to a turbine from [windpowerlib](extracted_wind_speeds) in `exp/other/0002_find_turbine.jl`. 


### Full folder structure
    .
    ├── ...
    ├── data                    # data folder
    │   ├── ERA5
    │   │   ├── germany_wind_2011  # yearly ERA5 files
    │   │   ├── ...
    │   │   └── germany_wind_2023 
    │   ├── extracted_wind_speeds         # store extracted wind speeds
    │   │   ├── ERA5
    │   │   └── MPI
    │   │       ├── historical
    │   │       ├── past      # until 2023
    │   │       │   ├── SSP126
    │   │       │   ├── SSP245
    │   │       │   ├── SSP370
    │   │       │   └── SSP585
    │   │       ├── SSP126
    │   │       ├── SSP245
    │   │       ├── SSP370
    │   │       └── SSP585
    │   ├── forecasts_era5
    │   ├── hyperparams
    │   ├── original         # store downloaded CMIP6
    │   │   ├── historical
    │   │   ├── past        # until 2023
    │   │   │   ├── SSP126
    │   │   │   ├── SSP245
    │   │   │   ├── SSP370
    │   │   │   └── SSP585
    │   │   ├── SSP126
    │   │   ├── SSP245
    │   │   ├── SSP370
    │   │   └── SSP585
    │   ├── power_forecasts         # store generated predictions from CMIP6
    │   │   ├── historical
    │   │   ├── past        # until 2023
    │   │   │   ├── SSP126
    │   │   │   ├── SSP245
    │   │   │   ├── SSP370
    │   │   │   └── SSP585
    │   │   ├── SSP126
    │   │   │   ├── orig 
    │   │   │   └── turbines
    │   │   ├── SSP245
    │   │   │   ├── orig 
    │   │   │   └── turbines
    │   │   ├── SSP370
    │   │   │   ├── orig 
    │   │   │   └── turbines
    │   │   └── SSP585
    │   │       ├── orig 
    │   │       └── turbines
    │   ├── power_gen         # actual power generation reported by TSOs
    │   │   ├── 50hertz 
    │   │   ├── amprion
    │   │   ├── tennet
    │   │   └── transnet 
    │   ├── prob_extracted_mean         # mean wind speed predictions at turbine locations 
    │   │   ├── historical
    │   │   ├── past        # until 2023
    │   │   │   ├── SSP126
    │   │   │   ├── SSP245
    │   │   │   ├── SSP370
    │   │   │   └── SSP585
    │   │   ├── SSP126
    │   │   ├── SSP245
    │   │   ├── SSP370
    │   │   └── SSP585
    │   ├── prob_extracted_var         # variance wind speed predictions at turbines 
    │   │   ├── historical
    │   │   ├── past        # until 2023
    │   │   │   ├── SSP126
    │   │   │   ├── SSP245
    │   │   │   ├── SSP370
    │   │   │   └── SSP585
    │   │   ├── SSP126
    │   │   ├── SSP245
    │   │   ├── SSP370
    │   │   └── SSP585
    │   └──  turbine_locations         # yearly turbine locations extracted from [Manske and Schmiedt, 2023] (https://zenodo.org/records/8188601)
    └──  ... 