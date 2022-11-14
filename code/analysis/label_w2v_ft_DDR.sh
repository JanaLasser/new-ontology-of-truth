source_path="/data/honesty/code/Honesty-project/labeling"
#all-mpnet-base-v2
#sentence-transformers/average_word_embeddings_glove.6B.300d
model_name_or_path="/data/honesty/corpora/word2vec-googlenews-model/"
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label.csv"\
	--output_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label_DDR_word2vec.csv" \
	--truth_lexicon "/data/honesty/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "/data/honesty/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--avg_dict --average_of_similarity \
	--corpus Twitter 
	#--smoke_test



model_name_or_path="/data/honesty/corpora/fasttext-cc-model/"
python ${source_path}/compute_sbert_avg_lexicon.py --model_name_or_path ${model_name_or_path}\
	--input_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label.csv"\
	--output_file "/data/honesty/corpora/Twitter/combined_US_politician_twitter_timelines_2010-11-06_to_2022-03-16_p0.05_swapped_label_DDR_fasttext.csv" \
	--truth_lexicon "/data/honesty/truth_seeking_p=0.05_swapped_wn_def_example.csv"\
	--belief_lexicon "/data/honesty/belief_speaking_p=0.05_swapped_wn_def_example.csv"\
	--avg_dict --average_of_similarity \
	--corpus Twitter 
	#--smoke_test
