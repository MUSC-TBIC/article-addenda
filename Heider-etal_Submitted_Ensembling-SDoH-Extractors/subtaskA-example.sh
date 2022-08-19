#!/bin/zsh

## Task specific Anaconda environments for each of the major Python
## scripts used:
## -- for running lexical-sdoh.py
export SDOH_BIN=/Users/pmh/opt/anaconda3/envs/n2c2SDoH-py3.8/bin
## -- for running the brat_scoring script
export SCORING_BIN=/Users/pmh/opt/anaconda3/envs/bratScoring-py3.8/bin
## -- for running the post-hoc ensemble generator
export ENSEMBLE_BIN=/Users/pmh/opt/anaconda3/envs/ensemble-py3.8/bin

## Available from:  https://github.com/MUSC-TBIC/corpus-utils
export CORPUS_UTILS_DIR=/Users/pmh/git/corpus-utils
## Path to this folder
export SDOH_DIR=/Users/pmh/git/article-addenda/Heider-etal_Submitted_Ensembling-SDoH-Extractors
## Available from:  https://github.com/Lybarger/brat_scoring
export SCORING_DIR=/Users/pmh/git/brat_scoring
## Available from:  https://github.com/MUSC-TBIC/ots-ensemble-systems
export ENSEMBLE_DIR=/Users/pmh/git/ots-ensemble-systems

## Available from:  https://ctakes.apache.org/downloads.cgi
export TYPES_FILE=/Users/pmh/bin/apache-ctakes-4.0.0.1/resources/org/apache/ctakes/typesystem/types/TypeSystem.xml

export OUTPUT_ROOT=/tmp/sdoh-results/2022_n2c2_sdoh
export RESULTS_DIR=/tmp/sdoh-results/Track2_SubtaskA/results
export SUBMISSION_ROOT=/tmp/sdoh-results/Track2_SubtaskA/submissions

export TASKA_CORPUS_ROOT=/Users/pmh/data/shac
export TASKA_MODELS_ROOT=/tmp/sdoh-results/Track2_SubtaskA/models
export TASKA_LEXICON_ROOT=/tmp/sdoh-results/lexicons


mkdir -p ${OUTPUT_ROOT}
mkdir -p ${RESULTS_DIR}
mkdir -p ${SUBMISSION_ROOT}
mkdir -p ${TASKA_LEXICON_ROOT}
mkdir -p ${TASKA_MODELS_ROOT}

function omop2Brat () {
    CAS_SUFFIX=$1
    LEFT_WINDOW=$2
    RIGHT_WINDOW=$3
    TXT_OUT_SUFFIX=$4
    BRAT_OUT_SUFFIX=$5
    ####
    mkdir -p ${SUBMISSION_ROOT}/${TXT_OUT_SUFFIX}
    mkdir -p ${SUBMISSION_ROOT}/${BRAT_OUT_SUFFIX}
    ## Convert OMOP CDM (NoteNLP) into brat output
    print "Convert OMOP CDM (NoteNLP) into brat output"
    print "  ${CAS_SUFFIX} -> ${BRAT_OUT_SUFFIX}"
    ##set -x
    ${SDOH_BIN}/python ${CORPUS_UTILS_DIR}/n2c2/convert-omop-cdm-to-n2c2-sdoh-brat.py \
               --left-window ${LEFT_WINDOW} \
               --right-window ${RIGHT_WINDOW} \
               --types-file ${TYPES_FILE} \
               --cas-root ${OUTPUT_ROOT}/${CAS_SUFFIX} \
               --txt-root ${SUBMISSION_ROOT}/${TXT_OUT_SUFFIX} \
               --brat-root ${SUBMISSION_ROOT}/${BRAT_OUT_SUFFIX}
}

function extractLexicons () {
    TXT_IN_SUFFIX=$1
    BRAT_IN_SUFFIX=$2
    MIN_SIZE=$3
    LEXICON_SUFFIX=$4
    NORMALIZE_FLAG=$5
    ####
    mkdir -p ${TASKA_LEXICON_ROOT}/${LEXICON_SUFFIX}
    ## Extract lexicons from brat corpus
    print "Extract lexicons from brat corpus"
    print "  ${BRAT_IN_SUFFIX} --> ${LEXICON_SUFFIX}"
    ${SDOH_BIN}/python ${CORPUS_UTILS_DIR}/n2c2/convert-n2c2-sdoh-brat-to-omop-cdm.py \
               --normalization ${NORMALIZE_FLAG} \
               --min-term-length ${MIN_SIZE} \
               --types-file ${TYPES_FILE} \
               --txt-root ${TASKA_CORPUS_ROOT}/${TXT_IN_SUFFIX} \
               --brat-root ${TASKA_CORPUS_ROOT}/${BRAT_IN_SUFFIX} \
               --lxcn-root ${TASKA_LEXICON_ROOT}/${LEXICON_SUFFIX}
}

