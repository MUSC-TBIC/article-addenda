library( "dplyr" )
library( "tidyr" )
library( "ggplot2" )

## testSet <- read.delim( "data-raw/yeh2000_pg952.csv" ,
##                       sep = "\t" )

getSampleSizeOfDisjunction <- function( sampleSet ){
    return( sampleSet %>%
            filter( Method %in% c( "I" , "II" ) ) %>%
            select( TrueRelations , SpuriousRelations ) %>%
            sum() )
}

## sampleSizeDisjunct <- getSampleSizeOfDisjunction( testSet )

getSampleSize <- function( sampleSet ){
    return( sampleSet %>%
            select( TrueRelations , SpuriousRelations ) %>%
            sum() )
}

## sampleSize <- getSampleSize( testSet )


getTrueSpuriousCounts <- function( sampleSet ){
    relationTypeCounts <-
        sampleSet %>%
        filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
        summarise( TrueCount = sum( TrueRelations ) ,
                  SpuriousCount = sum( SpuriousRelations ) ,
                  .groups = "keep" )
    trueCounts <-
        relationTypeCounts %>%
        select( TrueCount ) %>%
        as.numeric()
    spuriousCounts <-
        relationTypeCounts %>%
        select( SpuriousCount ) %>%
        as.numeric()
    return( c( trueCounts , spuriousCounts ) )
}

## combinedCounts <-
##     getTrueSpuriousCounts( testSet )
## trueCounts <- combinedCounts[ 1 ]
## spuriousCounts <- combinedCounts[ 2 ]


generateLongSet <- function( sampleSet ,
                            newMethod = NA ,
                            oldMethod = NA ){
    ## If the user didn't provide an explicit value for both
    ## the old and new method names, we'll automatically
    ## extract them based on sort order.
    if( is.na( newMethod ) ||
        is.na( oldMethod ) ){
        methodList <-
            sampleSet %>%
            filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
            select( Method ) %>%
            arrange( Method ) %>%
            unlist()
        newMethod <- methodList[ 1 ] %>% as.character()
        oldMethod <- methodList[ 2 ] %>% as.character()
    }
    ##
    testSetWithTotal <-
        sampleSet %>%
        mutate( TotalRelations = TrueRelations + SpuriousRelations )
    ##
    newMethodCount <-
        testSetWithTotal %>%
        filter( Method == newMethod ) %>%
        select( TotalRelations ) %>%
        as.numeric()
    newTrueCount <-
        testSetWithTotal %>%
        filter( Method == newMethod ) %>%
        select( TrueRelations ) %>%
        as.numeric()
    newSpuriousCount <-
        testSetWithTotal %>%
        filter( Method == newMethod ) %>%
        select( SpuriousRelations ) %>%
        as.numeric()
    ##
    oldMethodCount <-
        testSetWithTotal %>%
        filter( Method == oldMethod ) %>%
        select( TotalRelations ) %>%
        as.numeric()
    oldTrueCount <-
        testSetWithTotal %>%
        filter( Method == oldMethod ) %>%
        select( TrueRelations ) %>%
        as.numeric()
    oldSpuriousCount <-
        testSetWithTotal %>%
        filter( Method == oldMethod ) %>%
        select( SpuriousRelations ) %>%
        as.numeric()
    ##
    bothMethodCount <-
        testSetWithTotal %>%
        filter( Method == "Both" ) %>%
        select( TotalRelations ) %>%
        as.numeric()
    bothTrueCount <-
        testSetWithTotal %>%
        filter( Method == "Both" ) %>%
        select( TrueRelations ) %>%
        as.numeric()
    bothSpuriousCount <-
        testSetWithTotal %>%
        filter( Method == "Both" ) %>%
        select( SpuriousRelations ) %>%
        as.numeric()
    ##
    neitherMethodCount <-
        testSetWithTotal %>%
        filter( Method == "Neither" ) %>%
        select( TotalRelations ) %>%
        as.numeric()
    neitherTrueCount <-
        testSetWithTotal %>%
        filter( Method == "Neither" ) %>%
        select( TrueRelations ) %>%
        as.numeric()
    neitherSpuriousCount <-
        testSetWithTotal %>%
        filter( Method == "Neither" ) %>%
        select( SpuriousRelations ) %>%
        as.numeric()
    ##
    longSet <-
        data.frame( Method = c( rep( newMethod , newMethodCount ) ,
                               rep( oldMethod , oldMethodCount ) ,
                               rep( "Both" , bothMethodCount ) ,
                               rep( "Neither" , neitherMethodCount ) ) ,
                   Relation = c( rep( "TrueRelations" , newTrueCount ) ,
                                rep( "SpuriousRelations" , newSpuriousCount ) ,
                                rep( "TrueRelations" , oldTrueCount ) ,
                                rep( "SpuriousRelations" , oldSpuriousCount ) ,
                                rep( "TrueRelations" , bothTrueCount ) ,
                                rep( "SpuriousRelations" , bothSpuriousCount ) ,
                                rep( "TrueRelations" , neitherTrueCount ) ,
                                rep( "SpuriousRelations" , neitherSpuriousCount ) ) )
    ##
    return( longSet )
}


