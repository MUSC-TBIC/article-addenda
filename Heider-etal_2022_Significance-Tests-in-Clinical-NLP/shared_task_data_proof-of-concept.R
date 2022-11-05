### R code from vignette source 'p-values.Rnw'

###################################################
### code chunk number 1: loadLibraries
###################################################

## ###############################
library( dplyr )
library( tidyr) 
library( readr )

## ###############################
library( ggplot2 )
library( xtable )

source( "figures.R" )
source( "replicating-yeh2000.R" )
source( "replicating-n2c2.R" )


###################################################
### code chunk number 2: globalVariables
###################################################

## ###############################
rawDataDir <- 'data-raw'
finalDataDir <- 'data-final'

## ###############################
bootstrapPower <- 7
##             100 =  1.5 secs
## 2**10 =    1024 = 15   secs
## 2**15 =   32768 =  8.2 minutes
## 2**20 = 1048576 =  4.9 hours

## ###############################
## Directories for shared tasks
i2b2SpansDir <- paste( rawDataDir ,
                       '2009_i2b2_medications' , sep = '/' )

i2b2AttribsDir <- paste( rawDataDir ,
                         '2008_i2b2_obesity' , sep = '/' )

n2c2CuiDir <- paste( rawDataDir ,
                     '2019_n2c2_track3' , sep = '/' )


###################################################
### code chunk number 3: loadSampleData CUIs
###################################################

cuiData <-
    loadCUIData( n2c2CuiDir ,
                c( 'train_score-cards_2' ,
                  'train_score-cards_3' ) )


binnedCUIsYeh <-
    cuiData %>%
    binMethods( methods = c( 'train_score-cards_2' ,
                            'train_score-cards_3' ) ) %>%
    convertBinsToYeh( methods = c( 'train_score-cards_2' ,
                                   'train_score-cards_3' ) )

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleCUIsYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpCUIsYeh <- readRDS( dataFile )                      
} else {
    smpCUIsYeh <-
        sampleYeh( binnedCUIsYeh ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpCUIsYeh , file = dataFile )
}

smpCUIsYeh.Metrics <- smpCUIsYeh[[ 1 ]]
smpCUIsYeh.Improvement <- smpCUIsYeh[[ 2 ]]

plotDistributions( smpCUIsYeh.Metrics ,
                  dataSet = binnedCUIsYeh ,
                  blackWeight = 1 )

smpCUIsYeh.SignifLevels <-
    calculateSignifLevels( smpCUIsYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSet = binnedCUIsYeh )

smpCUIsYeh.F1Prob <-
    smpCUIsYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

## ## #################################################
## ## TODO - and this is where I introduced a bug in the last merge

## nt <- 2 ** bootstrapPower
## dataFile <- paste( finalDataDir ,
##                    paste0( 'sampleCUIsBerg_n-' , nt , '.rds' ) ,
##                    sep = "/" )
## if( file.exists( dataFile ) ){
##     smpCUIsBerg <- readRDS( file = dataFile )
## } else {
##     smpCUIsBerg <-
##         sampleCUIsBerg( testSet ,
##                    testSetImprovement ,
##                    trueCounts ,
##                    spuriousCounts ,
##                    newMethod = "I" ,
##                    oldMethod = "II" ,
##                    bootstrapPower = bootstrapPower )
##     saveRDS( smpCUIsBerg , file = dataFile )
## }

## ## ##
## smpCUIsBerg.Metrics <- smpCUIsBerg[[ 1 ]]
## smpCUIsBerg.Improvement <- smpCUIsBerg[[ 2 ]]

## meanCUIsBergF1 <-
##     smpCUIsBerg.Metrics %>%
##     select( F1 ) %>%
##     summarise( mF1 = mean( F1 ) ) %>%
##     as.numeric()

## smpCUIsBerg.Metrics <-
##     smpCUIsBerg.Metrics %>%
##     mutate( F1 = F1 - meanCUIsBergF1 )

## smpCombined.Metrics <-
##     smpCUIsYeh.Metrics %>%
##     mutate( Algorithm = 'Yeh' ) %>%
##     full_join( smpCUIsBerg.Metrics %>%
##                mutate( Algorithm = 'Berg-Kirkpatrick' ) )

## ##########################################################

