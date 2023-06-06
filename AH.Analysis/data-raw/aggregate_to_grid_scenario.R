library("dplyr")
library("tmap")


## ## heat wave period
## result.file = "sim_result_by_idf_epw.csv"
## annual 2018

setwd("AH.Analysis/data-raw")

load(file="../data/building.metadata.rda")

load(file="../data/prototype.area.rda")

sf::st_geometry(building.metadata) <- NULL

prototype.area

building.metadata <- building.metadata %>%
    tibble::as_tibble() %>%
    dplyr::mutate(epw.id = id.grid.coarse) %>%
    dplyr::left_join(prototype.area, by = "idf.kw") %>%
    {.}

building.metadata 

area.per.tract <- building.metadata %>%
    dplyr::group_by(id.tract, idf.kw, epw.id, building.type, vintage) %>%
    dplyr::summarise(building.area.m2 = sum(building.area.m2),
                     FootprintArea.m2 = sum(FootprintArea.m2),
                     prototype.m2 = first(prototype.m2)) %>%
    dplyr::ungroup() %>%
    {.}

usethis::use_data(area.per.tract, overwrite = TRUE)

area.per.coarse.grid <- building.metadata %>%
    dplyr::group_by(id.grid.coarse, idf.kw, epw.id, building.type, vintage) %>%
    dplyr::summarise(building.area.m2 = sum(building.area.m2),
                     FootprintArea.m2 = sum(FootprintArea.m2),
                     prototype.m2 = first(prototype.m2)) %>%
    dplyr::ungroup() %>%
    {.}

usethis::use_data(area.per.coarse.grid, overwrite = TRUE)

area.per.finer.grid <- building.metadata %>%
    dplyr::group_by(id.grid.finer, idf.kw, epw.id, building.type, vintage) %>%
    dplyr::summarise(building.area.m2 = sum(building.area.m2),
                     FootprintArea.m2 = sum(FootprintArea.m2),
                     prototype.m2 = first(prototype.m2)) %>%
    dplyr::ungroup() %>%
    {.}

usethis::use_data(area.per.finer.grid, overwrite = TRUE)

output.dir = "hourly_heat_energy/scenario"

