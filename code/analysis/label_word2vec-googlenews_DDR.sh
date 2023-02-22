#!/bin/bash

source_path="./"
model_name_or_path="../../data/utilities/sentence-transformers/word2vec-googlenews-model"

# compute belief-speaking and truth-seeking similarities for the twitter corpus 
# using the glove embedding
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_clean.csv.gzip"\
	--output_file "../../data/tweets/combined_US_politician_twitter_timelines_2010-11-06_to_2022-12-31_honesty_component_scores_word2vec.csv.gzip"\
	--truth_lexicon "../../data/utilities/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "../../data/utilities/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--avg_dict --average_of_similarity\
    --compression_type "gzip"\
	--corpus "Twitter"\
   #--smoke_test