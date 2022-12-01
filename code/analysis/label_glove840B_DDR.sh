#!/bin/bash

source_path="./"
model_name_or_path="../../data/utilities/sentence-transformers/average_word_embeddings_glove.840B.300d"

# compute belief-speaking and truth-seeking similarities for the twitter corpus 
# using the glove embedding
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_clean.csv.gzip"\
	--output_file "../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_honesty_component_scores_glove.csv.gzip"\
	--truth_lexicon "../../data/utilities/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "../../data/utilities/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--avg_dict --average_of_similarity\
    --compression_type "gzip"\
	--corpus "Twitter"\
    #--smoke_test

# compute belief-speaking and truth-seeking similarities for the articles corpus
# using the glove embedding
if [ -f ../../data/articles/article_corpus_clean.csv.gz ]; then
   mv ../../data/articles/article_corpus_clean.csv.gz ../../data/articles/article_corpus_clean.csv.gzip
fi
  
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "../../data/articles/article_corpus_clean.csv.gzip"\
	--output_file "../../data/articles/article_corpus_clean_honesty_component_scores_glove.csv.gzip" \
	--truth_lexicon "../../data/utilities/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "../../data/utilities/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--compression_type "gzip" \
	--avg_dict --average_of_similarity\
    --corpus "Articles"\
    --text_column "link_text"\
    #--smoke_test

# compute the belief-speaking and truth-seeking similarities for the NYT corpus
# using the glove embedding
# NOTE: as we cannot publicly share the NYT articles corpus, you will have to
# collect them yourself using their API: https://developer.nytimes.com/apis
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path {model_name_or_path}\
	--input_file "../../data/NYT/NYT_abstracts.csv.gzip"\
	--output_file "../../data/NYT/NYT_abstracts_honesty_component_scores_glove.csv.gzip" \
	--truth_lexicon "../../data/utilities/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "../../data/utilities/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--avg_dict --average_of_similarity\
   --compression_type "gzip"\
   --corpus "NYT"\
    #--smoke_test
