# author: Segun Aroyehun

from pathlib import Path
from os.path import join
import argparse
import multiprocessing as mp
import spacy
from spacy.matcher import PhraseMatcher
import pandas as pd
from collections import Counter
from tqdm import tqdm
from pandarallel import pandarallel
pandarallel.initialize(nb_workers=100 )#progress_bar=True

def config(parser):
    parser.add_argument('--input_file')
    parser.add_argument('--corpus')
    parser.add_argument('--filter_liwc', default=False, action='store_true')
    parser.add_argument('--mask_match', default=False, action='store_true')
    parser.add_argument('--mask_all', default=False, action='store_true')
    parser.add_argument('--split_df', default=False, action='store_true')
    parser.add_argument('--output_file')
    parser.add_argument('--threshold', type=int)
    return parser

nlp = spacy.load("en_core_web_sm", disable = ['ner'])#, 'parser'

matcher = PhraseMatcher(nlp.vocab, attr='LEMMA')
 
#load lexica into phrase_dict
#df = pd.read_csv('lexicons.csv') #combine lexicons in a single file with header
#read lexicon files  with pandas
#convert to dicts and merge into phrase_dict
src = "../../data/utilities/"
belief_speaking_df = pd.read_csv(join(src, 'belief_speaking_lemmav3.csv'))
belief_dict = belief_speaking_df.to_dict(orient='list')
seeking_understanding_df = pd.read_csv(join(src, 'seeking_understanding_lemmav3.csv'))
understanding_dict = seeking_understanding_df.to_dict(orient='list')
truth_seeking_df = pd.read_csv(join(src, 'truth_seeking_lemmav3.csv'))
truth_dict = truth_seeking_df.to_dict(orient='list')

phrase_dict = {**belief_dict, **understanding_dict, **truth_dict}
#add rules
for key in phrase_dict.keys(): #keys--as categories
    phrase_match = [nlp(term) for term in phrase_dict[key]]
    matcher.add(key, phrase_match)
mask_matcher = PhraseMatcher(nlp.vocab, attr='LEMMA')
mask_list = pd.read_csv(join(src, 'mask_list.csv'), header=None)
mask_list = mask_list[0].values.tolist()

mask_matcher.add('mask', [nlp(term) for term in mask_list])
def get_matches(file):
    result = {'documents':[], 'category':[], 'terms':[]}
    #texts = [line for line in open(file, 'r')]
    for text in open(file, 'r'):
        nlp.max_length = len(text) + 100
        doc = nlp(text)
        if matcher(doc):
            for m in matcher(doc):
                match_id, start, end = m 
                rule_id = nlp.vocab.strings[match_id]
                result['documents'].append(doc.text)
                result['category'].append(rule_id)
                result['terms'].append(doc[start:end].text)
    return result
def get_text_matches(text):
    belief_terms, truth_terms, understanding_terms = [], [], []
    nlp.max_length = len(text) + 100
    doc = nlp(text)
    words = [t.text.lower() for t in doc if t.pos_ not in ['PUNCT', 'NUM', 'SYM', 'SPACE',]]
    word_count = len(words)

    if matcher(doc):
        for m in matcher(doc):
            match_id, start, end = m 
            rule_id = nlp.vocab.strings[match_id]
            if 'belief' in rule_id:
                belief_terms.append(doc[start:end].text)
            elif 'truth' in rule_id:
                truth_terms.append(doc[start:end].text)
            elif 'understanding' in rule_id:
                understanding_terms.append(doc[start:end].text)
    return  pd.Series([belief_terms, len(belief_terms), truth_terms, len(truth_terms), understanding_terms,\
         len(understanding_terms), word_count])
def mask_match(text):
    nlp.max_length = len(text) + 100
    doc = nlp(text)
    if mask_matcher(doc):
        for m in matcher(doc):
            match_id, start, end = m 
            match_term = doc[start:end].text
            text = text.replace(match_term, '#')
    return text
def mask_full_list(text):
    nlp.max_length = len(text) + 100
    doc = nlp(text)
    if matcher(doc):
        for m in matcher(doc):
            match_id, start, end = m 
            match_term = doc[start:end].text
            text = text.replace(match_term, '#')
    return text

def mask_matches_full(args):
    if args.corpus == 'Twitter':
        usecols=['id','text', 'retweeted']  
    else:
        usecols=['id','text']

    df = pd.read_csv(
        args.input_file,
        error_bad_lines=False,
        warn_bad_lines=True,
        usecols=usecols,
        compression="gzip"
    )
    df = preprocess(df, args)
    df['text'] = df.text.parallel_apply(mask_full_list)
    df = df[['id','text']]
    if args.split_df:
        from more_itertools import sliced
        import math
        chunk_size = math.ceil(len(df)/4)
        for i, chunk in enumerate(sliced(df,chunk_size)):
            chunk.to_csv(f'{args.corpus}_id_maskalltext{i}.csv', index=False)
    else:
        df.to_csv(f'{args.corpus}_id_maskalltext.csv', index=False)

