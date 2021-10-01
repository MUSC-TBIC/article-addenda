
library( "ggplot2" )
library( "dplyr" )
library( "readr" )
library( "tidyr" )
library( "stringr" )
library( RColorBrewer )
library( ggpubr )

paperRoot <- "ots-ensemble-methods"

## This path should point to whichever folder your wrote the
## output evaluation data to. The data-final folder contains
## all the consolidated data used in plotting. The figures folder
## contains all output figures. Both of these directories will
## need to be created.
rawDataDir <- paste( paperRoot , "data-raw" , sep = "/" )
finalDataDir <- paste( "/tmp" , "data-final" , sep = "/" )
plotDir = paste( "/tmp" , "figures" , sep = "/" )


  
## TODOs
## - clean classifier names (e.g., submission_Ali.txt -> Ali)

## ########################################################
## 2008 i2b2 obesity - context attributes
## ########################################################

class2id2008 <- read_delim( paste( rawDataDir , 
                                   "2008_i2b2_obesity" ,
                                   "classifiers2ids_v004.csv" ,
                                  sep = "/" ) ,
                            delim = "\t" ) %>%
  mutate( Classifier = factor( Classifier ) )

dvh2008 <- read_delim( paste( rawDataDir , 
                              "2008_i2b2_obesity" ,
                              "2008_i2b2_obesity_results_vComposite.csv" ,
                              sep = "/" ) ,
                       delim = "\t" ) %>%
  mutate( Method = factor( Method ) ) %>%
  mutate( Context = ifelse( grepl( "DNE" , Type ) , "Absent" ,
                            ifelse( grepl( "Exists" , Type ) , "Present" ,
                                    ifelse( grepl( "Uncert" , Type ) , "Uncertain" ,
                                      "Mentioned" ) ) ) ) %>%
  mutate( Context = factor( Context ) ) %>%
  mutate( Disease = str_replace( Type , "DNE" , "" ) ) %>%
  mutate( Disease = str_replace( Disease , "Exists" , "" ) ) %>%
  mutate( Disease = str_replace( Disease , "Uncert" , "" ) ) %>%
  mutate( Disease = factor( Disease ) ) %>%
  rename( ClassifierID = Classifiers ) %>%
  mutate( ClassifierID = factor( ClassifierID ) ) %>%
  select( Method , ClassifierID , 
          Disease , Context , 
          TP , FP , FN , TN , MinVote ) %>%
  pivot_wider( names_from = c( Context ) , 
               values_from = c( TP , FP , FN , TN ) ) %>%
  mutate( TP_Unmentioned = TN_Mentioned ,
          FP_Unmentioned = FN_Mentioned ,
          FN_Unmentioned = FP_Mentioned ,
          TN_Unmentioned = TP_Mentioned ) %>%
  pivot_longer( cols = TP_Absent:TN_Unmentioned , 
                names_sep = "_" ,
                names_to = c( ".value" , "Context" ) ) %>%
  mutate( Context = factor( Context ) ) %>%
  mutate( Precision = ifelse( ( TP + FP ) == 0 , 0 ,
                              TP / ( TP + FP ) ) ,
          Recall = ifelse( ( TP + FN ) == 0 , 0 ,
                           TP / ( TP + FN ) ) ) %>%
  mutate( Precision = ifelse( is.na( Precision ) , 0 , Precision ) ) %>%
  mutate( Recall = ifelse( is.na( Recall ) , 0 , Recall ) ) %>%
  mutate( F1 = 2 * Precision * Recall / ( Precision + Recall ) ) %>%
  mutate( F1 = ifelse( is.na( F1 ) , 0 , F1 ) ) %>%
  pivot_wider( names_from = c( Context ) , 
               values_from = c( TP , FP , FN , TN , Recall , Precision , F1 ) ) %>%
  ungroup() %>%
  group_by( Method , ClassifierID , Disease , MinVote ) %>%
  summarise( macroPrecision = mean( Precision_Present ,
                                      Precision_Absent ,
                                      Precision_Uncertain ,
                                      Precision_Unmentioned , na.rm = TRUE ) ,
          macroRecall = mean( Recall_Present ,
                              Recall_Absent ,
                              Recall_Uncertain ,
                             Recall_Unmentioned , na.rm = TRUE ) ,
          macroF1 = mean( F1_Present ,
                          F1_Absent ,
                          F1_Uncertain ,
                         F1_Unmentioned , na.rm = TRUE ) ) %>%
  ungroup() %>%
  group_by( Method , ClassifierID , MinVote ) %>%
  summarise( avgMacroPrecision = mean( macroPrecision , na.rm = TRUE ) ,
             avgMacroRecall = mean( macroRecall , na.rm = TRUE ) ,
             avgMacroF1 = mean( macroF1 , na.rm = TRUE ) ) %>%
  mutate( k = str_count( ClassifierID , ' ' ) + 1 )

