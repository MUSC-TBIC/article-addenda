library( "dplyr" )
library( "tidyr" )
library( "ggplot2" )
library( "RColorBrewer" )

plotDistributions <- function( sampledMetrics ,
                              baselineImprovement = NA ,
                              dataSet = NA ,
                              newMethod = NA ,
                              oldMethod = NA ,
                              blackWeight = 1 ,
                              grayWeight = 1 ,
                              figureFile = NA ){
    ## ##
    if( is.na( baselineImprovement ) ){
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
        baselineImprovement <-
            dataSet %>%
            evaluateSample( newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) )
    }
    ##print(             dataSet %>%
    ##        evaluateSample( newMethod = newMethod ,
    ##                       oldMethod = oldMethod ) )
    ##print( baselineImprovement )
    ## ##########################################
    ggplot( sampledMetrics %>%
            pivot_longer( cols = Recall:Accuracy ,
                         names_to = "Metric" ,
                         values_to = "Score" ) %>%
            mutate( Metric = factor( Metric ,
                                    levels = c( "Recall" ,
                                               "Precision" ,
                                               "F1" ,
                                               "Accuracy" ) ) ) ,
           aes( x = Score ,
               group = Metric ,
               color = Metric ,
               fill = Metric ) ) +
        geom_histogram() +
        geom_vline( data = baselineImprovement %>%
                        pivot_longer( cols = Recall:Accuracy ,
                                     names_to = "Metric" ,
                                     values_to = "Score" ) %>%
                        mutate( Metric = factor( Metric ,
                                                levels = c( "Recall" ,
                                                           "Precision" ,
                                                           "F1" ,
                                                           "Accuracy" ) ) ) ,
                   aes( xintercept = grayWeight * Score ) ,
                   color = "gray" ,
                   linetype = "dashed" ) +
        geom_vline( data = baselineImprovement %>%
                        pivot_longer( cols = Recall:Accuracy ,
                                     names_to = "Metric" ,
                                     values_to = "Score" ) %>%
                        mutate( Metric = factor( Metric ,
                                                levels = c( "Recall" ,
                                                           "Precision" ,
                                                           "F1" ,
                                                           "Accuracy" ) ) ) ,
                   aes( xintercept = blackWeight * Score ) ,
                   color = "black" ) +
        facet_grid( . ~ Metric ,
                   scales = "free" ) +
        theme_bw() +
        theme( legend.position = "none" ,
              axis.text.x = element_text( angle = 45 ,
                                         vjust = 0.5 ,
                                         hjust = 0.5 ) )
    if( ! is.na( figureFile ) ){
        ggsave( figureFile ,
               width = 6.72 , height = 2.88 , units = "in" )
    }
}



plotPairedDistributions <- function( sampledMetrics ,
                                    baselineImprovement = NA ,
                                    dataSet = NA ,
                                    newMethod = NA ,
                                    oldMethod = NA ,
                                    blackWeight = 1 ,
                                    grayWeight = 1 ,
                                    figureFile = NA ){
    ## ##
    if( is.na( baselineImprovement ) ){
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
        baselineImprovement <-
            dataSet %>%
            evaluateSample( newMethod = newMethod ,
                           oldMethod = oldMethod ) %>%
            arrange( desc( Method ) ) %>%
            select( Recall , Precision , F1 , Accuracy ) %>%
            summarise( across( Recall:Accuracy , diff ) )
    }
    ##print(             dataSet %>%
    ##        evaluateSample( newMethod = newMethod ,
    ##                       oldMethod = oldMethod ) )
    ##print( baselineImprovement )
    ## ##########################################
    ggplot( sampledMetrics %>%
            pivot_longer( cols = Recall:Accuracy ,
                         names_to = "Metric" ,
                         values_to = "Score" ) %>%
            filter( Metric %in% c( 'F1' ) ) %>%
            mutate( Metric = factor( Metric ,
                                    levels = c( "F1" ) ) ) ,
           aes( x = Score ,
               group = Algorithm ,
               color = Algorithm ,
               fill = Algorithm ) ) +
        scale_fill_brewer( palette = "Dark2" ) +
        scale_color_brewer( palette = "Dark2" ) +
        xlab( '' ) +
        ylab( 'Counts' ) +
        geom_histogram() +
        geom_vline( data = baselineImprovement %>%
                        pivot_longer( cols = Recall:Accuracy ,
                                     names_to = "Metric" ,
                                     values_to = "Score" ) %>%
                        filter( Metric %in% c( 'F1' ) ) %>%
                        mutate( Metric = factor( Metric ,
                                                levels = c( "F1" ) ) ) ,
                   aes( xintercept = blackWeight * Score ) ,
                   color = "black" ) +
        facet_grid( . ~ Algorithm ,
                   scales = "free" ) +
        theme_bw() +
        theme( legend.position = "none" ,
              axis.text.x = element_text( angle = 45 ,
                                         vjust = 0.5 ,
                                         hjust = 0.5 ) ,
              plot.margin = margin( t = 0,  # Top margin
                                   r = 0,  # Right margin
                                   b = -14,  # Bottom margin
                                   l = 5) ) # Left margin
    if( ! is.na( figureFile ) ){
        ggsave( figureFile ,
               width = 4 ,
               height = 1 , units = "in" )
    }
}

