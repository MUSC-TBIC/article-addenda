library( "dplyr" )
library( "tidyr" )


loadSpansData <- function( inputDir ,
                          methods ){
    n2c2Spans <- NA
    nt <- 0
    for( method in methods ){
        if( nt == 0 ){
            n2c2Spans <-
                read.delim( file = paste( inputDir ,
                                         method ,
                                         'metrics_partial_score_card.csv' ,
                                         sep = '/' ) ,
                           sep = '\t' ) %>%
                mutate( Score = factor( Score ,
                                       levels = c( 'TP' ,
                                                  'FP' ,
                                                  'FN' ,
                                                  'TN' ) ) ) %>%
                group_by( File , Start , End ) %>%
                arrange( Score ) %>%
                ## We're going to generously assume that multiple
                ## matching scores on the same span are awarded to the
                ## best score (TP > FP, FN)
                slice( 1L ) %>%
                ungroup() %>%
                mutate( Method = method )
        } else {
            n2c2Spans <-
                n2c2Spans %>%
                full_join( read.delim( file = paste( inputDir ,
                                                    method ,
                                                    'metrics_partial_score_card.csv' ,
                                                    sep = '/' ) ,
                                      sep = '\t' ) %>%
                           mutate( Score = factor( Score ,
                                                  levels = c( 'TP' ,
                                                             'FP' ,
                                                             'FN' ,
                                                             'TN' ) ) ) %>%
                           group_by( File , Start , End ) %>%
                           arrange( Score ) %>%
                           ## We're going to generously assume that
                           ## multiple matching scores on the same
                           ## span are awarded to the best score (TP >
                           ## FP, FN)
                           slice( 1L ) %>%
                           ungroup() %>%
                           mutate( Method = method ) )
        }
        nt <- nt + 1
    }
    n2c2Spans <-
        n2c2Spans %>%
        select( -Type , -Pivot ) %>%
        mutate( Method = factor( Method ) )
    return( n2c2Spans )
}


loadCUIData <- function( inputDir ,
                          methods ){
    n2c2CUIs <- NA
    nt <- 0
    for( method in methods ){
        if( nt == 0 ){
            n2c2CUIs <-
                read.delim( file = paste( inputDir ,
                                         method ,
                                         'metrics_exact_note_nlp_source_concept_id_score_card.csv' ,
                                         sep = '/' ) ,
                           sep = '\t' ) %>%
                mutate( Score = factor( Score ,
                                       levels = c( 'TP' ,
                                                  'FP' ,
                                                  'FN' ,
                                                  'TN' ) ) ) %>%
                group_by( File , Start , End ) %>%
                arrange( Score ) %>%
                ## We're going to generously assume that multiple
                ## matching scores on the same span are awarded to the
                ## best score (TP > FP, FN)
                slice( 1L ) %>%
                ungroup() %>%
                mutate( Method = method )
        } else {
            n2c2CUIs <-
                n2c2CUIs %>%
                full_join( read.delim( file = paste( inputDir ,
                                                    method ,
                                                    'metrics_exact_note_nlp_source_concept_id_score_card.csv' ,
                                                    sep = '/' ) ,
                                      sep = '\t' ) %>%
                           mutate( Score = factor( Score ,
                                                  levels = c( 'TP' ,
                                                             'FP' ,
                                                             'FN' ,
                                                             'TN' ) ) ) %>%
                           group_by( File , Start , End ) %>%
                           arrange( Score ) %>%
                           ## We're going to generously assume that
                           ## multiple matching scores on the same
                           ## span are awarded to the best score (TP >
                           ## FP, FN)
                           slice( 1L ) %>%
                           ungroup() %>%
                           mutate( Method = method ) )
        }
        nt <- nt + 1
    }
    n2c2CUIs <-
        n2c2CUIs %>%
        select( -Type ) %>%
        mutate( Method = factor( Method ) )
    return( n2c2CUIs )
}


loadAttribData <- function( inputDir ,
                            methods ){
    i2b2Attribs <- NA
    nt <- 0
    for( method in methods ){
        if( nt == 0 ){
            i2b2Attribs <-
                read.delim( file = paste( inputDir ,
                                         method ,
                                         'metrics_doc-property_score_card.csv' ,
                                         sep = '/' ) ,
                           sep = '\t' ) %>%
                mutate( Method = method )
        } else {
            i2b2Attribs <-
                i2b2Attribs %>%
                full_join( read.delim( file = paste( inputDir ,
                                                    method ,
                                                    'metrics_doc-property_score_card.csv' ,
                                                    sep = '/' ) ,
                                      sep = '\t' ) %>%
                           mutate( Method = method ) )
        }
        nt <- nt + 1
    }
    i2b2Attribs <-
        i2b2Attribs %>%
        select( -Start , -End , -Pivot ) %>%
        mutate( Score = factor( Score ,
                               levels = c( 'TP' ,
                                          'FP' ,
                                          'FN' ,
                                          'TN' ) ) ) %>%
        mutate( Method = factor( Method ) )
    return( i2b2Attribs )
}


