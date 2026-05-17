library(readxl)

folder_path <- "C:/Users/M320532/Desktop/Research/MDH Lab/postpartum-glp1/Perinatal Outcomes_files/Datasets"

smoking <- read_excel(file.path(folder_path, "smoking.xlsx"))

str(smoking)
head(smoking)

unique(smoking$tob_value)

## alcohol datasets

alcohol_flowsheet <- read_excel(file.path(folder_path, "alcohol_flowsheet.xlsx"))
alcohol_ppi <- read_excel(file.path(folder_path, "alcohol_ppi.xlsx"))
alcohol_sdoh <- read_excel(file.path(folder_path, "alcohol_sdoh.xlsx"))
alcohol_social_history <- read_excel(file.path(folder_path, "alcohol_social_history.xlsx"))

str(alcohol_flowsheet)
str(alcohol_ppi)
str(alcohol_sdoh)
str(alcohol_social_history)

unique(alcohol_ppi$Ans_Text)

unique(alcohol_social_history$Social_Hx_Name)
unique(alcohol_social_history$Social_Hx_Answer)
table(alcohol_social_history$Social_Hx_Name, alcohol_social_history$Social_Hx_Answer)

### EKG and Echo datasets
ecg <- read_excel(file.path(folder_path, "ecg.xlsx"))

str(ecg)
head(ecg)

echo_ef <- read_excel(file.path(folder_path, "echo_ef_data.xlsx"))

str(echo_ef)
head(echo_ef)

echo_dict <- read_excel(file.path(folder_path, "echo_data_dictionary.xlsx"))

str(echo_dict)
head(echo_dict)

datasets <- list(
  smoking = smoking,
  alcohol_flowsheet = alcohol_flowsheet,
  alcohol_ppi = alcohol_ppi,
  alcohol_sdoh = alcohol_sdoh,
  alcohol_social_history = alcohol_social_history,
  ecg = ecg,
  echo_ef = echo_ef
)

lapply(datasets, dim)
lapply(datasets, names)

quick_overview <- function(df) {
  list(
    dims = dim(df),
    cols = names(df),
    sample = head(df, 3)
  )
}

quick_overview(smoking)
quick_overview(ecg)
quick_overview(echo_ef)


