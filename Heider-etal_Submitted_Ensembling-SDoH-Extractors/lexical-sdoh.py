import sys
import logging as log

import argparse

from tqdm import tqdm

import glob
import os

import re

import cassis
import medspacy

import warnings

warnings.filterwarnings( 'ignore' , category = UserWarning , module = 'cassis' )

from medspacy.common.medspacy_matcher import MedspacyMatcher
from medspacy.common import BaseRule

from utils import loadTypesystem

noteNlp_typeString = 'edu.musc.tbic.omop_cdm.Note_Nlp_TableProperties'
factRelationship_typeString = 'edu.musc.tbic.omop_cdm.Fact_Relationship_TableProperties'

#############################################
## helper functions
#############################################

def initialize_arg_parser():
    parser = argparse.ArgumentParser( description = """
""")
    parser.add_argument( '-v' , '--verbose' ,
                         help = "print more information" ,
                         action = "store_true" )

    parser.add_argument( '--progressbar-output' ,
                         dest = 'progressbar_output' ,
                         default = 'stderr' ,
                         choices = [ 'stderr' , 'stdout' , 'none' ] ,
                         help = "Pipe the progress bar to stderr, stdout, or neither" )

    parser.add_argument( '--pretty-print' ,
                         dest = 'pretty_print' ,
                         help = "Round floats and remove decimals from integers" ,
                         action = "store_true" )

    parser.add_argument( '--types-file' ,
                         dest = 'typesFile' ,
                         help = 'XML file containing the types that need to be loaded' )
    
    parser.add_argument( '--txt-root' , default = None ,
                         required = True ,
                         dest = "txt_root",
                         help = "Directory containing input corpus in text format" )
    
    parser.add_argument( '--lxcn-root' , default = None ,
                         required = True ,
                         dest = "lxcn_root",
                         help = "Directory for reading in tab-delimited lexicon files" )

    parser.add_argument( '--trigger-labels' , nargs = '+' ,
                         dest = 'trigger_labels' ,
                         default = [ 'Employment' , 'LivingStatus' , 'Alcohol' , 'Drug' , 'Tobacco' ] ,
                         choices = [ 'Employment' , 'LivingStatus' , 'Alcohol' , 'Drug' , 'Tobacco' ,
                                     'none' ] ,
                         help = "List of trigger labels to apply lexicons for" )

    parser.add_argument( '--no-triggers' ,
                         dest = 'noTriggers' ,
                         help = "Do not apply any trigger label lexicons" ,
                         action = "store_true" )

    parser.add_argument( '--modifier-labels' , nargs = '+' ,
                         dest = 'modifier_labels' ,
                         default = [ 'Amount' , 'Duration' , 'Frequency' , 'History' ,
                                     'Method' , 'StatusEmploy' , 'StatusTime' , 'Type' ,
                                     'TypeLiving' ] ,
                         choices = [ 'Amount' , 'Duration' , 'Frequency' , 'History' ,
                                     'Method' , 'StatusEmploy' , 'StatusTime' , 'Type' ,
                                     'TypeLiving' ,
                                     'none' ] ,
                         help = "List of modifier labels to apply lexicons for" )

    parser.add_argument( '--no-modifiers' ,
                         dest = 'noModifiers' ,
                         help = "Do not apply any modifier label lexicons" ,
                         action = "store_true" )

    parser.add_argument( '--cas-root' , default = None ,
                         required = True ,
                         dest = "cas_root",
                         help = "Directory for output corpus in CAS XMI formatted XML" )
    ##
    return parser

def get_arguments( command_line_args ):
    parser = initialize_arg_parser()
    args = parser.parse_args( command_line_args )
    ##
    return args

