# author: Fabio Carrella

# load libraries and set functions
library(dplyr)
library(ggplot2)
library(ggpubr)
library(tidyverse)

calc_exp <- function(a,b,sum_a,sum_b) {
  c <-  sum_a-a
  d <-  sum_b-b
  a.exp <-  ((a+b)*(a+c))/(a+b+c+d)
  return(a.exp)
}

calc_g2 <- function(a,b,sum_a,sum_b) {
  c <-  sum_a-a
  d <-  sum_b-b
  a.exp <-  ((a+b)*(a+c))/(a+b+c+d)
  b.exp <-  ((a+b)*(b+d))/(a+b+c+d)
  c.exp <-  ((c+d)*(a+c))/(a+b+c+d)
  d.exp <-  ((c+d)*(b+d))/(a+b+c+d)
  G2 <-  2*(a*log(a/a.exp) + b*log(b/b.exp) + c*log(c/c.exp) + d*log(d/d.exp))
  return(G2)
}


# import and wrangle dataset with topics per class
topics_per_class <- topics_per_class %>% 
  filter(Topic != -1) # removes outlier group created by BERTOPIC
  

dataset <- topics_per_class %>% 
  pivot_wider(names_from = Class, values_from = Frequency) %>% 
  replace(is.na(.), 0) %>% 
  group_by(Topic, Name) %>% 
  summarise(db_freq = max(db),
            rb_freq = max(rb),
            dt_freq = max(dt),
            rt_freq = max(rt),
            do_freq = max(do),
            ro_freq = max(ro)) %>% 
  mutate(b_freq = db_freq + rb_freq,
         t_freq = dt_freq + rt_freq,
         o_freq = do_freq + ro_freq) %>% 
  ungroup()

# create relative frequencies and keyness measures 
dataset <- dataset %>% 
  mutate(b_rel = (b_freq / sum(b_freq)) * 100,
         t_rel = (t_freq / sum(t_freq)) * 100,
         o_rel = (o_freq / sum(o_freq)) * 100,
         db_rel = (db_freq / sum(db_freq)) * 100,
         dt_rel = (dt_freq / sum(dt_freq)) * 100,
         do_rel = (do_freq / sum(do_freq)) * 100,
         rb_rel = (rb_freq / sum(rb_freq)) * 100,
         rt_rel = (rt_freq / sum(rt_freq)) * 100,
         ro_rel = (ro_freq / sum(ro_freq)) * 100) %>% 
  mutate(b_ratio = b_rel/(o_rel+t_rel),
         t_ratio = t_rel/(o_rel+b_rel),
         b_exp = calc_exp(b_freq, (o_freq+t_freq), sum(b_freq), sum(o_freq)+sum(t_freq)),
         t_exp = calc_exp(t_freq, (o_freq+b_freq), sum(t_freq), sum(o_freq)+sum(b_freq)),
         b_G2_sign = ifelse(b_freq > b_exp, T, F),
         t_G2_sign = ifelse(t_freq > t_exp, T, F),
         b_G2 = calc_g2(b_freq, (o_freq+t_freq), sum(b_freq), sum(o_freq)+sum(t_freq)),
         t_G2 = calc_g2(t_freq, (o_freq+b_freq), sum(t_freq), sum(o_freq)+sum(b_freq)))

# select controversial topics as a subset
debated_topics <- c(3, 104, 2, 142, 163, 4, 218, 39, 331, 13, 20, 19, 116, 52, 7, 
                12, 15, 21, 29, 45)

# check for debated topics in parties (here example with Republicans)
rep_spec_topic <- dataset %>% 
  filter(Topic %in% debated_topics) %>% 
  select(Topic, Name, rb_rel, rt_rel) %>% 
  pivot_longer(c(rb_rel, rt_rel), names_to = "Class", values_to = "Rel_Freq")

# create dataset for relative frequencies of components within parties
share_dataset <- dataset %>% 
  filter(Topic %in% debated_topics) %>% 
  mutate(b_share = b_freq / (b_freq + t_freq + o_freq) * 100,
         t_share = t_freq / (b_freq + t_freq + o_freq) * 100,
         db_share = db_freq / (db_freq + dt_freq + do_freq) * 100,
         dt_share = dt_freq / (db_freq + dt_freq + do_freq) * 100,
         rb_share = rb_freq / (rb_freq + rt_freq + ro_freq) * 100,
         rt_share = rt_freq / (rb_freq + rt_freq + ro_freq) * 100,
         db_ratio = db_share - b_share,
         dt_ratio = dt_share - t_share,
         rb_ratio = rb_share - b_share,
         rt_ratio = rt_share - t_share)

# check for share distribution in components (here example with truth-seeking)
truth_share_dataset <- share_dataset %>% 
  pivot_longer(c(dt_ratio, rt_ratio), names_to = "Class", values_to = "Truth_Party_Ratio")


# creating bar plots from dataset (here example for Republicans' controversial topics)
rep_spec_plot <- ggplot(rep_spec_topic) +
  aes(x = reorder(Name, -Topic), fill = Class, weight = Rel_Freq) +
  geom_bar(position = position_dodge2(reverse = T), width = 0.7) +
  coord_flip() +
  theme_minimal() +
  scale_fill_manual(values = c("#ff6e40", "#ffc13b"), 
                    labels = c("Belief-speaking", "Truth-seeking"), "Component:") +
  labs(title = "Components Distribution in Democratic Discourse", 
       x = "Topic", y = "Relative Frequency") + 
  theme(axis.text = element_text(size = 18),
        axis.title = element_text(size = 14),
        plot.title = element_text(size = 20),
        plot.title.position = "plot",
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12))
