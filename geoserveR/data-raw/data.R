library(sf)
library(readr)
library(dplyr)
library(rmapshaper)

# population data --------------------------------------------------------------
x <-
  read_csv(
    file = "data-raw/TABLECODE7979_Data_8243d362-2d6a-4673-874e-850235d63cd1.csv"
  ) %>%
  select(-AGE, -SEX, -Flags) %>%
  mutate(geography = ifelse (nchar(AREA) == 2, "regc2018", "sa22018")) %>%
  rename(code = AREA) %>%
  setNames(tolower(colnames(.))) %>%
  select(geography, code, year, value)

y <-
  read_csv(
    file = "data-raw/TABLECODE7980_Data_3ed576cb-a733-4e06-80ef-5bc8264d8d27.csv"
  ) %>%
  select(-AGE, -SEX, -Flags) %>%
  filter(nchar(AREA) == 3) %>%
  mutate(geography = "ta2018") %>%
  rename(code = AREA) %>%
  setNames(tolower(colnames(.))) %>%
  select(geography, code, year, value)

popdata <- rbind(x, y) %>%
  arrange(geography, code, year)


# spatial data -----------------------------------------------------------------
regc2018 <- st_read("data-raw/regc2018.gpkg",
                    stringsAsFactors = FALSE) %>%
  setNames(tolower(colnames(.))) %>%
  filter(regc2018_v1_00 != "99") %>%
  rename(code = regc2018_v1_00, label = regc2018_v1_00_name) %>%
  select(code, label) %>%
  rmapshaper::ms_simplify(keep_shapes = TRUE)

ta2018 <- st_read("data-raw/ta2018.gpkg",
                  stringsAsFactors = FALSE) %>%
  setNames(tolower(colnames(.))) %>%
  filter(ta2018_v1_00 != "067") %>%
  rename(code = ta2018_v1_00, label = ta2018_v1_00_name) %>%
  select(code, label) %>%
  rmapshaper::ms_simplify(keep_shapes = TRUE)

sa22018 <- st_read("data-raw/sa22018.gpkg",
                   stringsAsFactors = FALSE) %>%
  setNames(tolower(colnames(.))) %>%
  filter(sa22018_v1_00 != "343000") %>%
  rename(code = sa22018_v1_00, label = sa22018_v1_00_name) %>%
  select(code, label) %>%
  rmapshaper::ms_simplify(keep_shapes = TRUE)

sa12018 <- st_read("data-raw/sa12018.gpkg",
                   stringsAsFactors = FALSE) %>%
  setNames(tolower(colnames(.))) %>%
  filter(!sa12018_v1_00 %in%
           c("7027634", "7027635", "7027637", "7027639", "7027636", "7027640")) %>%
  rename(code = sa12018_v1_00) %>%
  select(code) %>%
  rmapshaper::ms_simplify(keep_shapes = TRUE)

mb2018 <- st_read("data-raw/mb2018.gpkg",
                  stringsAsFactors = FALSE) %>%
  setNames(tolower(colnames(.))) %>%
  filter(!mb2018_v1_00 %in%
           c("2716700", "2716601", "2716603", "2717500",
             "2716801", "2716802", "2717100", "2717200",
             "2717300", "2717000", "2717400")) %>%
  rename(code = mb2018_v1_00) %>%
  select(code) %>%
  ms_simplify(keep_shapes = TRUE)


# save data --------------------------------------------------------------------

usethis::use_data(
  popdata, regc2018, ta2018, sa22018, sa12018, mb2018, overwrite = TRUE
)
