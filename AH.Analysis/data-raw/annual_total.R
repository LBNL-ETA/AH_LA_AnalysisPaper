## code compiling annual total goes in here
## assume home dir is "AH.Analysis/data-raw"

setwd("AH.Analysis/data-raw")

library("dplyr")

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

df.coarse = readr::read_csv("hourly_heat_energy/annual_2018.csv")

df.coarse.ann <- df.coarse %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

usethis::use_data(df.coarse.ann, overwrite = TRUE)

df.coarse.month <- df.coarse %>%
    dplyr::mutate(month = substr(timestamp, 1, 2)) %>%
    dplyr::group_by(geoid, month) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

usethis::use_data(df.coarse.month)

list.files("hourly_heat_energy", pattern = "annual_2018_finer*")

df.finer <- lapply(list.files("hourly_heat_energy", pattern = "annual_2018_finer*"), function(f) {
    print(f)
    mon = gsub(".csv", "", gsub("annual_2018_finer_", "", f))
    readr::read_csv(sprintf("hourly_heat_energy/%s", f)) %>%
        dplyr::filter(!is.na(timestamp)) %>%
        get.total() %>%
        dplyr::mutate(month = mon) %>%
        {.}
}) %>%
    dplyr::bind_rows()

df.finer.month <- df.finer %>%
    tibble::as_tibble() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

usethis::use_data(df.finer.month, overwrite = TRUE)

df.finer.ann <- df.finer %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

usethis::use_data(df.finer.ann, overwrite = TRUE)

df.tract = readr::read_csv("hourly_heat_energy/annual_2018_tract.csv")

df.tract.ann <- df.tract %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.tract.ann

usethis::use_data(df.tract.ann)

df.tract.month <- df.tract %>%
    dplyr::mutate(month = substr(timestamp, 1, 2)) %>%
    dplyr::group_by(geoid, month) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

usethis::use_data(df.tract.month)

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
    epw = gsub(".csv", "", tokens[[2]])
    df <- read.eplusout(result.csv.dir, f) %>%
        dplyr::mutate(idf.kw = idf.kw, epw.id = epw) %>%
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

mon.sim.result.by.idf.epw  %>%
    summary()

usethis::use_data(mon.sim.result.by.idf.epw, overwrite = TRUE)

result.ann <- result.mon %>%
    dplyr::group_by(idf.kw, epw.id) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    {.}

ann.sim.result.by.idf.epw <- result.ann

usethis::use_data(ann.sim.result.by.idf.epw, overwrite = TRUE)

## --------------------------------------------------------------
## annual total by grid and building type
## --------------------------------------------------------------

ann.sim.result.by.idf.epw

load(file="../data/prototype.area.rda")

load("../data/building.metadata.rda")
sf::st_geometry(building.metadata) <- NULL
building.metadata <- building.metadata %>%
    dplyr::mutate_at(vars(usetype), recode, "single_family"="residential", "multi_family"="residential", "residential_other"="residential") %>%
    {.}

building.metadata

## this can be used to aggregate to any spatial level
annual.total.AH.per.building <- building.metadata %>%
    tibble::as_tibble() %>%
    dplyr::select(-(GeneralUseType:EffectiveYearBuilt), -idf.name, -HEIGHT) %>%
    dplyr::inner_join(ann.sim.result.by.idf.epw %>% dplyr::mutate(epw.id = as.numeric(epw.id)),
                      by=c("idf.kw", "id.grid.coarse"="epw.id")) %>%
    dplyr::inner_join(prototype.area, by = "idf.kw") %>%
    ## scale simulation result by building size
    tidyr::gather(variable, value, emission.exfiltration:energy.gas) %>%
    dplyr::mutate(value = value / prototype.m2 * building.area.m2) %>%
    tidyr::spread(variable, value) %>%
    {.}

usethis::use_data(annual.total.AH.per.building, overwrite = TRUE)

annual.total.AH.per.building.type.grid.coarse <- annual.total.AH.per.building %>%
    dplyr::select(id.grid.coarse, building.type, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.grid.coarse, building.type) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

usethis::use_data(annual.total.AH.per.building.type.grid.coarse)

annual.total.AH.per.building.type.grid.finer <- annual.total.AH.per.building %>%
    dplyr::select(id.grid.finer, building.type, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.grid.finer, building.type) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

annual.total.AH.per.building.type.tract <- annual.total.AH.per.building %>%
    dplyr::select(id.tract, building.type, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.tract, building.type) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

annual.total.AH.per.usetype.grid.coarse <- annual.total.AH.per.building %>%
    dplyr::select(id.grid.coarse, usetype, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.grid.coarse, usetype) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

annual.total.AH.per.usetype.grid.finer <- annual.total.AH.per.building %>%
    dplyr::select(id.grid.finer, usetype, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.grid.finer, usetype) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

annual.total.AH.per.usetype.tract <- annual.total.AH.per.building %>%
    dplyr::select(id.tract, usetype, FootprintArea.m2, building.area.m2, emission.exfiltration:energy.overall) %>%
    dplyr::group_by(id.tract, usetype) %>%
    dplyr::summarise_if(is.numeric, sum) %>%
    dplyr::ungroup() %>%
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9}) %>%
    {.}

usethis::use_data(annual.total.AH.per.building.type.grid.coarse)
usethis::use_data(annual.total.AH.per.building.type.grid.finer)
usethis::use_data(annual.total.AH.per.building.type.tract)
usethis::use_data(annual.total.AH.per.usetype.grid.coarse)
usethis::use_data(annual.total.AH.per.usetype.grid.finer)
usethis::use_data(annual.total.AH.per.usetype.tract)
