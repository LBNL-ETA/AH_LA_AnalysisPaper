# compiling hourly AH data from pre to during heatwave period

library("dplyr")

## finer grid

heatwave.days.plot = sprintf("07/%02d", 6:14)
pre.heatwave.days.plot = c(sprintf("06/%02d", 27:30), sprintf("07/%02d", 1:5))

heatwave.days = sprintf("07/%02d", 6:12)
pre.heatwave.days = c(sprintf("06/%02d", 29:30), sprintf("07/%02d", 1:5))

july.data = readr::read_csv("hourly_heat_energy/annual_2018_finer_07.csv") %>%
    dplyr::select(-starts_with("energy")) %>%
    {.}

june.data = readr::read_csv("hourly_heat_energy/annual_2018_finer_06.csv") %>%
    dplyr::select(-starts_with("energy")) %>%
    {.}

july.data.study <- july.data %>%
    tidyr::separate(`timestamp`, into = c("date", "hour"), sep = "  ") %>%
    dplyr::filter(date %in% c(pre.heatwave.days.plot, heatwave.days.plot)) %>%
    {.}

june.data.study <- june.data %>%
    tidyr::separate(`timestamp`, into = c("date", "hour"), sep = "  ") %>%
    dplyr::filter(date %in% c(pre.heatwave.days.plot, heatwave.days.plot)) %>%
    {.}

hourly.AH.per.to.during.heatwave.finer <- june.data.study %>%
    dplyr::bind_rows(july.data.study) %>%
    dplyr::select(geoid:emission.exhaust, emission.ref:emission.surf, emission.overall) %>%
    dplyr::mutate(status = case_when(date %in% pre.heatwave.days ~ "pre",
                                     date %in% heatwave.days ~ "during"))

usethis::use_data(hourly.AH.per.to.during.heatwave.finer)
