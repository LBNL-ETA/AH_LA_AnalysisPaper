## export la county boundary

la.boundary = sf::st_read("geo_data/la-county-boundary.geojson", quiet=TRUE)

la.boundary.valid = sf::st_make_valid(la.boundary)

usethis::use_data(la.boundary.valid)