generateFullSetSample <- function( longSet , thisSampleSize ){
    sampleLongSet <-
        sample_n( longSet ,
                 thisSampleSize ,
                 replace = T )
    ## Two options. TODO - test which is faster
    ## Using pivot_wider
    sampleWideSet <-
        sampleLongSet %>%
        group_by( Method , Relation ) %>%
        summarise( n = n() ,
                  .groups = "rowwise" ) %>%
        pivot_wider( id_cols = "Method" ,
                    names_from = "Relation" ,
                    values_from = "n" ,
                    values_fill = 0 )
    ## Using table
    #sampleWideSet <-
    #    with( sampleLongSet ,
    #         table( Method , Relation ) )
    ##
    return( sampleWideSet )
}


evaluateSample <- function( sampleSet ,
                           newMethod = NA ,
                           oldMethod = NA ){
    ## If the user didn't provide an explicit value for both
    ## the old and new method names, we'll automatically
    ## extract them based on sort order.
    if( is.na( newMethod ) ||
        is.na( oldMethod ) ){
        methodList <-
            sampleSet %>%
            filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
            select( Method ) %>%
            arrange( Method ) %>%
            unlist()
        newMethod <- methodList[ 1 ] %>% as.character()
        oldMethod <- methodList[ 2 ] %>% as.character()
    }
    ##
    performanceMetrics <-    
        data.frame( Method = c( newMethod , oldMethod ) ,
                   TP = c( sampleSet %>%
                           filter( Method %in% c( newMethod ,
                                                 "Both" ) ) %>%
                           select( TrueRelations ) %>%
                           sum() ,
                          sampleSet %>%
                          filter( Method %in% c( oldMethod ,
                                                "Both" ) ) %>%
                          select( TrueRelations ) %>%
                          sum() ) ,
                   FP = c( sampleSet %>%
                           filter( Method %in% c( newMethod ,
                                                 "Both" ) ) %>%
                           select( SpuriousRelations ) %>%
                           sum() ,
                          sampleSet %>%
                          filter( Method %in% c( oldMethod ,
                                                "Both" ) ) %>%
                          select( SpuriousRelations ) %>%
                          sum() ) ,
                   FN = c( sampleSet %>%
                           filter( Method %in% c( oldMethod ,
                                                 "Neither" ) ) %>%
                           select( TrueRelations ) %>%
                           sum() ,
                          sampleSet %>%
                          filter( Method %in% c( newMethod ,
                                                "Neither" ) ) %>%
                          select( TrueRelations ) %>%
                          sum() ) ) %>%
        mutate( Recall = ifelse( TP + FN > 0 ,
                                TP / ( TP + FN ) , 0 ) ,
               Precision = ifelse( TP + FP > 0 ,
                                  TP / ( TP + FP ) , 0 ) ) %>%
        mutate( F1 = ifelse( Recall + Precision > 0 ,
                            2 * ( Recall * Precision ) / ( Recall + Precision ) ) ) %>%
        mutate( Accuracy = ifelse( TP + FN + FP > 0 ,
                                  TP / ( TP + FP + FN ) , 0 ) )
    ##
    return( performanceMetrics )
}


