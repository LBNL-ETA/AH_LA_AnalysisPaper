## export the building metadata file

library("dplyr")

building.metadata <- sf::st_read("building_metadata.geojson")

usethis::use_data(building.metadata)

sf::st_geometry(building.metadata) <- NULL
