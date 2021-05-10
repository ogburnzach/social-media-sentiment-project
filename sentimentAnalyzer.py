from Database import Database

class sentimentAnalyzer():

#setup class variables
    sentimentDict = []
    wordList = []
#these attributes allow for the database connection to the Sentiment tables
    databaseURL = ""
    databaseUsername = ""
    databasePassword = ""
    queryDatabase = "Sentiment"


#create instance of object and call method to initialize self.sentimentDict
    def __init__(self):
        #connect to database and set it up to access Sentiment tables
        self.dbSentiment = Database(self.databaseURL, self.databaseUsername, self.databasePassword, self.queryDatabase)
        self.getSentimentList()

    def getSentimentList(self):
        #Create a list of tuples of sentiment terms and values which are stored in the database
        self.sentimentDict = self.dbSentiment.QUERY("SELECT * FROM Lexicon ")
        tempDict = {}
        #get a list of all words in the sentiment database
        self.wordList = [x[1] for x in self.sentimentDict]

        #this block of code turns the nested list of sentiment dictionary data into a single dictionary of the sentiment table with the words as the keys
        tempDict = [{x[1]:[x[2], x[3]]} for x in self.sentimentDict]
        self.sentimentDict = {}
        for dict in tempDict:
            self.sentimentDict.update(dict)

#this function takes in a tweet body string and computes the sentiment score for both positive and negative words
    def sentimentAnalysis(self, tweetStr):


#split tweet string into a list of words and strip unnecessary characters
        tempStr = tweetStr.split()
        tweetWordList = [x.strip("#@',.!:;").lower() for x in tempStr]

        tweetPosScore = 0
        tweetNegScore = 0
#loop through tweet string word list and calculate the sentiment score for the whole tweet
        for word in tweetWordList:
            if word in self.wordList:
                #print(word, " : ", self.sentimentDict[word])
                tweetPosScore += self.sentimentDict[word][0]
                tweetNegScore += self.sentimentDict[word][1]
        print("\n\n\n")
        #return the positive and negative sentiment scores as ints
        return(tweetPosScore, tweetNegScore)