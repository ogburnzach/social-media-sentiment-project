from garc import Garc
from bs4 import BeautifulSoup
from Database import Database
from sentimentAnalyzer import sentimentAnalyzer
from time import sleep

class gabListener():

    gabIDList = []
    gabUsernameList = []
    gabDateList = []
    gabContentList = []
    gabHashtagList = []
    gabRetweetList = []
    gabPosScoreList = []
    gabNegScoreList = []
    dbObj = None
    tags = []
    garcObj = None
    sentObj = None

    def __init__(self, userName, password, dbCredentials):
#create garc object which allows us to interact with Gab API
        self.garcObj = Garc(userName, password)

        #temporary db connection to grab hashtags
        tempDBConnection = Database(dbCredentials.databaseURL, dbCredentials.databaseUsername, dbCredentials.databasePassword, "SocialMedia")
        tempList = tempDBConnection.QUERYTags("SELECT %s FROM %s" % (dbCredentials.hashtagField, dbCredentials.databaseHashTable))
#create db connection to upload Gabs
        self.dbObj = Database(dbCredentials.databaseURL, dbCredentials.databaseUsername, dbCredentials.databasePassword, dbCredentials.queryDatabase)
        #create sentiment analyzer obj
        self.sentObj = sentimentAnalyzer()
        #strip '#' from hashtags
        for tag in tempList:
            self.tags.append(tag.strip("#"))

#Method which searches Gab for posts linked to a certain hashtag
    def getGabs(self, searchHashtag):
#grab raw gab data
            rawGabDataList = list(self.garcObj.search(searchHashtag, gabs=100))
#initialize gab detail lists
            self.gabIDList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabUsernameList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabDateList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabContentList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabHashtagList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabRetweetList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabPosScoreList = [str(x) for x in range(0, len(rawGabDataList))]
            self.gabNegScoreList = [str(x) for x in range(0, len(rawGabDataList))]

#extract relevant data from each individual Gab
#loop through tags in Gab post and pick out a relevant one to include in gab detail list
#if there is a mismatch in the hashtags, then continue to the next post
            for i in range(0, len(rawGabDataList)):
                hashtagError = True
                for tag in rawGabDataList[i]['tags']:
                    if tag['name'] in self.tags:
                        hashtagError = False
                        self.gabHashtagList[i] = tag['name']
                if hashtagError:
                    continue

                self.gabIDList[i] = rawGabDataList[i]['id']
                self.gabDateList[i] = rawGabDataList[i]['created_at']
                self.gabUsernameList[i] = rawGabDataList[i]['account']['username']
                #self.gabRetweetList[i] = int(rawGabDataList[i]['reblogged'])
                if rawGabDataList[i]['reblog'] == None:
                    self.gabRetweetList[i] = 0
                else:
                    self.gabRetweetList[i] = 1
                tempTxt = BeautifulSoup(rawGabDataList[i]['content'], "html.parser").text
                tempTxt = tempTxt.replace(",", " ")
                tempTxt = tempTxt.replace("\n", " ")
                tempTxt = tempTxt.replace("'", "")
                tempTxt = tempTxt.replace("`", "")
                self.gabContentList[i] = tempTxt
#perform Sentiment analysis on Gab text
                (posScore, negScore) = self.sentObj.sentimentAnalysis(self.gabContentList[i])

                self.gabPosScoreList[i] = str(posScore)
                self.gabNegScoreList[i] = str(negScore)
#loop through tags in Gab post and pick out a relevant one to include in gab detail list

                # for tag in rawGabDataList[i]['tags']:
                #     if tag['name'] in self.tags:
                #         self.gabHashtagList[i] = tag['name']

#insert lists of Gabs into db obj to upload to server
            self.dbObj.insertGabs(self.gabIDList, self.gabUsernameList, self.gabDateList, self.gabContentList, self.gabRetweetList, 'Gab_Posts', "hashtagField", self.gabPosScoreList, self.gabNegScoreList, self.gabHashtagList)


    def run(self):
        #This method will search for Gabs related to all of the hashtags one by one , the thread sleeps for 2 minutes to account for slow internet connection

        while True:
            self.getGabs('trump')

            sleep(120)

            self.getGabs('biden')


            sleep(120)

            self.getGabs('republican')


            sleep(120)

            self.getGabs('democrat')

            sleep(3600)


