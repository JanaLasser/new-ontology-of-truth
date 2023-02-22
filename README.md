# From Alternative conceptions of honesty to alternative facts in communications by U.S. politicians

Data collection and analysis code for the article "A new ontology of truth shifts public political discourse towards misinformation".

Authors: Jana Lasser (jana.lasser@tugraz.at), Segun Taofeek Aroyehun, Fabio Carrella, Almog Simchon, David Garcia and Stephan
Lewandowsky (Stephan.Lewandowsky@bristol.ac.uk).

## General Notes

### Data publication
The code published in this repository needs a number of data sets to execute. These data sets are published in a separate [OSF repository](https://doi.org/10.17605/OSF.IO/VNY8K), because they are too large to be hosted on GitHub. Therefore, to run the code, after downloading this repository please download the `data` folder contained in the aforementioned OSF repository and copy it into the main directory of this repository (i.e. on the same level as the `code`, `plots`  and `tables` folders).

### Restrictions on data publication
There are restrictions to publishing all data sets required to fully reproduce our work. These restrictions apply to 
1. **Tweets**: Due to data protection reasons and Twitter's usage agreement for the use of its API, we cannot publish tweet texts. As a workaround, we publish a data set with tweet IDs and statistics that were computed using the tweet text, such as honesty component labels. Tweet IDs can be used to hydrate tweets and retrieve the original text, as long as the tweets are still accessible at the time of hydration. We provide the script `hydrate_tweets.ipynb` to hydrate tweets from the list of tweet IDs published in the OSF repository. This script produces the input for the script `wrangle_data.ipynb` and replaces the script `get_US_politician_twitter_timelines.ipynb`, which collects the same tweets using the Twitter v2 academic API.

2. **NewsGuard scores**: we cannot publish NewsGuard domain nutrition labels, since the NewsGuard data base is proprietary. For this reason, certain parts of the `wrangle_data.ipynb` that aggregate NewsGuard scores with the tweet data will not execute. Researchers that want to reproduce our results will have to acquire their own copy of a recent version of the NewsGuard data base and place it in the folder `data/utilities` named `NewsGuard_labels.csv`. This file is expected to have the columns `Domain` and `Score` as well as the nine columns for the individual criteria such as `Does not repeatedly publish false content`.

3. **New York Times article abstracts**: we cannot publish the New York Times article corpus. You can however collect the data yourself using the New York Times' [API](https://developer.nytimes.com/apis) to collect abstracts from the cateogires "Climate", "Education", "Health", "Science", "U.S.", "Washington", "World" and "Opinion".

Therefore, the following scripts will only execute partly without aquiring the tweet texts, NewsGuard data and New York Times abstracts are
* `tweet_collection/wrangle_data.ipynb` (requires NewsGuard data base and tweet texts)
* `analysis/descriptive_dataset_statistics.ipynb` (requires Newsguard data base) 
* `analysis/label_glove840B_DDR.sh` (requires tweet texts and New York Times abstracts)
* `analysis/label_lexicon_loop.sh` (requires tweet texts)
* `analysis/bertopic_model.ipynb` (requires tweet texts)
* `analysis/scattertext.R` (requires tweet texts)

Irrespective of these restrictions we publish all data sets necessary to reproduce all figures in our manuscript except for figure 1, since these data sets need not contain original texts nor the NewsGuard data base. 

### Restrictions on analysis reproducibility
We cannot supply code to reproduce our computation of the LIWC labels for the "authentic", "analytic", "moral", "positive emotion" and "negative emotion" text components. This is due to the fact that LIWC is a proprietary software. Authors interested in reproducing our results should acquire access to [LIWC-22](https://www.liwc.app/) and apply it to the tweet texts. We do hoverwer supply the computed scors for the LIWC text components in the file `US_politician_tweets_2010-11-06_to_2022-03-16.csv.gzip`


### Organisation of the repository
The repository is organized into the two top-level folders `code` and `plots`. The folder `plots` contains only outputs of the analysis scripts. The folder `code` is subdivided into three subfolders:
* `tweet_collection` contains all scripts necessary to collect data from the twitter API, clean the data and wrangle it into the various forms required for subsequent analysis.
* `article_collection` contains all scripts necessary to collect articles from the URLs in the tweets data set and wrangle them into a form suitable for further processing.
* `analysis` contains scripts for
    * calculating descriptive dataset statistics `descriptive_dataset_statistics.ipynb` 
    * calculating honesty component similarity with various embeddings: `label_glove840B_DDR.sh`, `label_fasttext-cc_DDR.sh`, `label_word2vec-googlenews_DDR.sh` and `compute_sbert_avg_lexicon.py`
    * calculating keyword similarity: `label_lexicon_single_word.sh` and `compute_sbert_avg_lexicon_reduce_lexicon_single_word.py`
    * validating honsty components with human ratings: `validation.R` `document_level_validation.ipynb` (drawing the sample) and `document_level_validation.R` (analysis)
    * bootstrapping: `bootstrapping.ipynb`
    * statistical modelling: `lmer_models_tweets.Rmd`, `OLS_regression_articles.ipynb` and `mediation.R`
    * assessing dictionary robustness `label_lexicon_loop.sh`, `compute_sbert_avg_lexicon_reduce_lexcion_loop.sh` and `compute_sbert_avg_lexicon_reduce_lexicon_loop.py`
    * topic modelling with BERTtopic: `bertopic_model.ipynb`
    * reproducing all plots from the article: `plots.ipynb` and `scattertext.R`
    * scrubbing all protected information from the data sets for public upload: `scrub_data_for_upload.ipynb`

## Tweet collection
### Collecting user accounts
Collection of Twitter user accounts associated with members of the U.S. congress is accompished in the script `get_US_politician_twitter_accounts.ipynb`. We combine lists of accounts from different sources such as [socialseer](https://www.socialseer.com), manually inspect and clean the data and download the account profiles using the Twitter API. Account information is stored in the file `users/US_politician_twitter_accounts_clean.csv` for later ingestion by `wrangle_data.ipynb`. 

### Collecting user timelines
Next, we collect the timelines of all tweets from all accounts in the script `get_US_politician_twitter_timelines.ipynb`. Since we are interested in tweets from November 6, 2010 to December 31, 2022, we make use of access to historic tweets via the academiv Twitter v2 API access. We use the Python library [twarc](https://twarc-project.readthedocs.io/en/latest/twarc2_en_us/) to collect the tweets and store them after some basic cleaning steps. Cleaned timelines are stored in the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_clean.csv.gzip` for later ingestion by `wrangle_data.ipynb`. 

A large part of our research relies on the quality of links shared by Congress Members. A large number of URLs are shared in shortened form, using a link shortening service such as bit.ly. We have also observed that links to low-quality websites are much more likely to be shortened than links to high-quality sites. We therefore follow all shortened links to retrieve their true domain. We identify shortened links using a [data base of link shorteners](https://github.com/boutetnico/url-shorteners). In addition, we manually inspect all domains that were tweeted > 100 times and look for additional link shortening services that were not contained in the initial data base of shorteners. The thus retrieved "unraveled" URLs are stored in the file `urls/US_unraveled_urls.csv.xz` for later ingestion by `wrangle_data.ipynb`.

## Article collection from links in Tweets
In the script `tweet_collection/wrangle_data.ipynb` we export a list of urls `articles/url_list_for_article_scraping.csv.gzip` from which we scrape article texts. This list is ingested by the script `article_scraping.R` which tries to retrieve the page texts from all links, making use of the Python library [newspaper3k](https://newspaper.readthedocs.io/en/latest/). 

Note that `wrangle_data.ipynb` also saves a file `articles/url_NG_scores.csv.gzip` with the URL, domain, author ID of the account that posted the URL, party, tweet ID in which the URL was posted and NewsGuard score. This file is later ingested by `OLR_regression_articles.ipynb`. We do not share this file, since it contains the NewsGuard scores, which are proprietary. We do, however, share a file `articles/url_independent_scores.csv.gzip`, which contains the trustworthiness scores calculated with our independent data base, which can be used to reproduce our results without having access to NewsGuard.

Scraped articles are stored in `articles/article_corpus_raw.rds.gz` and pre-processed by `article_preprocessing.R`. Pre-processing also reads the initial list of URLs for article scraping `articles/url_list_for_article_scraping.csv.gzip`, since this file also contains information about the party of the account that posted the link to the article. This information is needed to filter the articles retrieved from the URLs, since we only retain articles that were linked to by one party, not by both. The filtered articles are then stored in `articles/article_corpus_clean.csv.gzip` for later ingestion by ``label_glove840B_DDR.sh`.

## Validation data
Validation of the honesty component keywords and documents is done via a survey on qualtrics. The results of the survey are stored in `data/validataion`.

## Analysis
### Validation
The dictionary validation shown in Supplementary Figures 1 & 2 is done in the script `analysis/keyword_validation.R`. The script ingests the files `validation/validation_belief.csv` and `validation/validation_truth.csv`. The sample for the document level validation is created in the script `analysis/document_level_validation.ipynb`. The document level validation analysis, which is shown in supplementary figures S3-S6, is done in the script `analysis/document_level_validation.R`, which ingests the sample file `validation/document_validation_sample.csv` and `validation/document_validation_data.csv`.

### Honesty components
Honesty component similarities for the New York Times article corpus, the tweet corpus and the corpus of articles collected from URLs in the tweet corpus are calculated by the scripts `label_glove840B_DDR.sh`. In addition, the scripts `label_fasttext-cc_DDR.sh` and `label_word2vec-googlenews_DDR.sh` also calcupate honesty component similarities for the tweet corpus based on alternative embeddings ([word2vec](https://huggingface.co/fse/word2vec-google-news-300) and [fasttext](https://fasttext.cc/docs/en/crawl-vectors.html)). The scripts internally call `compute_sbert_avg_lexicon.py` with different parameters to specify settings for each corpus. The script `compute_sbert_avg_lexicon.py` ingests the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_clean.csv.gzip` and calculates honesty component similarity using the [glove](https://huggingface.co/sentence-transformers/average_word_embeddings_glove.840B.300d) sentence transformer embedding on the New York Times corpus, the tweet corpus and the article corpus. It outputs the honesty component similarity for every corpus in a file:
* The output file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_honesty_component_scores_glove.csv.gzip` is ingested by `wrangle_data.ipynb`. 
* The output file `NYT/NYT_abstracts_honesty_component_scores_glove.csv` is ingested by `scrub_data_for_upload.ipynb`.
* The output file `articles/article_corpus_clean_honesty_component_scores_glove.csv.gzip` is ingested by `scrub_data_for_upload.ipynb`.

Note that for this to work you will need to download the embeddings and place the respective models in the `data/utilities/sentence-transformers` directory.

### Dictonary robustness
We do not include the results of the dictionary robustness analysis here, due to the size of the generated data. You can however reproduce the results by running the script `label_lexicon_loop.sh`, which also ingests the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_clean.csv.gzip`. This calculates honesty component similarity using the [glove](https://huggingface.co/sentence-transformers/average_word_embeddings_glove.840B.300d) sentence transformer embedding, but for 100 perturbed versions of the belief-speaking and truth-seeking dictionaries. Note that for this to work you will need to download the [embeddings](https://huggingface.co/sentence-transformers/average_word_embeddings_glove.840B.300d) and place the respective models in the `data/utilities` directory.

The script `tweet_collection/wrangle_data.ipynb` includes a commented out section ("Add truth seeking & belief speaking scores for dictionary bootstraps") to include the dictionary robustness data `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_honesty_component_scores_glove_bootstrap.csv.gzip` in the data processing workflow. If you run `wrangle_data.ipynb` with these additional lines, it will load the output from `label_lexicon_loop.sh`, merge it to the rest of the tweet-level data and also include it in the final aggregated tweet data set `US_politician_tweets_2010-11-06_to_2022-12-31.csv.gzip`. 

This file then needs to be run through `scrub_data_for_upload.ipynb`. The resulting `tweets/tweets.csv` file can be loaded in `dictionary_robustness.ipynb` to fit the linear mixed effects model for every one of the 100 perturbed versions of each honesty components. The output of this script is the estimates for the fixed effects of the LME for each of the 100 dictionary versions, which is saved in `tweets/LME_results_dictionary_robustness.csv` and loaded in `analysis/plots.ipynb` to generate extended data figure 2.
 

### LIWC scores
We processed the full text of each tweet with LIWC-22, the latest version of the Linguistic Inquiry and Word Count Software [LIWC-22](https://www.liwc.app/). We exported the text of each tweet to a csv file with one row per tweet and two columns, one with the tweet id as a string and the second with the string containing the tweet text. We imported this file to LIWC-22 and processed only the column with the tweet text using the LIWC-22 English dictionary for the "authentic", "analytic", "moral", "positive emotion" and "negative emotion" text components. The result was exported as a csv file including additional columns for each LIWC metric for each tweet. We used this csv file in later statistical analyses.

Scores are stored in the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_clean_mask_LIWC.csv.gzip` for later ingestion by `wrangle_data.ipynb`.

### Data wrangling
The script `wrangle_data.ipynb` takes input from all previous data collection and analysis steps to create three output data files that aggregate most information for different downstream analysis tasks:

* **Tweets**: contains all information pertaining to individual tweets and is stored at `tweets/US_politician_tweets_2010-11-06_to_2022-12-31.csv.gzip`. It contains the following columns:
    * `id`: unique tweet ID
    * `author_id`: unique ID of the author that posted the given tweet. Used to link to the user data file described above.
    * `party`: party affiliation of the account that posted the tweet.
    * `created_at`: tweet creation time in UTZ time.
    * `retweeted`, `quoted` and `reply`: whether the tweet is a retweet, quote-tweet or reply. Note that these categories are not exclusive.
    * `avg_belief_score` and `avg_truth_score`: float, similarity to the belief-speaking and truth-seeking dictionaries. If the robustness analysis is included (see section "Dictionary robustness" above), there are columns with similarity scores calculated using perturbed dictionaries `avg_belief_score_i` and `avg_truth_score_i`, where i ranges from 0 to 99. In addition `avg_belief_score_word2vec`, `avg_truth_score_word2vec`, `avg_belief_score_fasttext` and `avg_truth_score_fasttext` contain the similarity ratings calculated with the word2vec and fasttext embeddings instead of GLoVe.
    * `has_url`: bool, whether the tweet contained an URL. 
    * `LIWC_analytic`, `LIWC_authentic`, `LIWC_moral`, `LIWC_emo_pos`, and `LIWC_emo_neg`: LIWC scores for the text components "analytic", "authentic", "moral", "positive emotions" and "negative emotions" determined using the [LIWC-22](https://www.liwc.app/) software.
    * `NG_score`: float. Only exists for tweets that contained an URL. NewsGuard score determined by matching the domain contained in the URL against the [NewsGuard database](https://www.newsguardtech.com/de/) of information quality. If the tweet contained more than one URL with a NewsGuard score, the scores are averaged.
    * `transparency` and `accuracy`: float. Only exists for tweets that contained an URL. Accuracy and transparency score determined by matching the domain contained in the URL against the [Independent information quality database](https://github.com/JanaLasser/misinformation_domains). If the tweet contained more than one URL with an accuracy and transparency score, the scores are averaged.
    * `NG_unreliable` and `independent_unreliable`: bool. Only exists for tweets that contained an URL. Whether the URL pointed to an "unreliable" website, i.e. a website with a NewsGuard score < 60 or an accuracy score < 1.5 or a transparency score of < 2.5.
* **Users**: contains all information pertaining to individual twitter accounts and is stored at `users/users.csv`. It contains the following columns:
    * `handle`, `name` and `author_id`: Twitter handle, screen name and author ID of the user account.
    * `followers_count`, `following_count`, `tweet_count`: number of followers, accounts followed and tweets posted since account creation, retrieved from the Twitter API.
    * `created_at`: account creation date, retrieved from the Twitter API.
    * `N_tweets`: number of tweets from the given account contained in the tweets data set collected for this project.
    * `party`: Party affiliation `Democrat`, `Republican`, `Independent` or `Libertarian`.
    * `congress`: Latest congress the Congress Member belonged to, can be 114, 115, 116 or 117.
    * `type`: type of the account, can be `official`, `campaign` or `staff`.
    * `NG_unreliable_share`, `independent_unreliable_share`: share of tweets containing a link to an "unreliable" domain, determined with the NewsGuard and independent data base of domain information quality, respectively.
    * `NG_score_mean`, `accuracy_mean`, `transparency_mean`: Average NewsGuard score as well as accuracy and transparency score over all domains contained in tweets by the given accounts.
    * `avg_belief_score`, `avg_truth_score`: average belief-speaking and truth-seeking similarity in tweets by the author.
    * `avg_belief_score_2010_to_2013`, `avg_truth_score_2010_to_2013`: average belief-speaking and truth-seeking similarity in tweets by the author in the years 2010 to 2013, respectively.
    * `avg_belief_score_2019_to_2022`, `avg_truth_score_2019_to_2022`: verage belief-speaking and truth-seeking similarity in tweets by the author in the years 2019 to 2022, respectively.
    * `ideology_count`, `ideology_mean` and `ideology_std`: number of ideology score entries found in the [govtrack database](https://www.govtrack.us/) for the given account as well as average ideology score and ideology score standard deviation.
    * `pf_score`: [politifact](https://www.politifact.com/) score.
* **URLs**: contains all information pertaining to individual URLs posted by twitter accounts of U.S. Congress Members and is stored at `urls/US_politician_URLs_2010-11-06_to_2022-03-16.csv.gzip`. It contains the following columns:
    * `id`: ID of the original tweet the URL was contained in
    * `author_id`: ID of the Twitter user account that posted the tweet the URL was contained in.
    * `created_at`: creation date of the tweet the URL was contained in.
    * `retweeted`, `quoted` and `reply`: bool. Whether the tweet the URL was contained in was a retweet, quote-tweet or reply. 
    * `party`: Party affiliation of the account that posted the tweet the URL was contained in. Can be `Democrat`, `Republican`, `Independent` or `Libertarian`.
    * `shortened_url`: whether the URL was originally shortened using a link shortening service such as bit.ly.
    * `avg_belief_score` and `avg_truth_score`: float, similarity to the belief-speaking and truth-seeking dictionaries. If the robustness analysis is included (see section "Dictionary robustness" above), there are columns with similarity scores calculated using perturbed dictionaries `avg_belief_score_i` and `avg_truth_score_i`, where i ranges from 0 to 99.
    * `NG_score`, `accuracy` and `transparency`: NewsGuard, accuracy and transparency score of the domain the URL pointed to, determined with the [NewsGuard](https://www.newsguardtech.com/de/) and [Independent](https://github.com/JanaLasser/misinformation_domains) of information quality.
    * `NG_unreliable` and `independent_unreliable`: Whether the URL pointed to an "unreliable" website, i.e. a website with a NewsGuard score < 60 or an accuracy score < 1.5 or a transparency score of < 2.5.
    
When all data has been preprocessed, the files `US_politician_tweets_2010-11-06_to_2022-12-131.csv.gzip`, `US_politician_URLs_2010-11-06_to_2022-12-31.csv.gzip`, `article_corpus_clean_honesty_component_scores_glove.csv.gzip`, `url_NG_scores.csv.gzip`, `url_independent_scores.csv.gzip`, `NYT_abstracts_honesty_component_scores_glove.csv.gzip` and `NYT_abstracts.csv.gzip` are ingested by the script `scrub_data_for_upload.ipynb` to scrub the data from all columns that contain protected information (tweet texts and New York Time article abstracts) or would allow for a link between domains and NewsGuard scores. The script produces four clean files that are (together with `users/users.csv`, `tweets_for_lme_modelling_NG.csv.gzip` and `tweets_for_lme_modelling_independent.csv.gzip` from `wrangle_data.ipynb`) provided in the OSF repository:
* `tweets/tweets.csv.gzip`
* `urls/urls.csv.gzip`
* `NYT/abstracts.csv.gzip`
* `articles/articles.csv.gzip`

The following analysis scripts all only need these files to run.
       
### Bootstrapping
Timelines shown in our paper (Figure 1, Extended Data Figure 3, Supplementary Figures S3 and S4) include confidence intervals determined via bootstrapping. Bootstrapping is performed in the script `bootstrapping.ipynb`. Bootstrapping results are saved in the folder `bootstrapping` for ingestion by `plots.ipynb`.   

### Statistical modelling
Statistical modelling to determine the relation of belief-speaking and truth-seeking to information quality is performed in two scripts: `lmer_models_tweets.r` for the tweets by politicians, and `OLS_regression_articles.ipynb` for articles retrieved from the links posted in tweets by politicians. 

For tweets we use a linear mixed effects model implemented in [lme4](https://cran.r-project.org/web/packages/lme4/index.html) where tweets are grouped within user and users are grouped within party. The script `lmer_models_tweets.r` ingests the files `tweets/tweets_for_lme_modelling_NG.csv.gzip` and `tweets/tweets_for_lme_modelling_independent.csv.gzip` produced by `tweet_collection/wrangle_data.ipynb`. The files contain belief-speaking and truth-seeking similarity and trustworthiness scores determined by NewsGuard and the independent list, respectively. The LME modelling script outputs the files `tweets/LME_predictions_tweets_belief.csv` and `tweets/LME_predictions_tweets_truth.csv` used to plot the prediction lines in Figure 3, panels A and B. It also outputs the file `tweets/LME_predictions_tweets_threeway.csv` used to plot the three-way interactions visualized in Extended Data Figure 1.

For articles we use a linear regressions model that are fitted using an ordinary least squares method, implemented by the Python library [statsmodels](https://www.statsmodels.org/stable/index.html). The script `OLS_regression_articles.ipynb` ingests the files `articles/articles.csv.gzip` containing the belief-speaking and truth-seeking similarity scores, the NewsGuard scores and party information. It then fits a regression models with one observation for each article. Results of the regression are stored in `tables/OLS_table_article_NG_score.txt` for input into the manuscript. The script also outputs predictions of average NewsGuard score of depending on the belief-speaking and truth-seeking similarity of a given article. The predictions are stored in the file `articles/OLS_predictions_articles_honesty.csv` and ingested by `plots.ipynb` to produce Figure 3.

### Mediation analysis
Mediation analysis is performed in the script `analysis/mediation.r`. The script ingests the file `users/users.csv` and outputs the summary statistics of the mediation analysis.
       
### Topic modelling
Before further analysis of the texts can be performed, the texts first need to be lemmatized. This is done in the script `tweet_collection/wrangle_data.ipynb`. The script   outputs the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_lemma.csv.gzip`, which is used by `bertopic_model.ipyb`. Topic modelling is performed using the library [BERTopic](https://github.com/MaartenGr/BERTopic). The fitted model is saved at `tweets/BERTopic_model` for later re-use, since fitting the model takes a while. 

The script outputs two results files: `tweets/topics_all_docs.csv.gzip` and `tweets/topics_per_class_ddr.csv`, which are used by `plots.ipynb` to visualize topics in Supplementary Figure 5.

## Descriptive statistics & plots
Descriptive statistics of the various data sets used in our analysis and reported in the paper are calculated in the script `analysis/descriptive_dataset_statistics.ipynb`. The script also contains additional descriptive visualisations not contained in the article.

All visualisations in the main manuscript, extended data and figures and supplement except for Figure 1 and Supplementary Figures 1 & 2 are created in the script `plots.ipynb` and saved in the folder `plots`. Figure 1 is created by `scattertext.R`. Supplementary Figures 1 & 2 are created by `keyword_validation.R` and Supplemengary Figures 3, 4, 5 and 6 are created by `document_level_validation.R`. The scripts ingest the following files to create the figures:

### Figure 1
* `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_lemma.csv.gzip' (created by `tweet_collection/wrangle_data.ipynb`, not provided in repository) 

### Figure 2
* `users/users.csv` (created by `tweet_collection/wrangle_data.ipynb`, provided in repository)
* `bootstrapping/belief.csv` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/truth.csv` (created by `analysis/bootstrapping.ipynb`, provided in repository)

### Figure 3
* `tweets/tweets.csv.gzip` (created by `analysis/scrub_data_for_upload.ipynb`, provided in repository) 
* `tweets/LME_predictions_tweets_belief.csv` (created by `analysis/lmer_models_tweets.Rmd`, provided in repository)
* `articles/articles.csv.gzip` (created by `analysis/scrub_data_for_upload.ipynb`, provided in repository)
* `articles/OLS_predictions_articles.csv` (created by `analysis/OLS_regression_articles.ipynb`, provided in repository)

### Extended Data Figure 1
* `LME_predictions_tweets_threeway.csv` (created by `analysis/lmer_models_tweets.Rmd`, provided in repository)

### Extended Data Figure 2
* `tweets/LME_results_dictionary_robustness.csv` (created by `analysis/dictionary_robustness.ipynb`, provided in repository)
* `tweets/tweets.csv.gzip` (created by running `tweet_collection/wrangle_data.ipynb` with the code for the robustness analysis included and then running the data through `analysis/scrub_data_for_upload.ipynb` again, not provided in repository.)

### Extended Data Figure 3
* `bootstrapping/NG_coverage.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/independent_coverage.csv.gzip` (created by `analysis/bootstrapping.ipynb` , provided in repository)

### Extended Data Figure 4
* `tweets/tweets.csv.gzip` (created by `analysis/scrub_data_for_upload.ipynb`, provided in repository) 
* `articles/articles.csv.gzip` (created by `analysis/scrub_data_for_upload.ipynb`, provided in repository) 

### Supplementary Figure 1
* `validation/validation_belief.csv` (output from Qualtrics, provided in repository)

### Supplementary Figure 2
* `validation/validation_truth.csv` (output from Qualtrics, provided in repository)

### Supplementary Figure 3, 4, 5 and 6
* `validation/document_validation_sample.csv` (created by `analysis/document_level_validation.ipynb`, provided in repository)
* `validation/document_validation_data.csv` (output from Qualtrics, provided in repository)

### Supplementary Figure 7
* `bootstrapping/LIWC.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_belief.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_truth.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_neutral_belief.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_neutral_truth.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)

### Supplementary Figure 8
* `bootstrapping/LIWC.csv` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_belief.csv` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_truth.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_neutral_belief.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)
* `bootstrapping/LIWC_neutral_truth.csv.gzip` (created by `analysis/bootstrapping.ipynb`, provided in repository)

### Supplementary Figure 9
* `tweets/topics_all_docs.csv.gzip` (created by `analysis/bertopic_model.ipynb`, provided in repository)
* `tweets/topics_per_class_ddr.csv` (created by `analysis/bertopic_model.ipynb`, provided in repository)

### Supplementary Figure 10
* `users/users.csv` (created by `analysis/scrub_data_for_upload.ipynb`, provided in repository) 
* `utilities/state_names.csv` (provided in `utilities`)
* `utilities/popular_vote_2020.csv` (provided in `utilities`)

### Supplementary Figure 11
* `users/users.csv` (created by `tweet_collection/wrangle_data.ipynb`, provided in repository)

### Supplementary Figure 12
* `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_honesty_component_scores_glove_singleword.csv.gzip` (created by `label_lexicon_single_word.sh`, not provided in the repository)
* `US_politician_tweets_2010-11-06_to_2022-12-31.csv.gzip` (created by `wrangle_data.ipynb`, not provided in the repository)