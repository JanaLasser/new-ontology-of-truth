# import libraries and data
library(verification)
library(tidyverse)
library(caret)

Document_Level_Honesty_Validation <- read_csv("../../data/validation/document_validation_data.csv")

document_validation_sample <- read_csv("../../data/validation/document_validation_sample.csv")

attention_check_df <- Document_Level_Honesty_Validation %>% 
  filter(`Q5.1#1_30` == 5 & `Q5.1#2_30` == 5)


# make table long-format, classify rating by type and filter attention check
df_long <- attention_check_df %>% 
  dplyr::select(ResponseId, 22:143) %>% 
  pivot_longer(!ResponseId, names_to = "doc", values_to = "rate") %>% 
  mutate(rate_type = case_when(
    str_detect(doc, "#1") ~ "belief",
    str_detect(doc,"#2") ~ "truth"
  ),
  id = as.numeric(gsub("^.{0,7}", "", doc))) %>% 
  filter(id != 30) %>% 
  mutate(id = ifelse(id > 30, id - 1, id))


# make data wide and count components rates > 3
df_wide <- df_long %>% 
  pivot_wider(names_from = rate_type, values_from = rate) %>% 
  group_by(ResponseId, id) %>% 
  summarise(belief = sum(belief, na.rm = T),
            truth = sum(truth, na.rm = T))

belief_count <-  df_wide %>% 
  filter(belief + truth != 0) %>% 
  mutate(is_belief = ifelse(belief %in% c(4,5), 1, 0)) %>% 
  group_by(id) %>% 
  count(is_belief) %>% 
  pivot_wider(names_from = is_belief, names_prefix = "belief_", values_from = n) %>% 
  mutate(is_belief = ifelse(belief_1 > belief_0, 1, 0))

truth_count <-  df_wide %>% 
  filter(belief + truth != 0) %>% 
  mutate(is_truth = ifelse(truth %in% c(4,5), 1, 0)) %>% 
  group_by(id) %>% 
  count(is_truth) %>% 
  pivot_wider(names_from = is_truth, names_prefix = "truth_", values_from = n) %>% 
  mutate(is_truth = ifelse(truth_1 > truth_0, 1, 0))

df_count <- belief_count %>% 
  inner_join(truth_count, by = "id") %>% 
  mutate(survey_cat_count = case_when(
    is_belief == 1 ~ "high_belief",
    is_truth == 1 ~ "high_truth",
    TRUE ~ "low_honesty"
  )) %>% 
  dplyr::select(id, survey_cat_count) 


# edit tweet sample categories
tweet_sample <- document_validation_sample %>% 
  mutate(category = case_when(
    str_detect(category, "high_belief") ~ "high_belief",
    str_detect(category, "high_truth") ~ "high_truth",
    TRUE ~ "low_honesty"
  ))


# join tweets with count values
sample_t_test <- tweet_sample %>% 
  mutate(n_row = row_number()) %>%
  left_join(df_count, by = c("n_row" = "id")) %>% 
  dplyr::select(-n_row)

library(caret)

# confusion matrix
confusionMatrix(data = as.factor(sample_t_test$category),
                reference = as.factor(sample_t_test$survey_cat_count))

#ROC curves
belief_roc <- sample_t_test %>% 
  mutate(survey_roc_count = ifelse(survey_cat_count != "high_belief", 0, 1),
         belief_ddr = scales::rescale(avg_belief_score, to = c(0,1)))

truth_roc <- sample_t_test %>% 
  mutate(survey_roc_count = ifelse(survey_cat_count != "high_truth", 0, 1),
         truth_ddr = scales::rescale(avg_truth_score, to = c(0,1)))

roc.plot(belief_roc$survey_roc_count, belief_roc$belief_ddr, 
         main = "Belief-speaking ROC Curve", plot = "both", binormal = T, CI = T)
roc.plot(truth_roc$survey_roc_count, truth_roc$truth_ddr,
         main = "Truth-seeking ROC Curve", plot = "both", binormal = T, CI = T)

roc.area(belief_roc$survey_roc_count, belief_roc$belief_ddr)
roc.area(truth_roc$survey_roc_count, truth_roc$truth_ddr)


# plot histograms
ggplot(sample_t_test) +
  aes(x = survey_cat_count, fill = survey_cat_count) +
  geom_bar() +
  facet_wrap(vars(category)) +
  scale_fill_manual(
    values = c(high_belief = "#FF6E40",
               high_truth = "#FFC13B"))


# plot boxplots
boxplot_df <- tweet_sample %>% 
  mutate(doc_id = row_number()) %>% 
  right_join(df_long, by = c("doc_id" = "id"), multiple = "all")
  
boxplot_df %>%
  filter(category %in% "high_belief") %>%
  ggplot() +
  aes(x = "", y = rate, fill = rate_type, group = rate_type) +
  geom_boxplot() +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(doc_id)) +
  labs(fill = "Rate Type", title = "High Belief-speaking Tweets") +
  xlab("Doc ID") +
  ylab("Rate Distributions")

boxplot_df %>%
  filter(category %in% "high_truth") %>%
  ggplot() +
  aes(x = "", y = rate, fill = rate_type, group = rate_type) +
  geom_boxplot() +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(doc_id)) +
  labs(fill = "Rate Type", title = "High Truth-seeking Tweets") +
  xlab("Doc ID") +
  ylab("Rate Distributions")

boxplot_df %>%
  filter(category %in% "low_honesty") %>%
  ggplot() +
  aes(x = "", y = rate, fill = rate_type, group = rate_type) +
  geom_boxplot() +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(doc_id)) +
  labs(fill = "Rate Type", title = "Low Honesty Tweets") +
  xlab("Doc ID") +
  ylab("Rate Distributions")
