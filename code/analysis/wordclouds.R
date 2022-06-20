#setting libraries
library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(ggwordcloud)
library(slam)
library(tidyverse)


#importing data
lemmatized_dataset <- read.csv("C:\\Users\\so21363\\OneDrive - University of Bristol\\Desktop\\Bristol\\Honesty\\Corpora\\Tweets\\Dataset\\lemmatized_dataset.csv",
                    colClasses = "character", encoding = "UTF-8")
lemmatized_dataset <- read.csv("C:\\Users\\fabio\\Desktop\\Lavoro\\OneDrive - University of Bristol\\Desktop\\Bristol\\Honesty\\Corpora\\Tweets\\Dataset\\lemmatized_dataset.csv",
                               colClasses = "character", encoding = "UTF-8")


#setting stopwords (from English and component dictionary keywords)
marimo <- readLines("C:\\Users\\fabio\\Desktop\\Lavoro\\OneDrive - University of Bristol\\Documents\\marimo.txt")
en_stopwords <- readLines("C:\\Users\\fabio\\Desktop\\Lavoro\\OneDrive - University of Bristol\\Documents\\stopwords_en.txt")
updated_keywords <- read_excel("Lavoro/OneDrive - University of Bristol/Desktop/Bristol/Honesty/Keywords/updated_keywords.xlsx")

b_keyword_list <- as.list(updated_keywords$`belief_speaking`) %>% 
  .[!is.na(.)]
b_keywords <- as.character(b_keyword_list)
t_keyword_list <- as.list(updated_keywords$`truth_seeking`) %>% 
  .[!is.na(.)]
t_keywords <- as.character(t_keyword_list)


# extracting dataframes from main one
belief_df <- lemmatized_dataset %>% 
  filter(component == "belief")
truth_df <- lemmatized_dataset %>% 
  filter(component == "truth")
b_dem_df <- belief_df %>% 
  filter(party == "Democrat")
b_rep_df <- belief_df %>% 
  filter(party == "Republican")
t_dem_df <- truth_df %>% 
  filter(party == "Democrat")
t_rep_df <- truth_df %>% 
  filter(party == "Republican")


# creating quanteda corpora
corpus <- quanteda::corpus(lemmatized_dataset, text_field = "text")
b_corpus <- quanteda::corpus(belief_df, text_field = "text")
t_corpus <- quanteda::corpus(truth_df, text_field = "text")
b_dem_corpus <- quanteda::corpus(b_dem_df, text_field = "text")
t_dem_corpus <- quanteda::corpus(t_dem_df, text_field = "text")
b_rep_corpus <- quanteda::corpus(b_rep_df, text_field = "text")
t_rep_corpus <- quanteda::corpus(t_rep_df, text_field = "text")


#tokenizing corpora
toks <- tokens(corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
               remove_url = T) %>% 
  tokens_remove(., pattern = c(en_stopwords, marimo, b_keywords, t_keywords))

b_toks <- tokens(b_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
               remove_url = T) %>% 
  tokens_remove(., pattern = c(b_keywords, en_stopwords, marimo))

t_toks <- tokens(t_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
                 remove_url = T) %>% 
  tokens_remove(., pattern = c(t_keywords, en_stopwords, marimo))

b_dem_toks <- tokens(b_dem_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
                  remove_url = T) %>% 
  tokens_remove(., pattern = c(b_keywords, en_stopwords, marimo))

t_dem_toks <- tokens(t_dem_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
                     remove_url = T) %>% 
  tokens_remove(., pattern = c(t_keywords, en_stopwords, marimo))

b_rep_toks <- tokens(b_rep_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
                     remove_url = T) %>% 
  tokens_remove(., pattern = c(b_keywords, en_stopwords, marimo))

t_rep_toks <- tokens(t_rep_corpus, remove_punct = T, remove_symbols = T, remove_numbers = T,
                     remove_url = T) %>% 
  tokens_remove(., pattern = c(t_keywords, en_stopwords, marimo))

  
#creating dfm from tokens
dfm <- dfm(toks)
b_dfm <- dfm(b_toks)
t_dfm <- dfm(t_toks)
b_dem_dfm <- dfm(b_dem_toks)
t_dem_dfm <- dfm(t_dem_toks)
b_rep_dfm <- dfm(b_rep_toks)
t_rep_dfm <- dfm(t_rep_toks)


#sorting terms by frequency
tweets_freq <- textstat_frequency(dfm)
b_freq <- textstat_frequency(b_dfm)
t_freq <- textstat_frequency(t_dfm)
b_dem_freq <- textstat_frequency(b_dem_dfm)
t_dem_freq <- textstat_frequency(t_dem_dfm)
b_rep_freq <- textstat_frequency(b_rep_dfm)
t_rep_freq <- textstat_frequency(t_rep_dfm)


#calculating relative frequencies and Difference Coefficient for single words
freq_df <- tweets_freq %>% 
  left_join(b_freq, by = "feature") %>% 
  left_join(t_freq, by = "feature") %>% 
  left_join(b_dem_freq, by = "feature") %>% 
  left_join(t_dem_freq, by = "feature") %>% 
  left_join(b_rep_freq, by = "feature") %>% 
  left_join(t_rep_freq, by = "feature") %>% 
  rename(total_freq = frequency.x,
         b_freq = frequency.y,
         t_freq = frequency.x.x,
         b_dem_freq = frequency.y.y,
         t_dem_freq = frequency.x.x.x,
         b_rep_freq = frequency.y.y.y,
         t_rep_freq = frequency) %>% 
  replace(is.na(.), 0) %>% 
  as.data.frame(.) %>% 
  select(feature, total_freq, b_freq, t_freq, b_dem_freq, t_dem_freq, 
         b_rep_freq, t_rep_freq) %>% 
  mutate(b_rel = b_freq / sum(b_freq) * 100,
         t_rel = t_freq / sum(t_freq) * 100,
         b_dem_rel = b_dem_freq / sum(b_dem_freq) * 100,
         t_dem_rel = t_dem_freq / sum(t_dem_freq) * 100,
         b_rep_rel = b_rep_freq / sum(b_rep_freq) * 100,
         t_rep_rel = t_rep_freq / sum(t_rep_freq) * 100) %>%  
  mutate(b_DC = (b_rel-t_rel)/(b_rel+t_rel),
         t_DC = (t_rel-b_rel)/(t_rel+b_rel),
         b_dem_DC = (b_dem_rel-b_rep_rel)/(b_dem_rel+b_rep_rel),
         t_dem_DC = (t_dem_rel-t_rep_rel)/(t_dem_rel+t_rep_rel))


# Extracting 5 most representative words in first 20 topics per component
belief_cloud <- belief_key_topics %>% 
  inner_join(word_embeddings, by = c("Topic" = "topic_ids")) %>%
  select(Topic, Name, topic_words, topic_embeddings) %>% 
  inner_join(freq_df, by = c("topic_words" = "feature")) %>% 
  distinct(topic_words, .keep_all = T) %>% 
  group_by(Topic) %>% 
  filter(row_number() <= 5) %>% 
  arrange(desc(b_freq))
  

# creating wordcloud and scaling range to harmonize word size
belief_wordcloud <- ggplot(belief_cloud, 
                           aes(label = topic_words, size = b_freq, color = b_dem_DC)) +
  geom_text_wordcloud_area() +
  scale_radius(range = c(5, 50), limits = c(0, NA)) +
  #scale_size_area(max_size = 25) +
  theme_minimal() +
  scale_color_gradient2(low = "#FF0000", mid = "darkgray", high = "#0015BC")
