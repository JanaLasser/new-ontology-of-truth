import argparse
import pandas as pd
import numpy as np
from os.path import join
import sys
from os import getcwd

import asyncio
import aiohttp
import time

description = '''Program to unravel a list of shortened URLs'''

parser = argparse.ArgumentParser(description=description)

parser.add_argument('url_list', type=str, 
                    help='Path to the list of URLs')

parser.add_argument('-dst', '--destination', type=str, 
                    help='Path to the results directory',
                    default=getcwd())

parser.add_argument('-n', '--batch_size', type=int, 
                    help='Size of requested URL batches',
                    default=100)

parser.add_argument('-v','--verbosity', type=int,
                    help='Verbosity level: ' +\
                         '0 (no output), '+\
                         '1 (some output), '+\
                         '2 (debug)',
                    default=1)

parser.add_argument('-dst_fname','--destination_filename', type=str,
                    help='Name of the file with the unraveled urls.',
                    default="unraveled_urls")

parser.add_argument('-t','--timeout', type=int,
                    help='Maximum duration of a request in seconds.',
                    default=100)

def get_url_list(src):
    src = src.split("/")[-1]
    file_name_parts = src.split(".")
    if len(file_name_parts) == 3:
        file_type = file_name_parts[1]
        compression = file_name_parts[2]
    elif len(file_name_parts) == 2:
        file_type = file_name_parts[1]
        compression = False
    else:
        print(f"weird file name {src}. Exiting.")
        sys.exit()

    if file_type == "csv" and compression:
        df = pd.read_csv(src, compression=compression)
        url_list = df["url"].values

    elif file_type == "csv" and not compression:
        df = pd.read_csv(src)
        url_list = df["url"].values

    elif file_type == "txt":
        url_list = np.load_txt(src, dtype=str)

    else:
        print(f"unknown file type {file_type}. Exiting.")
        sys.exit()

    return url_list, compression


async def get(url, session):
    try:
        if verbosity > 1:
            print(f"trying {url}")
        async with session.head(url=url, allow_redirects=True) as response:
            resp = await response.read()
            return response
    except Exception as e:
        return e


async def request_urls(urls):
    timeout = aiohttp.ClientTimeout(total=max_timeout, connect=5)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        ret = await asyncio.gather(*[get(url, session) for url in urls])
    return ret


def extract_unraveled_urls(urls, responses):
    df = pd.DataFrame()
    for url, resp in zip(urls, responses):
        if type(resp) == aiohttp.client_reqrep.ClientResponse:
            unraveled_url = str(resp.real_url)
            row = pd.DataFrame({
                "url":[url],
                "unraveled_url":[unraveled_url],
                "status_code":[resp.status]
            })
        else:
            row = pd.DataFrame({
                "url":[url],
                "unraveled_url":[str(resp)],
                "status_code":[pd.NA]
            })
        df = pd.concat([df, row])
    return df


def main():
    url_list, compression = get_url_list(src)

    n_batches = int(np.ceil(len(url_list) / batch_size))
    data_batches = [url_list[i * batch_size: (i + 1) * batch_size] \
                    for i in range(n_batches)]

    for i, urls in enumerate(data_batches):
        start = time.time()
        responses = asyncio.run(request_urls(urls))
        end = time.time()

        if verbosity:
            print(f"finished batch {i+1}/{n_batches}, took {end - start} seconds to retrieve")
        
        unraveled_urls = extract_unraveled_urls(urls, responses)
        unraveled_urls["unraveled_url"] = unraveled_urls["unraveled_url"]\
            .apply(lambda x: np.nan if x==np.nan else \
                   str(x).encode('utf-8', 'replace').decode('utf-8'))

        if compression:
            fname = f"{dst_fname}_{i+1}.csv.{compression}"
            unraveled_urls.to_csv(join(dst, fname), compression="gzip", 
                                  index=False)
        else:
            fname = f"{dst_fname}_{i+1}.csv"
            unraveled_urls.to_csv(join(dst, fname), index=False)


if __name__ == "__main__":
    args = parser.parse_args()
    src = args.url_list
    dst = args.destination
    batch_size = args.batch_size
    verbosity = args.verbosity
    dst_fname = args.destination_filename
    max_timeout = args.timeout
    main()
