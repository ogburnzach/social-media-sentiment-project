library(shiny)
#pool library is used for database connection and data retrieval
library(pool)
#dplyr is used for filtering data
library(dplyr)
library(psych)
#flexdashboard library is used for the gauge objects
library(flexdashboard)
#stringr library is used for filtering/ counting keywords in posts
library(stringr)
#shinyWidgets library is used to change background color of shinyApp
library(shinyWidgets)

#create a pool for DB connections
pool <- dbPool(
    drv = RMySQL::MySQL(),
    dbname = 'SocialMedia',
    host = 'oceanplatform0.cdb7tnix15tn.us-west-2.rds.amazonaws.com',
    username = 'ogburnzach',
    password = 'IH8P@sswords',
    idleTimeout = 600000 # 10 minutes
)

ui <- fluidPage(
    
    
    setBackgroundColor(
        color = "#F2F7F2",
    ),  
    
    
    #Title of the Webpage   
       div(style = 'text-align:center',
            titlePanel("Sentiment Analysis of Hashtags Between Twitter and Gab")),
   
   
    #Row for the first gauges, #trump on Gab and Twitter
    fluidRow( style = "padding-top:2%",
             div(style = " border-top: 4px solid black",
                 #first column displays 'Winning!' if this hashtag has a higher sentiment score on Twitter vs. Gab
                 #Will display '' if Gab has a higher sentiment score for this hashtag
                 column(1,style = "font-size: 48px; padding-top: 3%; padding-right: 15%", 
                        textOutput("trumpTwitterWinning")),
                 #Output Twitter logo image
                 column(1, style = "height:100px; padding-top: 2%; padding-bottom:-2em",
                        imageOutput("twitterTrump")),
                 #Output gauge object which visualizes #trump's sentiment score on Twitter
                 column(2, style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeTwitterTrump")),
                 #output text Describing which hashtag is being analyzed by the gauges in current row
                 column(2, style='font-size: 24px; text-align:center; padding-top: 5%', 
                        textOutput("gaugeLabel1")),
                 #Output gauge object which visualizes #trump's sentiment score on Gab
                 column(2, style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeGabTrump")
                 ),
                 #output Gab logo image
                 column(1, style = "height:100px; padding-top: 2%; padding-bottom:-2em", 
                        imageOutput("gabTrump")),
                 #last column displays 'Winning!' if this hashtag has a higher sentiment score on Gab vs. Twitter
                 #Will display '' if Twitter has a higher sentiment score for this hashtag
                 column(1,style = "font-size: 48px; padding-top: 3%", 
                        textOutput("trumpGabWinning"))
             )      
    ),
    
    #Row for the second gauges, #biden on Gab and Twitter. Follows same format as outlined above
    
    fluidRow(
             div(style = "height: 100px;  border-top: 2px solid black",
                 column(1,style = "font-size: 48px; padding-top: 3%; padding-right: 15%", 
                        textOutput("bidenTwitterWinning")),
                 column(1,style = "height:100px; padding-top: 2%", 
                        imageOutput("twitterBiden")),
                 
                 column(2, style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeTwitterBiden")),
                 column(2, style='font-size: 24px; text-align:center; padding-top: 5%', 
                        textOutput("gaugeLabel3")),
                 column(2,style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeGabBiden")
                 ),
                 column(1, style = "height:100px; padding-top: 2%",
                        imageOutput("gabBiden")),
                 column(1,style = "font-size: 48px; padding-top: 3%", 
                        textOutput("bidenGabWinning"))
                 
                 
             )
    ),
    
    #Row for the third gauges, #republicans on Gab and Twitter. Follows same format as outlined above
    
    fluidRow(
        div(style = "height:100px; border-top: 2px solid black",
            column(1,style = "font-size: 48px; padding-top: 3%; padding-right: 15%", 
                   textOutput("repubTwitterWinning")),
            column(1, style = "height:100px; padding-top:2%",
                   imageOutput("twitterRepub")),
            
            column(2, style = "padding-top: 2%",
                   gaugeOutput(outputId ="gaugeTwitterRepub")),
            column(2, style='font-size: 24px; text-align:center; padding-top:5%', 
                   textOutput("gaugeLabel5")),
            column(2, style = "padding-top: 2%",
                   gaugeOutput(outputId ="gaugeGabRepub")
            ),
            column(1, style = "height:100px; padding-top: 2%",
                   imageOutput("gabRepub")),
            column(1,style = "font-size: 48px; padding-top: 3%", 
                   textOutput("repubGabWinning"))
            
        )
    ),
    
    #Row for the fourth gauges, #democrats on Gab and Twitter. Follows same format as outlined above
    
    fluidRow(
             div(style = "height:100px; border-top: 2px solid black",
                 column(1,style = "font-size: 48px; padding-top: 3%; padding-right: 15%", 
                        textOutput("demTwitterWinning")),
                 column(1, style = "height:100px; padding-top:2%",
                        imageOutput("twitterDem")),
                 
                 column(2, style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeTwitterDem")),
                 column(2, style='font-size: 24px; text-align:center; padding-top:5%', 
                        textOutput("gaugeLabel7")),
                 column(2, style = "padding-top: 2%",
                        gaugeOutput(outputId ="gaugeGabDem")
                 ),
                 column(1, style = "height:100px; padding-top: 2%",
                        imageOutput("gabDem")),
                 column(1,style = "font-size: 48px; padding-top: 3%", 
                        textOutput("demGabWinning"))
                 
             )
    ),
    
    
    
)
#Begin server function
server <- function(input, output, session) {
    
    mySQLData <- reactiveValues()
    
    getSQLData <- function() {
        
        #query the SQL database and retrieve all data from Twitter
        sqlTwitter <- "SELECT * FROM TwitterTweets WHERE (NOT TonePos IS NULL AND Retweet = FALSE AND LENGTH(TweetID) > 3)"
        queryTwitter <- sqlInterpolate(pool, sqlTwitter)
        resTwitter <- dbGetQuery(pool, queryTwitter)
        #account for the fact that 'trump' is a positive word, and reduce positive score accordingly
        resTwitter$TonePos <- resTwitter$TonePos - str_count(resTwitter$TweetContent,regex('\\btrump\\b', ignore_case = TRUE))
        resTwitter$TonePos[resTwitter$TonePos<0] <- 0
        #calculate total sentiment score
        resTwitter$totalScore <- resTwitter$TonePos-resTwitter$ToneNeg
        #split tweets into different hashtags
        originalTrumpTweets <- filter(resTwitter, ClubHash == '#trump')
        originalBidenTweets <- filter(resTwitter, ClubHash == '#biden')
        originalRepubTweets <- filter(resTwitter, ClubHash == '#republicans')
        originalDemTweets <- filter(resTwitter, ClubHash == '#democrats')
        #query the SQL database and retrieve all data from Gab 
        sqlGab <- "SELECT * FROM Gab_Posts WHERE (NOT Positive_Sentiment IS NULL AND Gab_Reblogged = 0 AND LENGTH(Post_ID) > 3)"
        queryGab <- sqlInterpolate(pool, sqlGab)
        resGab <- dbGetQuery(pool, queryGab)
        #account for the fact that 'trump' is a positive word, and reduce positive score accordingly
        resGab$Positive_Sentiment <- resGab$Positive_Sentiment - str_count(resGab$Post_Content,regex('\\btrump\\b', ignore_case = TRUE))
        resGab$Positive_Sentiment[resGab$Positive_Sentiment<0] <- 0
        #calculate total sentiment score
        resGab$totalScore <- resGab$Positive_Sentiment-resGab$Negative_Sentiment
        #split Gabs into different hashtags 
        originalTrumpGabs <- filter(resGab, Gab_Hashtag == 'trump')
        originalBidenGabs <- filter(resGab, Gab_Hashtag == 'biden')
        originalRepubGabs <- filter(resGab, Gab_Hashtag == 'republicans')
        originalDemGabs <- filter(resGab, Gab_Hashtag == 'democrats')
        #return a list of values which will be used in the reactive functions which create the gauges
        return(
            list(
                resTwitter = resTwitter,
                originalTrumpTweets = originalTrumpTweets,
                originalBidenTweets = originalBidenTweets,
                originalRepubTweets = originalRepubTweets,
                originalDemTweets = originalDemTweets,
                resGab = resGab,
                originalTrumpGabs = originalTrumpGabs,
                originalBidenGabs = originalBidenGabs,
                originalRepubGabs = originalRepubGabs,
                originalDemGabs = originalDemGabs
            )
        )
    }
    
    
    #reactive functions for all of the gauges 
    dataTrumpTwitterGauge <- reactive({
        
        #get total number of positive posts with this hashtag
        trumpTweetsTotalPos <- with(mySQLData$outerList$originalTrumpTweets, mySQLData$outerList$originalTrumpTweets$totalScore > 0)
        trumpPosNum <- sum(trumpTweetsTotalPos)
        trumpPosNum
        #get total number of negative posts with this hashtag
        trumpTweetsTotalNeg <- with(mySQLData$outerList$originalTrumpTweets, mySQLData$outerList$originalTrumpTweets$totalScore < 0)
        trumpNegNum <- sum(trumpTweetsTotalNeg)
        trumpNegNum
        #calculate final score for this hashtag
        trumpRatioScore <- round(100 * ((trumpPosNum - trumpNegNum)/(NROW(mySQLData$outerList$originalTrumpTweets))), digits = 2)
        #Add final sentiment score for this hashtag to reactiveValues in order to be used later by other reactive functions 
        mySQLData$trumpTwitterRatio <- trumpRatioScore
        
        #produce gauge for this hashtag
        trumpTwitterGauge <- gauge(trumpRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        #return gauge object
        trumpTwitterGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataBidenTwitterGauge <- reactive({
        bidenTweetsTotalPos <- with(mySQLData$outerList$originalBidenTweets, mySQLData$outerList$originalBidenTweets$totalScore > 0)
        bidenPosNum <- sum(bidenTweetsTotalPos)
        bidenPosNum
        bidenTweetsTotalNeg <- with(mySQLData$outerList$originalBidenTweets, mySQLData$outerList$originalBidenTweets$totalScore < 0)
        bidenNegNum <- sum(bidenTweetsTotalNeg)
        bidenNegNum
        bidenRatioScore <- round(100 * ((bidenPosNum - bidenNegNum)/(NROW(mySQLData$outerList$originalBidenTweets))), digits = 2)
        
        mySQLData$bidenTwitterRatio <- bidenRatioScore
        
        bidenTwitterGauge <- gauge(bidenRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        bidenTwitterGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataRepubTwitterGauge <- reactive({
        repubTweetsTotalPos <- with(mySQLData$outerList$originalRepubTweets, mySQLData$outerList$originalRepubTweets$totalScore > 0)
        repubPosNum <- sum(repubTweetsTotalPos)
        repubPosNum
        repubTweetsTotalNeg <- with(mySQLData$outerList$originalRepubTweets, mySQLData$outerList$originalRepubTweets$totalScore < 0)
        repubNegNum <- sum(repubTweetsTotalNeg)
        repubNegNum
        repubRatioScore <- round(100 * ((repubPosNum - repubNegNum)/(NROW(mySQLData$outerList$originalRepubTweets))), digits = 2)
        
        mySQLData$repubTwitterRatio <- repubRatioScore
        
        repubTwitterGauge <- gauge(repubRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        repubTwitterGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataDemTwitterGauge <- reactive({
        demTweetsTotalPos <- with(mySQLData$outerList$originalDemTweets, mySQLData$outerList$originalDemTweets$totalScore > 0)
        demPosNum <- sum(demTweetsTotalPos)
        demPosNum
        demTweetsTotalNeg <- with(mySQLData$outerList$originalDemTweets, mySQLData$outerList$originalDemTweets$totalScore < 0)
        demNegNum <- sum(demTweetsTotalNeg)
        demNegNum
        demRatioScore <- round(100 * ((demPosNum - demNegNum)/(NROW(mySQLData$outerList$originalDemTweets))), digits = 2)
        
        mySQLData$demTwitterRatio <- demRatioScore
        
        demTwitterGauge <- gauge(demRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        demTwitterGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataTrumpGabGauge <- reactive({
        trumpGabsTotalPos <- with(mySQLData$outerList$originalTrumpGabs, mySQLData$outerList$originalTrumpGabs$totalScore > 0)
        trumpPosNum <- sum(trumpGabsTotalPos)
        trumpPosNum
        trumpGabsTotalNeg <- with(mySQLData$outerList$originalTrumpGabs, mySQLData$outerList$originalTrumpGabs$totalScore < 0)
        trumpNegNum <- sum(trumpGabsTotalNeg)
        trumpNegNum
        trumpRatioScore <- round(100 * ((trumpPosNum - trumpNegNum)/(NROW(mySQLData$outerList$originalTrumpGabs))), digits = 2)
        
        mySQLData$trumpGabRatio <- trumpRatioScore
        
        
        trumpGabGauge <- gauge(trumpRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        trumpGabGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataBidenGabGauge <- reactive({
        bidenGabsTotalPos <- with(mySQLData$outerList$originalBidenGabs, mySQLData$outerList$originalBidenGabs$totalScore > 0)
        bidenPosNum <- sum(bidenGabsTotalPos)
        bidenPosNum
        bidenGabsTotalNeg <- with(mySQLData$outerList$originalBidenGabs, mySQLData$outerList$originalBidenGabs$totalScore < 0)
        bidenNegNum <- sum(bidenGabsTotalNeg)
        bidenNegNum
        bidenRatioScore <- round(100 * ((bidenPosNum - bidenNegNum)/(NROW(mySQLData$outerList$originalBidenGabs))), digits = 2)
        
        mySQLData$bidenGabRatio <- bidenRatioScore
        
        bidenGabGauge <- gauge(bidenRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        bidenGabGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataRepubGabGauge <- reactive({
        repubGabsTotalPos <- with(mySQLData$outerList$originalRepubGabs, mySQLData$outerList$originalRepubGabs$totalScore > 0)
        repubPosNum <- sum(repubGabsTotalPos)
        repubPosNum
        repubGabsTotalNeg <- with(mySQLData$outerList$originalRepubGabs, mySQLData$outerList$originalRepubGabs$totalScore < 0)
        repubNegNum <- sum(repubGabsTotalNeg)
        repubNegNum
        repubRatioScore <- round(100 * ((repubPosNum - repubNegNum)/(NROW(mySQLData$outerList$originalRepubGabs))), digits = 2)
        
        mySQLData$repubGabRatio <- repubRatioScore
        
        repubGabGauge <- gauge(repubRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        repubGabGauge
    })
    #reactive fnction to create sentiment score gauge follows same format as outlined above
    dataDemGabGauge <- reactive({
        demGabsTotalPos <- with(mySQLData$outerList$originalDemGabs, mySQLData$outerList$originalDemGabs$totalScore > 0)
        demPosNum <- sum(demGabsTotalPos)
        demPosNum
        demGabsTotalNeg <- with(mySQLData$outerList$originalDemGabs, mySQLData$outerList$originalDemGabs$totalScore < 0)
        demNegNum <- sum(demGabsTotalNeg)
        demNegNum
        demRatioScore <- round(100 * ((demPosNum - demNegNum)/(NROW(mySQLData$outerList$originalDemGabs))), digits = 2)
        
        mySQLData$demGabRatio <- demRatioScore
        
        demGabGauge <- gauge(demRatioScore, min = -100, max = 100, symbol = '%', gaugeSectors(
            success = c(20, 100), warning = c(-20,20), danger = c(-100,-20)
        ))
        demGabGauge
    })
    #print output to the R Shiny webpage
    
    #These if statements will return the text to display next to the website logo images
    #If statements are necessary to determine which website has the higher sentiment score 
    #and return the correct string
    output$trumpTwitterWinning <- renderText({
        #if statement to determine if #trump has a higher sentiment score on Twitter
        if(mySQLData$trumpTwitterRatio > mySQLData$trumpGabRatio){
            #if so, output 'Winning!' next to Twitter website logo
            return("Winning!")
        } else {
            #else output empty string next to Twitter website logo
            return("")
        }})
    #if statement follows same format outlined above
    output$bidenTwitterWinning <- renderText({
        if(mySQLData$bidenTwitterRatio > mySQLData$bidenGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above
    output$repubTwitterWinning <- renderText({
        if(mySQLData$repubTwitterRatio > mySQLData$repubGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above
    output$demTwitterWinning <- renderText({
        if(mySQLData$demTwitterRatio > mySQLData$demGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above, 
    #however, these if statements are checking if Gab has a higher sentiment score than Twitter
    output$trumpGabWinning <- renderText({
        if(mySQLData$trumpTwitterRatio < mySQLData$trumpGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above, 
    
    output$bidenGabWinning <- renderText({
        if(mySQLData$bidenTwitterRatio < mySQLData$bidenGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above, 
    
    output$repubGabWinning <- renderText({
        if(mySQLData$repubTwitterRatio < mySQLData$repubGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #if statement follows same format outlined above, 
    
    output$demGabWinning <- renderText({
        if(mySQLData$demTwitterRatio < mySQLData$demGabRatio){
            return("Winning!")
        } else {
            return("")
        }})
    #render text which identifies which hashtag is being analyzed in current row
    output$gaugeLabel1 <- renderText({"#Trump Sentiment Score"})
    #call function to create sentiment score gauge for current hashtag & output gauge object to webpage
    output$gaugeTwitterTrump <- renderGauge({
        dataTrumpTwitterGauge()
    })
    
    output$gaugeTwitterBiden <- renderGauge({
        dataBidenTwitterGauge()
    })
    output$gaugeLabel3 <- renderText({"#Biden Sentiment Score"})
    output$gaugeTwitterRepub <- renderGauge({
        dataRepubTwitterGauge()
    })
    output$gaugeTwitterDem <- renderGauge({
        dataDemTwitterGauge()
    })
    output$gaugeLabel5 <- renderText({"#Republicans Sentiment Score"})
    
    output$gaugeGabTrump <- renderGauge({
        dataTrumpGabGauge()
    })
    output$gaugeGabBiden <- renderGauge({
        dataBidenGabGauge()
    })
    output$gaugeLabel7 <- renderText({"#Democrats Sentiment Score"})
    output$gaugeGabRepub <- renderGauge({
        dataRepubGabGauge()
    })
    output$gaugeGabDem <- renderGauge({
        dataDemGabGauge()
    })
    
    
    #These if statements will output the website comapny's logo image
    #The if statement will determine whether or not to output a greyscale version of the logo based on 
    #whether or not it has the higher sentiment score for the current hashtag
    output$twitterTrump <- renderImage({
        #check if Twitter has a higher sentiment score for #trump than Gab
        if(mySQLData$trumpTwitterRatio > mySQLData$trumpGabRatio){
            #if so, output normal color version of Twitter logo
            return(list(
                src = "images/twitterLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
        else {
            #else output greyscale version of Twitter logo
            return(list(
                src = "images/twitterLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
        #Do not delete file from local storage
    }, deleteFile = FALSE)
    
    
    #If statement follows same format as outlined above
    output$gabTrump <- renderImage({
        
        if(mySQLData$trumpTwitterRatio < mySQLData$trumpGabRatio){
            
            return(list(
                src = "images/gabLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        } else {
            return(list(
                src = "images/gabLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$twitterBiden <- renderImage({
        
        if(mySQLData$bidenTwitterRatio > mySQLData$bidenGabRatio){
            return(list(
                src = "images/twitterLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
        else {
            return(list(
                src = "images/twitterLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$gabBiden <- renderImage({
        
        if(mySQLData$bidenTwitterRatio < mySQLData$bidenGabRatio){
            
            return(list(
                src = "images/gabLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        } else {
            return(list(
                src = "images/gabLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$twitterRepub <- renderImage({
        
        if(mySQLData$repubTwitterRatio > mySQLData$repubGabRatio){
            return(list(
                src = "images/twitterLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
        else {
            return(list(
                src = "images/twitterLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$gabRepub <- renderImage({
        
        if(mySQLData$repubTwitterRatio < mySQLData$repubGabRatio){
            
            return(list(
                src = "images/gabLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        } else {
            return(list(
                src = "images/gabLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$twitterDem <- renderImage({
        
        if(mySQLData$demTwitterRatio > mySQLData$demGabRatio){
            return(list(
                src = "images/twitterLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
        else {
            return(list(
                src = "images/twitterLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "twitterLogo"
            ))
        }
    }, deleteFile = FALSE)
    #If statement follows same format as outlined above
    output$gabDem <- renderImage({
        
        if(mySQLData$demTwitterRatio < mySQLData$demGabRatio){
            
            return(list(
                src = "images/gabLogo.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        } else {
            return(list(
                src = "images/gabLogoGrey.png",
                width = 100,
                height = 100,
                contentType = "image/png",
                alt = "gabLogo"
            ))
        }
    }, deleteFile = FALSE)
    
    #my attempt at refreshing the app every 30 minutes, I think it works correctly
    pollData <- reactivePoll(1800000, session,
                             # This function returns the timestamp of the last Tweet inserted into the DB
                             # It checks to see if the timestamp has changed, indicating that the DB has been updated
                             checkFunc = function() {
                                 checkDB <- "SELECT MAX(TweetDate) FROM TwitterTweets;"
                                 checkQuery <- sqlInterpolate(pool, checkDB)
                                 resCheck <- dbGetQuery(pool, checkQuery)
                                 resCheck
                             },
                             # This function queries the DB and gets SQL data for the gauges
                             valueFunc = function() {
                                 getSQLData()
                             }
    )
    #Assign mySQL to reactiveValues which creates dependencies when used in other reactive functions
    #observe the reactivePoll pollData to determine when to requery the DB
    observe(
        mySQLData$outerList <- pollData(), 
    )
    
    session$allowReconnect(TRUE)
    
    
    
}


#call shinyApp
shinyApp(ui = ui, server = server)
