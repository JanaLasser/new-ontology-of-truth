library(dplyr)
library(spacyr)

# import df
df <- read.csv("../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_honesty_component_labels.csv.gzip",
                    encoding = "UTF-8")

View(df)

# assign component label based on N keywords
belief_df <- df %>% 
  filter(belief_count > 0 & belief_count >= truth_count) %>% 
  mutate(component = "belief")

draws <- df %>%
  filter(belief_count > 0 & belief_count == truth_count)

truth_df <- df %>% 
  filter(truth_count > 0 & truth_count >= belief_count) %>% 
  mutate(component = "truth")

neutral_df <- df %>% 
  anti_join(belief_df, by = "id") %>% 
  anti_join(truth_df, by = "id") %>% 
  mutate(component = "other")

# check if sum of component-based dfs == sum of source df + draws
print(nrow(neutral_df) + nrow(belief_df) + nrow(truth_df) == nrow(df) + nrow(draws))

# join component-based (cb) df + draws
cb_df <- rbind(neutral_df, belief_df, truth_df) %>% 
  mutate(row_id = row_number())

View(cb_df)

# lemmatize tweets using spacyr
lemmatized_tweets <- spacy_parse(structure(cb_df$text, names = cb_df$row_id),
                                 lemma = T, pos = F, entity = F, dependency = F) %>% 
  mutate(id = doc_id) %>% 
  group_by(id) %>% 
  summarise(text = paste(lemma, collapse = " "))

lemmatized_tweets$id <- as.numeric(as.character(lemmatized_tweets$id))

lemmatized_df <-  cb_df %>% 
  left_join(lemmatized_tweets, by = c("row_id" = "id"))

# save using readr::write_excel_csv to avoid encoding issues
readr::write_excel_csv2(lemmatized_df, "../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_lemmatized_text.csv.gzip")
