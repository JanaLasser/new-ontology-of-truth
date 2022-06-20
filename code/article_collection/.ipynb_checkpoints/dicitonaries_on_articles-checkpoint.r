# Apply Dictionaries on the Articles --------------------------------------

#load libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, data.table, quanteda)

#read_data
fully_scraped <- read_rds("scraped_corpus_raw.rds")

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
  mutate(link_text = str_remove(link_text,"Placeholder while article actions load"))

# read honest components
belief_speaking <- read_csv("dictionaires/belief_speaking_lemmav3.csv")
truth_seeking <- read_csv("dictionaires/truth_seeking_lemmav3.csv")

#define dictionary
dict <- dictionary(list(belief = belief_speaking$belief_speaking,
                        truth = truth_seeking$truth_seeking))

#lemmatize
toks <- tokens(fully_scraped_analysis$link_text)    %>% 
  tokens_tolower() %>% 
  tokens_replace(pattern = lexicon::hash_lemmas$token, 
                 replacement = lexicon::hash_lemmas$lemma)

#apply dict
dfm_news <- dfm(toks)
dfm_news <- dfm_lookup(dfm_news, dict, nomatch = 'other_words')

#convert to data frame and create honesty prop cols
dt_to_model <- convert(dfm_news, to = 'data.frame') %>% 
  mutate(wc = belief+truth+other_words, #create total word count
         belief_prop = belief/wc, 
         truth_prop = truth/wc) %>% 
  bind_cols(fully_scraped_analysis)

#add share by party
dt_to_model_party <- dt_to_model %>% 
  left_join(tweets_with_urls)

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
  anti_join(dt_to_model_party_duplicates)

#write data
data.table::fwrite(dt_to_model_party_no_duplicates, "articles_text_honesty.csv")
