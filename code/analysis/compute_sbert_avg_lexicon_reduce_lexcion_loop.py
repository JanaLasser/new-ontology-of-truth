from sentence_transformers import SentenceTransformer, util, models
import pickle
import argparse
import numpy as np
import pandas as pd
import torch
from tqdm import tqdm
from pandarallel import pandarallel
pandarallel.initialize(nb_workers=100 )

def config(parser):
    parser.add_argument('--model_name_or_path')
    parser.add_argument('--input_file')
    parser.add_argument('--output_file')
    parser.add_argument('--truth_lexicon')
    parser.add_argument('--belief_lexicon')
    parser.add_argument('--avg_dict', action="store_true")
    parser.add_argument('--verbalize_label', action="store_true")
    parser.add_argument('--save_embeddings', action="store_true")
    parser.add_argument('--use_word_definition', action="store_true")
    parser.add_argument('--use_definition', action="store_true")
    parser.add_argument('--use_example', action="store_true")
    parser.add_argument('--average_of_similarity', action="store_true")
    parser.add_argument('--maximum_of_similarity', action="store_true")
    parser.add_argument('--smoke_test', action="store_true")
    parser.add_argument('--text_column', type=str, default='text')
    parser.add_argument('--corpus', type=str)
    parser.add_argument('--compression_type', type=str, default='infer')
    parser.add_argument('--length_threshold', type=int, default=10)
    parser.add_argument('--tab_delimiter', action="store_true")
    parser.add_argument('--N_bootstrap', type=int, default=100)
    return parser 

def preprocess(df, args):
    df.replace(to_replace=[r"(?:https?:\/\/(?:www\.|(?!www))[^\s\.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,})"], value=[""], 
            regex=True, inplace=True)
    df.replace(to_replace=r"&.*;", value="", regex=True, inplace=True)
    df.replace(to_replace=[r"\\t|\\n|\\r", "\t|\n|\r"], value=["",""], regex=True, inplace=True) 
    df.replace(to_replace=r"\s+", value=" ", regex=True, inplace=True)
    df.replace(to_replace=r"\@\w+", value="@user", regex=True, inplace=True)

    if 'text' in df.columns:
        df = df.drop_duplicates(subset='text',keep='first')
    if 'id' in df.columns:
        df = df.drop_duplicates(subset='id',keep='first')
        df['id'] = df['id'].replace('"', '')
    if args.corpus == 'Twitter':
        if 'retweeted' in df.columns:
            df = df[~df.retweeted]
        def tw_len(x):
            x = str(x).split()
            x_filter = filter(lambda x: x != '@user', x)
            x_filter = list(x_filter)
            return len(x_filter)
        df['length'] = df.text.parallel_apply(tw_len)
    else:
        df['length'] = df.text.parallel_apply(lambda x: len(x.split()))
    if args.length_threshold:
        df = df[df.length > args.length_threshold]
    return df

def get_embeddings(text, model_name_or_path):
    model = SentenceTransformer(model_name_or_path)

    #encode text in batches perhaps save this to disk
    corpus_embeddings = model.encode(text, batch_size=1024, show_progress_bar=True, convert_to_tensor=True) 
    assert len(corpus_embeddings) == len(text)
    return corpus_embeddings

def compute_similarity(text_embeddings, label_embeddings):
    cos_sim = util.cos_sim(text_embeddings, label_embeddings)
    return cos_sim

#leave-one-out
def leave_one_keyword_out(keywords):
    sample_keywords = []
    for elem in keywords:
        tmp = keywords.copy()
        tmp.remove(elem)
        sample_keywords.append(tmp)
    return sample_keywords

def reduce_keywords_by_frac(keywords, frac=0.2):
    import random
    sample_keywords = []
    n = (1-frac) * len(keywords)
    n = round(n)
    for i in range(args.N_bootstrap):
        sample_keyword = random.sample(keywords, n)
        sample_keywords.append(sample_keyword)
    return sample_keywords

def main(args):
    delimiter = '\t' if args.tab_delimiter else None
    if args.smoke_test:
        df = pd.read_csv(
            args.input_file, 
            nrows=1000, 
            compression=args.compression_type,
            delimiter=delimiter,
            dtype={"id":str}
        )
    else:
        df = pd.read_csv(
            args.input_file, 
            compression=args.compression_type, 
            delimiter=delimiter,
            dtype={"id":str}
        )
        
    #rename text column if different from text
    if args.text_column != 'text':
        df.rename(columns = {args.text_column:'text'}, inplace = True)
    df = preprocess(df, args)
    all_text = df['text']
    all_text = list(all_text)
    text_embeddings = get_embeddings(all_text, args.model_name_or_path)       

    if args.save_embeddings:
        output_fn = args.output_file.replace(".csv", ".pkl")
        with open(output_fn, "wb") as fout:
            pickle.dump(
                {'text': all_text, 'embeddings': text_embeddings},
                fout, 
                protocol=pickle.HIGHEST_PROTOCOL
            )

    truth_keywords = pd.read_csv(args.truth_lexicon) 

    if args.verbalize_label:
        truth_keywords = ["The text expresses "+ l for l in list(truth_keywords['truth_seeking'])] 
    elif args.use_definition:
        truth_keywords = list(truth_keywords['definition'])
    elif args.use_word_definition:
        truth_keywords = list(truth_keywords['truth_seeking'] + " " + truth_keywords['definition'])
    elif args.use_example:
        truth_keywords = list(truth_keywords['example'].dropna())
    else:
        truth_keywords = list(truth_keywords['truth_seeking'])  
    
    truth_keywords_sample = reduce_keywords_by_frac(truth_keywords)
    for i, truth_kw in enumerate(tqdm(truth_keywords_sample)):
        truth_embeddings = get_embeddings(truth_kw, args.model_name_or_path)
        #print(truth_embeddings.shape)
        if args.avg_dict:
            truth_embeddings = torch.mean(truth_embeddings, dim=0)
        #print(truth_embeddings.shape)
        truth_sim = util.cos_sim(text_embeddings, truth_embeddings)
        df[f'avg_truth_score_{i}'] = truth_sim.cpu().numpy()

    df = df.copy()
    belief_keywords = pd.read_csv(args.belief_lexicon) 
    if args.verbalize_label:
        belief_keywords = ["The text expresses "+ l for l in belief_keywords] 
    elif args.use_definition:
        belief_keywords = list(belief_keywords['definition'])
    elif args.use_word_definition:
        belief_keywords = list(belief_keywords['belief_speaking'] + " " + belief_keywords['definition'])
    elif args.use_example:
        belief_keywords = list(belief_keywords['example'].dropna())
    else:
        belief_keywords = list(belief_keywords['belief_speaking'])  

    belief_keywords_sample = reduce_keywords_by_frac(belief_keywords)
    for i, belief_kw in enumerate(tqdm(belief_keywords_sample)):
        belief_embeddings = get_embeddings(belief_kw, args.model_name_or_path)
        if args.avg_dict:
            belief_embeddings = torch.mean(belief_embeddings, dim=0)
        belief_sim = util.cos_sim(text_embeddings, belief_embeddings)
        df[f'avg_belief_score_{i}'] = belief_sim.cpu().numpy()

    output_cols = ["id"] + \
                  [f"avg_belief_score_{i}" for i in range(args.N_bootstrap)] + \
                  [f"avg_truth_score_{i}" for i in range(args.N_bootstrap)]
    df['id'] = df['id'].str.replace('"', '')
    df[output_cols].to_csv(
        args.output_file, 
        index=False, 
        compression=args.compression_type
    )
        
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser = config(parser)
    args = parser.parse_args()
    main(args)