function applyAllLexicons () {
    LEXICON_SUFFIX=$1
    TXT_IN_SUFFIX=$2
    CAS_OUT_SUFFIX=$3
    ####
    mkdir -p ${OUTPUT_ROOT}/${CAS_OUT_SUFFIX}
    ## Apply lexicons to txt corpus and generate SHARPn output
    print "Apply lexicons to txt corpus and generate SHARPn output"
    print "  ${TXT_IN_SUFFIX} --( all )--> ${CAS_OUT_SUFFIX}"
    ${SDOH_BIN}/python ${SDOH_DIR}/lexical-sdoh.py \
               --types-file ${TYPES_FILE} \
               --lxcn-root ${TASKA_LEXICON_ROOT}/${LEXICON_SUFFIX} \
               --txt-root ${TASKA_CORPUS_ROOT}/${TXT_IN_SUFFIX} \
               --cas-root ${OUTPUT_ROOT}/${CAS_OUT_SUFFIX}
}

function applySpecificLexicons () {
    LEXICON_SUFFIX=$1
    TRIGGER_FLAG=$2
    MODIFIER_FLAG=$3
    TXT_IN_SUFFIX=$4
    CAS_OUT_SUFFIX=$5
    ####
    mkdir -p ${OUTPUT_ROOT}/${CAS_OUT_SUFFIX}
    ## Apply lexicons to txt corpus and generate SHARPn output
    print "Apply lexicons to txt corpus and generate SHARPn output"
    print "  ${TXT_IN_SUFFIX} --( ${LEXICON_SUFFIX} )--> ${CAS_OUT_SUFFIX}"
    ${SDOH_BIN}/python ${SDOH_DIR}/lexical-sdoh.py \
               --types-file ${TYPES_FILE} \
               --lxcn-root ${TASKA_LEXICON_ROOT}/${LEXICON_SUFFIX} \
               --trigger-labels ${TRIGGER_FLAG} \
               --modifier-labels ${MODIFIER_FLAG} \
               --txt-root ${TASKA_CORPUS_ROOT}/${TXT_IN_SUFFIX} \
               --cas-root ${OUTPUT_ROOT}/${CAS_OUT_SUFFIX}
}

function mergeSystems () {
    TXT_IN_SUFFIX=$1
    SYSTEM_IN_SUFFIX=$2
    SHARPN_OUT_SUFFIX=$3
    ####
    mkdir -p ${OUTPUT_ROOT}/${SHARPN_OUT_SUFFIX}
    ## Merge ref and system outputs to create ensemble-able SHARPn corpus
    print "Merge ref and system outputs to create ensemble-able SHARPn corpus"
    print "  ${TXT_IN_SUFFIX} + ${SYSTEM_IN_SUFFIX}/* -> ${SHARPN_OUT_SUFFIX}"
    ${ENSEMBLE_BIN}/python ${ENSEMBLE_DIR}/medspaCy/n2c2-2022-sdoh-converter.py \
                   --types-file ${TYPES_FILE} \
                   --input-text ${TASKA_CORPUS_ROOT}/${TXT_IN_SUFFIX} \
                   --input-systems ${OUTPUT_ROOT}/${SYSTEM_IN_SUFFIX} \
                   --output-dir ${OUTPUT_ROOT}/${SHARPN_OUT_SUFFIX}
}

function trainEnsemble (){
    SHARPN_IN_SUFFIX=$1
    CLASSIFIER_LIST=$2
    MODEL_DIR=$3
    MODEL_FILE=$4
    ####
    mkdir -p ${TASKA_MODELS_ROOT}/${MODEL_DIR}
    ## Train a decision template model
    print "Train a decision template model"
    print "  ${SHARPN_IN_SUFFIX} -> ${MODEL_FILE}"
    ${ENSEMBLE_BIN}/python \
                   ${ENSEMBLE_DIR}/medspaCy/decisionTemplate.py \
                   --types-file ${TYPES_FILE} \
                   --phase train \
                   --no-split \
                   --voting-unit span \
                   --input-dir ${OUTPUT_ROOT}/${SHARPN_IN_SUFFIX} \
                   --classifier-list ${CLASSIFIER_LIST} \
                   --overlap-strategy rank \
                   --zero-strategy drop \
                   --decision-profiles-file ${TASKA_MODELS_ROOT}/${MODEL_DIR}/${MODEL_FILE}
}

function testEnsemble (){
    SHARPN_IN_SUFFIX=$1
    CLASSIFIER_LIST=$2
    MODEL_DIR=$3
    MODEL_FILE=$4
    OMOP_OUT_SUFFIX=$5
    ####
    mkdir -p ${OUTPUT_ROOT}/${OMOP_OUT_SUFFIX}
    ## Test a decision template model
    print "Test a decision template model"
    print "  ${SHARPN_IN_SUFFIX} -> ${OMOP_OUT_SUFFIX}"
    ${ENSEMBLE_BIN}/python \
                   ${ENSEMBLE_DIR}/medspaCy/decisionTemplate.py \
                   --types-file ${TYPES_FILE} \
                   --phase test \
                   --no-split \
                   --voting-unit span \
                   --input-dir ${OUTPUT_ROOT}/${SHARPN_IN_SUFFIX} \
                   --classifier-list "${CLASSIFIER_LIST}" \
                   --overlap-strategy rank \
                   --zero-strategy drop \
                   --decision-profiles-file ${TASKA_MODELS_ROOT}/${MODEL_DIR}/${MODEL_FILE} \
                   --output-dir ${OUTPUT_ROOT}/${OMOP_OUT_SUFFIX}
}

