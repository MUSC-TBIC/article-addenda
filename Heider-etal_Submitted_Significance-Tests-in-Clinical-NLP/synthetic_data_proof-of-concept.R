### R code from vignette source '2022-11_amia_symposium/p-values/p-values.Rnw'

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



###################################################
### code chunk number 2: globalVariables
###################################################

## ###############################
rawDataDir <- 'data-raw'
finalDataDir <- 'data-final'

## ###############################
bootstrapPower <- 10
##             100 =  1.5 secs
## 2**10 =    1024 = 15   secs
## 2**15 =   32768 =  8.2 minutes
## 2**20 = 1048576 =  4.9 hours



###################################################
### code chunk number 3: loadSampleData
###################################################

## ###############################
testSet <- read.delim( paste( rawDataDir ,
                              "yeh2000_pg952.csv" ,
                              sep = "/" ) ,
                      sep = "\t" )

## ###############################
sampleSizeDisjunct <- getSampleSizeOfDisjunction( testSet )
sampleSize <- getSampleSize( testSet )
combinedCounts <-
    getTrueSpuriousCounts( testSet )
trueCounts <- combinedCounts[ 1 ]
spuriousCounts <- combinedCounts[ 2 ]



###################################################
### code chunk number 4: p-values.Rnw:227-244
###################################################
testSetEval <-
   evaluateSample( testSet ,
                   newMethod = "I" ,
                   oldMethod = "II" )

testSetImprovement <-
    testSetEval %>%
    arrange( desc( Method ) ) %>%
    select( Recall , Precision , F1 , Accuracy ) %>%
    summarise( across( Recall:Accuracy , diff ) )

testSetFullEval <-
    testSetEval %>%
    full_join( testSet ) %>%
    full_join( testSetImprovement %>%
               mutate( Method = "Delta" ) )
                     


###################################################
### code chunk number 5: testSetFullEval
###################################################

print( xtable( testSetFullEval %>%
               filter( Method %in% c( 'I' , 'II' , 'Delta' ) ) ,
               align = "rc|rrrrrrrrr" ,
               display = c( "s" , "s" ,
                            "d" , "d" , "d" ,
                            "f" , "f" , "f" , "f" ,
                            "d" , "d" ) ,
               digits = c( 0 , 0 ,
                           0 , 0 , 0 ,
                           4 , 4 , 4 , 4 ,
                           0 , 0 ) ,
               label = "table:test-set-full-eval" ,
               caption = "Sample Data Adapted from Yeh (2000, pg. 952)" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )



###################################################
### code chunk number 6: bootstrapYehBerg
###################################################

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpYeh <- readRDS( file = dataFile )
} else {
    smpYeh <-
        sampleYeh( testSet ,
                   testSetImprovement ,
                   trueCounts ,
                   spuriousCounts ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpYeh , file = dataFile )
}

## ##
smpYeh.Metrics <- smpYeh[[ 1 ]]
smpYeh.Improvement <- smpYeh[[ 2 ]]

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleBerg_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpBerg <- readRDS( file = dataFile )
} else {
    smpBerg <-
        sampleBerg( testSet ,
                   testSetImprovement ,
                   trueCounts ,
                   spuriousCounts ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpBerg , file = dataFile )
}

## ##
smpBerg.Metrics <- smpBerg[[ 1 ]]
smpBerg.Improvement <- smpBerg[[ 2 ]]

meanBergF1 <-
    smpBerg.Metrics %>%
    select( F1 ) %>%
    summarise( mF1 = mean( F1 ) ) %>%
    as.numeric()

smpBerg.Metrics <-
    smpBerg.Metrics %>%
    mutate( F1 = F1 - meanBergF1 )

smpCombined.Metrics <-
    smpYeh.Metrics %>%
    mutate( Algorithm = 'Yeh' ) %>%
    full_join( smpBerg.Metrics %>%
               mutate( Algorithm = 'Berg-Kirkpatrick' ) )



###################################################
### code chunk number 7: distribution-of-deltas
###################################################

figureFile <- paste( 'figures' ,
                     'fig-distribution-of-deltas.png' ,
                     sep = "/" )
plotPairedDistributions( smpCombined.Metrics ,
                         baselineImprovement = testSetImprovement ,
                        blackWeight = 1 ,
                        figureFile = figureFile )
                   


###################################################
### code chunk number 8: signifLevels
###################################################

smpYeh.SignifLevels <-
    calculateSignifLevels( smpYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = testSetImprovement )

smpYeh.F1Prob <-
    smpYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

smpBerg.SignifLevels <-
    calculateSignifLevels( smpBerg.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = testSetImprovement )

smpBerg.F1Prob <-
    smpBerg.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

print( xtable( smpYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               full_join( smpBerg.SignifLevels %>%
                          mutate( Technique = "Berg-Kirkpatrick" ) ) %>%
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

cat( "\nPrecisely," , round(smpYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm and" ,
    round(smpBerg.F1Prob*100,2),
    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )
