library("dplyr")

prototype.area <- readr::read_csv("prototype_bldg_area.csv") %>%
    dplyr::mutate(idf.kw = gsub(".idf", "", idf.name, fixed=TRUE)) %>%
    dplyr::mutate(idf.kw = gsub(".", "_", idf.kw, fixed=TRUE)) %>%
    dplyr::select(-idf.name) %>%
    dplyr::select(idf.kw, everything()) %>%
    {.}

usethis::use_data(prototype.area)
