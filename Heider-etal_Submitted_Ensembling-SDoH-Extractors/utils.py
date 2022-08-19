import cassis

## TODO - make this easily configurable from the command line
def loadTypesystem( args ):
    ############################
    ## Create a type system
    ## - https://github.com/dkpro/dkpro-cassis/blob/master/cassis/typesystem.py
    with open( args.typesFile , 'rb' ) as fp:
        typesystem = cassis.load_typesystem( fp )
    ############
    ## ... for OMOP CDM v5.3 NOTE_NLP table properties
    ##     https://ohdsi.github.io/CommonDataModel/cdm53.html#NOTE_NLP
    NoteNlp = typesystem.create_type( name = 'edu.musc.tbic.omop_cdm.Note_Nlp_TableProperties' ,
                                      supertypeName = 'uima.tcas.Annotation' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'note_nlp_id' ,
                               description = 'A unique identifier for the NLP record.' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'note_id' ,
                               description = 'This is the NOTE_ID for the NOTE record the NLP record is associated to.' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'section_concept_id' ,
                               description = '' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'snippet' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'offset' ,
                               description = '' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'lexical_variant' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'note_nlp_concept_id' ,
                               description = '' ,
                               rangeType = 'uima.cas.Integer' )
    ## TODO - this really should be an int but we can't look up the appropriate
    ##        ID without a connected OMOP CDM Concept table
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'note_nlp_source_concept_id' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'nlp_system' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'term_exists' ,
                               description = 'Term_exists is defined as a flag that indicates if the patient actually has or had the condition. Any of the following modifiers would make Term_exists false: Negation = true; Subject = [anything other than the patient]; Conditional = true; Rule_out = true; Uncertain = very low certainty or any lower certainties. A complete lack of modifiers would make Term_exists true. For the modifiers that are there, they would have to have these values: Negation = false; Subject = patient; Conditional = false; Rule_out = false; Uncertain = true or high or moderate or even low (could argue about low).' ,
                               rangeType = 'uima.cas.Boolean' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'term_temporal' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    typesystem.create_feature( domainType = NoteNlp ,
                               name = 'term_modifiers' ,
                               description = '' ,
                               rangeType = 'uima.cas.String' )
    ############
    ## ... for OMOP CDM v5.3 FACT_RELATIONSHIP table properties
    ##     https://ohdsi.github.io/CommonDataModel/cdm53.html#FACT_RELATIONSHIP
    FactRelationship = typesystem.create_type( name = 'edu.musc.tbic.omop_cdm.Fact_Relationship_TableProperties' ,
                                               supertypeName = 'uima.tcas.Annotation' )
    typesystem.create_feature( domainType = FactRelationship ,
                               name = 'domain_concept_id_1' ,
                               description = 'The CONCEPT id for the appropriate scoping domain' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = FactRelationship ,
                               name = 'fact_id_1' ,
                               description = 'The id for the first fact' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = FactRelationship ,
                               name = 'domain_concept_id_2' ,
                               description = 'The CONCEPT id for the appropriate scoping domain' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = FactRelationship ,
                               name = 'fact_id_2' ,
                               description = 'The id for the second fact' ,
                               rangeType = 'uima.cas.Integer' )
    typesystem.create_feature( domainType = FactRelationship ,
                               name = 'relationship_concept_id' ,
                               description = 'This id for the relationship held between the two facts' ,
                               rangeType = 'uima.cas.Integer' )
    ####
    return( typesystem )