binMethods <- function( dataSet ,
                       methods ){
    ## Get a list of files shared between methods
    fileIntersect <-
        dataSet %>%
        filter( Method %in% c( methods[ 1 ] ) ) %>%
        distinct( File ) %>%
        intersect( dataSet %>%
                   filter( Method %in% c( methods[ 2 ] ) ) %>%
                   distinct( File ) )
    ##print( fileIntersect )
    ##
    joinCols <- NA
    if( 'Start' %in% names( dataSet ) ){
        joinCols <- c( 'File' ,
                      'Start' ,
                      'End' )
    } else {
        joinCols <- c( 'File' ,
                      'Type' )
    }
    filteredSpans <-
        dataSet %>%
        filter( Method %in% c( methods[ 1 ] ) ) %>%
        right_join( fileIntersect ) %>%
        rename( `Method A` = Score ) %>%
        select( -Method ) %>%
        full_join( dataSet %>%
                   filter( Method %in% c( methods[ 2 ] ) ) %>%
                   right_join( fileIntersect ) %>%
                   rename( `Method B` = Score ) %>%
                   select( -Method ) ,
                  by = joinCols )
    ##
    return( filteredSpans )
}


convertBinsToYeh <- function( wideBins ,
                             methods ,
                             pairedFlag = FALSE ){
    wideBins <-
        wideBins %>%
        ungroup()        
    yehBins <-
        wideBins %>%
        mutate( Method = case_when(
                    `Method A` == 'FN' & `Method B` == 'FN' ~ 'Neither' ,
                    `Method A` == `Method B` ~ 'Both' ,
                    `Method A` == 'TP' & `Method B` == 'FN' ~ methods[ 1 ] ,
                    ## Special case when we need to duplicate rows
                    `Method A` == 'TN' & `Method B` == 'FP' ~ methods[ 1 ] ,
                    `Method A` == 'FN' & `Method B` == 'TP' ~ methods[ 2 ] ,
                    ## Special case when we need to duplicate rows
                    `Method A` == 'FP' & `Method B` == 'TN' ~ methods[ 2 ] ,
                    `Method A` == 'FP' & is.na( `Method B` ) ~ methods[ 1 ] ,
                    is.na( `Method A` ) & `Method B` == 'FP' ~ methods[ 2 ] ,
                    `Method A` == 'FP' & `Method B` == 'FN' ~ methods[ 1 ] ,
                    `Method A` == 'FN' & `Method B` == 'FP' ~ methods[ 2 ] ,
                    TRUE ~ 'Other' ) ) %>%
        mutate( RelationType = case_when(
                    `Method A` == 'TP' & `Method B` == 'TP' ~ 'TrueRelations' ,
                    `Method A` == 'TP' & `Method B` == 'FN' ~ 'TrueRelations' ,
                    `Method A` == 'TN' & `Method B` == 'TN' ~ 'TrueRelations' ,
                    ## Special case when we need to duplicate rows
                    `Method A` == 'TN' & `Method B` == 'FP' ~ 'TrueRelations' ,
                    ## Special case when we need to duplicate rows
                    `Method A` == 'FP' & `Method B` == 'TN' ~ 'TrueRelations' ,
                    `Method A` == 'FN' & `Method B` == 'TP' ~ 'TrueRelations' ,
                    `Method A` == 'FN' & `Method B` == 'FN' ~ 'TrueRelations' ,
                    `Method A` == 'FP' & is.na( `Method B` ) ~ 'SpuriousRelations' ,
                    is.na( `Method A` ) & `Method B` == 'FP' ~ 'SpuriousRelations' ,
                    `Method A` == 'FP' & `Method B` == 'FN' ~ 'SpuriousRelations' ,
                    `Method A` == 'FN' & `Method B` == 'FP' ~ 'SpuriousRelations' ,
                    `Method A` == 'TP' ~ 'TrueRelations' ,
                    is.na( `Method A` ) ~ 'TrueRelations' ,
                    TRUE ~ 'SpuriousRelations' ) ) %>%
        full_join( wideBins %>%
                   ## Special case when we need to duplicate rows
                   filter( `Method A` == 'TN' & `Method B` == 'FP' ) %>%
                   mutate( Method = methods[ 2 ] ,
                          RelationType = 'SpuriousRelations' ) ) %>%
        full_join( wideBins %>%
                   ## Special case when we need to duplicate rows
                   filter( `Method A` == 'FP' & `Method B` == 'TN' ) %>%
                   mutate( Method = methods[ 1 ] ,
                          RelationType = 'SpuriousRelations' ) ) %>%
        ## If we know all annotations are necessarily paired, then an incorrect
        ## annotation will result in both a FP and FN row so we need to filter
        ## out the double SpuriousRelations
        #filter( !pairedFlag |
        #        ( !( `Method A` == 'TP' & `Method B` == 'FN' ) &
        #          !( `Method A` == 'FN' & `Method B` == 'TP' ) ) ) %>%
        mutate( Method = factor( Method ) ,
               RelationType = factor( RelationType ) ) %>%
        group_by( Method , RelationType ) %>%
        ## Useful for debugging
        ##group_by( Method , RelationType , `Method A` , `Method B` ) %>%
        summarise( n = n() )
    print( yehBins )
    ##    Method TrueRelations SpuriousRelations
    ## 1       I            28                43
    ## 2      II             6                 9
    ## 3    Both            19                 5
    ## 4 Neither            50                 0
    yehBinsWide <-
        yehBins %>%
        pivot_wider( names_from = 'RelationType' ,
                    values_from = 'n' ) %>%
        ungroup() %>%
        select( Method ,
               TrueRelations ,
               SpuriousRelations )
    return( yehBinsWide )
}