dvh2008 %>%
  summary()

plotData2008 <-
  dvh2008 %>%
  ungroup() %>%
  filter( Method == "voting" ) %>%
  select( -Method ) %>%
  arrange( k , desc( avgMacroF1 ) , MinVote , ClassifierID )

plotData2008 %>%
  write_delim( file = paste( finalDataDir , 
                             "2008_i2b2_obesity" ,
                             "rankedClassifiersAll.csv" ,
                             sep = "/" ) ,
               delim = "\t" )

topMean2008 <-
  plotData2008 %>%
  group_by( k , ClassifierID ) %>%
  summarise( meanAvgMacroF1 = mean( avgMacroF1 ) ) %>%
  arrange( k , desc( meanAvgMacroF1 ) ) %>%
    slice( 1L )
topIndiv2008 <-
  plotData2008 %>%
  group_by( k ) %>%
  arrange( k , desc( avgMacroF1 ) ) %>%
  slice( 1L )
ggplot( data = plotData2008 ,
        aes( y = avgMacroF1 , 
             x = ClassifierID ,
             group = ClassifierID ) ) +
  geom_boxplot() +
  theme_bw() +
  geom_point( data = topMean2008 ,
              aes( y = meanAvgMacroF1 ) ,
              color = "orange" ) +
  geom_point( data = topIndiv2008 ,
              color = "red" ) +
  theme( axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , scales = "free_x" )
topMean2008
topIndiv2008

plotData2008 %>%
  filter( ClassifierID %in% c( "1 2 3 12 13 14 15" ,
                               "1 3 4 12 13 14 15" ,
                               "1 3 5 12 13 14 15" ,
                               "1 3 6 12 13 14 15" ,
                               "1 3 7 12 13 14 15" ,
                               "1 3 8 12 13 14 15" ,
                               "1 3 9 12 13 14 15" ,
                               "1 3 10 12 13 14 15" ,
                               "1 3 11 12 13 14 15" ,
                               "1 3 12 13 14 15 16" ,
                               "1 3 12 13 14 15 17" ) ) %>%
  group_by( k , ClassifierID ) %>%
  summarise( meanAvgMacroF1 = mean( avgMacroF1 ) ) %>%
  arrange( k , desc( meanAvgMacroF1 ) )

threeFigHeight <- 1.5
threeFigWidth <- 6.0

