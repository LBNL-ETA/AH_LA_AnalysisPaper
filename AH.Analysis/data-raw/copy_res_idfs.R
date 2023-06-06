library("dplyr")

setwd("AH.Analysis/data-raw")

files.original = list.files("scenario_simulation/original", pattern = "*.idf")

for (f in files.original) {
    file.copy(sprintf("scenario_simulation/original/%s", f),
              sprintf("scenario_simulation/to_simulate/original_%s", f))
}

file.copy("scenario_simulation/Heat Pump/bldg_11_vin_1_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_SingleFamily-pre-1980.idf")
file.copy("scenario_simulation/Heat Pump/bldg_11_vin_5_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_SingleFamily-2004.idf")
file.copy("scenario_simulation/Heat Pump/bldg_11_vin_8_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_SingleFamily-2013.idf")
file.copy("scenario_simulation/Heat Pump/bldg_11_vin_8_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_SingleFamily-2013.idf")

file.copy("scenario_simulation/Heat Pump/bldg_13_vin_1_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_MultiFamily-pre-1980.idf")
file.copy("scenario_simulation/Heat Pump/bldg_13_vin_5_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_MultiFamily-2004.idf")
file.copy("scenario_simulation/Heat Pump/bldg_13_vin_8_cz_6/model.idf",
          "scenario_simulation/to_simulate/HeatPump_MultiFamily-2013.idf")

## copy files with title 24 settings, these are not directly simulated
file.copy("Res (CBES) different climate zones/bldg_11_vin_10_cz_6/model.idf",
          "scenario_simulation/title24_2019/SingleFamily-2019.idf")
file.copy("Res (CBES) different climate zones/bldg_13_vin_10_cz_6/model.idf",
          "scenario_simulation/title24_2019/MultiFamily-2019.idf")

for (f in c("MultiFamily-pre-1980.idf", "MultiFamily-2004.idf", "MultiFamily-2013.idf")) {
  file.full.path = sprintf("scenario_simulation/original/%s", f)
  lines <- readLines(file.full.path)
  new.text = c("WindowMaterial:SimpleGlazingSystem,",
               "multi_family Window material_simple glazing,  !- Name" ,
               "1.7034,                  !- U-Factor {W/m2-K}" ,
               "0.23,                    !- Solar Heat Gain Coefficient" ,
               "0.81;                    !- Visible Transmittance")
  substring.pattern = "WindowMaterial:SimpleGlazingSystem,"
  new.lines <- read.idfEnergyPlus::replace.idf.chunk(lines, new.text, object.type = substring.pattern)
  obj.type.pattern = "Material,"
  obj.name.pattern = "multi_family ext wall 4 wall_consol_layer,"
  new.text <- c("Material,", "multi_family ext wall 4 wall_consol_layer," ,
                "Rough,                   !- Roughness" ,
                "0.138209541957025,       !- Thickness {m} replaced here!" ,
                "0.05966275,              !- Conductivity {W/m-K}" ,
                "120.801,                 !- Density {kg/m3}" ,
                "1036.25775,              !- Specific Heat {J/kg-K}" ,
                "0.9,                     !- Thermal Absorptance" ,
                "0.7,                     !- Solar Absorptance" ,
                "0.7;                     !- Visible Absorptance")
  new.lines <- read.idfEnergyPlus::replace.idf.chunk(new.lines, new.text, object.type = obj.type.pattern,
                                                    object.name = obj.name.pattern)
  ## change ceiling thickness
  if (stringr::str_detect(f, "pre-1980")) {
      new.text <- c("Material,",
                    "multi_family ceiling 2 UAAdditionalCeilingIns, !- Name",
                    "Rough,                                  !- Roughness",
                    "0.214606004710193,                      !- Thickness {m}",
                    "0.0406177631578947,                     !- Conductivity {W/m-K}",
                    "16.02,                                  !- Density {kg/m3}",
                    "1046.75,                                !- Specific Heat {J/kg-K}",
                    "0.9,                                    !- Thermal Absorptance",
                    "0.7,                                    !- Solar Absorptance",
                    "0.7;                                    !- Visible Absorptance")
      new.lines <- read.idfEnergyPlus::replace.idf.chunk(new.lines, new.text,
                                                         object.type = "Material,",
                                                         object.name="multi_family ceiling 2 UAAdditionalCeilingIns,")
  }
  writeLines(new.lines, sprintf("scenario_simulation/to_simulate/envelope_%s", f))
}

