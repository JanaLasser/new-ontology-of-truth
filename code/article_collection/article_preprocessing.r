# Pre-process Articles --------------------------------------

#load libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, data.table, stringi)

#read_data
fully_scraped <- read_rds("../../data/articles/article_corpus_raw.rds.gz")
party_information <- read_csv("../../data/articles/url_list_for_article_scraping.csv.gzip")

#remove missing content
fully_scraped_analysis <- fully_scraped %>% 
  mutate(remove = case_when(
    is.na(link_text) ~ "remove",
    link_text=="" ~ "remove",
    str_detect(link_text, "unfortunately our website is currently unavailable in most European countries due to GDPR rules") ~ "remove",
    str_detect(link_text, "We recognize you are attempting to access this website from a country belonging to the European Economic Area") ~ "remove",
    TRUE ~ "keep"
  )) %>% 
  filter(remove=="keep") %>% 
  mutate(link_text = str_remove(link_text,"Placeholder while article actions load"),
         wc = stringi::stri_count_words(link_text)) 


#add share by party
dt_to_model_party <- fully_scraped_analysis %>% 
  left_join(select(party_information, url, party), by = c("url"))

#check what articles were shared by both Reps and Dems
dt_to_model_party_duplicates <- dt_to_model_party %>% 
  filter(party %in% c("Democrat" ,"Republican"),
         wc>=100) %>% 
  group_by(url, party) %>% 
  summarise(n = n()) %>% 
  ungroup() %>% 
  group_by(url) %>% 
  summarise(n = n()) %>% 
  filter(n>1)

#remove articles that were shared by both Dems and Reps
dt_to_model_party_no_duplicates <- dt_to_model_party %>% 
  filter(party %in% c("Democrat" ,"Republican"),
         wc>=100) %>% #keep only articles with more than 100 words
  mutate(fishy = ifelse(Score<60, "fishy", "non_fishy")) %>% 
  anti_join(dt_to_model_party_duplicates) %>% 
  distinct()



#write data
data.table::fwrite(dt_to_model_party_no_duplicates, "../../data/articles/article_corpus_clean.csv.gz")