compile.grid.data <- function(grid.level, grid.suf, year, scenario) {
    result.file = sprintf("annual_sim_result_by_idf_epw_%s.csv", scenario)
    time.pref = sprintf("annual_%d", year)
    if (grid.level != "finer") {
        if (file.exists(sprintf("%s/%s/%s%s.csv", output.dir, scenario, time.pref, grid.suf))) {
            return(NULL)
        }
    }
    result <- readr::read_csv(result.file)
    result.by.time <- result %>%
        dplyr::group_by(`Date/Time`) %>%
        dplyr::group_split()
    if (grid.level == "tract") {
        idf.epw.per.grid <- area.per.tract %>%
            dplyr::rename(id = id.tract) %>%
            {.}
    } else if (grid.level == "coarse") {
        idf.epw.per.grid <- area.per.coarse.grid %>%
            dplyr::rename(id = id.grid.coarse) %>%
            {.}
    } else { # finer
        idf.epw.per.grid <- area.per.finer.grid %>%
            dplyr::rename(id = id.grid.finer) %>%
            {.}
    }
    dirname = sprintf("%s/%s/%s%s", output.dir, scenario, time.pref, grid.suf)
    if (!dir.exists(dirname)) {
        dir.create(dirname, recursive = TRUE)
    }
    ## memory issue with mclapply, gets slower and slower towards the end of the loop
    ## set.seed(0)
    ## ## looping like this to prevent memory from running out
    ## building.heat.grid <- parallel::mclapply(result.by.time, function(df.time.i) {
    ##     print(df.time.i$`Date/Time`[[1]])
    ##     ## print(df.time.i$`Date`[[1]])
    ##     result.time.i <- idf.epw.per.grid %>%
    ##         dplyr::left_join(df.time.i, by=c("idf.kw", "epw.id")) %>%
    ##         ## dplyr::select(-idf.name) %>%
    ##         tidyr::gather(variable, value, emission.exh:energy.gas) %>%
    ##         dplyr::mutate(value = value / prototype.m2 * building.area.m2) %>%
    ##         dplyr::group_by(`Date/Time`, id, variable) %>%
    ##         dplyr::summarise(value = sum(value)) %>%
    ##         dplyr::ungroup() %>%
    ##         {.}
    ##     result.time.i
    ## }, mc.cores = 4) %>%
    ##     dplyr::bind_rows()
    ## looping like this to prevent memory from running out
    for (df.time.i in result.by.time) {
        timestamp = df.time.i$`Date/Time`[[1]]
        print(timestamp)
        out.file = sprintf("%s/%s/%s%s/%s.csv", output.dir, scenario,
                           time.pref, grid.suf,
                           gsub("[/:]", "_", timestamp))
        if (file.exists(out.file)) {
            next
        }
        result.time.i <- idf.epw.per.grid %>%
            dplyr::inner_join(df.time.i, by=c("idf.kw", "epw.id")) %>%
            tidyr::gather(variable, value, emission.exfiltration:energy.gas) %>%
            dplyr::mutate(value = value / prototype.m2 * building.area.m2) %>%
            dplyr::group_by(`Date/Time`, id, variable) %>%
            dplyr::summarise(value = sum(value)) %>%
            dplyr::ungroup() %>%
            tidyr::spread(variable, value) %>%
            dplyr::rename(geoid = id, timestamp=`Date/Time`) %>%
            dplyr::select(geoid, timestamp, starts_with("emission"), starts_with("energy")) %>%
            {.}
        result.time.i %>%
            readr::write_csv(out.file)
    }
    months = sprintf("%02d", 1:12)
    ## write to output heat energy file
    if (grid.level != "finer") {
        result.time.files <- list.files(sprintf("%s/%s/%s%s", output.dir, scenario, time.pref, grid.suf), "*.csv")
        lapply(result.time.files, function(f) {
            print(f)
            readr::read_csv(sprintf("%s/%s/%s%s/%s", output.dir, scenario, time.pref, grid.suf, f),
                            col_types = readr::cols())
        }) %>%
            dplyr::bind_rows() %>%
            readr::write_csv(sprintf("%s/%s/%s%s.csv", output.dir, scenario, time.pref, grid.suf))
    } else {
        for (month.str in months) {
            if (file.exists(sprintf("%s/%s/%s%s_%s.csv", output.dir, scenario, time.pref, grid.suf, month.str))) {
                next
            }
            print(sprintf("month.str = %s", month.str))
            result.time.files <- list.files(sprintf("%s/%s/%s%s", output.dir, scenario, time.pref, grid.suf),
                                            pattern=sprintf("^%s_*", month.str))
            df.month <- lapply(result.time.files, function(f) {
                print(f)
                readr::read_csv(sprintf("%s/%s/%s%s/%s", output.dir, scenario, time.pref, grid.suf, f),
                                col_types = readr::cols())
            }) %>%
                dplyr::bind_rows() %>%
                {.}
            df.month %>%
                readr::write_csv(sprintf("%s/%s/%s%s_%s.csv", output.dir, scenario, time.pref, grid.suf, month.str))
        }
    }
}

scenario = "envelope"

year = 2018

for (grid.level in c("tract", "finer")) {
    ## for (grid.level in c("coarse", "tract", "finer")) {
    for (scenario.i in c("baseline")) {
    ## for (scenario.i in c("envelope", "Lighting70", "infiltration", "CoolingCoilCOP")) {
        if (grid.level == "coarse") {
            grid.suf = ""
        } else {
            grid.suf = paste0("_", grid.level)
        }
        print("-------------------------------------------------")
        print(sprintf("%s_%s", scenario.i, grid.level))
        print("-------------------------------------------------")
        compile.grid.data(grid.level, grid.suf, year, scenario.i)
        dirname = sprintf("%s/%s/%s%s", output.dir, scenario.i, time.pref, grid.suf)
        ## remove temp individual hour data
        unlink(dirname, recursive = TRUE)
    }
}

