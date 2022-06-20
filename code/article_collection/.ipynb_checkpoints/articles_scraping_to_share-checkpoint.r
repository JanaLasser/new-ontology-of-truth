#NewsGuard Scraping


# Scrape ---------------------------------------------------------------

#load libraries

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, data.table, reticulate)


#load urls
df <- fread('../../data/urls/url_list_for_article_scraping.csv.gzip')

#clean urls
df_cleaned <- df %>% 
  filter(domain != "",
         domain != 'youtube.com') %>% 
  filter(str_detect(url, ".com/|.gov/")) %>% 
  mutate(link_text = NA) %>% #preallocate text column
  select(url, score, link_text) %>% 
  distinct()


#loop newspaper3k: extract main text of articles
for (i in 1:nrow(df_cleaned)){
  
  url <- df_cleaned$url[i]
  
  tryCatch({
    #python bit
    reticulate::py_run_file("article_script.py")
    
    #back to r
    df_cleaned$link_text[i] <- py$article_text
  }, error=function(e){})
  
}

#write data file
write_rds(df_cleaned, "../../data/articles/scraped_corpus_raw.rds", "gz")
