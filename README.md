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
    - AH.Analysis/data: tidied data for the analysis. Can be loaded with devtools::load_all("../AH.Analysis"). Currently some data files are too large to upload to github. Once all data sets are ready, they will be uploaded to the MSDLive website.

- rmd/ has the analysis script.
    - heatwave_analysis.Rmd has the script for the heatwave period analysis used in the AGU poster

- images/ has the analysis figures

- tables/ has the result tables