## not sure what these are for start
    annual.sim.result <- readr::read_csv(sprintf("intermediate_data/annual_total_result_%d.csv", year))

    idf.epw.per.grid %>%
        dplyr::left_join(annual.sim.result, by=c("idf.kw", "epw.id")) %>%
        tidyr::gather(variable, value, emission.exfiltration:energy.gas) %>%
        dplyr::mutate(value = value / prototype.m2 * building.area.m2) %>%
        tidyr::spread(variable, value) %>%
        readr::write_csv(sprintf("intermediate_data/annual_heat_energy/%d_by_grid_id_type%s.csv", year, grid.suf))

    monthly.sim.result <- readr::read_csv(sprintf("intermediate_data/monthly_total_result_%d.csv", year))

    idf.epw.per.grid %>%
        dplyr::left_join(monthly.sim.result, by=c("idf.kw", "epw.id")) %>%
        tidyr::gather(variable, value, emission.exfiltration:energy.gas) %>%
        dplyr::mutate(value = value / prototype.m2 * building.area.m2) %>%
        tidyr::spread(variable, value) %>%
        readr::write_csv(sprintf("intermediate_data/monthly_heat_energy/%d_by_grid_id_type%s_.csv", year, grid.suf))

## not sure what these are for end


for (grid.level in c("coarse", "finer", "tract")) {
    ## get monthly total, and monthly diurnal profile (month-hour average)
    if (grid.level == "finer") {
        lapply(months, function(month.str) {
            print(month.str)
            df.month.i <-
                readr::read_csv(sprintf("output_data/hourly_heat_energy/%s%s_%s.csv", time.pref, grid.suf, month.str))
            df.month.i %>%
                dplyr::group_by(geoid) %>%
                dplyr::summarise_if(is.numeric, sum) %>%
                dplyr::ungroup() %>%
                dplyr::mutate(month = month.str) %>%
                dplyr::select(month, geoid, everything())
        }) %>%
            dplyr::bind_rows() %>%
            readr::write_csv(sprintf("intermediate_data/monthly_heat_energy/%d_monthly%s.csv", year, grid.suf))
        lapply(months, function(month.str) {
            print(month.str)
            df.month.i <-
                readr::read_csv(sprintf("output_data/hourly_heat_energy/%s%s_%s.csv", time.pref, grid.suf, month.str))
            df.month.i %>%
                dplyr::mutate(month = month.str) %>%
                tidyr::separate(timestamp, into=c("Date", "Hour"), sep="  ") %>%
                dplyr::mutate(Hour=as.numeric(gsub(":00:00", "", Hour))) %>%
                dplyr::group_by(month, Hour, geoid) %>%
                dplyr::summarise_if(is.numeric, mean) %>%
                dplyr::ungroup()
        }) %>%
            dplyr::bind_rows() %>%
            readr::write_csv(sprintf("intermediate_data/diurnal/%s%s_hourly_avg_month.csv", time.pref, grid.suf))
    } else {
        df.year <- readr::read_csv(sprintf("output_data/hourly_heat_energy/%s%s.csv", time.pref, grid.suf))
        df.year %>%
            tidyr::separate(timestamp, into=c("month", "other"), sep="/") %>%
            dplyr::select(-other) %>%
            dplyr::group_by(month, geoid) %>%
            dplyr::summarise_if(is.numeric, sum) %>%
            dplyr::ungroup() %>%
            readr::write_csv(sprintf("intermediate_data/monthly_heat_energy/%d_monthly%s.csv", year, grid.suf))
        print(sprintf("write to: intermediate_data/monthly_heat_energy/%d_monthly%s.csv", year, grid.suf))
        df.year %>%
            tidyr::separate(timestamp, into=c("month", "other"), sep="/") %>%
            tidyr::separate(other, into=c("Date", "Hour"), sep="  ") %>%
            dplyr::mutate(Hour=as.numeric(gsub(":00:00", "", Hour))) %>%
            dplyr::select(-Date) %>%
            dplyr::group_by(month, Hour, geoid) %>%
            dplyr::summarise_if(is.numeric, mean) %>%
            dplyr::ungroup() %>%
            readr::write_csv(sprintf("intermediate_data/diurnal/%s%s_hourly_avg_month.csv", time.pref, grid.suf))
        print(sprintf("write to: intermediate_data/diurnal/%s%s_hourly_avg_month.csv", time.pref, grid.suf))
    }
}


temp.dirname = sprintf("%s/%s", output.dir, "Lighting70")
if (!dir.exists(temp.dirname)) {
    dir.create(temp.dirname)
}

temp.dirname = sprintf("%s/%s/%s%s", output.dir, "Lighting70", "annual_2018", "")
if (!dir.exists(temp.dirname)) {
    dir.create(temp.dirname, recursive = TRUE)
}
