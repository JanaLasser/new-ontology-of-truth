# A new ontology of truth shifts public political discourse towards misinformation

Data collection and analysis code for the article "A new ontology of truth shifts public political discourse towards misinformation" (see [preprint](TODO)).

Authors: Jana Lasser (jana.lasser@tugraz.at), Segun Taofeek Aroyehun, Fabio Carrella, Almog Simchon, David Garcia and Stephan
Lewandowsky (Stephan.Lewandowsky@bristol.ac.uk).

## General Notes

### Data publication
The code published in this repository needs a number of data sets to execute. These data sets are published in a separate [OSF repository](TODO), because they are too large to be hosted on GitHub. Therefore, to run the code, after downloading this repository please download the `data` folder contained in the aforementioned OSF repository and copy it into the main directory of this repository (i.e. on the same level as the `code`, `plots`  and `tables` folders).

### Restrictions on data publication
There are restrictions to publishing all data sets required to fully reproduce our work. These restrictions apply to 
1. **Tweets**: Due to data protection reasons and Twitter's usage agreement for the use of its API, we cannot publish tweet texts. As a workaround, we publish a data set with tweet IDs and statistics that were computed using the tweet text, such as honesty component labels. Tweet IDs can be used to hydrate tweets and retrieve the original text, as long as the tweets are still accessible at the time of hydration. We provide the script `hydrate_tweets.ipynb` to hydrate tweets from the list of tweet IDs published in the OSF repository. This script produces the input for the script `wrangle_data.ipynb` and replaces the script `get_US_politician_twitter_timelines.ipynb`, which collects the same tweets using the Twitter v2 academic API.

2. **NewsGuard scores**: we cannot publish NewsGuard domain nutrition labels, since the NewsGuard data base is proprietary. For this reason, certain parts of the `wrangle_data.ipynb` that aggregate NewsGuard scores with the tweet data will not execute. Researchers that want to reproduce our results will have to acquire their own copy of a recent version of the NewsGuard data base and place it in the folder `data/utilities` named `NewsGuard_labels.csv`. This file is expected to have the columns `Domain` and `Score` as well as the nine columns for the individual criteria such as `Does not repeatedly publish false content`.

Irrespective of these restrictions we publish all data sets necessary to reproduce all figures in our manuscript, since these data sets need not contain original tweet texts nor the NewsGuard data base. Therefore, the only scripts that will NOT execute correctly without aquiring the tweet texts and NewsGuard data are
* `wrangle_data.ipynb` (requires NewsGuard data base)
* `descriptive_dataset_statistics.ipynb` (requires Newsguard data base) 
* `label_honesty_components.py` (requires tweet texts)
* `keyness_topic_modelling.R` (requires tweet texts)
* `BERT_topic_modelling.R` (requires tweet texts)

