import newspaper
from newspaper import Article
from newspaper.configuration import Configuration

config = Configuration()
config.request_timeout = 10

#read url from r
url = r.url 

#download and parse article
article = Article(url, config=config)
article.download()
article.parse()

#extract article text to call from r
article_text = article.text
