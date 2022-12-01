## code compiling annual total goes in here

library("dplyr")

get.total <- function(df) {
    df %>%
        dplyr::group_by(geoid) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
}

df.coarse = readr::read_csv("hourly_heat_energy/annual_2018.csv")

df.coarse.ann <- df.coarse %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

usethis::use_data(df.coarse.ann)

df.finer <- lapply(list.files("hourly_heat_energy", pattern = "annual_2018_finer*"), function(f) {
    print(f)
    readr::read_csv(sprintf("hourly_heat_energy/%s", f)) %>%
        get.total()
}) %>%
    dplyr::bind_rows()

df.finer.ann <- df.finer %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.finer.ann

usethis::use_data(df.finer.ann, overwrite = TRUE)

df.tract = readr::read_csv("hourly_heat_energy/annual_2018_tract.csv")

df.tract.ann <- df.tract %>%
    get.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.tract.ann

usethis::use_data(df.tract.ann)