def mask_matches(args):
    df = pd.read_csv(args.input_file, error_bad_lines=False, warn_bad_lines=True)#, nrows=10000
    df = preprocess(df, args)
    df['text'] = df.text.parallel_apply(mask_match)
    if args.corpus == 'NYT':
        from more_itertools import sliced
        import math
        chunk_size = math.ceil(len(df)/4)
        for i, chunk in enumerate(sliced(df,chunk_size)):
            chunk.to_csv(f'{args.corpus}_id_maskedtext{i}.csv', index=False)
    else:
        df.to_csv(f'{args.corpus}_id_maskedtext.csv', index=False)
    
    
def get_lemma(x):
    x = ' '.join([w.lower() for w in x.split()])
    lemma = ' '.join([t.lemma_ for t in nlp(x)])
    return lemma
def compute_df(df):
    
    for cat in df.category.unique():
        df_cat = df[df['category'] == cat]
        count_frame = df_cat.lemma.value_counts().to_frame(name="")
        count_frame.reset_index(inplace=True)
        count_frame.columns = ['vocab', 'freq']
        if cat == 'truth_seeking':
            vocab_df = truth_seeking_df
        elif cat == 'belief_speaking':
            vocab_df = belief_speaking_df
        elif cat == 'seeking_understanding':
            vocab_df = seeking_understanding_df
        vocab_df.columns = ['vocab']
        vocab_df.join(count_frame.set_index('vocab'), on='vocab', how='left').to_csv(
                            f'{cat}_dfcomb.csv', index=False, header=None)
def preprocess(df, args):
    df.replace(to_replace=[r"(?:https?:\/\/(?:www\.|(?!www))[^\s\.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,})"], value=[""], 
            regex=True, inplace=True)
    df.replace(to_replace=r"&.*;", value="", regex=True, inplace=True)
    df.replace(to_replace=[r"\\t|\\n|\\r", "\t|\n|\r"], value=["",""], regex=True, inplace=True) 
    df.replace(to_replace=r"\s+", value=" ", regex=True, inplace=True)
    df.replace(to_replace=r"\@\w+", value="user", regex=True, inplace=True)

    df = df.drop_duplicates(subset='text',keep='first')
    df = df.drop_duplicates(subset='id',keep='first')
    if args.corpus == 'Twitter':
        if 'retweeted' in df.columns:
            df = df[~df.retweeted]
        def tw_len(x):
            x = x.split()
            x_filter = filter(lambda x: x != 'user', x)
            x_filter = list(x_filter)
            return len(x_filter)
        df['length'] = df.text.parallel_apply(tw_len)
    else:
        df['length'] = df.text.parallel_apply(lambda x: len(x.split()))
    df = df[df.length > 10]
    return df

def filter_liwc(args):
    df = pd.read_csv(args.input_file, error_bad_lines=False, warn_bad_lines=True)#, nrows=10000
    df = preprocess(df)
    cols = ["id", "belief_count", "truth_count"]
    df[cols].to_csv(f'{args.corpus}_{args.output_file} + .gzip', 
                    index=False, compression="gzip")


def main(args):
    df = pd.read_csv(args.input_file, error_bad_lines=False, warn_bad_lines=True, low_memory=False)#, nrows=10000
    df = preprocess(df, args)

    df[['belief_terms','belief_count','truth_terms','truth_count', 'understanding_terms', 'understanding_count','word_count']] \
    = df.text.parallel_apply(get_text_matches)
    #df['max_label'] = df[['belief_count', 'truth_count', 'understanding_count']].apply(classify, axis=1)

    
    df[['belief_label', 'truth_label']] = df[['belief_count', 'truth_count']].apply(classify_majority, axis=1)
    #df = df[df['label']!="unknown"]
    #df[['belief_label', 'truth_label', 'understanding_label']] \
    #= df[['belief_count', 'truth_count', 'understanding_count']].apply(classify_threshold, args=(args.threshold,), axis=1)
    df.to_csv(args.output_file, index=False)
    #print(df.groupby('max_label')['max_label'].value_counts())

def classify_threshold(x, threshold):
    belief_label = 0 if x['belief_count'] < threshold else 1
    truth_label = 0 if x['truth_count'] < threshold else 1
    understanding_label = 0 if x['understanding_count'] < threshold else 1
    return  pd.Series([belief_label, truth_label, understanding_label])

def classify_majority(x):
    belief_label = 0 if x['belief_count'] < x['truth_count'] or  x['belief_count'] == 0 else 1
    truth_label = 0 if x['truth_count'] < x['belief_count'] or x['truth_count'] == 0 else 1
    return  pd.Series([belief_label, truth_label])

def classify(x):
    x = x.values.tolist()
    cat = ['belief','truth','understanding']
    if sum(x) == 0:
        label = "unknown"
    else:
        max_val = max(x)
        max_idx = x.index(max_val) 
        label = cat[max_idx]
    return label
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser = config(parser)
    args = parser.parse_args()
    if args.filter_liwc:
        filter_liwc(args)
    elif args.mask_match:
        mask_matches(args)    
    elif args.mask_all:
        mask_matches_full(args)    
    else:
        main(args)
