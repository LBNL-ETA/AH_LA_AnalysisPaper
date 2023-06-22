## code getting diurnal profile here

library("dplyr")

setwd("AH.Analysis/data-raw")

devtools::load_all("../../../../packages/AHhelper")

load("../data/grid.finer.rda")

grid.finer.area <- grid.finer

sf::st_geometry(grid.finer.area) <- NULL

grid.finer.area <- grid.finer.area %>%
    tibble::as_tibble() %>%
    dplyr::select(id.grid.finer, area.m2) %>%
    {.}

## finer

diurnal.month.finer <- lapply(sprintf("%02d", 1:12), function(mon) {
    print(mon)
    readr::read_csv(sprintf("hourly_heat_energy/annual_2018_finer_%s.csv", mon)) %>%
        na.omit() %>%
        dplyr::mutate(hour = as.numeric(substr(timestamp, 8, 9)) - 1) %>%
        dplyr::mutate(month = as.numeric(substr(timestamp, 1, 2))) %>%
        dplyr::group_by(geoid, month, hour) %>%
        dplyr::summarise_if(is.numeric, mean) %>%
        dplyr::ungroup() %>%
        dplyr::left_join(grid.finer.area, by = c("geoid"="id.grid.finer")) %>%
        ## convert to W/m2
        dplyr::mutate_at(vars(starts_with("emission"), starts_with("energy")),
                         list(~ . * 0.000277778 / .data$area.m2)) %>%
        dplyr::select(-area.m2) %>%
        ## average across grid cell geoid
        dplyr::group_by(month, hour) %>%
        dplyr::summarise_if(is.numeric, mean) %>%
        dplyr::ungroup() %>%
        {.}
}) %>%
    dplyr::bind_rows() %>%
    {.}

diurnal.month.finer <- diurnal.month.finer %>%
    dplyr::select(-geoid) %>%
    {.}

usethis::use_data(diurnal.month.finer, overwrite = TRUE)

days.in.month = tibble::tibble(month = 1:12,
                               num.days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31))

diurnal.finer <- diurnal.month.finer %>%
    dplyr::left_join(days.in.month, by = "month") %>%
    dplyr::select(-month) %>%
    dplyr::group_by(hour) %>%
    ## weighted average across months
    dplyr::summarise_if(is.numeric, ~ weighted.mean(., .data$num.days)) %>%
    dplyr::ungroup() %>%
    {.}

usethis::use_data(diurnal.finer, overwrite = TRUE)

summer.week.day = "07/11"
summer.weekend.day = "07/07"
winter.week.day = "01/17"
winter.weekend.day = "01/13"

subset.hour <- function(mon, days, hours) {
    readr::read_csv(sprintf("hourly_heat_energy/annual_2018_finer_%s.csv", mon)) %>%
        tidyr::separate(timestamp, into=c("date", "hour"), sep="  ") %>%
        dplyr::filter(date %in% days) %>%
        dplyr::mutate(hour = as.numeric(substr(hour, 1, 2)) - 1) %>%
        dplyr::filter(hour %in% hours) %>%
        {.}
}

snapshot.winter <- subset.hour(mon="01", days=c(winter.week.day, winter.weekend.day), hours=c(14, 22)) %>%
    ## subset.hour(mon="07", days=c(summer.week.day, summer.weekend.day), hours=c(14, 22)) %>%
    {.}

snapshot.summer <- subset.hour(mon="07", days=c(summer.week.day, summer.weekend.day), hours=c(14, 22)) %>%
    {.}

df.day.status = tibble::tibble(date = c(winter.week.day, winter.weekend.day,
                                        summer.week.day, summer.weekend.day),
                               label = c("winter weekday", "winter weekend",
                                         "summer weekday", "summer weekend"))

snapshot.finer <- snapshot.winter %>%
    dplyr::bind_rows(snapshot.summer) %>%
    dplyr::left_join(df.day.status, by="date") %>%
    dplyr::mutate(time.label = sprintf("%s %02d:00", label, hour)) %>%
    dplyr::left_join(grid.finer.area, by = c("geoid"="id.grid.finer")) %>%
    ## convert to W/m2
    dplyr::mutate_at(vars(starts_with("emission"), starts_with("energy")),
                     list(~ . * 0.000277778 / .data$area.m2)) %>%
    dplyr::select(-area.m2) %>%
    dplyr::select(date, hour, time.label, geoid, everything())

usethis::use_data(snapshot.finer, overwrite = TRUE)