### Restrictions on analysis reproducibility
We cannot supply code to reproduce our computation of the LIWC labels for the "authentic", "analytic", "moral", "positive emotion" and "negative emotion" text components. This is due to the fact that LIWC is a proprietary software. Authors interested in reproducing our results should acquire access to [LIWC-22](https://www.liwc.app/) and apply it to the tweet texts.


### Organisation of the repository
The repository is organized into the three top-level folders `code`, `plots` and `tables`. The folders `plots` and `tables` contain only outputs of the analysis scripts. The folder `code` is subdivided into three subfolders:
* `tweet_collection` contains all scripts necessary to collect data from the twitter API, clean the data and wrangle it into the various forms required for subsequent analysis.
* `article_collection` contains all scripts necessary to collect articles from the URLs in the tweets data set and wrangle them into a form suitable for further processing.
* `analysis` contains scripts for bootstrapping (`bootstrapping.ipynb`), statistical modelling (`statistical_modelling.ipynb`), calculating descriptive dataset statistics (`descriptive_dataset_statistics.ipynb`), topic modelling with BERTtopic(`BERT_topic_modelling.ipynb`) and keyness (`keyness_topic_modelling.R`), calculating interrater reliability (`kripp_alpha.R`), labelling tweets by their honesty componnents (`label_honesty_components.py` and `label_honesty_components.sh`), creating the wordclouds for figure 1 (`wordclouds.R`) and reproducing all plots from the article (`plots.ipynb`).

## Tweet collection
### Collecting user accounts
Collection of Twitter user accounts associated with members of the U.S. congress is accompished in the script `get_US_politician_twitter_accounts.ipynb`. We combine lists of accounts from different sources such as [socialseer](https://www.socialseer.com), manually inspect and clean the data and download the account profiles using the Twitter API. Account information is stored in the file `users/US_politician_twitter_accounts_clean.csv` for later ingestion by `wrangle_data.ipynb`. 

### Collecting user timelines
Next, we collect the timelines of all tweets from all accounts in the script `get_US_politician_twitter_timelines.ipynb`. Since we are interested in tweets from November 6, 2010 to March 16, 2022, we make use of access to historic tweets via the academiv Twitter v2 API access. We use the Python library [twarc](https://twarc-project.readthedocs.io/en/latest/twarc2_en_us/) to collect the tweets and store them after some basic cleaning steps. Cleaned timelines are stored in the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_clean.csv.gzip` for later ingestion by `wrangle_data.ipynb`. 

A large part of our research relies on the quality of links shared by Congress Members. A large number of URLs are shared in shortened form, using a link shortening service such as bit.ly. We have also observed that links to low-quality websites are much more likely to be shortened than links to high-quality sites. We therefore follow all shortened links to retrieve their true domain. We identify shortened links using a [data base of link shorteners](https://github.com/boutetnico/url-shorteners). In addition, we manually inspect all domains that were tweeted > 100 times and look for additional link shortening services that were not contained in the initial data base of shorteners. The thus retrieved "unraveled" URLs are stored in the file `urls/US_unraveled_urls.csv.xz` for later ingestion by `wrangle_data.ipynb`.

## Article collection
In the script `wrangle_data.ipynb` we export a list of urls `url_list_for_article_scraping.csv.gzip` from which we scrape article texts. This list is ingested by the script `articles_scraping_to_share.R` which tries to retrieve the page texts from all links, making use of the Python library [newspaper3k](https://newspaper.readthedocs.io/en/latest/). Scraped articles are stored in `articles/scraped_corpus_raw.rds.gz` for later ingestion by `dicitonaries_on_articles.R`.

## Analysis
### Honesty components
The script `label_honesty_components.sh` calls the script `label_honesty_components.py` with a number of parameters to detect honesty components in the tweet texts. The script ingests the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_clean.csv.gzip` and outputs the honesty component labels for each tweet in the file `tweets/twitter_honesty_component_labels.csv.gzip` for later ingestion by `wrangle_data.ipynb`. The script requires the three honesty component dictionaries `belief_speaking_lemmav3.csv`, `truth_seeking_lemmav3.csv` and `seeking_understanding_lemmav3.csv` as well as a list of masked words `mask_list.csv`, all stored in `utilities`. 

### Interrater reliability
TODO Interrater reliability

### LIWC scores
We processed the full text of each tweet with LIWC-22, the latest version of the Linguistic Inquiry and Word Count Software [LIWC-22](https://www.liwc.app/). We exported the text of each tweet to a csv file with one row per tweet and two columns, one with the tweet id as a string and the second with the string containing the tweet text. We imported this file to LIWC-22 and processed only the column with the tweet text using the LIWC-22 English dictionary for the "authentic", "analytic", "moral", "positive emotion" and "negative emotion" text components. The result was exported as a csv file including additional columns for each LIWC metric for each tweet. We used this csv file in later statistical analyses.

Scores are stored in the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_clean_mask_LIWC.csv.gzip` for later ingestion by `wrangle_data.ipynb`.

### Data wrangling
The script `wrangle_data.ipynb` takes input from all previous data collection and analysis steps to create three output data files that aggregate all information for different downstream analysis tasks:

* **Tweets**: contains all information pertaining to individual tweets and is stored at `tweets/US_politician_tweets_2010-11-06_to_2022-03-16.csv.gzip`. It contains the following columns:
    * `id`: unique tweet ID
    * `author_id`: unique ID of the author that posted the given tweet. Used to link to the user data file described above.
    * `party`: party affiliation of the account that posted the tweet.
    * `created_at`: tweet creation time in UTZ time.
    * `retweeted`, `quoted` and `reply`: whether the tweet is a retweet, quote-tweet or reply. Note that these categories are not exclusive.
    * `belief`, `truth` and `neutral`: bool, whether the tweet contains belief-speaking, truth-seeking or none of the two (neutral).
    * `has_url`: bool, whether the tweet contained an URL. 
    * `word_count`: number of words in the tweet text
    * `LIWC_analytic`, `LIWC_authentic`, `LIWC_moral`, `LIWC_emo_pos`, and `LIWC_emo_neg`: LIWC scores for the text components "analytic", "authentic", "moral", "positive emotions" and "negative emotions" determined using the [LIWC-22](https://www.liwc.app/) software.
    * `NG_score`: float. Only exists for tweets that contained an URL. NewsGuard score determined by matching the domain contained in the URL against the [NewsGuard database](https://www.newsguardtech.com/de/) of information quality. If the tweet contained more than one URL with a NewsGuard score, the scores are averaged.
    * `transparency` and `accuracy`: float. Only exists for tweets that contained an URL. Accuracy and transparency score determined by matching the domain contained in the URL against the [Independent information quality database](https://github.com/JanaLasser/misinformation_domains). If the tweet contained more than one URL with an accuracy and transparency score, the scores are averaged.
    * `NG_unreliable` and `independent_unreliable`: bool. Only exists for tweets that contained an URL. Whether the URL pointed to an "unreliable" website, i.e. a website with a NewsGuard score < 60 or an accuracy score < 1.5 or a transparency score of < 2.5.
* **Users**: contains all information pertaining to individual twitter accounts and is stored at `users/US_politician_accounts_2010-11-06_to_2022-03-16.csv`. It contains the following columns:
    * `handle`, `name` and `author_id`: Twitter handle, screen name and author ID of the user account.
    * `followers_count`, `following_count`, `tweet_count`: number of followers, accounts followed and tweets posted since account creation, retrieved from the Twitter API.
    * `created_at`: account creation date, retrieved from the Twitter API.
    * `N_tweets`: number of tweets from the given account contained in the tweets data set collected for this project.
    * `party`: Party affiliation `Democrat`, `Republican`, `Independent` or `Libertarian`.
    * `congress`: Latest congress the Congress Member belonged to, can be 114, 115, 116 or 117.
    * `type`: type of the account, can be `official`, `campaign` or `staff`.
    * `NG_unreliable_share`, `independent_unreliable_share`: share of tweets containing a link to an "unreliable" domain, determined with the NewsGuard and independent data base of domain information quality, respectively.
    * `NG_score_mean`, `accuracy_mean`, `transparency_mean`: Average NewsGuard score as well as accuracy and transparency score over all domains contained in tweets by the given accounts.
    * `belief_share`, `truth_share`, `neutral_share`: share of tweets with belief-speaking, truth-seeking or neither.
    * `belief_share_2010_to_2013`, `truth_share_2010_to_2013`: share of tweets with belief-speaking and truth-seeking in the years 2010 to 2013, respectively.
    * `belief_share_2019_to_2022`, `truth_share_2019_to_2022`: share of tweets with belief-speaking and truth-seeking in the years 2019 to 2022, respectively.
    * `ideology_count`, `ideology_mean` and `ideology_std`: number of ideology score entries found in the [govtrack database](https://www.govtrack.us/) for the given account as well as average ideology score and ideology score standard deviation.
    * `pf_score`: [politifact](https://www.politifact.com/) score.
* **URLs**: contains all information pertaining to individual URLs posted by twitter accounts of U.S. Congress Members and is stored at `urls/US_politician_URLs_2010-11-06_to_2022-03-16.csv.gzip`. It contains the following columns:
    * `id`: ID of the original tweet the URL was contained in
    * `author_id`: ID of the Twitter user account that posted the tweet the URL was contained in.
    * `created_at`: creation date of the tweet the URL was contained in.
    * `retweeted`, `quoted` and `reply`: bool. Whether the tweet the URL was contained in was a retweet, quote-tweet or reply. 
    * `party`: Party affiliation of the account that posted the tweet the URL was contained in. Can be `Democrat`, `Republican`, `Independent` or `Libertarian`.
    * `shortened_url`: whether the URL was originally shortened using a link shortening service such as bit.ly.
    * `belief`, `truth` and `neutral`: bool. Whether the tweet the URL was contained in was labelled as belief-speaking, truth-seeking or none of the two.
    * `NG_score`, `accuracy` and `transparency`: NewsGuard, accuracy and transparency score of the domain the URL pointed to, determined with the [NewsGuard](https://www.newsguardtech.com/de/) and [Independent](https://github.com/JanaLasser/misinformation_domains) of information quality.
    * `NG_unreliable` and `independent_unreliable`: Whether the URL pointed to an "unreliable" website, i.e. a website with a NewsGuard score < 60 or an accuracy score < 1.5 or a transparency score of < 2.5.
       

### Lemmatization
Before further analysis of the texts can be performed, the texts first need to be lemmatized. This is performed in the script `analysis/lemmatization.R`. The script takes as input file the file containing texts and honesty labels created by the script `analysis/label_honesty_components.sh` and outputs the file `tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_lemmatized_text.csv.gzip`, which is used by the scripts `scattertext.R` and `BERT_topic_modelling.ipynb`.

### Topic modelling
Topic modelling is performed using the library [BERTopic](https://github.com/MaartenGr/BERTopic). The fitted model is saved under `twitter_lemmatized` for later re-use, since fitting the model takes about 4 hours. The script outputs two results files: `tweets/topics_per_class.csv` and `tweets/key_topics.csv`, which are used by `plots.ipynb` to visualize topics.

TODO: upload model to OSF

### Statistical modelling
Statistical modelling to determine the relation of belief-speaking and truth-seeking to information quality is performed in the script `statistical_modelling.ipynb`. We use linear regressions models that are fitted using an ordinary least squares method, implemented by the Python library [statsmodels](https://www.statsmodels.org/stable/index.html).  

The script ingests the file `users/US_politician_accounts_2010-11-06_to_2022-03-16.csv` to fit the user-level regression models, and the file `articles/article_scores_with_parties.csv.gzip` to fit the article-level regression models.  

The script outputs predictions of average NewsGuard, accuracy and transparency scores of individual users depending on the share of belief-speaking and truth-seeking tweets by that user. The predictions are stored in the files `OLS_predictions_score.csv`, `OLS_predictions_accuracy.csv` and `OLS_predictions_transparency.csv` in the folder `users` and ingested by `plots.ipynb` to produce visualisations. Similarly, the script outputs predictions for NewsGuard scores of individual domains depending on the share of belief-speaking and truth-seeking words contained in the article text. These predictions are stored at `articles/OLS_predictions_articles.csv`.

Lastly, the script also outputs LaTeX tables containing the regression statistics that are reported in the paper. These stables are saved in `tables`.

### Bootstrapping
Timelines shown in our paper include confidence intervals determined via bootstrapping. Bootstrapping is performed in the script `bootstrapping.ipynb`. Bootstrapping results are saved in the folder `bootstrapping` for ingestion by `plots.ipynb`.

### Descriptive statistics & plots
Descriptive statistics of the various data sets used in our analysis and reported in the paper are calculated in the script `descriptive_dataset_statistics.ipynb`. The script also contains additional descriptive visualisations not contained in the article.

Data-based visualisations of the manuscript are created in the script `plots.ipynb` and saved in the folder `plots`.  

The script ingests the following files to create all figures in the main manuscript, extended data and figures and supplement:

#### Figure 1
* `tweets/topics_per_class.csv' 
* Note that panel A of figure 1 is created in a separate script `scattertext.R` and merged with panels B and C in the LaTeX file.

#### Figure 2
* `users/US_politician_accounts_2010-11-06_to_2022-03-16.csv`
* `bootstrapping/belief.csv`
* `bootstrapping/truth.csv`

#### Figure 3
* `users/"US_politician_accounts_2010-11-06_to_2022-03-16.csv`
* `users/OLS_predictions_score.csv`
* `articles/article_scores_with_parties.csv.gzip`
* `OLS_predictions_articles.csv`

#### Extended Data Figure 2
* `bootstrapping/LIWC.csv`
* `bootstrapping/LIWC_belief.csv`
* `bootstrapping/LIWC_truth.csv`
* `bootstrapping/LIWC_neutral.csv`

#### Extended Data Figure 3
* `bootstrapping/NG_coverage.csv`
* `bootstrapping/independent_coverage.csv`

#### Extended Data Figure 4
* `articles/article_scores_with_parties.csv.gzip`

#### Supplementary Figure 1
* `bootstrappng/user_reliability_score_correlations.csv`