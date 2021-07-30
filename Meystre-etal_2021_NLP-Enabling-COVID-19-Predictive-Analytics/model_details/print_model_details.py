import os
import sys

from sklearn.linear_model import LogisticRegression
from sklearn import svm

import pickle

modelFile = os.path.join( 'models' ,
                          sys.argv[ 2 ] )
clf = None

trained_features , clf = pickle.load( open( modelFile , 'rb' ) )

print( 'Trained features (n = {}):\n\n\t- {}\n'.format( len( trained_features ) , 
                                                        '\n\t- '.join( trained_features ) ) )

print( 'Parameters:\n\n{}\n'.format( clf ) )

print( 'classes_:\n\n{}\n\nintercept_:\n\n{}\n'.format( clf.classes_ ,
                                                        clf.intercept_ ) )

if( sys.argv[ 1 ] == 'logreg' ):
    print( 'Coefficients:\n' )
    for i in range( 0 , len( clf.coef_[ 0 ] ) ):
        print( '\t{}\t{}'.format( clf.coef_[ 0 ][ i ] , trained_features[ i ] ) )
