# author: Almog Simchon


# Mediation Analysis ------------------------------------------------------

#load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, mediation)

#load data
liwc_binded <- read_csv("data/tweets/US_politician_tweets_2010-11-06_to_2022-03-16.csv.gzip")


#summarize
liwc_summarized <- liwc_binded %>% 
  group_by(author_id, party) %>% 
  summarise(neg = mean(LIWC_emo_neg, na.rm=T),
            belief_share = mean(belief, na.rm=T),
            truth_share = mean(truth, na.rm=T),
            fishy = mean(NG_unreliable, na.rm=T)) %>%
  ungroup() %>% 
  filter(party %in% c("Republican", "Democrat"))


#Negative emotion as mediator

#Reps
path.y.rep.neg <- lm(data = na.omit(filter(liwc_summarized, party == "Republican")),
                     fishy~neg+belief_share)

path.m.rep.neg <- lm(data = na.omit(filter(liwc_summarized, party == "Republican")),
                     neg~belief_share)

med.belief.rep.neg <- mediation::mediate(path.m.rep.neg ,path.y.rep.neg , 
                                         treat = "belief_share", mediator = "neg" ,
                                         boot = T, sims = 10000)

#Summary
summary(med.belief.rep.neg)


#Dems
path.y.dem.neg <- lm(data = na.omit(filter(liwc_summarized, party == "Democrat")),
                     fishy~neg+belief_share)

path.m.dem.neg <- lm(data = na.omit(filter(liwc_summarized, party == "Democrat")),
                     neg~belief_share)

med.belief.dem.neg <- mediation::mediate(path.m.dem.neg ,path.y.dem.neg , 
                                         treat = "belief_share", mediator = "neg" ,
                                         boot = T, sims = 10000)

#Summary
summary(med.belief.dem.neg)




#Belief Speaking as mediator

#Reps
path.y.rep <- lm(data = na.omit(filter(liwc_summarized, party == "Republican")),
                 fishy~neg+belief_share)

path.m.rep <- lm(data = na.omit(filter(liwc_summarized, party == "Republican")),
                 belief_share~neg)

med.belief.rep <- mediation::mediate(path.m.rep ,path.y.rep , 
                                     treat = "neg", mediator = "belief_share",
                                     boot = T, sims = 10000)

#Summary
summary(med.belief.rep)


#Dems
path.y.dem <- lm(data = na.omit(filter(liwc_summarized, party == "Democrat")),
                 fishy~neg+belief_share)

path.m.dem <- lm(data = na.omit(filter(liwc_summarized, party == "Democrat")),
                 belief_share~neg)

med.belief.dem <- mediation::mediate(path.m.dem ,path.y.dem , 
                                     treat = "neg", mediator = "belief_share",
                                     boot = T, sims = 10000)

#Summary
summary(med.belief.dem)
