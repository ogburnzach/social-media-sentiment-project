from Database import Database
from streamListener import StreamListener
from sentimentAnalyzer import sentimentAnalyzer
from gabListener import gabListener
import time
import threading
from Credentials import Credentials

def main():
#credentials for Twitter API and for the SQL database

    credGab = Credentials()
    credGab.setupGabCredentials()

    credTwitter = Credentials()
    credTwitter.setupTwitterCredentials()

    credSentiment = Credentials()
    credSentiment.setupSentimentCredentials()

    gab1 = gabListener("", "", credGab)

    gabThread = threading.Thread(target=gab1.run)

    gabThread.start()

    listener1 = StreamListener()
    listener1.run(credTwitter)

    #gabThread = threading.Thread(target=gab1.run)

main()