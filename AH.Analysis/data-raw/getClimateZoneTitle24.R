library("dplyr")

setwd("AH.Analysis/data-raw")

## source: https://www.energy.ca.gov/media/3560
zipcode.to.ca.climate.zone = readxl::read_excel("BuildingClimateZonesByZIPCode_ada.xlsx") %>%
    dplyr::mutate(ZIPCODE = as.character(`Zip Code`))

zipcode.to.ca.climate.zone

## zipcodes in LA county
## source: https://geohub.lacity.org/datasets/71b2fed2c1f24fc8850f5b7f8d2a320a/explore?location=33.857348%2C-117.885815%2C8.68
df.zipcode <- sf::st_read("Zip_Codes_(LA_County).geojson")

join.geo <- df.zipcode %>%
    dplyr::mutate(ZIPCODE = as.character(ZIPCODE)) %>%
    dplyr::left_join(zipcode.to.ca.climate.zone, by = "ZIPCODE") %>%
    dplyr::mutate(`Building CZ` = factor(`Building CZ`)) %>%
    sf::st_as_sf() %>%
    {.}

join.geo %>%
    ggplot2::ggplot(ggplot2::aes(fill = `Building CZ`)) +
    ggplot2::geom_sf(size=0.3)
ggplot2::ggsave("zipcode_ca_climate_zone.png")

la.zipcode <- df.zipcode %>%
    tibble::as_tibble() %>%
    distinct(ZIPCODE) %>%
    dplyr::mutate(ZIPCODE = as.character(ZIPCODE))

la.zipcode %>%
    dplyr::left_join(zipcode.to.ca.climate.zone, by = "ZIPCODE") %>%
    ## dplyr::filter(is.na(`Building CZ`)) %>%
    ## distinct(`Building CZ`) %>%
    dplyr::group_by(`Building CZ`) %>%
    dplyr::summarise(count = n()) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(desc(count)) %>%
    {.}

## match building to climate zone
df.building <- sf::st_read("building_metadata.geojson")

df.building <- df.building %>%
    dplyr::select(OBJECTID)

sf::sf_use_s2(FALSE)

join.geo %>%
    distinct(ZIPCODE)

building.cz <- sf::st_join(df.building, join.geo, join = sf::st_within)

building.cz.no.geom <- building.cz %>%
    select(OBJECTID.x, ZIPCODE, `Building CZ`) %>%
    tibble::as_tibble()

building.cz.no.geom %>%
    dplyr::group_by(`Building CZ`) %>%
    dplyr::count()

    distinct(OBJECTID.x)