generateSample <- function( originalSet ,
                           newMethod = NA ,
                           oldMethod = NA ,
                           trueCounts = NA ,
                           spuriousCounts = NA ){
    ## If the user didn't provide an explicit value for both
    ## the old and new method names, we'll automatically
    ## extract them based on sort order.
    if( is.na( newMethod ) ||
        is.na( oldMethod ) ){
        methodList <-
            originalSet %>%
            filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
            select( Method ) %>%
            arrange( Method ) %>%
            unlist()
        newMethod <- methodList[ 1 ] %>% as.character()
        oldMethod <- methodList[ 2 ] %>% as.character()
    }
    ##
    if( is.na( trueCounts ) ||
        is.na( spuriousCounts ) ){
        combinedCounts <-
            getTrueSpuriousCounts( originalSet )
        trueCounts <- combinedCounts[ 1 ]
        spuriousCounts <- combinedCounts[ 2 ]
    }
    ##
    sampleSet <-
        originalSet %>%
        filter( Method %in% c( "Both" , "Neither" ) ) %>%
        full_join( data.frame( Method = c( sample( c( newMethod ,
                                                     oldMethod ) ,
                                                  trueCounts ,
                                                  replace = T ) ,
                                          sample( c( newMethod ,
                                                    oldMethod ) ,
                                                 spuriousCounts ,
                                                 replace = T ) ) ,
                              Relation = c( rep( "TrueRelations" ,
                                                trueCounts ) ,
                                           rep( "SpuriousRelations" ,
                                               spuriousCounts ) ) ) %>%
                   group_by( Method , Relation ) %>%
                   summarise( n = n() ,
                             .groups = "keep" ) %>%
                   pivot_wider( id_cols = c( Method ) ,
                               names_from = c( Relation ) ,
                               values_from = c( n ) ) ,
                  by = c( "Method" ,
                         "TrueRelations" ,
                         "SpuriousRelations" ) )
    return( sampleSet )
}


sampleYeh <- function( dataSet ,
                      dataSetImprovement = NA ,
                      trueCounts = NA ,
                      spuriousCounts = NA ,
                      newMethod = NA ,
                      oldMethod = NA ,
                      bootstrapPower = 10 ){
    ## If the user didn't provide an explicit value for both
    ## the old and new method names, we'll automatically
    ## extract them based on sort order.
    if( is.na( newMethod ) ||
        is.na( oldMethod ) ){
        methodList <-
            dataSet %>%
            filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
            select( Method ) %>%
            arrange( Method ) %>%
            unlist()
        newMethod <- methodList[ 1 ] %>% as.character()
        oldMethod <- methodList[ 2 ] %>% as.character()
    }
    ####
    if( is.na( dataSetImprovement ) ){
        dataSetImprovement <-
            dataSet %>%
            evaluateSample( newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) )
    }
    ####
    if( is.na( trueCounts ) ||
        is.na( spuriousCounts ) ){
        combinedCounts <-
            getTrueSpuriousCounts( dataSet )
        trueCounts <- combinedCounts[ 1 ]
        spuriousCounts <- combinedCounts[ 2 ]
    }
    ## ######################################
    nt <- 0
    sampled.Metrics <- NA
    sampled.Improvement <- NA
    t1 <- Sys.time()
    while( nt < 2 ** bootstrapPower ){
        newSampling <-
            generateSample( dataSet ,
                           newMethod = newMethod ,
                           oldMethod = oldMethod ,
                           trueCounts = trueCounts ,
                           spuriousCounts = spuriousCounts )
        newMethodSampleImprovement <-
            evaluateSample( newSampling ,
                           newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) ,
                      .groups = "keep" )
        improvementOverTestSet <-
            ( newMethodSampleImprovement > dataSetImprovement )
        if( nt == 0 ){
            sampled.Metrics <- newMethodSampleImprovement
            sampled.Improvement <- improvementOverTestSet
        } else {
            sampled.Metrics <-
                sampled.Metrics %>%
                rbind( newMethodSampleImprovement )
            sampled.Improvement <-
                sampled.Improvement %>%
                rbind( improvementOverTestSet )
        }
        nt <- nt + 1
    }
    t2 <- Sys.time()
    ## units = "auto"
    print( t2 - t1 )
    ## units = "secs"
    ##print(difftime(t2, t1, units = "secs"))
    return( list( sampled.Metrics , sampled.Improvement ) )
}


