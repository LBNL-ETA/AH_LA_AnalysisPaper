## code compiling daily total (with annual duration) goes in here

library("dplyr")

get.daily.total <- function(df) {
    df %>%
        tidyr::separate(timestamp, into = c("date", "hour"), sep = "  ") %>%
        dplyr::select(-hour) %>%
        dplyr::group_by(geoid, date) %>%
        dplyr::summarise_if(is.numeric, sum) %>%
        dplyr::ungroup() %>%
        {.}
}

df.coarse = readr::read_csv("hourly_heat_energy/annual_2018.csv")

df.coarse.daily <- df.coarse %>%
    get.daily.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.coarse.daily

usethis::use_data(df.coarse.daily)

df.finer <- lapply(list.files("hourly_heat_energy", pattern = "annual_2018_finer*"), function(f) {
    print(f)
    readr::read_csv(sprintf("hourly_heat_energy/%s", f)) %>%
        get.daily.total()
}) %>%
    dplyr::bind_rows()

df.finer.daily <- df.finer %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.finer.daily

usethis::use_data(df.finer.daily)

df.tract = readr::read_csv("hourly_heat_energy/annual_2018_tract.csv")

df.tract.daily <- df.tract %>%
    get.daily.total() %>%
    ## unit to GJ
    dplyr::mutate_at(vars(emission.exfiltration:energy.overall), function (x) {x * 1e-9})

df.tract.daily %>%
    distinct(geoid)

usethis::use_data(df.tract.daily)
