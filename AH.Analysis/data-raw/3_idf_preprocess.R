## Modify design day info
library("dplyr")

setwd("AH.Analysis/data-raw")

## update design day
devtools::load_all("../../../../packages/read.idfEnergyPlus")

vintage.labels = c("pre-1980", "2004", "2013", "2019")
names(vintage.labels) = c("1", "5", "8", "10")

pathname = "scenario_simulation/idf_to_modify"

prefixes = c("bldg_11_*", "bldg_13_*")
names(prefixes) = c("SingleFamily", "MultiFamily")

## copy single and multi-family
for (building.type in c("SingleFamily", "MultiFamily")) {
    prefix = prefixes[[building.type]]
    dirs = list.files("Res (CBES) different climate zones", pattern = prefix)
    for (dirname in dirs) {
        input.file = sprintf("Res (CBES) different climate zones/%s/model.idf", dirname)
        tokens = unlist(stringr::str_split(dirname, "_"))
        vintage.label = vintage.labels[[tokens[[4]]]]
        climate.zone.label = tokens[[6]]
        output.file = sprintf("scenario_simulation/idf_to_modify/%s-%s_cz_%s.idf", building.type, vintage.label, climate.zone.label)
        file.copy(input.file, output.file)
    }
}

## copy ones with heatpump for climate zone 6
input.dir = "scenario_simulation/Heat pump"
for (building.type in c("SingleFamily", "MultiFamily")) {
    prefix = prefixes[[building.type]]
    dirs = list.files(input.dir, pattern = prefix)
    for (dirname in dirs) {
        input.file = sprintf("%s/%s/model.idf", input.dir, dirname)
        tokens = unlist(stringr::str_split(dirname, "_"))
        vintage.label = vintage.labels[[tokens[[4]]]]
        climate.zone.label = tokens[[6]]
        output.file = sprintf("scenario_simulation/idf_to_modify/HeatPump_%s-%s_cz_%s.idf",
                              building.type, vintage.label, climate.zone.label)
        file.copy(input.file, output.file)
    }
}

input.dir = "scenario_simulation/"

files = list.files("scenario_simulation/idf_to_modify", pattern = "*.idf")

files

## only modify heatpump here
files <- files[which(stringr::str_detect(files, "HeatPump"))]

## check number of design days
num.design.day <- apply.fun.to.files(files, pathname, get.object.count.by.type, object.type="SizingPeriod:DesignDay")

more.than.two.design.day <- num.design.day %>%
    filter(value > 2) %>%
    .$filename

## find names of design day objects
names.design.day <- apply.fun.to.files(files, pathname, get.object.names, object.type="SizingPeriod:DesignDay")

names.design.day %>%
    dplyr::group_by(filename) %>%
    dplyr::filter(n() > 2) %>%
    dplyr::ungroup() %>%
    print(n=Inf)

names.design.day %>%
    dplyr::group_by(filename) %>%
    dplyr::filter(n() == 2) %>%
    dplyr::ungroup() %>%
    print(n=Inf)

la.design.day <- readLines("scenario_simulation/la_design_day/USA_CA_Los.Angeles.Intl.AP.722950_TMY3.ddy")
location.data <- la.design.day[6:11]

for (f in more.than.two.design.day) {
    print("##############################")
    print(f)
    print("##############################")
    file.full.path = sprintf("scenario_simulation/idf_to_modify/%s", f)
    lines <- readLines(file.full.path)
    ## remove monthly design days
    new.text = c("")
    obj.names = c(sprintf(" %s Clg 0{0,1}.4%% Condns", c("AUG", "JUL", "JUN", "SEP", "OCT", "NOV")))
    for (obj.name in obj.names) {
        print(sprintf("-----%s------", obj.name))
        lines <- read.idfEnergyPlus::replace.idf.chunk(lines, new.text="", object.type = "SizingPeriod:DesignDay,",
                                                      object.name=obj.name, verbose=TRUE)
    }
    ## replace Site:Location
    lines <- read.idfEnergyPlus::replace.idf.chunk(lines, new.text=location.data, object.type = "Site:Location,",
                                                  object.name="", verbose=TRUE)
    ## replace design day
    lines <- replace.design.day(lines, ddy.lines=la.design.day, design.day.kw="Ann Htg 99.6% Condns", verbose=TRUE)
    lines <- replace.design.day(lines, ddy.lines=la.design.day, design.day.kw="Ann Clg 0{0,1}.4% Condns", verbose=TRUE)
    writeLines(lines, sprintf("scenario_simulation/idf_change_design_day/%s", f))
}

only.two.design.days = setdiff(files, more.than.two.design.day)

for (f in only.two.design.days) {
    print("##############################")
    print(f)
    print("##############################")
    file.full.path = sprintf("scenario_simulation/idf_to_modify/%s", f)
    lines <- readLines(file.full.path)
    lines <- read.idfEnergyPlus::replace.idf.chunk(lines,
                                                   new.text=location.data,
                                                   object.type = "Site:Location,",
                                                   object.name="", verbose=TRUE)
    ## replace design day
    lines <- replace.design.day(lines, ddy.lines=la.design.day, design.day.kw="Ann Htg 99.6% Condns", verbose=TRUE)
    lines <- replace.design.day(lines, ddy.lines=la.design.day, design.day.kw="Ann Clg 0{0,1}.4% Condns", verbose=TRUE)
    writeLines(lines, sprintf("scenario_simulation/idf_change_design_day/%s", f))
}
