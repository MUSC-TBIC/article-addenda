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
bootstrapPower <- 7
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
maxOverlapSet <- read.delim( paste( rawDataDir ,
                              "yeh2000_pg952_maxOverlap.csv" ,
                              sep = "/" ) ,
                      sep = "\t" )
## ###############################
minOverlapSet <- read.delim( paste( rawDataDir ,
                              "yeh2000_pg952_minOverlap.csv" ,
                              sep = "/" ) ,
                      sep = "\t" )

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
### code chunk number 4: p-values.Rnw:227-244
###################################################
maxOverlapSetEval <-
   evaluateSample( maxOverlapSet ,
                   newMethod = "I" ,
                   oldMethod = "II" )

maxOverlapSetImprovement <-
    maxOverlapSetEval %>%
    arrange( desc( Method ) ) %>%
    select( Recall , Precision , F1 , Accuracy ) %>%
    summarise( across( Recall:Accuracy , diff ) )

maxOverlapSetFullEval <-
    maxOverlapSetEval %>%
    full_join( maxOverlapSet ) %>%
    full_join( maxOverlapSetImprovement %>%
               mutate( Method = "Delta" ) )
                     
###################################################
### code chunk number 4: p-values.Rnw:227-244
###################################################
minOverlapSetEval <-
   evaluateSample( minOverlapSet ,
                   newMethod = "I" ,
                   oldMethod = "II" )

minOverlapSetImprovement <-
    minOverlapSetEval %>%
    arrange( desc( Method ) ) %>%
    select( Recall , Precision , F1 , Accuracy ) %>%
    summarise( across( Recall:Accuracy , diff ) )

minOverlapSetFullEval <-
    minOverlapSetEval %>%
    full_join( minOverlapSet ) %>%
    full_join( minOverlapSetImprovement %>%
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

print( xtable( maxOverlapSetFullEval %>%
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
               label = "table:max-overlap-set-full-eval" ,
               caption = "Sample Data Adapted from Yeh with Maximum Overlap between NLP Systems (2000, pg. 952)" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )

print( xtable( minOverlapSetFullEval %>%
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
               label = "table:min-overlap-set-full-eval" ,
               caption = "Sample Data Adapted from Yeh with Minimum Overlap between NLP Systems (2000, pg. 952)" ) ,
      size="\\fontsize{9pt}{10pt}\\selectfont" ,
      include.rownames = FALSE ,
      includecolnames = TRUE ,
      booktabs = TRUE )


###################################################
### code chunk number 6: bootstrapYehBerg
###################################################

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleMaxOverlapYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpMaxOverlapYeh <- readRDS( file = dataFile )
} else {
    smpMaxOverlapYeh <-
        sampleYeh( maxOverlapSet ,
                   maxOverlapSetImprovement ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpMaxOverlapYeh , file = dataFile )
}

## ##
smpMaxOverlapYeh.Metrics <- smpMaxOverlapYeh[[ 1 ]]
smpMaxOverlapYeh.Improvement <- smpMaxOverlapYeh[[ 2 ]]

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleMaxOverlapBerg_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpMaxOverlapBerg <- readRDS( file = dataFile )
} else {
    smpMaxOverlapBerg <-
        sampleBerg( maxOverlapSet ,
                   maxOverlapSetImprovement ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpMaxOverlapBerg , file = dataFile )
}

## ##
smpMaxOverlapBerg.Metrics <- smpMaxOverlapBerg[[ 1 ]]
smpMaxOverlapBerg.Improvement <- smpMaxOverlapBerg[[ 2 ]]

meanBergF1 <-
    smpMaxOverlapBerg.Metrics %>%
    select( F1 ) %>%
    summarise( mF1 = mean( F1 ) ) %>%
    as.numeric()

smpMaxOverlapBerg.Metrics <-
    smpMaxOverlapBerg.Metrics %>%
    mutate( F1 = F1 - meanBergF1 )

smpCombined.Metrics <-
    smpMaxOverlapYeh.Metrics %>%
    mutate( Algorithm = 'MaxOverlapYeh' ) %>%
    full_join( smpMaxOverlapBerg.Metrics %>%
               mutate( Algorithm = 'Berg-Kirkpatrick' ) )



###################################################
### code chunk number 7: distribution-of-deltas
###################################################

figureFile <- paste( 'figures' ,
                    paste0( 'fig-distribution-of-deltas-maxOverlap_n-' , nt , '.png' ) ,
                    sep = "/" )
plotPairedDistributions( smpCombined.Metrics ,
                         baselineImprovement = maxOverlapSetImprovement ,
                        blackWeight = 1 ,
                        figureFile = figureFile )
                   


