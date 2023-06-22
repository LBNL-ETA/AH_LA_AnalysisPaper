# AH_LA_AnalysisPaper
Code to analyze AH data for LA county

## Abstract

To be added...

## Journal reference

To be added...

## Code reference

To be added...

## Folder Structure

- AH.Analysis: contains the data and helper functions used in the analysis. It is organized as a stand-alone R package.
    - AH.Analysis/data-raw: input data and script processing the inputs. All these files are from https://doi.org/10.57931/1892041
        - scenario_simulation: contains the residential building idf files to be
          simulated, the final simulation model are in
          scenario_simulation/scenario_sim_output_cz_6. The model prefix denotes
          the retrofit scenario
            - envelope: increased thickness of wall/roof layers, reduced window solar heat gain coefficient (SHGC) and U-value
            - CoolingCoilCOP: increased cooling coil gross rated cooling coefficient of performance (COP)
            - infiltration: reduced air changes per hour (ACH) for living spaces according to Title 24-2019 requirements
            - Lighting70: reduce lighting intensity (internal gain) by 30%
            - HeatPump: change HVAC system to heat pumps
    - AH.Analysis/data: tidied data for the analysis. Can be loaded with
      devtools::load_all("../AH.Analysis"). Or load("../AH.Analysis/xx.rda")
      individually. Currently some data files are too large to upload to github.
      Once all data sets are ready, they will be uploaded to the MSDLive
      website.

- rmd/ has the analysis script.
    - heatwave_analysis.Rmd has the script for the heatwave period analysis used in the AGU poster
    - main_analysis.Rmd has the script for the annual, monthly, diurnal profile analysis.
    - viewHighEmitGrid_annual.Rmd has the script for viewing satellite view of grid cells with high anthropogenic heat

- app/ has the code for a shiny app to visualize simulation results of prototype building simulation results in folder
"../AH.Analysis/data-raw/scenario_simulation/scenario_sim_output_cz_6_csv"

- app_map/ has the code for a shiny app to visualize census tract level
  energy/anthropogenic heat of 4 retrofit scenario (heat pump scenario not
  included yet) and their relative change comparing with the no-retrofit
  scenario

- images/ has the analysis figures. Some figures are directly saved in rmd exported html files

- tables/ has the result tables
