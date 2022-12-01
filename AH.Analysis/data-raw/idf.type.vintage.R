## code compiling the mapping from simulation model name (.idf) to building
## type, vintage, and idf kw in the simulation output csv

library("dplyr")

idf.type.vintage <- readr::read_csv("type_vintage_to_idf_mapping.csv") %>%
  dplyr::mutate(idf.kw = gsub(".idf", "", idf.name, fixed=TRUE)) %>%
  dplyr::mutate(idf.kw = gsub(".", "_", idf.kw, fixed=TRUE)) %>%
  {.}

usethis::use_data(idf.type.vintage)
