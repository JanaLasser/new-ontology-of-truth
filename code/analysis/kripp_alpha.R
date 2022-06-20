library(krippendorffsalpha)
library(dplyr)

alpha_df <- ann_a_df %>% 
  left_join(ann_b_df, by = "Texts") %>% 
  rename(annotator_a = Component.x,
         annotator_b = Component.y) %>% 
  mutate(annotator_a = ifelse(annotator_a == "No", 0, 1),
         annotator_b = ifelse(annotator_b == "No", 0, 1)) %>% 
  select(-Texts)

alpha_fit <- krippendorffs.alpha(as.matrix(alpha_df), level = "interval", 
                                 confint = T, verbose = T, 
                                 control = list(parallel = F, bootit = 1000))

summary(alpha_fit)
