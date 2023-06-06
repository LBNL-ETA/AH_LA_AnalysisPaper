library("dplyr")

setwd("AH.Analysis/data-raw")

df = readr::read_csv("epw_idf_to_simulate.csv") %>%
    dplyr::filter(stringr::str_detect(idf.name, "Family")) %>%
    dplyr::mutate(idf.name = gsub(".idf", "_cz_6.idf", idf.name)) %>%
    {.}

df

scenario.files = list.files("scenario_simulation/to_simulate_cz_6", pattern="*.idf")

tibble::tibble(filename = scenario.files) %>%
    dplyr::mutate(filename.to.sep = gsub("_Single", "__Single", filename)) %>%
    dplyr::mutate(filename.to.sep = gsub("_Multi", "__Multi", filename.to.sep )) %>%
    tidyr::separate(filename.to.sep, sep = "__", into = c("scenario", "idf.name")) %>%
    dplyr::left_join(df, by = "idf.name") %>%
    dplyr::rename(base.file = idf.name) %>%
    dplyr::rename(idf.name = filename) %>%
    readr::write_csv("epw_idf_to_simulate_scenario_cz6.csv")