print( xtable( smpCUIsYeh.SignifLevels ,
               ##align = "rc|rrrrrrrr" ,
               display = c( "s" ,
                            "f" , "f" , "f" , "f" ) ,
               auto = TRUE ,
               digits = c( 0 ,
                           6 , 6 , 6 , 6 ) ,
               label = "table:cuis-signif-levels" ,
               caption = "CUIs 1.2 vs. 1.3:  Probability (0-1) that the Reported Difference Is Not True (Because the $H_0$ is True) Based on Yeh's Reshuffled Sampling Algorithm" ) ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

print( xtable( smpCUIsYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               ##full_join( smpCUIsBerg.SignifLevels %>%
               ##           mutate( Technique = "Berg-Kirkpatrick" ) ) %>%
               select( "Technique" ,
                      "RecallProb" ,
                      "PrecisionProb" ,
                      "F1Prob" ,
                      "AccuracyProb" ) ,
              align = "rl|rrrr" ,
              display = c( "s" , "s" ,
                          "f" , "f" , "f" , "f" ) ,
              digits = c( 0 , 0 ,
                         4 , 4 , 4 , 4 ) ,
               label = "table:test-set-signif-levels" ,
               caption = "Significance Levels as Generated by two techniques" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

cat( "\nPrecisely," , round(smpCUIsYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm.\n" )
##and" ,
##    round(smpBerg.F1Prob*100,2),
##    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )


###################################################
### code chunk number 3: loadSampleData Spans
###################################################

spansData <-
    loadSpansData( i2b2SpansDir ,
                   c( 'test_score-cards_2' ,
                      'test_score-cards_3' ) )


binnedSpansYeh <-
    spansData %>%
    binMethods( methods = c( 'test_score-cards_2' ,
                            'test_score-cards_3' ) ) %>%
    convertBinsToYeh( methods = c( 'test_score-cards_2' ,
                                   'test_score-cards_3' ) )

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleSpansYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpSpansYeh <- readRDS( dataFile )                      
} else {
    smpSpansYeh <-
        sampleYeh( binnedSpansYeh ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpSpansYeh , file = dataFile )
}

smpSpansYeh.Metrics <- smpSpansYeh[[ 1 ]]
smpSpansYeh.Improvement <- smpSpansYeh[[ 2 ]]

plotDistributions( smpSpansYeh.Metrics ,
                  dataSet = binnedSpansYeh ,
                  blackWeight = 1 )

smpSpansYeh.SignifLevels <-
    calculateSignifLevels( smpSpansYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSet = binnedSpansYeh )

smpSpansYeh.F1Prob <-
    smpSpansYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

## ## #################################################
## ## TODO - and this is where I introduced a bug in the last merge

## nt <- 2 ** bootstrapPower
## dataFile <- paste( finalDataDir ,
##                    paste0( 'sampleSpansBerg_n-' , nt , '.rds' ) ,
##                    sep = "/" )
## if( file.exists( dataFile ) ){
##     smpSpansBerg <- readRDS( file = dataFile )
## } else {
##     smpSpansBerg <-
##         sampleSpansBerg( testSet ,
##                    testSetImprovement ,
##                    trueCounts ,
##                    spuriousCounts ,
##                    newMethod = "I" ,
##                    oldMethod = "II" ,
##                    bootstrapPower = bootstrapPower )
##     saveRDS( smpSpansBerg , file = dataFile )
## }

## ## ##
## smpSpansBerg.Metrics <- smpSpansBerg[[ 1 ]]
## smpSpansBerg.Improvement <- smpSpansBerg[[ 2 ]]

## meanSpansBergF1 <-
##     smpSpansBerg.Metrics %>%
##     select( F1 ) %>%
##     summarise( mF1 = mean( F1 ) ) %>%
##     as.numeric()

## smpSpansBerg.Metrics <-
##     smpSpansBerg.Metrics %>%
##     mutate( F1 = F1 - meanSpansBergF1 )

## smpCombined.Metrics <-
##     smpSpansYeh.Metrics %>%
##     mutate( Algorithm = 'Yeh' ) %>%
##     full_join( smpSpansBerg.Metrics %>%
##                mutate( Algorithm = 'Berg-Kirkpatrick' ) )

## ##########################################################

print( xtable( smpSpansYeh.SignifLevels ,
               ##align = "rc|rrrrrrrr" ,
               display = c( "s" ,
                            "f" , "f" , "f" , "f" ) ,
               auto = TRUE ,
               digits = c( 0 ,
                           6 , 6 , 6 , 6 ) ,
               label = "table:cuis-signif-levels" ,
               caption = "Spans 1.2 vs. 1.3:  Probability (0-1) that the Reported Difference Is Not True (Because the $H_0$ is True) Based on Yeh's Reshuffled Sampling Algorithm" ) ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

print( xtable( smpSpansYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               ##full_join( smpSpansBerg.SignifLevels %>%
               ##           mutate( Technique = "Berg-Kirkpatrick" ) ) %>%
               select( "Technique" ,
                      "RecallProb" ,
                      "PrecisionProb" ,
                      "F1Prob" ,
                      "AccuracyProb" ) ,
              align = "rl|rrrr" ,
              display = c( "s" , "s" ,
                          "f" , "f" , "f" , "f" ) ,
              digits = c( 0 , 0 ,
                         4 , 4 , 4 , 4 ) ,
               label = "table:test-set-signif-levels" ,
               caption = "Significance Levels as Generated by two techniques" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

cat( "\nPrecisely," , round(smpSpansYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm.\n" )
##and" ,
##    round(smpBerg.F1Prob*100,2),
##    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )



###################################################
### code chunk number 3: loadSampleData Attrib
###################################################

attribData <-
    loadAttribData( i2b2AttribsDir ,
                   c( 'test_score-cards_2' ,
                      'test_score-cards_3' ) )


binnedAttribsYeh <-
    attribData %>%
    binMethods( methods = c( 'test_score-cards_2' ,
                            'test_score-cards_3' ) ) %>%
    convertBinsToYeh( methods = c( 'test_score-cards_2' ,
                                   'test_score-cards_3' ) )

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleAttribsYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpAttribsYeh <- readRDS( dataFile )                      
} else {
    smpAttribsYeh <-
        sampleYeh( binnedAttribsYeh ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpAttribsYeh , file = dataFile )
}

smpAttribsYeh.Metrics <- smpAttribsYeh[[ 1 ]]
smpAttribsYeh.Improvement <- smpAttribsYeh[[ 2 ]]

plotDistributions( smpAttribsYeh.Metrics ,
                  dataSet = binnedAttribsYeh ,
                  blackWeight = 1 )

smpAttribsYeh.SignifLevels <-
    calculateSignifLevels( smpAttribsYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSet = binnedAttribsYeh )

smpAttribsYeh.F1Prob <-
    smpAttribsYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

## ## #################################################
## ## TODO - and this is where I introduced a bug in the last merge

## nt <- 2 ** bootstrapPower
## dataFile <- paste( finalDataDir ,
##                    paste0( 'sampleAttribsBerg_n-' , nt , '.rds' ) ,
##                    sep = "/" )
## if( file.exists( dataFile ) ){
##     smpAttribsBerg <- readRDS( file = dataFile )
## } else {
##     smpAttribsBerg <-
##         sampleBerg( binnedAttribsYeh %>%
##                     replace(is.na(.), 0) %>%
##                     as.data.frame() ,
##                     dataSetImprovement = NA ,
##                     trueCounts = NA ,
##                    spuriousCounts = NA ,
##                    newMethod = 'test_score-cards_2' ,
##                    oldMethod = 'test_score-cards_3' ,
##                    bootstrapPower = bootstrapPower )
##     saveRDS( smpAttribsBerg , file = dataFile )
## }

## ## ##
## smpAttribsBerg.Metrics <- smpAttribsBerg[[ 1 ]]
## smpAttribsBerg.Improvement <- smpAttribsBerg[[ 2 ]]

## meanAttribsBergF1 <-
##     smpAttribsBerg.Metrics %>%
##     select( F1 ) %>%
##     summarise( mF1 = mean( F1 ) ) %>%
##     as.numeric()

## smpAttribsBerg.Metrics <-
##     smpAttribsBerg.Metrics %>%
##     mutate( F1 = F1 - meanAttribsBergF1 )

## smpCombined.Metrics <-
##     smpAttribsYeh.Metrics %>%
##     mutate( Algorithm = 'Yeh' ) %>%
##     full_join( smpAttribsBerg.Metrics %>%
##                mutate( Algorithm = 'Berg-Kirkpatrick' ) )

## ## ##########################################################

print( xtable( smpAttribsYeh.SignifLevels ,
               ##align = "rc|rrrrrrrr" ,
               display = c( "s" ,
                            "f" , "f" , "f" , "f" ) ,
               auto = TRUE ,
               digits = c( 0 ,
                           6 , 6 , 6 , 6 ) ,
               label = "table:cuis-signif-levels" ,
               caption = "Attribs 1.2 vs. 1.3:  Probability (0-1) that the Reported Difference Is Not True (Because the $H_0$ is True) Based on Yeh's Reshuffled Sampling Algorithm" ) ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

print( xtable( smpAttribsYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               ##full_join( smpAttribsBerg.SignifLevels %>%
               ##           mutate( Technique = "Berg-Kirkpatrick" ) ) %>%
               select( "Technique" ,
                      "RecallProb" ,
                      "PrecisionProb" ,
                      "F1Prob" ,
                      "AccuracyProb" ) ,
              align = "rl|rrrr" ,
              display = c( "s" , "s" ,
                          "f" , "f" , "f" , "f" ) ,
              digits = c( 0 , 0 ,
                         4 , 4 , 4 , 4 ) ,
               label = "table:test-set-signif-levels" ,
               caption = "Significance Levels as Generated by two techniques" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

cat( "\nPrecisely," , round(smpAttribsYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm.\n" )
##and" ,
##    round(smpBerg.F1Prob*100,2),
##    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )
