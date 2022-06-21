# author: Fabio Carrella & Almog Simchon

#setting libraries and functions
library(quanteda)
library(quanteda.textstats)
library(slam)
library(tidyverse)
library(scales)
library(ggplot2)
library(ggrepel)
library(psych)
library(plotly)

create_freq_table <- function(dataframe, stopwords) {
  # create corpus from df
  corpus <- corpus(dataframe, text_field = "text")
  
  # tokenize corpus
  toks <- tokens(corpus, remove_punct = T, remove_symbols = T, 
                 remove_numbers = T, remove_url = T)
  
  # check if stopwords argument is provided
  if(!missing(stopwords)) {
    toks <- tokens_remove(toks, pattern = stopwords)
  }
  
  # create dfm
  dfm <- dfm(toks)
  
  # return frequency table
  frequency_table <- textstat_frequency(dfm)
  return(frequency_table)
}


# importing data
lemmatized_dataset <- read.csv("../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_lemmatized_text.csv.gzip", colClasses = "character", encoding = "UTF-8")                          

# setting stopwords (from English and component dictionary keywords)
marimo <- readLines("../../data/utilities/marimo.txt")
en_stopwords <- readLines("../../data/utilities/stopwords_en.txt")
updated_keywords <- readxl::read_excel("../../data/utilities/updated_keywords.xlsx")

b_keyword_list <- as.list(updated_keywords$`belief_speaking`) %>% 
  .[!is.na(.)]
b_keywords <- as.character(b_keyword_list)
t_keyword_list <- as.list(updated_keywords$`truth_seeking`) %>% 
  .[!is.na(.)]
t_keywords <- as.character(t_keyword_list)


# extracting dataframes from main one
lemmatized_dataset <- lemmatized_dataset %>% 
  filter(component != "other")
belief_df <- lemmatized_dataset %>% 
  filter(component == "belief")
truth_df <- lemmatized_dataset %>% 
  filter(component == "truth")
dem_df <- lemmatized_dataset %>% 
  filter(party == "Democrat")
rep_df <- lemmatized_dataset %>% 
  filter(party == "Republican")

# creating frequency tables
tweets_freq <- create_freq_table(lemmatized_dataset, 
                                 c(marimo, en_stopwords, b_keywords, t_keywords))

b_freq <- create_freq_table(belief_df, 
                            c(marimo, en_stopwords, b_keywords, t_keywords))

t_freq <- create_freq_table(truth_df, 
                            c(marimo, en_stopwords, b_keywords, t_keywords))

dem_freq <- create_freq_table(dem_df, 
                              c(marimo, en_stopwords, b_keywords, t_keywords))

rep_freq <- create_freq_table(rep_df, 
                              c(marimo, en_stopwords, b_keywords, t_keywords))

# calculating precision and recall values
st_df <- tweets_freq %>% 
  left_join(b_freq, by = "feature") %>% 
  left_join(t_freq, by = "feature") %>% 
  left_join(dem_freq, by = "feature" ) %>% 
  left_join(rep_freq, by = "feature" ) %>% 
  rename(total_freq = frequency.x,
         b_freq = frequency.y,
         t_freq = frequency.x.x,
         dem_freq = frequency.y.y,
         rep_freq = frequency) %>% 
  replace(is.na(.), 0) %>% 
  as.data.frame(.) %>% 
  select(feature, total_freq, b_freq, t_freq, dem_freq, rep_freq) %>% 
  filter(total_freq > 200) %>% 
  mutate(b_precision = b_freq / (b_freq + t_freq),
         b_freq_pct = b_freq / sum(b_freq),
         t_precision = t_freq / (t_freq + b_freq),
         t_freq_pct = t_freq / sum(t_freq),
         dem_precision = dem_freq / (dem_freq + rep_freq),
         dem_freq_pct = dem_freq / sum(dem_freq),
         rep_precision = rep_freq / (rep_freq + dem_freq),
         rep_freq_pct = rep_freq / sum(rep_freq))

# calculating CDF for precision and recall
st_df <- st_df %>% 
  mutate(b_precision_cdf = pnorm(b_precision, mean(b_precision), sd(b_precision)),
         b_freq_pct_cdf = pnorm(b_freq_pct, mean(b_freq_pct), sd(b_freq_pct)),
         t_precision_cdf = pnorm(t_precision, mean(t_precision), sd(t_precision)),
         t_freq_pct_cdf = pnorm(t_freq_pct, mean(t_freq_pct), sd(t_freq_pct)),
         dem_precision_cdf = pnorm(dem_precision, mean(dem_precision), sd(dem_precision)),
         dem_freq_pct_cdf = pnorm(dem_freq_pct, mean(dem_freq_pct), sd(dem_freq_pct)),
         rep_precision_cdf = pnorm(rep_precision, mean(rep_precision), sd(rep_precision)),
         rep_freq_pct_cdf = pnorm(rep_freq_pct, mean(rep_freq_pct), sd(rep_freq_pct)))

# extracting scaled F-score (harmonic mean of CDFs)
st_df <- st_df %>% 
  rowwise() %>% 
  mutate(b_scaled_fscore = harmonic.mean(c(b_precision_cdf, b_freq_pct_cdf)),
         t_scaled_fscore = harmonic.mean(c(t_precision_cdf, t_freq_pct_cdf)),
         dem_scaled_fscore = harmonic.mean(c(dem_precision_cdf, dem_freq_pct_cdf)),
         rep_scaled_fscore = harmonic.mean(c(rep_precision_cdf, rep_freq_pct_cdf))) %>% 
  ungroup()

# computing scaled F-score of negative scoring terms
st_df <- st_df %>% 
  mutate(comp_scaled_f_score = ifelse(b_scaled_fscore > t_scaled_fscore, 
                                 b_scaled_fscore, 1-t_scaled_fscore)) %>% 
  mutate(comp_scaled_f_score = 2 * (comp_scaled_f_score - 0.5)) %>% 
  mutate(party_scaled_f_score = ifelse(dem_scaled_fscore > rep_scaled_fscore,
                                       dem_scaled_fscore, 1-rep_scaled_fscore)) %>% 
  mutate(party_scaled_f_score = 2 * (party_scaled_f_score - 0.5))

# plotting results
st_df_filtered <- st_df %>% 
  mutate(keyword = ifelse(comp_scaled_f_score > 0.65 | comp_scaled_f_score < -0.65 |
                            party_scaled_f_score > 0.65 | party_scaled_f_score < -0.65,
                          feature, ""))



st_plot <- ggplot(st_df_filtered, aes(party_scaled_f_score, comp_scaled_f_score,
                  color = party_scaled_f_score, group = 1, label = keyword,
                  text = paste("Word: ", feature,
                               "<br>Party_SFS: ", party_scaled_f_score,
                               "<br>Component_SFS: ", comp_scaled_f_score))) +
  geom_text_repel(nudge_y = 0.02) +
  geom_point() +
  scale_color_gradient2(low = "#FF0000", mid = "darkgray", high = "#0015BC") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.title.x = element_text(hjust = 1),
        axis.title.y = element_text(hjust = 1)) +
  labs(x = "More Democratic", y = "More Belief-speaking")

pdf("../../plots/fig1a.pdf")
print(st_plot)
st_plot

ggplotly(st_plot, tooltip = "text")
