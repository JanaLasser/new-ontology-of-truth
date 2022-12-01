# author: Almog Simchon


# Mediation Analysis ------------------------------------------------------

#load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, mediation)

#load data
data_users <- read_csv("../../data/users/US_politician_accounts_2010-11-06_to_2022-03-16.csv")

data_users <- data_users %>% 
  dplyr::select(author_id, party, NG_score_mean,
                LIWC_emo_neg_mean, avg_belief_score, avg_truth_score) %>% 
  drop_na()


#Negative emotion as mediator

#Reps
path.y.rep.neg <- lm(data = filter(data_users, party == "Republican"),
                     NG_score_mean~LIWC_emo_neg_mean+avg_belief_score)

path.m.rep.neg <- lm(data = na.omit(filter(data_users, party == "Republican")),
                     LIWC_emo_neg_mean~avg_belief_score)

med.belief.rep.neg <- mediation::mediate(path.m.rep.neg ,path.y.rep.neg , 
                                         treat = "avg_belief_score", mediator = "LIWC_emo_neg_mean" ,
                                         boot = T, sims = 10000)

#Summary
summary(med.belief.rep.neg)
plot(med.belief.rep.neg)

#Dems
path.y.dem.neg <- lm(data = na.omit(filter(data_users, party == "Democrat")),
                     NG_score_mean~LIWC_emo_neg_mean+avg_belief_score)

path.m.dem.neg <- lm(data = na.omit(filter(data_users, party == "Democrat")),
                     LIWC_emo_neg_mean~avg_belief_score)

med.belief.dem.neg <- mediation::mediate(path.m.dem.neg ,path.y.dem.neg , 
                                         treat = "avg_belief_score", mediator = "LIWC_emo_neg_mean" ,
                                         boot = T, sims = 10000)

#Summary
summary(med.belief.dem.neg)




#Belief Speaking as mediator

#Reps
path.y.rep <- lm(data = na.omit(filter(data_users, party == "Republican")),
                 NG_score_mean~LIWC_emo_neg_mean+avg_belief_score)

path.m.rep <- lm(data = na.omit(filter(data_users, party == "Republican")),
                 avg_belief_score~LIWC_emo_neg_mean)

med.belief.rep <- mediation::mediate(path.m.rep ,path.y.rep , 
                                     treat = "LIWC_emo_neg_mean", mediator = "avg_belief_score",
                                     boot = T, sims = 10000)

#Summary
summary(med.belief.rep)
plot(med.belief.rep)

#Dems
path.y.dem <- lm(data = na.omit(filter(data_users, party == "Democrat")),
                 NG_score_mean~LIWC_emo_neg_mean+avg_belief_score)

path.m.dem <- lm(data = na.omit(filter(data_users, party == "Democrat")),
                 avg_belief_score~LIWC_emo_neg_mean)

med.belief.dem <- mediation::mediate(path.m.dem ,path.y.dem , 
                                     treat = "LIWC_emo_neg_mean", mediator = "avg_belief_score",
                                     boot = T, sims = 10000)

#Summary
summary(med.belief.dem)
