# author: Fabio Carrella

# set packages and functions
library(krippendorffsalpha)
library(dplyr)

extract_alpha_from_df <- function(df) { 
  df <- df %>% 
    mutate(Annotator_A = ifelse(Annotator_A == "No", 0, 1),
           Annotator_B = ifelse(Annotator_B == "No", 0, 1)) %>% 
    select(-Texts)
  
  df_fit <- krippendorffs.alpha(as.matrix(df), level = "interval", 
                                confint = T, verbose = T, 
                                control = list(parallel = F, bootit = 1000))
  
  return(summary(df_fit))
}

#import dataframes
belief_annotations <- readxl::read_xlsx("../../data/tweets/belief_annotations.xlsx")
truth_annotations <- readxl::read_xlsx("../../data/tweets/truth_annotations.xlsx")
foster_annotations <- readxl::read_xlsx("../../data/tweets/foster_annotations.xlsx")

# calculate Krippendorff's Alpha from dataframes
extract_alpha_from_df(belief_annotations)
extract_alpha_from_df(truth_annotations)
extract_alpha_from_df(foster_annotations)
