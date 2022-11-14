#!/bin/bash
source_path="/data/honesty/code/Honesty-project/labeling"
#all-mpnet-base-v2
#sentence-transformers/average_word_embeddings_glove.6B.300d
model_name_or_path="sentence-transformers/average_word_embeddings_glove.840B.300d"
#python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
#	--input_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label.csv"\
#	--output_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label_DDR_glove840B.csv" \
#	--truth_lexicon "/data/honesty/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
#	--belief_lexicon "/data/honesty/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
#	--avg_dict --average_of_similarity 
#	--corpus Twitter
	#--use_word_definition --maximum_of_similarity


#python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
#	--input_file "/data/honesty/corpora/NYT/NYT-API/1980_2021/NYT_id_text_section_majority_vote_p_0.05_swapped.csv"\
#	--output_file "/data/honesty/corpora/NYT/NYT-API/1980_2021/NYT_id_text_section_majority_vote_p_0.05_swapped_label_DDR_glove840B.csv" \
#	--truth_lexicon "/data/honesty/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
#	--belief_lexicon "/data/honesty/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
#	--avg_dict --average_of_similarity 


python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "/data/honesty/corpora/articles/full_links_with_text_and_honesty.csv.gzip"\
	--output_file "/data/honesty/corpora/articles/full_links_with_text_and_honesty_p_0.05_swapped_label_DDR_glove840B.csv.gzip" \
	--truth_lexicon "/data/honesty/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "/data/honesty/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--text_column "link_text" --compression_type "gzip" \
	--avg_dict --average_of_similarity 