for (f in c("SingleFamily-pre-1980.idf", "SingleFamily-2004.idf", "SingleFamily-2013.idf")) {
  file.full.path = sprintf("scenario_simulation/original/%s", f)
  lines <- readLines(file.full.path)
  new.text = c("WindowMaterial:SimpleGlazingSystem,",
               "single_family_first_story Window material_simple glazing,  !- Name",
               "1.7034,                  !- U-Factor {W/m2-K}",
               "0.23,                    !- Solar Heat Gain Coefficient",
               "0.81;                    !- Visible Transmittance")
  substring.pattern = "WindowMaterial:SimpleGlazingSystem,"
  new.lines <- read.idfEnergyPlus::replace.idf.chunk(lines, new.text, object.type = substring.pattern)
  obj.type.pattern = "Material,"
  obj.name.pattern = "single_family_first_story ext wall 4 wall_consol_layer,"
  new.text <- c("Material,",
                "single_family_first_story ext wall 4 wall_consol_layer," ,
                "Rough,                   !- Roughness" ,
                "0.138209541957025,       !- Thickness {m} replaced here!" ,
                "0.05966275,              !- Conductivity {W/m-K}" ,
                "120.801,                 !- Density {kg/m3}" ,
                "1036.25775,              !- Specific Heat {J/kg-K}" ,
                "0.9,                     !- Thermal Absorptance" ,
                "0.7,                     !- Solar Absorptance" ,
                "0.7;                     !- Visible Absorptance")
  new.lines <- read.idfEnergyPlus::replace.idf.chunk(new.lines, new.text, object.type = obj.type.pattern,
                                                    object.name = obj.name.pattern)
  ## change ceiling thickness
  if (stringr::str_detect(f, "pre-1980")) {
      new.text <- c("Material,",
                    "single_family_first_story ceiling 2 UAAdditionalCeilingIns, !- Name",
                    "Rough,                                  !- Roughness",
                    "0.214606004710193,                      !- Thickness {m}",
                    "0.0406177631578947,                     !- Conductivity {W/m-K}",
                    "16.02,                                  !- Density {kg/m3}",
                    "1046.75,                                !- Specific Heat {J/kg-K}",
                    "0.9,                                    !- Thermal Absorptance",
                    "0.7,                                    !- Solar Absorptance",
                    "0.7;                                    !- Visible Absorptance")
      new.lines <- read.idfEnergyPlus::replace.idf.chunk(new.lines, new.text,
                                                         object.type = "Material,",
                                                         object.name="single_family_first_story ceiling 2 UAAdditionalCeilingIns,")
  }
  writeLines(new.lines, sprintf("scenario_simulation/to_simulate/envelope_%s", f))
}

dirs = list.files("Res (CBES) different climate zones", pattern = "bldg_11_*")

for (dirname in dirs) {
    input.file = sprintf("Res (CBES) different climate zones/%s/model.idf", dirname)
    output.file = sprintf("scenario_simulation/original_climate_zone/%s.idf", dirname)
    file.copy(input.file, output.file)
}

single.family.ceiling.layer.thickness <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="Material,",
                            object.name="single_family_first_story ceiling 2 UAAdditionalCeilingIns,",
                            field.name="Thickness \\{m\\}")
    tibble::tibble(folder = dirname, item = "ceiling 2 UAAdditionalCeilingIns", field = "thickness", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "SingleFamily")

single.family.wall.layer.thickness <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="Material,", object.name="single_family_first_story ext wall 4 wall_consol_layer,",
                            field.name="Thickness \\{m\\}")
    tibble::tibble(folder = dirname, item = "ext wall 4 wall_consol_layer", field = "thickness", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "SingleFamily")

single.family.uvalue <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="WindowMaterial:SimpleGlazingSystem,", object.name="", field.name="U-Factor")
    tibble::tibble(folder = dirname, item = "window", field = "U", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "SingleFamily")