sampleBerg <- function( dataSet ,
                        dataSetImprovement = NA ,
                        trueCounts = NA ,
                        spuriousCounts = NA ,
                        newMethod = NA ,
                        oldMethod = NA ,
                        bootstrapPower = 10 ){
    ## If the user didn't provide an explicit value for both
    ## the old and new method names, we'll automatically
    ## extract them based on sort order.
    if( is.na( newMethod ) ||
        is.na( oldMethod ) ){
        methodList <-
            dataSet %>%
            filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
            select( Method ) %>%
            arrange( Method ) %>%
            unlist()
        newMethod <- methodList[ 1 ] %>% as.character()
        oldMethod <- methodList[ 2 ] %>% as.character()
    }
    ####
    if( is.na( dataSetImprovement ) ){
        dataSetImprovement <-
            dataSet %>%
            evaluateSample( newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) )
    }
    ####
    if( is.na( trueCounts ) ||
        is.na( spuriousCounts ) ){
        combinedCounts <-
            getTrueSpuriousCounts( dataSet )
        trueCounts <- combinedCounts[ 1 ]
        spuriousCounts <- combinedCounts[ 2 ]
    }
    ## ######################################
    longSet <- generateLongSet( dataSet )
    ## ####
    nt <- 0
    sampled.Metrics <- NA
    sampled.Improvement <- NA
    sampleSize <- getSampleSize( dataSet )
    t1 <- Sys.time()
    while( nt < 2 ** bootstrapPower ){
        newSampling <-
            generateFullSetSample( longSet , sampleSize ) %>%
            ungroup()
        newMethodSampleImprovement <-
            evaluateSample( newSampling ,
                           newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) ,
                      .groups = "keep" )
        improvementOverTestSet <-
            ( newMethodSampleImprovement > 2*dataSetImprovement )
        if( nt == 0 ){
            sampled.Metrics <- newMethodSampleImprovement
            sampled.Improvement <- improvementOverTestSet
        } else {
            sampled.Metrics <-
                sampled.Metrics %>%
                rbind( newMethodSampleImprovement )
            sampled.Improvement <-
                sampled.Improvement %>%
                rbind( improvementOverTestSet )
        }
        nt <- nt + 1
    }
    t2 <- Sys.time()
    ## units = "auto"
    print( t2 - t1 )
    ## units = "secs"
    ##print(difftime(t2, t1, units = "secs"))
    return( list( sampled.Metrics , sampled.Improvement ) )
}


calculateSignifLevels <- function( sampledImprovement ,
                                  nt ,
                                  dataSetImprovement = NA ,
                                  dataSet = NA ,
                                  newMethod = NA ,
                                  oldMethod = NA ){
    ## ##
    if( is.na( dataSetImprovement ) ){
        if( is.na( newMethod ) ||
            is.na( oldMethod ) ){
            methodList <-
                dataSet %>%
                filter( ! Method %in% c( "Both" , "Neither" ) ) %>%
                select( Method ) %>%
                arrange( Method ) %>%
                unlist()
            newMethod <- methodList[ 1 ] %>% as.character()
            oldMethod <- methodList[ 2 ] %>% as.character()
        }
        dataSetImprovement <-
            dataSet %>%
            evaluateSample( newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) )
    }
    ## ##
    countShowingImprovement <-
        sampledImprovement %>%
        as.data.frame() %>%
        summarise( ncRecall = sum( Recall ) ,
                  ncPrecision = sum( Precision ) ,
                  ncF1 = sum( F1 ) ,
                  ncAccuracy = sum( Accuracy ) )
    ##print( countShowingImprovement )
    ##
    countMeetingCriteria <-
        ( ( dataSetImprovement > 0 ) %>%
          as.numeric() - 0.5 ) * 2 *
        ( ( ( dataSetImprovement > 0 ) %>%
            as.numeric() - 1 ) * nt +
          countShowingImprovement )
    ##print( countMeetingCriteria )
    ##
    signifLevels <-
        ( ( countMeetingCriteria + 1 ) / ( nt + 1 ) ) %>%
        as.data.frame() %>%
        rename( RecallProb = ncRecall ,
               PrecisionProb = ncPrecision ,
               F1Prob = ncF1 ,
               AccuracyProb = ncAccuracy )
    return( signifLevels )
}

## smpYeh[[2]] %>%
##     calculateSignifLevels( dataSet = testSet , nt = 2**10 )

##     as.data.frame() %>% summarise( ncRecall = sum( Recall ) )

## ###################################################
## Yeh (2000)

## What's our baseline performance improvement?
## testSetImprovement <-
##     evaluateSample( testSet ,
##                    newMethod = "I" ,
##                    oldMethod = "II" ) %>%
##     arrange( desc( Method ) ) %>%
##     select( Recall , Precision , F1 ) %>%
##     summarise( across( Recall:F1 , diff ) )

