# author: fabio
library(tidyverse)
library(readxl)
library(broom)

df_belief <- read.csv("../../data/validation/validation_belief.csv")
df_truth <- read.csv("../../data/validation/validation_truth.csv")

belief_speaking_df <- read.csv("../../data/utilities/belief_speaking_p=0.05_swapped_wn_def_example.csv")
truth_seeking_df <- read.csv("../../data/utilities/truth_seeking_p=0.05_swapped_wn_def_example.csv")

b_keywords <- as.list(belief_speaking_df$`belief_speaking`) %>% .[!is.na(.)]
t_keywords <- as.list(truth_seeking_df$`truth_seeking`) %>% .[!is.na(.)]


# pivot data and bind df together
df_belief_long <- df_belief %>% 
  rename(Prolific_ID = 1) %>% 
  pivot_longer(!Prolific_ID, names_to = "keyword", values_to = "rate") %>% 
  mutate(kw_component = ifelse(keyword %in% b_keywords, "belief", "truth"),
         rate_type = "belief",
         ID = row_number())
  

df_truth_long <- df_truth %>% 
  rename(Prolific_ID = 1) %>% 
  pivot_longer(!Prolific_ID, names_to = "keyword", values_to = "rate") %>% 
  mutate(kw_component = ifelse(keyword %in% b_keywords, "belief", "truth"),
         rate_type = "truth",
         ID = row_number())
  

df <- df_belief_long %>% 
  rbind(df_truth_long)


# density plots
df %>%
  filter(kw_component %in% "belief") %>%
  ggplot() +
  aes(x = rate, fill = rate_type, group = rate_type) +
  geom_density(adjust = 1L, alpha = 0.5) +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(keyword), scales = "free")

df %>%
  filter(kw_component %in% "truth") %>%
  ggplot() +
  aes(x = rate, fill = rate_type, group = rate_type) +
  geom_density(adjust = 1L, alpha = 0.5) +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(keyword), scales = "free")


# boxplots
df_belief_plot <- df %>% filter(kw_component %in% "belief")
df_truth_plot <- df %>% filter(kw_component %in% "truth")

belief_boxplot <- ggplot(df_belief_plot) +
  aes(x = "", y = rate, fill = rate_type, group = rate_type) +
  geom_boxplot() +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(keyword)) +
  labs(fill = "Rate Type", title = "Belief-speaking Keywords") +
  xlab("Keywords") +
  ylab("Rate Distributions") +
  theme(text = element_text(size = 14))
ggsave(file="../../plots/SI_fig1.svg", plot=belief_boxplot, width=10, height=7)

truth_boxplot <-   ggplot(df_truth_plot) +
  aes(x = "", y = rate, fill = rate_type, group = rate_type) +
  geom_boxplot() +
  scale_fill_manual(
    values = c(belief = "#FF6E40",
               truth = "#FFC13B")
  ) +
  theme_minimal() +
  facet_wrap(vars(keyword)) +
  labs(fill = "Rate Type", title = "Truth-seeking Keywords") +
  xlab("Keywords") +
  ylab("Rate Distributions") +
  theme(text = element_text(size = 14))
ggsave(file="../../plots/SI_fig2.svg", plot=truth_boxplot, width=10, height=7)

# t-tests
t_test_df <-  df %>% 
  group_by(keyword) %>% 
  summarise(t = t.test(rate, rate.y, paired=T)$statistic,
            pval = t.test(rate, rate.y, paired=T)$p.value) %>% 
  mutate(kw_component = ifelse(keyword %in% b_keywords, "belief", "truth"),
         tail_component = ifelse(t < 0, "truth", "belief"),
         is_valid = ifelse(pval < 0.5 & kw_component == tail_component, "yes", "no"),
         is_opposite = ifelse(pval < 0.5 & kw_component != tail_component, "yes", "no"))


readr::write_csv(t_test_df, "../../tables/t_test_0.5.csv")


  