def init_args():
    ##
    args = get_arguments( sys.argv[ 1: ] )
    ## Set up logging
    if( args.verbose ):
        log.basicConfig( format = "%(levelname)s: %(message)s" ,
                         level = log.DEBUG )
        log.info( "Verbose output." )
        log.debug( "{}".format( args ) )
    else:
        log.basicConfig( format="%(levelname)s: %(message)s" )
    ## Configure progressbar peformance
    if( args.progressbar_output == 'none' ):
        args.progressbar_disabled = True
        args.progressbar_file = None
    else:
        args.progressbar_disabled = False
        if( args.progressbar_output == 'stderr' ):
            args.progressbar_file = sys.stderr
        elif( args.progressbar_output == 'stdout' ):
            args.progressbar_file = sys.stdout
    ####
    if( args.noTriggers or
        'none' in args.trigger_labels ):
        args.trigger_labels = []
    if( args.noModifiers or
        'none' in args.modifier_labels ):
        args.modifier_labels = []
    ##
    return args


eventMention_typeString = 'org.apache.ctakes.typesystem.type.textsem.EventMention'
modifier_typeString = 'org.apache.ctakes.typesystem.type.textsem.Modifier'
timeMention_typeString = 'org.apache.ctakes.typesystem.type.textsem.TimeMention'

event_typeString = 'org.apache.ctakes.typesystem.type.refsem.Event'
eventProperties_typeString = 'org.apache.ctakes.typesystem.type.refsem.EventProperties'
attribute_typeString = 'org.apache.ctakes.typesystem.type.refsem.Attribute'

umlsConcept_typeString = 'org.apache.ctakes.typesystem.type.refsem.UmlsConcept'

relationArgument_typeString = 'org.apache.ctakes.typesystem.type.relation.RelationArgument'
binaryTextRelation_typeString = 'org.apache.ctakes.typesystem.type.relation.BinaryTextRelation'

#############################################
## core functions
#############################################

