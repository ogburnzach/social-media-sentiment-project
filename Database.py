import mysql.connector
from mysql.connector import Error

class Database:

#create instance of object by passing in the credentials to log into the SQL Database
    def __init__(self, url, username, password, databaseToConnect):
        self.connection = None
        self.st = None
        self.rSet = None
        self.sqlStatement = None
        self.cursor = None
        self.URL = url
        self.userName = username
        self.password = password
        self.databaseToConnect = databaseToConnect

#open connection to database using the credentials provided to the Database object
    def openConnection(self):
        try:
            self.connection = mysql.connector.connect(
                host = self.URL,
                user = self.userName,
                passwd = self.password,
                database = self.databaseToConnect
            )
            self.cursor = self.connection.cursor()

        except Error as e:
            print("Error: ", e, " occurred")

#close the connection to the SQL Database
    def closeConnection(self):
        try:
            self.connection.close()
            self.connection = None
            self.cursor = None
        except Error as e:
            print("Error: ", e, " occurred")

#method which uploads tweets into the SQL Database
    def insertTweets(self, tweetID, hashtag, tweeter, tweetDate, tweetContent, retweet, tweetsTable, hashtagField, positiveScore, negativeScore):
        print("Inserting Tweets!")
        #open new connection to SQL Database
        self.openConnection()
        #create SQL statement to upload multiple rows into SQL Database at once
        self.sqlStatement = "INSERT IGNORE INTO " + tweetsTable + " (TweetID, " + hashtagField + ", Tweeter, TweetDate, TweetContent, Retweet, TonePos, ToneNeg) VALUES "
        #loop through the provided lists of tweet details to construct the query for all rows
        for x in range(0, len(tweetID)):
            self.sqlStatement += "('" + str(tweetID[x]) + "', '" + hashtag[x] + "', '" + tweeter[x] + "', '" + str(tweetDate[x]) + "', '" + tweetContent[x] + "', " + str(retweet[x]) + ", " + positiveScore[x] + ", " + negativeScore[x] + ")";
            #add comma to SQL query if not on final row
            if (x != len(tweetID) - 1):
                self.sqlStatement += ", "
#execute SQL Database query
        try:
            self.cursor.execute(self.sqlStatement)
            self.connection.commit()
        except Error as e:
            print("\n\n\nError occurred:  ", e, "\n\n")

        self.closeConnection()


#method which uploads tweets into the SQL Database
    def insertGabs(self, gabID, userName, gabDate, gabContent, reblog, gabTable, hashtagField, positiveScore, negativeScore, hashtags):
        print("Inserting Gabs!")
        #open new connection to SQL Database
        self.openConnection()
        #create SQL statement to upload multiple rows into SQL Database at once
        self.sqlStatement = "INSERT IGNORE INTO " + gabTable + " (Post_ID, Post_TimeStamp, Post_Content,Positive_Sentiment, Negative_Sentiment, Gab_Hashtag, Gab_Username, Gab_Reblogged) VALUES "
        #loop through the provided lists of tweet details to construct the query for all rows

        i = 0
        for x in range(0, len(gabID)):
            #this if statement fixes a weird issue where there would be gaps in the gab data
            #the initializing vales of the list (0-100 range) would be inserted into db, this if statement prevents that
            if len(str(gabID[x])) > 4:
                self.sqlStatement += "('" + str(gabID[x]) + "', '" + str(gabDate[x]) + "', '" + gabContent[x] + "', " + positiveScore[x] + ", " + negativeScore[x] + ", '" + hashtags[x] + "', '" + userName[x] + "', " + str(reblog[x]) + ")";
                #add comma to SQL query
                self.sqlStatement += ", "
#execute SQL Database query
        try:
            #this if statement removes the final comma from the SQL string, which prevents a SQL syntax error
            if (self.sqlStatement[len(self.sqlStatement)-2:] == ", "):
                modSQL = self.sqlStatement[:len(self.sqlStatement) - 2]
                self.cursor.execute(modSQL)
                self.connection.commit()
            else:
                self.cursor.execute(self.sqlStatement)
                self.connection.commit()

        except Error as e:
            print("\n\n\nError occurred:  ", e, "\n\n")

        self.closeConnection()

#method which takes in a string SQL query and returns a list of the results
    def QUERY(self, sqlStatement):
        outputList = []
        self.openConnection()

        self.cursor.execute(sqlStatement)
        for element in self.cursor:
            outputList.append(element)

        self.closeConnection()
        return outputList

#method which will return a list of the hashtags which are stored in the SQL Database
    def QUERYTags(self, sqlStatement):
        outputList = []

        self.openConnection()

        self.cursor.execute(sqlStatement)
        for element in self.cursor:
            outputList.append('#'+element[0])
        self.closeConnection()

        return outputList