function mergeNoteNlps () {
    OMOP_OUT_ROOT=$1
    OMOP_MERGED_DIR=$2
    ####
    mkdir -p ${OUTPUT_ROOT}/${OMOP_MERGED_DIR}
    ## Merge OMOP CDM (NoteNLP) outputs into a single file
    print "Merge OMOP CDM (NoteNLP) outputs into a single file"
    print "  ${OMOP_OUT_ROOT} -> ${OMOP_MERGED_DIR}"
    ${ENSEMBLE_BIN}/python \
                   ${ENSEMBLE_DIR}/medspaCy/n2c2-2022-omop-cdm-merger.py \
                   --types-file ${TYPES_FILE} \
                   --input-systems ${OUTPUT_ROOT}/${OMOP_OUT_ROOT} \
                   --output-dir ${OUTPUT_ROOT}/${OMOP_MERGED_DIR}
}

function scoreSystem () {
    BRAT_IN_SUFFIX=$1
    BRAT_OUT_SUFFIX=$2
    RESULTS_SUFFIX=$3
    ## Score brat output
    print "Scoring brat output of each system"
    print "  ${BRAT_IN_SUFFIX} vs. ${BRAT_OUT_SUFFIX}"
    ${SCORING_BIN}/python ${SCORING_DIR}/brat_scoring/run_sdoh_scoring.py \
                  ${TASKA_CORPUS_ROOT}/${BRAT_IN_SUFFIX} \
                  ${SUBMISSION_ROOT}/${BRAT_OUT_SUFFIX} \
                  ${RESULTS_DIR}/${RESULTS_SUFFIX} \
                  --score_trig overlap \
                  --score_span exact \
                  --score_labeled label
}

########
corpus=mimic
split=test
leftW=1
rightW=35

#######################################################################
##
##  Extract lexical from the MIMIC-III train split
##
#######################################################################

for split in train
do
    for minTermLen in 0 3 5
    do
        for normalization in none lowercase digits
        do
            ####
            ## Don't run this loop if we've already generated the first lexicon for this
            if [[ ! -a ${TASKA_LEXICON_ROOT}/${split}_${normalization}/${minTermLen}/Alcohol.lxcn ]]; then
                extractLexicons "${split}/mimic" \
                                "${split}/mimic" \
                                "${minTermLen}" \
                                "${split}_${normalization}/${minTermLen}" \
                                "${normalization}"
            fi
        done
        ########

    done
    ########

done
########

#######################################################################
##
##  A single K-wise Lexical Classifier filter to at least 3 chars
##
#######################################################################

for split in train test
do
    for minTermLen in 3
    do
        ####
        for normalization in none lowercase digits
        do
            ####
            applyAllLexicons "train_${normalization}/${minTermLen}" \
                             "${split}/${corpus}" \
                             "a6/01_lexicons_sharpn/${split}/${normalization}"
        done
        ########
        mergeSystems "${split}/${corpus}" \
                     "a6/01_lexicons_sharpn/${split}" \
                     "a6/02_merged_sharpn/${split}"

        for classifiers in "3"
        do
            safe_classifiers=`echo $classifiers | tr ' ' 'x'`
            ## Train a new model if it doesn't exist yet for this
            ## configuration.  We're being a bit clever here by
            ## running the train split first so a model will always be
            ## generated on the first loop (split=train) to the test
            ## on the second loop (split=test).
            if [[ ! -a ${TASKA_MODELS_ROOT}/v005/v005_${safe_classifiers}_${minTermLen}.pkl ]]; then
                trainEnsemble "a6/02_merged_sharpn/train" \
                              "${classifiers}" \
                              "v005" \
                              "v005_${safe_classifiers}_${minTermLen}.pkl"
            fi
            ####
            testEnsemble "a6/02_merged_sharpn/${split}" \
                         "${classifiers}" \
                         "v005" \
                         "v005_${safe_classifiers}_${minTermLen}.pkl" \
                         "a6/03_ensembled_omop/${split}"
            
            omop2Brat "a6/03_ensembled_omop/${split}" \
                      "${leftW}" "${rightW}" \
                      "a6/Text/${split}/${corpus}" \
                      "a6/Text/${split}/${corpus}"
            ####
            scoreSystem "${split}/${corpus}" \
                        "a6/Text/${split}/${corpus}" \
                        "submission_a6_${split}.csv"

        done
    done
done