## testSetEval <-
##     evaluateSample( testSet ,
##                    newMethod = "I" ,
##                    oldMethod = "II" )

## testSetImprovement <-
##     testSetEval %>%
##     arrange( desc( Method ) ) %>%
##     select( Recall , Precision , F1 ) %>%
##     summarise( across( Recall:F1 , diff ) )

## testSetEval %>%
##     full_join( testSet ) %>%
##     full_join( testSetImprovement %>%
##                mutate( Method = "Delta" ) )


## nt <- 0
## sampledMetrics <- NA
## sampledImprovement <- NA
## t1 <- Sys.time()
## while( nt < 2**10 ){
##     newSampling <-
##         generateSample( testSet ,
##                        newMethod = "I" ,
##                        oldMethod = "II" ,
##                        trueCounts = trueCounts ,
##                        spuriousCounts = spuriousCounts )
##     newMethodSampleImprovement <-
##         evaluateSample( newSampling ,
##                        newMethod = "I" ,
##                        oldMethod = "II" ) %>%
##         arrange( desc( Method ) ) %>%
##         select( Recall , Precision , F1 ) %>%
##         summarise( across( Recall:F1 , diff ) ,
##                   .groups = "keep" )
##     improvementOverTestSet <-
##         ( newMethodSampleImprovement > testSetImprovement )
##     if( nt == 0 ){
##         sampledMetrics <- newMethodSampleImprovement
##         sampledImprovement <- improvementOverTestSet
##     } else {
##         sampledMetrics <-
##             sampledMetrics %>%
##             rbind( newMethodSampleImprovement )
##         sampledImprovement <-
##             sampledImprovement %>%
##             rbind( improvementOverTestSet )
##     }
##     nt <- nt + 1
## }
## t2 <- Sys.time()
## ## units = "auto"
## print( t2 - t1 )
## ## units = "secs"
## ##print(difftime(t2, t1, units = "secs"))


## ggplot( sampledMetrics %>%
##         pivot_longer( cols = Recall:F1 ,
##                      names_to = "Metric" ,
##                      values_to = "Score" ) %>%
##         mutate( Metric = factor( Metric ,
##                                 levels = c( "Recall" ,
##                                            "Precision" ,
##                                           "F1" ) ) ) ,
##        aes( x = Score ,
##            group = Metric ,
##            color = Metric ,
##            fill = Metric ) ) +
##     geom_histogram() +
##     geom_vline( data = testSetImprovement %>%
##                     pivot_longer( cols = Recall:F1 ,
##                                  names_to = "Metric" ,
##                                  values_to = "Score" ) %>%
##                     mutate( Metric = factor( Metric ,
##                                             levels = c( "Recall" ,
##                                                        "Precision" ,
##                                                        "F1" ) ) ) ,
##                aes( xintercept = Score ) ,
##                color = "black" ,
##                linetype = "dashed" ) +
##     facet_grid( . ~ Metric ) +
##     theme_bw() +
##     theme( legend.position = "none" )


## countShowingImprovement <-
##     sampledImprovement %>%
##     as.data.frame() %>%
##     summarise( ncRecall = sum( Recall ) ,
##               ncPrecision = sum( Precision ) ,
##               ncF1 = sum( F1 ) )

## countMeetingCriteria <-
##     ( ( testSetImprovement > 0 ) %>%
##       as.numeric() - 0.5 ) * 2 *
##     ( ( ( testSetImprovement > 0 ) %>%
##         as.numeric() - 1 ) * nt +
##       countShowingImprovement )

## ( ( countMeetingCriteria + 1 ) / ( nt + 1 ) ) %>%
##     as.data.frame() %>%
##     rename( RecallSigLevel = ncRecall ,
##            PrecisionSigLevel = ncPrecision ,
##            F1SigLevel = ncF1 )

## ##             100 =  1.5 secs
## ## 2**10 =    1024 = 15   secs
## ## 2**15 =   32768 =  8.2 minutes
## ## 2**20 = 1048576 =  4.9 hours

## ###################################################
## Berg-Kirkpatrick et al. (2012)

## testSetImprovement <-
##     evaluateSample( testSet ,
##                    newMethod = "I" ,
##                    oldMethod = "II" ) %>%
##     arrange( desc( Method ) ) %>%
##     select( Recall , Precision , F1 ) %>%
##     summarise( across( Recall:F1 , diff ) )


## longSet <- generateLongSet( testSet )

