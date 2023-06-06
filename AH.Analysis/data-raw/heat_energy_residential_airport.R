library("dplyr")

setwd("AH.Analysis/data-raw")

## this path contains test runs for all climate zones, heat pump is not using the right model here
## result.path = "scenario_simulation/testrun"
## this path contains test runs for climate zone 6. heat pump model is right here
result.path = "scenario_simulation/testrun_cz_6"
## this path contains regular simulation runs
## result.path = "scenario_simulation/scenario_sim_output_cz_6"
dirs = list.dirs(result.path)

dirs <- dirs[which(stringr::str_detect(dirs, "Family"))]

dirs

devtools::load_all("../../../../packages/AHhelper")

## get monthly total AH and energy from simulation results using airport epw
residential.monthly.total.airport <- lapply(dirs, function(dirname) {
    print(dirname)
    read.eplusout(dirname, "eplusout.csv") %>%
        dplyr::mutate(filename = dirname) %>%
        tidyr::separate(`Date/Time`, into = c("month", "suffix"), sep = "/") %>%
        dplyr::select(-suffix) %>%
        dplyr::group_by(filename, month) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
}) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(filename = gsub("/Single", "/_Single", filename)) %>%
    dplyr::mutate(filename = gsub("/Multi", "/_Multi", filename)) %>%
    dplyr::mutate(filename = gsub(paste0(result.path, "/"), "", filename)) %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", filename)) %>%
    tidyr::separate(filename, into=c("scenario", "building.type", "vintage", "pref", "cz"), sep="_") %>%
    dplyr::select(-pref) %>%
    {.}

usethis::use_data(residential.monthly.total.airport, overwrite = TRUE)

## get annual total AH and energy from simulation results using airport epw
residential.annual.total.airport <- residential.monthly.total.airport %>%
    dplyr::group_by(scenario, building.type, vintage, cz) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    ## convert to GJ
    dplyr::mutate_if(is.numeric, function(x) {x * 1e-9}) %>%
    {.}

## get monthly total AH and energy from simulation results using airport epw
residential.monthly.total.airport <- lapply(dirs, function(dirname) {
    print(dirname)
    read.eplusout(dirname, "eplusout.csv") %>%
        dplyr::mutate(filename = dirname) %>%
        tidyr::separate(`Date/Time`, into = c("month", "suffix"), sep = "/") %>%
        dplyr::select(-suffix) %>%
        dplyr::group_by(filename, month) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
}) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(filename = gsub("/Single", "/_Single", filename)) %>%
    dplyr::mutate(filename = gsub("/Multi", "/_Multi", filename)) %>%
    dplyr::mutate(filename = gsub(paste0(result.path, "/"), "", filename)) %>%
    {.}

usethis::use_data(residential.annual.total.airport, overwrite = TRUE)

residential.annual.total.airport %>%
    dplyr::filter(cz = "6", scenario %in% c("", "HeatPump")) %>%
    dplyr::select(scenario)

## devtools::document("~/Dropbox/workLBNL/packages/AHhelper")
## devtools::document("~/Dropbox/workLBNL/packages/read.idfEnergyPlus")

## get month-hour average of AH and energy from simulation results using airport epw
residential.month.hour.mean.airport <- lapply(dirs, function(dirname) {
    print(dirname)
    read.eplusout(dirname, "eplusout.csv") %>%
        dplyr::mutate(filename = dirname) %>%
        tidyr::separate(`Date/Time`, into = c("month", "suffix"), sep = "/") %>%
        tidyr::separate(`suffix`, into = c("pref", "hour"), sep = "  ") %>%
        dplyr::mutate(hour = as.numeric(gsub(":00:00", "", hour))) %>%
        dplyr::select(-pref) %>%
        dplyr::group_by(filename, month, hour) %>%
        dplyr::summarise_if(is.numeric, mean) %>%
        dplyr::ungroup() %>%
        {.}
}) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(filename = gsub("/Single", "/_Single", filename)) %>%
    dplyr::mutate(filename = gsub("/Multi", "/_Multi", filename)) %>%
    dplyr::mutate(filename = gsub(paste0(result.path, "/"), "", filename)) %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", filename)) %>%
    tidyr::separate(filename, into=c("scenario", "building.type", "vintage", "pref", "cz"), sep="_") %>%
    dplyr::select(-pref) %>%
    {.}

usethis::use_data(residential.month.hour.mean.airport, overwrite = TRUE)
