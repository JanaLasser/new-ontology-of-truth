# import libraries and data
library(tidyverse)
library(broom)
library(verification)
library(pROC)

Document_Level_Honesty_Validation <- read_csv("../../data/tweets/document_validation_data.csv")

document_validation_sample <- read_csv("../../data/tweets/document_validation_sample.csv")

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
  


# make data wide
df_wide <- df_long %>% 
  pivot_wider(names_from = rate_type, values_from = rate) %>% 
  group_by(ResponseId, id) %>% 
  summarise(belief = sum(belief, na.rm = T),
            truth = sum(truth, na.rm = T))


# calculate t values
df_t_test <- df_wide %>% 
  filter(belief + truth != 0) %>% 
  group_by(id) %>% 
  summarise(t = t.test(belief, truth, paired=T)$statistic,
            pval = t.test(belief, truth, paired=T)$p.value,
            belief_survey_avg = mean(belief),
            truth_survey_avg = mean(truth)) %>% 
  mutate(across(c(4:5), ~scales::rescale(.x, to = c(0,1))))


# edit tweet sample categories
tweet_sample <- document_validation_sample %>% 
  mutate(category = case_when(
    str_detect(category, "high_belief") ~ "high_belief",
    str_detect(category, "high_truth") ~ "high_truth",
    TRUE ~ "low_honesty"
  ))


# join tweets with t test values
sample_t_test <- tweet_sample %>% 
  mutate(n_row = row_number()) %>% 
  left_join(df_t_test, by = c("n_row" = "id")) %>% 
  dplyr::select(-n_row) %>% 
  mutate(survey_cat = case_when(
    pval < 0.05 & t > 0 ~ "high_belief",
    pval < 0.05 & t < 0 ~ "high_truth",
    TRUE ~ "low_honesty"
  ))


# plot histograms
ggplot(sample_t_test) +
  aes(x = survey_cat, fill = survey_cat) +
  geom_bar() +
  scale_fill_hue(direction = 1) +
  facet_wrap(vars(category)) +
  scale_fill_manual(
    values = c(high_belief = "#FF6E40",
               high_truth = "#FFC13B"))


# plot boxplots
boxplot_df <- tweet_sample %>% 
  mutate(doc_id = row_number()) %>% 
  right_join(df_long, by = c("doc_id" = "id"))
  
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

ggsave("../../plots/SI_fig4.pdf", width=8, height=6)

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

ggsave("../../plots/SI_fig5.pdf", width=8, height=6)

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

ggsave("../../plots/SI_fig6.pdf", width=8, height=6)

# ROC curves
belief_roc <- sample_t_test %>% 
  mutate(sample_roc = ifelse(category != "high_belief", 0, 1),
         survey_roc = ifelse(survey_cat != "high_belief", 0, 1))

truth_roc <- sample_t_test %>% 
  mutate(sample_roc = ifelse(category != "high_truth", 0, 1),
         survey_roc = ifelse(survey_cat != "high_truth", 0, 1))

roc.plot(belief_roc$sample_roc, belief_roc$belief_survey_avg, 
                       main = "Belief-speaking ROC Curve", plot = "both", binormal = T, CI = T)

roc.plot(truth_roc$sample_roc, truth_roc$truth_survey_avg,
                       main = "Truth-seeking ROC Curve", plot = "both", binormal = T, CI = T)

roc.area(belief_roc$sample_roc, belief_roc$belief_survey_avg)
roc.area(truth_roc$sample_roc, truth_roc$truth_survey_avg)
