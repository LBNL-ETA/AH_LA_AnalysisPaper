## code to prepare geo_data goes here

grid.coarse = sf::st_read("../data-raw/geo_data/coarse_grid.geojson")

usethis::use_data(grid.coarse)

grid.finer = sf::st_read("../data-raw/geo_data/finer_grid.geojson")

usethis::use_data(grid.finer)

tract = sf::st_read("../data-raw/geo_data/tract.geojson")

usethis::use_data(tract)
