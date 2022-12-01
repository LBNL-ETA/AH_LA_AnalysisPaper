## code compiling energyplus output by type and vintage during and pre-heatwave (epout.pre.during.heatwave) goes here

library("dplyr")

filepath = "EP_output_csv/sim_result_ann_WRF_2018_csv"

files <- list.files(filepath, pattern = "*.csv")

epout <- lapply(files, function(f) {
    print(f)
    readr::read_csv(sprintf("%s/%s", filepath, f), col_types = readr::cols()) %>%
        dplyr::select(-starts_with("Environment:Site Outdoor Air"),
                      -starts_with("Environment:Site Wind")) %>%
        dplyr::mutate(filename = f) %>%
        {.}
}) %>%
    dplyr::bind_rows()

kw.to.type.vin <- readr::read_csv("type_vintage_to_idf_mapping.csv") %>%
    dplyr::mutate(idf.kw = gsub(".idf", "", idf.name, fixed=TRUE)) %>%
    dplyr::mutate(idf.kw = gsub(".", "_", idf.kw, fixed=TRUE)) %>%
    dplyr::select(-idf.name) %>%
    {.}

kw.to.type.vin

epout.tidy <- epout %>%
    tidyr::separate(filename, into = c("idf.kw", "epw.id"), sep = "____") %>%
    dplyr::mutate(epw.id = gsub(".csv", "", epw.id, fixed = TRUE)) %>%
    dplyr::left_join(kw.to.type.vin, by = "idf.kw") %>%
    dplyr::mutate(emission.exfiltration = `Environment:Site Total Zone Exfiltration Heat Loss [J](Hourly)`,
                  emission.exhaust = `Environment:Site Total Zone Exhaust Air Heat Loss [J](Hourly)`,
                  emission.ref = `SimHVAC:Air System Relief Air Total Heat Loss Energy [J](Hourly)`,
                  emission.rej = `SimHVAC:HVAC System Total Heat Rejection Energy [J](Hourly)`,
                  emission.surf = `Environment:Site Total Surface Heat Emission to Air [J](Hourly)`,
                  emission.overall = emission.exfiltration + emission.exhaust + emission.ref + emission.rej + emission.surf) %>%
    dplyr::mutate(energy.elec = `Electricity:Facility [J](Hourly)`) %>%
    dplyr::mutate(energy.gas = `NaturalGas:Facility [J](Hourly)`) %>%
    dplyr::mutate(energy.overall = ifelse(is.na(energy.gas), energy.elec,
                                   ifelse(is.na(energy.elec), energy.gas, energy.elec + energy.gas))) %>%
    dplyr::select(idf.kw, epw.id, building.type, vintage, `Date/Time`, starts_with("emission"), starts_with("energy")) %>%
    {.}

heatwave.days = sprintf("07/%02d", 6:12)

pre.heatwave.days = c(sprintf("06/%02d", 29:30), sprintf("07/%02d", 1:5))

epout.pre.during.heatwave <- epout.tidy %>%
    tidyr::separate(`Date/Time`, into = c("date", "hour"), sep = "  ") %>%
    dplyr::filter(date %in% c(pre.heatwave.days, heatwave.days)) %>%
    {.}

usethis::use_data(epout.pre.during.heatwave)