single.family.shgc <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines,
                            object.type="WindowMaterial:SimpleGlazingSystem,",
                            object.name="",
                            field.name="Solar Heat Gain Coefficient")
    tibble::tibble(folder = dirname, item = "window", field = "SHGC", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "SingleFamily")

dirs = list.files("Res (CBES) different climate zones", pattern = "bldg_13_*")

dirs

devtools::load_all("../../../../packages/read.idfEnergyPlus")

multi.family.ceiling.layer.thickness <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="Material,",
                            object.name="multi_family ceiling 2 UAAdditionalCeilingIns,",
                            field.name="Thickness \\{m\\}")
    tibble::tibble(folder = dirname, item = "ceiling 2 UAAdditionalCeilingIns", field = "thickness", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "MultiFamily")

multi.family.wall.layer.thickness <- lapply(dirs, function(dirname) {
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="Material,", object.name="multi_family ext wall 4 wall_consol_layer,", field.name="Thickness \\{m\\}")
    tibble::tibble(folder = dirname, item = "ext wall 4 wall_consol_layer", field = "thickness", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "MultiFamily")

multi.family.uvalue <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, object.type="WindowMaterial:SimpleGlazingSystem,", object.name="", field.name="U-Factor")
    tibble::tibble(folder = dirname, item = "window", field = "U", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "MultiFamily")

multi.family.shgc <- lapply(dirs, function(dirname) {
    print(dirname)
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines,
                            object.type="WindowMaterial:SimpleGlazingSystem,",
                            object.name="",
                            field.name="Solar Heat Gain Coefficient")
    tibble::tibble(folder = dirname, item = "window", field = "SHGC", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "MultiFamily")

envelope.summary <- single.family.wall.layer.thickness %>%
    dplyr::bind_rows(multi.family.wall.layer.thickness) %>%
    dplyr::bind_rows(single.family.ceiling.layer.thickness) %>%
    dplyr::bind_rows(multi.family.ceiling.layer.thickness) %>%
    dplyr::bind_rows(single.family.uvalue) %>%
    dplyr::bind_rows(multi.family.uvalue) %>%
    dplyr::bind_rows(single.family.shgc) %>%
    dplyr::bind_rows(multi.family.shgc) %>%
    {.}

vintage.lookup = tibble::tibble(vin = c(1, 5, 8, 10), vintage = c("pre-1980", 2004, 2013, 2019))

envelope.summary <- envelope.summary %>%
    dplyr::mutate_at(vars(value, vin, cz), as.numeric) %>%
    dplyr::left_join(vintage.lookup, by="vin") %>%
    dplyr::arrange(field, type, vin, cz) %>%
    dplyr::select(field, type, vin, cz, everything()) %>%
    {.}

envelope.summary %>%
    readr::write_csv("envelope_compare_by_vin_cz.csv")

envelope.summary %>%
    dplyr::distinct(item, field, type, vin, value) %>%
    dplyr::arrange(field, type, vin) %>%
    readr::write_csv("envelope_unique_value.csv")

envelope.summary %>%
    dplyr::select(-item) %>%
    tidyr::spread(field, value) %>%
    dplyr::group_by(type, vin, vintage, SHGC, thickness, U) %>%
    dplyr::summarise(cz = paste0(cz, collapse = "|")) %>%
    dplyr::ungroup() %>%
    readr::write_csv("envelope_unique_value_wide.csv")

## get HVAC equipment
multi.family.wall.layer.thickness <- lapply(dirs, function(dirname) {
    lines = readLines(sprintf("Res (CBES) different climate zones/%s/model.idf", dirname))
    value = get.field.value(lines, "Material,", "multi_family ext wall 4 wall_consol_layer,", "Thickness \\{m\\}")
    tibble::tibble(folder = dirname, item = "ext wall 4 wall_consol_layer", field = "thickness", value = value)
}) %>%
    dplyr::bind_rows() %>%
    tidyr::separate(folder, into = c("a", "b", "c", "vin", "e", "cz")) %>%
    dplyr::select(-a, -b, -c, -e) %>%
    dplyr::mutate(type = "MultiFamily")