ggplot( data = plotData2008 %>%
          filter( ClassifierID %in% topIndiv2008$ClassifierID ) %>%
          mutate( `Total Classifiers` = factor( k ) ) ,
        aes( y = avgMacroF1 , 
             x = `Total Classifiers` ,
             group = ClassifierID ) ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_boxplot() +
  theme_bw() +
  theme( legend.position = "none" )
ggsave( paste( plotDir , 
               "classifier-path-performance-context-attrib-2008.png" , sep = "/" ) , 
        width = threeFigWidth , height = threeFigHeight , units = "in" )

ggplot( data = plotData2008 ,
        aes( y = avgMacroF1 , 
             x = MinVote ,
             color = ClassifierID ,
             group = ClassifierID ) ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "none" ,
         axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , scales = "free_x" )


## ########################################################
## 2009 i2b2 - Spans
## ########################################################

class2id2009 <- read_delim( paste( rawDataDir , 
                                   "2009_i2b2_medications" ,
                                   "classifiers2ids_v003.csv" ,
                                   sep = "/" ) ,
                            delim = "\t" ) %>%
  mutate( Classifier = factor( Classifier ) )

dvh2009 <- read_delim( paste( rawDataDir , 
                              "2009_i2b2_medications" ,
                              "2009_i2b2_medications_results_vComposite.csv" ,
                              sep = "/" ) ,
                       delim = "\t" ) %>%
  mutate( Method = factor( Method ) ) %>%
  mutate( MatchFlag = factor( MatchFlag ) ) %>%
  rename( ClassifierID = Classifiers ) %>%
  mutate( k = str_count( ClassifierID , ' ' ) + 1 )

dvh2009 %>%
  summary()

plotData2009 <-
  dvh2009 %>%
  filter( Method == "voting" ) %>%
  filter( MatchFlag == "Partial" ) %>%
  select( ClassifierID , MinVote , k , Recall , Precision , F1 ) %>%
  ungroup() %>%
  arrange( k , desc( F1 ) , MinVote , ClassifierID )

plotData2009 %>%
  write_delim( file = paste( finalDataDir , 
                             "2009_i2b2_medications" ,
                             "rankedClassifiersAll.csv" ,
                             sep = "/" ) ,
               delim = "\t" )

topMean2009 <-
  plotData2009 %>%
  group_by( k , ClassifierID ) %>%
  summarise( meanF1 = mean( F1 ) ) %>%
  arrange( k , desc( meanF1 ) ) %>%
  slice( 1L )
topIndiv2009 <-
  plotData2009 %>%
  group_by( k ) %>%
  arrange( k , desc( F1 ) ) %>%
  slice( 1L )
ggplot( data = plotData2009 ,
        aes( y = F1 , 
             x = ClassifierID ,
             group = ClassifierID ) ) +
  geom_boxplot() +
  geom_point( data = topMean2009 ,
              aes( y = meanF1 ) ,
              color = "orange" ) +
  geom_point( data = topIndiv2009 ,
              color = "red" ) +
  theme_bw() +
  theme( axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , scales = "free_x" )

ggplot( data = plotData2009 %>%
          filter( ClassifierID %in% topIndiv2009$ClassifierID ) %>%
          mutate( `Total Classifiers` = factor( k ) ) ,
        aes( y = F1 , 
             x = `Total Classifiers` ,
             group = ClassifierID ) ) +
  geom_boxplot() +
  theme_bw() +
  theme( legend.position = "none" )
ggsave( paste( plotDir , 
               "classifier-path-performance-spans-2009.png" , sep = "/" ) , 
        width = threeFigWidth , height = threeFigHeight , units = "in" )


## ########################################################
## 2019 n2c2 Track 3 - CUIs
## ########################################################

class2id2019 <- read_delim( paste( rawDataDir , 
                                   "2019_n2c2_track3" ,
                                   "classifiers2ids.csv" ,
                                   sep = "/" ) ,
                            delim = "\t" ) %>%
  mutate( Classifier = factor( Classifier ) )

dvh2019 <- read_delim( paste( rawDataDir , 
                              "2019_n2c2_track3" ,
                              "2019_n2c2_track3_results_vComposite.csv" ,
                              sep = "/" ) ,
                       delim = "\t" ) %>%
  mutate( Method = factor( Method ) ) %>%
  rename( ClassifierID = Classifiers ) %>%
  mutate( k = str_count( ClassifierID , ' ' ) + 1 ) %>%
  filter( ! ( MinVote == 9 & k == 8 ) ) %>%
  mutate( `Composite Score` = Accuracy * Coverage ) %>%
  mutate( F1 = 2 * Accuracy * Coverage / ( Accuracy + Coverage ) )
##
dvh2019 %>%
  summary()
##
plotData2019 <-
  dvh2019 %>%
  filter( Method == "voting" ) %>%
  select( ClassifierID , MinVote , k ,
          Accuracy , Coverage , `Composite Score` , F1 ) %>%
  ungroup() %>%
  arrange( desc( F1 ) )
##
plotData2019 %>%
  write_delim( file = paste( finalDataDir , 
                             "2019_n2c2_track3" ,
                             "rankedClassifiersAll.csv" ,
                             sep = "/" ) ,
               delim = "\t" )
##
topMean2019 <-
  plotData2019 %>%
  group_by( k , ClassifierID ) %>%
  summarise( meanF1 = mean( F1 ) ) %>%
  arrange( desc( meanF1 ) ) %>%
  slice( 1L )
topIndiv2019 <-
  plotData2019 %>%
  group_by( k ) %>%
  arrange( desc( F1 ) ) %>%
  slice( 1L )
ggplot( data = plotData2019 ,
        aes( y = F1 , 
             x = ClassifierID ,
             group = ClassifierID ) ) +
  geom_boxplot() +
  geom_point( data = topMean2019 ,
              aes( y = meanF1 ) ,
              color = "orange" ) +
  geom_point( data = topIndiv2019 ,
              color = "red" ) +
  theme_bw() +
  theme( axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , scales = "free_x" )
topMean2019
topIndiv2019

ggplot( data = plotData2019 %>%
          filter( k < 5 ) ,
        aes( y = F1 , 
             x = ClassifierID ,
             group = ClassifierID ) ) +
  xlab( 'Classifier Subset' ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_boxplot() +
  geom_point( data = topMean2019 %>%
                filter( k < 5 ) ,
              aes( y = meanF1 ) ,
              shape = 8 ,
              size = 3 ,
              color = "orange" ) +
  geom_point( data = topIndiv2019 %>%
                filter( k < 5 ) ,
              shape = 17 ,
              size = 2.5 ,
              color = "red" ) +
  theme_bw() +
  theme( axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , ncol = 4 ,
              scales = "free_x" )
ggsave( paste( plotDir , 
               "additive-and-subtractive-pruning-misalignment-cuis-2019.png" , sep = "/" ) , 
        width = threeFigWidth , height = 2.0 , units = "in" )

####
ggplot( data = plotData2019 %>%
          filter( ClassifierID %in% topIndiv2019$ClassifierID ) %>%
          mutate( k = factor( k ) ) ,
        aes( y = F1 , 
             x = k ,
             group = ClassifierID ) ) +
  xlab( 'Total Classifiers' ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_boxplot() +
  theme_bw() +
  theme( legend.position = "none" )
ggsave( paste( plotDir , 
               "classifier-path-performance-cuis-2019.png" , sep = "/" ) , 
        width = threeFigWidth , height = threeFigHeight , units = "in" )

ggplot( data = plotData2019 ,
        aes( y = F1 , 
             x = MinVote ,
             color = ClassifierID ,
             group = ClassifierID ) ) +
  ylim( 0.75 , 0.9 ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "none" ,
         axis.text.x = element_text( angle = 45 , 
                                     vjust = 0.95 , 
                                     hjust = 1 ) ) +
  facet_wrap( . ~ k , scales = "free_x" )


## ########################################################
## minVote-vs-Performance
## ########################################################

combinedPlotData <-
  plotData2008 %>%
  filter( MinVote > 1 ) %>%
  mutate( `Relative Min Vote` = MinVote / k ) %>%
  mutate( `Total Classifiers` = factor( k ) ) %>%
  mutate( Task = '2008 i2b2' ) %>%
  rename( F1 = avgMacroF1 ) %>%
  full_join( plotData2009 %>%
  filter( MinVote > 1 ) %>%
  mutate( `Relative Min Vote` = MinVote / k ) %>%
  mutate( `Total Classifiers` = factor( k ) ) %>%
  mutate( Task = '2009 i2b2' ) ) %>%
  full_join( plotData2019 %>%
  filter( MinVote > 1 ) %>%
  filter( ! ( MinVote == 9 & k == 8 ) ) %>%
  mutate( `Relative Min Vote` = MinVote / k ) %>%
  mutate( `Total Classifiers` = factor( k ) ) %>%
  mutate( Task = '2019 n2c2' ) ) %>%
  mutate( Task = factor( Task , 
                         levels = c( '2009 i2b2' ,
                                     '2019 n2c2' ,
                                     '2008 i2b2' ) ) )

colourCount = length( unique( combinedPlotData$`Total Classifiers` ) )
getPalette = colorRampPalette( brewer.pal( 9 , "Set1" ) )


ggpubr::show_point_shapes()

ggplot( data = combinedPlotData %>%
          mutate( `Total Classifiers` = factor( `Total Classifiers` ) ) ,
        aes( y = F1 , 
             x = `Relative Min Vote` ,
             color = `Total Classifiers` ,
             shape = `Total Classifiers` ,
             linetype = `Total Classifiers` ,
             group = ClassifierID ) ) +
  xlab( 'Relative Vote Threshold' ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "right" ) +
  facet_grid( Task ~ . , scales = "free_y" ) +
  guides( color = guide_legend( ncol = 2 ) ,
          linetype = guide_legend( ncol = 2 ) ,
          shape = guide_legend( ncol = 2 ) ) +
  scale_shape_manual( values = c( 0 , 1 , 2 , 3 , 
                                  4 , 5 , 6 , 7 , 
                                  8 , 9 , 10 , 11 , 
                                  12 , 13 ) ) + 
  scale_fill_manual( values = getPalette( colourCount ) )
ggsave( paste( plotDir , 
               "minVote-vs-Performance-combined.png" , sep = "/" ) ,
        width = threeFigWidth , height = 3.25 , units = "in" )

## ############

ggplot( data = plotData2008 %>%
          filter( MinVote > 1 ) %>%
          mutate( `Relative Min Vote` = MinVote / k ) %>%
          mutate( `Total Classifiers` = factor( k ) ) ,
        aes( y = avgMacroF1 , 
             x = `Relative Min Vote` ,
             color = `Total Classifiers` ,
             group = ClassifierID ) ) +
  ylab( bquote( 'Avg. Macro ' * ~F[1] * '-Measure' ) ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "top" ) +
  guides( color = guide_legend( nrow = 1 ) )
ggsave( paste( plotDir , 
               "minVote-vs-Performance-context-attrib-2008.png" , sep = "/" ) , 
        width = threeFigWidth , height = threeFigHeight , units = "in" )

ggplot( data = plotData2009 %>%
          filter( MinVote > 1 ) %>%
          mutate( `Relative Min Vote` = MinVote / k ) %>%
          mutate( `Total Classifiers` = factor( k ) ) ,
        aes( y = F1 , 
             x = `Relative Min Vote` ,
             color = `Total Classifiers` ,
             group = ClassifierID ) ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "top" ) +
  guides( color = guide_legend( nrow = 1 ) )
ggsave( paste( plotDir , 
               "minVote-vs-Performance-spans-2009.png" , sep = "/" ) ,
        width = threeFigWidth , height = threeFigHeight , units = "in" )

ggplot( data = plotData2019 %>%
          filter( MinVote > 1 ) %>%
          filter( ! ( MinVote == 9 & k == 8 ) ) %>%
          mutate( `Relative Min Vote` = MinVote / k ) %>%
          mutate( `Total Classifiers` = factor( k ) ) ,
        aes( y = F1 , 
             x = `Relative Min Vote` ,
             color = `Total Classifiers` ,
             group = ClassifierID ) ) +
  ylab( bquote( ~F[1] * '-Measure' ) ) +
  geom_point() +
  geom_line() +
  theme_bw() +
  theme( legend.position = "none" ) +
  guides( color = guide_legend( nrow = 1 ) )
ggsave( paste( plotDir , 
               "minVote-vs-Performance-cuis-2019.png" , sep = "/" ) ,
        width = threeFigWidth , height = threeFigHeight , units = "in" )
