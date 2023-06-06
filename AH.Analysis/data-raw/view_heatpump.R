## used to debug heat pump model output
library("dplyr")

setwd("AH.Analysis/data-raw")

filepath = "scenario_simulation/testrun_cz_6"

dirs = list.dirs(filepath)


devtools::load_all("~/Dropbox/workLBNL/packages/AHhelper")

type.prefix = "Multi"
vintage = "pre-1980"
multi.heatpump.dirs = dirs[which(stringr::str_detect(dirs, sprintf("HeatPump_%s", type.prefix)))]
multi.baseline.dirs = dirs[which(stringr::str_detect(dirs, sprintf("/%s", type.prefix)))]
dirname.baseline = multi.baseline.dirs[which(stringr::str_detect(multi.baseline.dirs, vintage))]
dirname.heatpump = multi.heatpump.dirs[which(stringr::str_detect(multi.heatpump.dirs, vintage))]
df.baseline = AHhelper::read.eplusout(dirname.baseline, "eplusout.csv") %>%
    AHhelper::convert.timestamp(year = 2018)
df.heatpump = AHhelper::read.eplusout(dirname.heatpump, "eplusout.csv") %>%
    AHhelper::convert.timestamp(year = 2018)
col = "energy.overall"
baseline = xts::xts(df.baseline[[col]], order.by=df.baseline$`Date/Time`)
heatpump = xts::xts(df.heatpump[[col]], order.by=df.heatpump$`Date/Time`)
dygraphs::dygraph(cbind(baseline, heatpump),
                  main=sprintf("%sFamily %s comparison vintage %s", type.prefix,
                               col, vintage)) %>%
    dygraphs::dyRangeSelector() %>%
    dygraphs::dyOptions(useDataTimezone = TRUE)
