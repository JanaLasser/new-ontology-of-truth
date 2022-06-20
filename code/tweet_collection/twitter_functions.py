import json
from os.path import join
from twarc import Twarc2
import datetime
import time
import pandas as pd
import numpy as np

def get_user_timelines(info):
    '''
    Gets the user timelines for a list of user IDs and dumps them into json
    files.
    '''
    IDs = info["IDs"]
    start_time = info["start"]
    end_time = info["end"]
    dst = info["dst"]
    
    bearer_token = info["bearer_token"]
    client = Twarc2(bearer_token=bearer_token)
    for ID in IDs:
        fname = f"{ID}_usertimeline_{str(start_time.date())}_to_{str(end_time.date())}.json"
        with open(join(dst, fname), 'a') as f:
            for tweet_bunch in client.timeline(ID, 
                                start_time=start_time,
                                end_time=end_time):
                json.dump(tweet_bunch, f)
                f.write('\n')
                    
                    
def get_twitter_API_credentials(namelist=['jana', 'david', 'max', 'hannah',\
                        'alina', 'anna'], keydst="twitter_API_keys"):
    '''
    Returns the bearer tokens to access the Twitter v2 API for a list of users.
    '''
    credentials = {}
    for name in namelist:
        tmp = {}
        with open(join(keydst, f"twitter_API_{name}.txt"), 'r') as f:
            for l in f:
                tmp[l.split('=')[0]] = l.split('=')[1].strip('\n')
        credentials[name] = tmp['bearer_token']
    return credentials


def create_crawlinfo(N_tasks, userids, start, end, dst, credentials):
    '''
    Splits the full user ID list into shorter lists that are handled by sub-
    processes. Since we can only hand over a single parameter to the subprocess
    we bundle the ID sublists with other relevant parameters (start time, end
    time, file dump destination and Twitter API access credentials).
    '''
    N_IDs = int(len(userids) / N_tasks) + 1
    task_info = []
    for i in range(N_tasks):
        task_info.append({"IDs":userids[i * N_IDs:(i + 1) * N_IDs],
                         "start":start,
                         "end":end,
                         "dst":dst,
                         "bearer_token":""})

    credlist = list(credentials.values()) * \
                (int(len(task_info) / len(credentials)) + 1)
    for i in range(len(task_info)):
        task_info[i]['bearer_token'] = credlist[i]
    return task_info

def respect_rate_limit(n_calls_in_window, n_max_calls, 
                       window_start, window_width, slack=1):
    '''
    Function to respect the rate limit within a given window 
    '''
    # Check if max allowed calls within the time window is reached
    if n_calls_in_window % n_max_calls == 0:
        curr_time = datetime.datetime.today()
        data_retrieval_duration = (window_start - curr_time).seconds
        sleeptime = (window_width + slack) * 60 - window_width
        print(f"sleeping for {sleeptime}s to respect the rate limit")
        time.sleep(sleeptime)
        return 1, datetime.datetime.today()
    else:
        return n_calls_in_window, window_start
    
def load_json_userprofiles(fname, src):
    json_profiles = []
    with open(join(src, fname), 'r') as f:
        #json_profiles = json.loads(f)
        for line in f:
        #    print("line")
            try:
                json_profiles = json.loads(line)
            except JSONDecodeError:
                print(f"JSONDecodeError for file {fname}")
            
    return json_profiles


def unravel_user_profile_data(user_obj_list):
    tmp = pd.DataFrame()
    for user_obj in user_obj_list['data']:
        row = extract_user_profile_information(user_obj)
        row["retrieved_at"] = user_obj_list["__twarc"]["retrieved_at"]
        tmp = tmp.append(row, ignore_index=True)
        
    return tmp


def extract_user_profile_information(j):
    u = {}
    u['id'] = str(j['id'])
    u['username'] = j['username']
    u['name'] = j['name']
    u['created_at'] = j['created_at']
    u['protected'] = j['protected']
    u['verified'] = j['verified']
    u['followers_count'] = j['public_metrics']['followers_count']
    u['following_count'] = j['public_metrics']['following_count']
    u['tweet_count'] = j['public_metrics']['tweet_count']
    u['listed_count'] = j['public_metrics']['listed_count']
    u['description'] = j['description']
    u['profile_image_url'] = j["profile_image_url"]
    u['url'] = j['url']
                
    return u


def load_json_timeline(ID, src):
    json_timeline = []
    with open(join(src,
        f'{ID}_usertimeline_2010-11-06_to_2021-12-14.json'), 'r') as f:
        for line in f:
            try:
                json_timeline.append(json.loads(line))
            except JSONDecodeError:
                print(f"JSONDecodeError for ID {ID}")
            
    return json_timeline


def unravel_data(tl_obj):
    tmp = pd.DataFrame()
    for j in tl_obj['data']:
        tmp = tmp.append(extract_tweet_information(j), ignore_index=True)
        
    return tmp


def extract_tweet_information(j):
    t = {}
    t['id'] = '"{}"'.format(j['id'])
    t['author_id'] = '"{}"'.format(j['author_id'])
    t['conversation_id'] = '"{}"'.format(j['conversation_id'])
    t['created_at'] = j['created_at']
    t['lang'] = j['lang']
    t['text'] = j['text']
    t['retweet_count'] = j['public_metrics']['retweet_count']
    t['reply_count'] = j['public_metrics']['reply_count']
    t['like_count'] = j['public_metrics']['like_count']
    t['quote_count'] = j['public_metrics']['quote_count']
    t['urls'] = []
    t['reference_type'] = []
    t['expanded_urls'] = []
    t['geo'] = np.nan
    
    if 'entities' in j.keys():
        if 'urls' in j['entities'].keys():
            for url in j['entities']['urls']:
                t['urls'].append(url['url'])
                t['expanded_urls'].append(url['expanded_url'])
            
    if 'geo' in j.keys():
        try:
            t['geo'] = j['geo']['place_id']
        except KeyError:
            pass
        
    if 'referenced_tweets' in j.keys():
        for rt in j['referenced_tweets']:
            if 'type' in rt.keys():
                t['reference_type'].append(rt['type'])
                
            
    return t

def check_retweet(reference_list):
    if reference_list != reference_list or reference_list == None: # nan-check
        return False
    else:
        if 'retweeted' in reference_list:
            return True
        else:
            return False
        
        
def check_quoted(reference_list):
    if reference_list != reference_list or reference_list == None: # nan-check
        return False
    else:
        if 'quoted' in reference_list:
            return True
        else:
            return False
        
def check_reply(reference_list):
    if reference_list != reference_list or reference_list == None: # nan-check
        return False
    else:
        if 'replied_to' in reference_list:
            return True
        else:
            return False
        
def extract_domain(url):
    if url != url:
        return np.nan
    # reformat entries that have the domain after a general name in parantheses
    if url.find('(') > 0:
        url = url.split('(')[-1]
        url = url.strip(')')
    # trailing "/" and spaces
    url = url.strip('/').strip()
    # transform all domains to lowercase
    url = url.lower()
    # remove any white spaces
    url = url.replace(' ', '')
    # if present: remove the protocol
    if url.startswith(("http", "https")):
        try:
            url = url.split('//')[1]
        except IndexError:
            print(f"found malformed URL {url}")
            return np.nan
    # remove "www." 
    url = url.replace('www.', '')
    url = url.split("/")[0]
    return url


