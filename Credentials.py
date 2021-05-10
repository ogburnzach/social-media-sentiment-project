
#This class contains the login credentials for Twitter API and SQL database
class Credentials:

    oathConsumerKey = ""
    oathSecretKey = ""
    accesssToken = ""
    accessTokenSecret = ""

    databaseURL = ""
    databaseUsername = ""
    databasePassword = ""

    queryDatabaseSM = "SocialMedia"
    queryDatabaseSA = "Sentiment"

    hashtagField = "ClubHash"
    databaseHashTable = "TwitterClubs"
    databaseTweetTable = "TwitterTweets"
    databaseGabTable = "Gab_Posts"

    queryDatabase = ""
    table = ""

    def __init__(self):
        pass

    def setupGabCredentials(self):
       self.queryDatabase = self.queryDatabaseSM
       self.table = self.databaseGabTable

    def setupTwitterCredentials(self):
        self.queryDatabase = self.queryDatabaseSM
        self.table = self.databaseTweetTable



    def setupSentimentCredentials(self):
        self.queryDatabase = self.queryDatabaseSA
