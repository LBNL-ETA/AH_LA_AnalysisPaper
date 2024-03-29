library("dplyr")

setwd("AH.Analysis/data-raw")

## update design day
devtools::load_all("../../../../packages/read.idfEnergyPlus")

pathname = "scenario_simulation/idf_version_update"

files = list.files(pathname, pattern = "*.idf")

files = files[which(!stringr::str_detect(files, "HeatPump_"))]
files = files[which(!stringr::str_detect(files, "Lighting70_"))]
files = files[which(!stringr::str_detect(files, "CoolingCoilCOP_"))]
files = files[which(!stringr::str_detect(files, "infiltration_"))]
files = files[which(!stringr::str_detect(files, "envelope_"))]

files

apply.fun.to.files(files, pathname, "Lights,", get.object.names) %>%
    ## dplyr::arrange(filename) %>%
    dplyr::filter(stringr::str_detect(filename, "Single")) %>%
    {.}

non.2019.files <- files[which(!stringr::str_detect(files, "-2019_"))]

non.2019.files 

## --------------------------------------------------------------------
## replace lighting with 30% lower density
## --------------------------------------------------------------------
for (f in non.2019.files) {
    file.full.path = sprintf("%s/%s", pathname, f)
    lines <- readLines(file.full.path)
    new.lines <- replace.field.value(lines, object.type = "Lights,",
                                     object.name="family_living lights,",
                                     field.name="Watts per Zone Floor Area ",
                                     function(x) {as.numeric(x) * 0.7})
    writeLines(new.lines, sprintf("%s/Lighting70_%s", pathname, f))
}


## replace lower cooling coil with lower COP

devtools::load_all("../../../../packages/read.idfEnergyPlus")
apply.fun.to.files(files, pathname, get.object.names,
                   object.type="Coil:Cooling:DX:SingleSpeed,") %>%
    dplyr::arrange(filename) %>%
    readr::write_csv("names_cooling_coil.csv")

apply.fun.to.files(files, pathname, get.field.value,
                   field.name="Gross Rated Cooling COP ",
                   object.type="Coil:Cooling:DX:SingleSpeed,") %>%
    dplyr::arrange(filename) %>%
    readr::write_csv("current_COP.csv")

## --------------------------------------------------------------------
## replace cooling coil COP to Title24 2019 level
## --------------------------------------------------------------------
for (f in non.2019.files) {
    print(f)
    file.full.path = sprintf("%s/%s", pathname, f)
    lines <- readLines(file.full.path)
    new.lines <- replace.field.value(lines, object.type = "Coil:Cooling:DX:SingleSpeed,",
                                     object.name="",
                                     field.name="Gross Rated Cooling COP ",
                                     function(x) {return("    3.1525439623356")})
    writeLines(new.lines, sprintf("%s/CoolingCoilCOP_%s", pathname, f))
}

## --------------------------------------------------------------------
## replace envelope
## --------------------------------------------------------------------

for (f in non.2019.files) {
    print(f)
    file.full.path = sprintf("%s/%s", pathname, f)
    lines <- readLines(file.full.path)
    if (stringr::str_detect(f, "cz_6")) {
        wall.thickness = "    0.138209541957025"
    } else {
        wall.thickness = "    0.195463063813731"
    }
    print(wall.thickness)
    # wall
    lines <- replace.field.value(lines,
                                 object.type = "Material,",
                                 object.name="ext wall 4 wall_consol_layer",
                                 field.name="Thickness ",
                                 function(x) {return(wall.thickness)})
    # window
    lines <- replace.field.value(lines,
                                 object.type = "WindowMaterial:SimpleGlazingSystem,",
                                 object.name="",
                                 field.name="U-Factor ",
                                 function(x) {return("    1.7034")})
    lines <- replace.field.value(lines,
                                 object.type = "WindowMaterial:SimpleGlazingSystem,",
                                 object.name="",
                                 field.name="Solar Heat Gain Coefficient",
                                 function(x) {return("    0.23")})
    lines <- replace.field.value(lines,
                                 object.type = "WindowMaterial:SimpleGlazingSystem,",
                                 object.name="",
                                 field.name="Solar Heat Gain Coefficient",
                                 function(x) {return("    0.23")})
    ## roof
    if (stringr::str_detect(f, "pre-1980")) {
        if (stringr::str_detect(f, "cz_14") || stringr::str_detect(f, "cz_16")) {
            ceiling.thickness = "    0.27183427262208"
        } else {
            ceiling.thickness = "    0.214606004710193"
        }
        lines <- replace.field.value(lines, object.type = "Material,",
                                      object.name=" ceiling 2 UAAdditionalCeilingIns,",
                                      field.name="Thickness ",
                                      function(x) {return(ceiling.thickness)})
    }
    writeLines(lines, sprintf("%s/envelope_%s", pathname, f))
}

## --------------------------------------------------------------------
## replace infiltration
## --------------------------------------------------------------------

for (f in non.2019.files) {
    print(f)
    file.full.path = sprintf("%s/%s", pathname, f)
    lines <- readLines(file.full.path)
    if (stringr::str_detect(f, "SingleFamily")) {
        new.lines <- replace.field.value(lines, object.type = "ZoneInfiltration:DesignFlowRate,",
                                         object.name="single_family_living infiltration",
                                         field.name="Air Changes per Hour",
                                         function(x) {return("    0.853361")})
    } else { # multi-family
        new.lines <- replace.field.value(lines, object.type = "ZoneInfiltration:DesignFlowRate,",
                                         object.name="multi_family_living infiltration",
                                         field.name="Air Changes per Hour",
                                         function(x) {return("    1.194706")})
    }
    writeLines(new.lines, sprintf("%s/infiltration_%s", pathname, f))
}
