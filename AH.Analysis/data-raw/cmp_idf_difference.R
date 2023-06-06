library("dplyr")

setwd("AH.Analysis/data-raw")

## update design day
devtools::load_all("../../../../packages/read.idfEnergyPlus")

vintage.labels = c("pre-1980", "2004", "2013", "2019")
names(vintage.labels) = c("1", "5", "8", "10")

pathname = "scenario_simulation/idf_version_update"

files = list.files(pathname, pattern = "*.idf")

files = files[which(!stringr::str_detect(files, "HeatPump_"))]
files = files[which(!stringr::str_detect(files, "Lighting70_"))]
files = files[which(!stringr::str_detect(files, "CoolingCoilCOP_"))]
files = files[which(!stringr::str_detect(files, "envelope_"))]

single.family.files <- files[which(stringr::str_detect(files, "SingleFamily"))]


get.field.value.files <- function(files, pathname, field.name,
                                  obj.type,
                                  obj.name) {
    apply.fun.to.files(files, pathname, get.field.value,
                       field.name,
                       obj.type,
                       obj.name, verbose=TRUE) %>%
        dplyr::mutate(object.type = obj.type) %>%
        dplyr::mutate(object.name = obj.name) %>%
        dplyr::mutate(field = field.name) %>%
        dplyr::arrange(filename) %>%
        {.}
}

idf.fields.to.query <- readr::read_csv("single_family_field_to_cmp.csv")

idf.fields.to.query

devtools::load_all("../../../../packages/read.idfEnergyPlus")
result <- lapply(1:nrow(idf.fields.to.query), function(i) {
    row.i = idf.fields.to.query[i,]
    print(row.i$field.name)
    get.field.value.files(single.family.files, pathname, field.name=row.i$field.name[[1]],
                          obj.type=row.i$object.type[[1]], obj.name=row.i$object.name[[1]]) %>%
        dplyr::mutate(value = as.numeric(value))
}) %>%
    dplyr::bind_rows()

result

result %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", filename)) %>%
    tidyr::separate(filename, c("type", "vintage", "pref", "cz"), sep="_") %>%
    dplyr::mutate(cz = gsub(".idf", "", cz)) %>%
    readr::write_csv("single_family_idf_cmp.csv")

## compare multi-family
lines = readLines("scenario_simulation/idf_version_update/MultiFamily-2004_cz_6.idf")

devtools::load_all("../../../../packages/read.idfEnergyPlus")
get.field.value.all.object(lines, field.name = "Maximum Air Flow Rate",
                           object.type = "AirTerminal:SingleDuct:ConstantVolume:NoReheat", verbose=TRUE)

get.field.value.all.object(lines, field.name = "Air Changes per Hour",
                           object.type = "ZoneInfiltration:DesignFlowRate,", verbose=TRUE)

get.field.and.name.idx(lines, field.name = "Maximum Air Flow Rate",
                       object.type = "AirTerminal:SingleDuct:ConstantVolume:NoReheat", verbose=TRUE) 

get.field.and.name.value.files <- function(files, pathname, field.name,
                                  obj.type,
                                  obj.name) {
    apply.fun.to.files(files, pathname, get.field.value.all.object,
                       field.name,
                       obj.type,
                       obj.name, verbose=FALSE) %>%
        dplyr::mutate(object.type = obj.type) %>%
        dplyr::mutate(field = field.name) %>%
        dplyr::arrange(filename) %>%
        {.}
}

multi.family.files <- files[which(stringr::str_detect(files, "MultiFamily"))]

multi.family.files

result <- get.field.and.name.value.files(multi.family.files, pathname, field.name="Air Changes per Hour",
                      obj.type="ZoneInfiltration:DesignFlowRate,", obj.name="")

multi.family.infiltration <- result$value %>%
    dplyr::bind_cols(result %>% select(-value)) %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", filename)) %>%
    tidyr::separate(filename, c("type", "vintage", "pref", "cz"), sep="_") %>%
    dplyr::mutate(cz = gsub(".idf", "", cz)) %>%
    dplyr::mutate(value = as.numeric(value)) %>%
    dplyr::select(type:field, name, value) %>%
    {.}

multi.family.infiltration %>%
    readr::write_csv("multi_family_idf_cmp.csv")

## compare differences for climate zone 6

pathname = "scenario_simulation/to_simulate_cz_6"

files = list.files(pathname, pattern="*.idf")

files = files[which(!stringr::str_detect(files, "HeatPump"))]

single.family.files <- files[which(stringr::str_detect(files, "SingleFamily"))]

single.family.files

idf.fields.to.query <- readr::read_csv("single_family_field_to_cmp_scenario.csv")

devtools::load_all("../../../../packages/read.idfEnergyPlus")
result <- lapply(1:nrow(idf.fields.to.query), function(i) {
    row.i = idf.fields.to.query[i,]
    print(row.i$field.name)
    get.field.value.files(single.family.files, pathname, field.name=row.i$field.name[[1]],
                          obj.type=row.i$object.type[[1]], obj.name=row.i$object.name[[1]]) %>%
        dplyr::mutate(value = as.numeric(value)) %>%
        {.}
}) %>%
    dplyr::bind_rows()

result %>%
    readr::write_csv("scenario_cmp_cz_6.csv")

idf.fields.to.query <- readr::read_csv("multi_family_field_to_cmp_scenario.csv")

multi.family.files <- files[which(stringr::str_detect(files, "MultiFamily"))]

cop.multi.family.files <- files[which(stringr::str_detect(multi.family.files, "COP_"))]

result <- get.field.and.name.value.files(cop.multi.family.files, pathname, field.name="Gross Rated Cooling COP",
                                         obj.type="Coil:Cooling:DX:SingleSpeed,", obj.name="")

multi.family.values <- result$value %>%
    dplyr::bind_cols(result %>% select(-value)) %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", filename)) %>%
    dplyr::mutate(value = as.numeric(value)) %>%
    dplyr::select(object.type:field, name, value) %>%
    {.}

multi.family.values %>%
    readr::write_csv("cop.csv")