###################################################
### code chunk number 8: signifLevels
###################################################

smpMaxOverlapYeh.SignifLevels <-
    calculateSignifLevels( smpMaxOverlapYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = maxOverlapSetImprovement )

smpMaxOverlapYeh.F1Prob <-
    smpMaxOverlapYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

smpMaxOverlapBerg.SignifLevels <-
    calculateSignifLevels( smpMaxOverlapBerg.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = maxOverlapSetImprovement )

smpMaxOverlapBerg.F1Prob <-
    smpMaxOverlapBerg.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

print( xtable( smpMaxOverlapYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               full_join( smpMaxOverlapBerg.SignifLevels %>%
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

cat( "\nPrecisely," , round(smpMaxOverlapYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm and" ,
    round(smpMaxOverlapBerg.F1Prob*100,2),
    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )





###################################################
### code chunk number 6: bootstrapYehBerg
###################################################

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleMinOverlapYeh_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpMinOverlapYeh <- readRDS( file = dataFile )
} else {
    smpMinOverlapYeh <-
        sampleYeh( minOverlapSet ,
                   minOverlapSetImprovement ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpMinOverlapYeh , file = dataFile )
}

## ##
smpMinOverlapYeh.Metrics <- smpMinOverlapYeh[[ 1 ]]
smpMinOverlapYeh.Improvement <- smpMinOverlapYeh[[ 2 ]]

nt <- 2 ** bootstrapPower
dataFile <- paste( finalDataDir ,
                   paste0( 'sampleMinOverlapBerg_n-' , nt , '.rds' ) ,
                   sep = "/" )
if( file.exists( dataFile ) ){
    smpMinOverlapBerg <- readRDS( file = dataFile )
} else {
    smpMinOverlapBerg <-
        sampleBerg( minOverlapSet ,
                   minOverlapSetImprovement ,
                   newMethod = "I" ,
                   oldMethod = "II" ,
                   bootstrapPower = bootstrapPower )
    saveRDS( smpMinOverlapBerg , file = dataFile )
}

## ##
smpMinOverlapBerg.Metrics <- smpMinOverlapBerg[[ 1 ]]
smpMinOverlapBerg.Improvement <- smpMinOverlapBerg[[ 2 ]]

meanBergF1 <-
    smpMinOverlapBerg.Metrics %>%
    select( F1 ) %>%
    summarise( mF1 = mean( F1 ) ) %>%
    as.numeric()

smpMinOverlapBerg.Metrics <-
    smpMinOverlapBerg.Metrics %>%
    mutate( F1 = F1 - meanBergF1 )

smpCombined.Metrics <-
    smpMinOverlapYeh.Metrics %>%
    mutate( Algorithm = 'MinOverlapYeh' ) %>%
    full_join( smpMinOverlapBerg.Metrics %>%
               mutate( Algorithm = 'Berg-Kirkpatrick' ) )



###################################################
### code chunk number 7: distribution-of-deltas
###################################################

figureFile <- paste( 'figures' ,
                    paste0( 'fig-distribution-of-deltas-minOverlap_n-' , nt , '.png' ) ,
                    sep = "/" )
plotPairedDistributions( smpCombined.Metrics ,
                         baselineImprovement = minOverlapSetImprovement ,
                        blackWeight = 1 ,
                        figureFile = figureFile )
                   


###################################################
### code chunk number 8: signifLevels
###################################################

smpMinOverlapYeh.SignifLevels <-
    calculateSignifLevels( smpMinOverlapYeh.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = minOverlapSetImprovement )

smpMinOverlapYeh.F1Prob <-
    smpMinOverlapYeh.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

smpMinOverlapBerg.SignifLevels <-
    calculateSignifLevels( smpMinOverlapBerg.Improvement ,
                           nt = 2 ** bootstrapPower ,
                           dataSetImprovement = minOverlapSetImprovement )

smpMinOverlapBerg.F1Prob <-
    smpMinOverlapBerg.SignifLevels %>%
    select( F1Prob ) %>%
    as.numeric()

print( xtable( smpMinOverlapYeh.SignifLevels %>%
               mutate( Technique = "Yeh" ) %>%
               full_join( smpMinOverlapBerg.SignifLevels %>%
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

cat( "\nPrecisely," , round(smpMinOverlapYeh.F1Prob*100,2) ,
    "% of the samples generated using Yeh's algorithm and" ,
    round(smpMinOverlapBerg.F1Prob*100,2),
    "% of those from Berg-Kirkpatrick's algorithm had differences in F1-measure more extreme than those observed.\n" )