def process_txt_file( note_contents , cas ,
                      nlp ,
                      span_matchers ,
                      typed_span_matchers ):
    spans = {}
    ##
    FSArray = typesystem.get_type( 'uima.cas.FSArray' )
    
    eventMentionType = typesystem.get_type( eventMention_typeString )
    modifierType = typesystem.get_type( modifier_typeString )
    timeMentionType = typesystem.get_type( timeMention_typeString )
    
    eventType = typesystem.get_type( event_typeString )
    eventPropertiesType = typesystem.get_type( eventProperties_typeString )
    attributeType = typesystem.get_type( attribute_typeString )
    
    umlsConceptType = typesystem.get_type( umlsConcept_typeString )
    
    relationArgumentType = typesystem.get_type( relationArgument_typeString )
    binaryTextRelationType = typesystem.get_type( binaryTextRelation_typeString )
    
    umlsConceptType = typesystem.get_type( umlsConcept_typeString )

    eventTypes = {}
    ##########################################################
    ## All Semantics Types are Finding (T033) unless otherwise
    ## specified
    ####################################################
    ## https://uts.nlm.nih.gov/uts/umls/concept/C2184149
    ## living situation
    eventTypes[ 'LivingStatus' ] = umlsConceptType( cui = 'C2184149' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0439044
    ## Living Alone
    eventTypes[ 'alone' ] = umlsConceptType( cui = 'C0439044' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0557130
    ## Lives with family
    eventTypes[ 'with_family' ] = umlsConceptType( cui = 'C0557130' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C3242657
    ## unrelated person
    eventTypes[ 'with_others' ] = umlsConceptType( cui = 'C3242657' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0237154
    ## Homelessness
    eventTypes[ 'homeless' ] = umlsConceptType( cui = 'C0237154' , tui = 'T033' )
    ####################################################
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0242271
    ## Employment status
    eventTypes[ 'Employment' ] = umlsConceptType( cui = 'C0242271' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0557351
    ## Employed
    eventTypes[ 'employed' ] = umlsConceptType( cui = 'C0557351' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0041674
    ## Unemployment
    eventTypes[ 'unemployed' ] = umlsConceptType( cui = 'C0041674' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0035345
    ## Retirement
    eventTypes[ 'retired' ] = umlsConceptType( cui = 'C0035345' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0682148
    ## Disability status
    eventTypes[ 'on_disability' ] = umlsConceptType( cui = 'C0682148' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0038492
    ## student (Population Group)
    eventTypes[ 'student' ] = umlsConceptType( cui = 'C0038492' , tui = 'T098' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0555052
    ## homemaker (Professional or Occupational Group)
    eventTypes[ 'homemaker' ] = umlsConceptType( cui = 'C0555052' , tui = 'T097' )
    ####################################################
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0001948
    ## Alcohol consumption (Individual Behavior)
    eventTypes[ 'Alcohol' ] = umlsConceptType( cui = 'C0001948' , tui = 'T055' )
    ####################################################
    ## https://uts.nlm.nih.gov/uts/umls/concept/C0281875
    ## illicit drug use (finding)
    eventTypes[ 'Drug' ] = umlsConceptType( cui = 'C0281875' , tui = 'T033' )
    ####################################################
    ## https://uts.nlm.nih.gov/uts/umls/concept/C1287520
    ## Tobacco use and exposure – finding
    eventTypes[ 'Tobacco' ] = umlsConceptType( cui = 'C1287520' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C1971295
    ## TOBACCO NON-USER
    eventTypes[ 'none' ] = umlsConceptType( cui = 'C1971295' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C1698618
    ## Ex-tobacco user
    eventTypes[ 'past' ] = umlsConceptType( cui = 'C1698618' , tui = 'T033' )
    ## https://uts.nlm.nih.gov/uts/umls/concept/C3853727
    ## Tobacco user
    eventTypes[ 'current' ] = umlsConceptType( cui = 'C3853727' , tui = 'T033' )
    ####
    for event_type in eventTypes:
        cas.add( eventTypes[ event_type ] )
    ####
    doc = nlp( note_contents )
    for matcher in span_matchers:
        ##continue
        matches = matcher( doc )
        if( len( matches ) > 0 ):
            for match in matches:
                match_id , begin_token , end_token = match
                begin_offset = doc[ begin_token ].idx
                end_offset = doc[ end_token - 1 ].idx + len( doc[ end_token - 1 ] )
                rule = matcher._rule_item_mapping[ nlp.vocab.strings[ match_id ] ]
                span_class = rule.category
                event_cui = eventTypes[ span_class ]
                if( span_class in [ 'Employment' ] ):
                    anEvent = eventType( ontologyConcept = event_cui ,
                                         properties = eventPropertiesType( category = 'Unknown' ) )
                elif( span_class in [ 'LivingStatus' ] ):
                    anEvent = eventType( ontologyConcept = event_cui ,
                                         properties = eventPropertiesType( aspect = 'Unknown' ,
                                                                           category = 'Unknown' ) )
                elif( span_class in [ 'Alcohol' , 'Drug' , 'Tobacco' ] ):
                    anEvent = eventType( ontologyConcept = event_cui ,
                                         properties = eventPropertiesType( aspect = 'Unknown' ) )
                ## Trigger Event Mention
                anEventMention = eventMentionType( begin = begin_offset ,
                                                   end = end_offset ,
                                                   ontologyConceptArr = FSArray( elements = [ eventTypes[ span_class ] ] ) ,
                                                   event = anEvent )
                ##
                cas.add( anEvent )
                cas.add( anEventMention )
    for matcher in typed_span_matchers:
        matches = matcher( doc )
        if( len( matches ) > 0 ):
            for match in matches:
                match_id , begin_token , end_token = match
                begin_offset = doc[ begin_token ].idx
                end_offset = doc[ end_token - 1 ].idx + len( doc[ end_token - 1 ] )
                rule = matcher._rule_item_mapping[ nlp.vocab.strings[ match_id ] ]
                span_class = rule.category
                span_value = rule.metadata[ 'label' ]
                if( span_value in [ 'Frequency' , 'Duration' , 'History' ] ):
                    roleMention = timeMentionType( begin = begin_offset ,
                                                   end = end_offset ,
                                                   timeClass = span_value )
                else:
                    roleMention = modifierType( begin = begin_offset ,
                                                end = end_offset ,
                                                category = span_value )
                cas.add( roleMention )
    ####
    return( cas )


def parse_lexicon_file( lxcn_root , factor , label = None ):
    rules = []
    with open( os.path.join( lxcn_root , '{}.lxcn'.format( factor ) ) , 'r' ) as fp:
        uniq_lines = []
        for line in fp:
            line = line.strip()
            if( line != '' ):
                if( line in uniq_lines ):
                    continue
                uniq_lines.append( line )
                lexical_entry = line.split( '\t' )
                if( len( lexical_entry ) == 2 ):
                    rules.append( BaseRule( lexical_entry[ 0 ] ,
                                            category = factor ,
                                            metadata = { "label" : lexical_entry[ 1 ] } ) )
                else:
                    ## If we didn't find a label in the lexical entry,
                    ## then we should treat this as a annotation
                    ## withour further subtypes.  We'll use the factor
                    ## name as the label to help with downstream
                    ## relation tagging
                    if( '\d+' in line ):
                        pattern_rule = []
                        for token in line.split( ' ' ):
                            pattern_rule.append( { "LOWER" : { "REGEX" : token } } )
                        rules.append( BaseRule( line ,
                                                category = factor ,
                                                pattern = pattern_rule ,
                                                metadata = { "label" : factor } ) )
                    else:
                        rules.append( BaseRule( line ,
                                                category = factor ,
                                                metadata = { "label" : factor } ) )
    return( rules )


if __name__ == "__main__":
    ##
    args = init_args()
    ##
    typesystem = loadTypesystem( args )
    ##
    ############################
    nlp = medspacy.load( enable = [ "pyrush" ] )
    ########
    ## Triggers
    triggerMatchers = []
    for factor in args.trigger_labels:
        if( os.path.exists( os.path.join( args.lxcn_root , '{}.lxcn'.format( factor ) ) ) ):
            log.debug( 'Loading \'{}.lxcn\''.format( factor ) )
            triggerMatchers.append( MedspacyMatcher( nlp , phrase_matcher_attr="LOWER" , prune = True ) )
            matcher_rules = parse_lexicon_file( args.lxcn_root ,
                                                factor )
            triggerMatchers[ len( triggerMatchers ) - 1 ].add( matcher_rules )
    ########
    ## Modifiers and TimeMentions
    modifierMatchers = []
    modifierLabels = { 'Amount' : None ,
                       'Duration' : None ,
                       'Frequency' : None ,
                       'History' : None ,
                       'Method' : None ,
                       'StatusEmploy' : 'employed' ,
                       'StatusTime' : 'current' ,
                       'Type' : None ,
                       'TypeLiving' : 'with_others' }
    for factor in args.modifier_labels:
        if( os.path.exists( os.path.join( args.lxcn_root , '{}.lxcn'.format( factor ) ) ) ):
            log.debug( 'Loading \'{}.lxcn\''.format( factor ) )
            modifierMatchers.append( MedspacyMatcher( nlp , phrase_matcher_attr="LOWER" , prune = True ) )
            matcher_rules = parse_lexicon_file( args.lxcn_root ,
                                                factor ,
                                                modifierLabels[ factor ] )
            modifierMatchers[ len( modifierMatchers ) - 1 ].add( matcher_rules )
    ############################
    ## Iterate over the files, covert to CAS, and write the XMI to disk
    file_list = [ os.path.basename( f ) for f in glob.glob( os.path.join( args.txt_root ,
                                                                          '*.txt' ) ) ]
    for txt_filename in tqdm( sorted( file_list ) ,
                              file = args.progressbar_file ,
                              disable = args.progressbar_disabled ):
        plain_filename = txt_filename[ 0:-4 ]
        txt_path = os.path.join( args.txt_root ,
                                 txt_filename )
        cas_path = os.path.join( args.cas_root ,
                                 '{}.xmi'.format( plain_filename ) )
        with open( txt_path , 'r' ) as fp:
            note_contents = fp.read().strip()
        cas = cassis.Cas( typesystem = typesystem )
        cas.sofa_string = note_contents
        cas.sofa_mime = "text/plain"
        cas = process_txt_file( note_contents ,
                                cas ,
                                nlp ,
                                triggerMatchers ,
                                modifierMatchers )
        cas.to_xmi( path = cas_path ,
                    pretty_print = True )

