## code compiling annual total for retrofit scenarios goes in here
## assume home dir is "AH.Analysis/data-raw"

library("dplyr")

setwd("AH.Analysis/data-raw")

get.total <- function(df) {
    df %>%
        dplyr::group_by(geoid) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
}

## --------------------------------------------------------------
## annual total by grid
## --------------------------------------------------------------

scenarios = c("baseline", "envelope", "Lighting70", "infiltration", "CoolingCoilCOP")

## residential scenario heat energy data annual total
res.scenario.coarse.ann <- lapply(scenarios, function(scenario.i) {
    df.coarse = readr::read_csv(sprintf("hourly_heat_energy/scenario/%s/annual_2018.csv", scenario.i))
    df.coarse %>%
        get.total() %>%
        ## unit to GJ
        dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
        dplyr::mutate(scenario = scenario.i)
}) %>%
    dplyr::bind_rows()

usethis::use_data(res.scenario.coarse.ann, overwrite = TRUE)

res.scenario.coarse.ann <- lapply(scenarios, function(scenario.i) {
    df.tract = readr::read_csv(sprintf("hourly_heat_energy/scenario/%s/annual_2018_tract.csv", scenario.i))
    df.tract %>%
        get.total() %>%
        ## unit to GJ
        dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
        dplyr::mutate(scenario = scenario.i)
}) %>%
    dplyr::bind_rows()


df.tract.ann <- df.tract %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.tract.ann

usethis::use_data(df.tract.ann)



## --------------------------------------------------------------
## annual total by idf and epw
## --------------------------------------------------------------

## read simulation results for annual
result.csv.dir = "EP_output_csv/sim_result_ann_WRF_2018_csv"
files = list.files(result.csv.dir, pattern = "*.csv")

head(files)

devtools::load_all("../../../../packages/AHhelper")

result.mon <- lapply(files, function(f) {
    print(f)
    tokens = unlist(stringr::str_split(f, pattern = "____"))
    idf.kw = tokens[[1]]
    epw.id = gsub(".csv", "", tokens[[2]])
    df <- read.eplusout(result.csv.dir, f) %>%
        dplyr::mutate(idf.kw = idf.kw, epw.id = epw.id) %>%
        {.}
    df <- df %>%
        dplyr::select(`Date/Time`, idf.kw, epw.id, everything()) %>%
        tidyr::separate(`Date/Time`, into = c("month", "suffix"), sep = "/") %>%
        dplyr::select(-suffix) %>%
        dplyr::group_by(idf.kw, epw.id, month) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
    df
}) %>%
  dplyr::bind_rows()

## monthly simulation result
mon.sim.result.by.idf.epw <- result.mon

usethis::use_data(mon.sim.result.by.idf.epw)

result.ann <- result.mon %>%
    dplyr::group_by(idf.kw, epw.id) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    {.}

ann.sim.result.by.idf.epw <- result.ann

usethis::use_data(ann.sim.result.by.idf.epw)

idf.kw.to.usetype <- readr::read_csv("idf_kw_to_EnergyAtlas_usetype.csv")

usethis::use_data(idf.kw.to.usetype)
