#!/bin/zsh

## Available from:  https://github.com/MUSC-TBIC/corpus-utils
UTILS_DIR=/path/to/corpus-utils/n2c2

## Available from:  https://github.com/Lybarger/brat_scoring
SCORING_DIR=/path/to/brat_scoring/brat_scoring

## Available from:  https://portal.dbmi.hms.harvard.edu/projects/n2c2-2022-t2/
SDOH_DIR=/path/to/Social-History-Annotated-Corpus/train

## Available from:  https://ctakes.apache.org/downloads.cgi
TYPESYSTEM_FILE=/path/to/apache-ctakes-4.0.0.1/resources/org/apache/ctakes/typesystem/types/TypeSystem.xml

## Temporary folders than can be anywhere
OMOP_DIR=/tmp/omopCdm
ROUNDTRIP_DIR=/tmp/sdohBrat

mkdir -p ${ROUNDTRIP_DIR}

for subset in mimic uw;do \
    mkdir -p ${ROUNDTRIP_DIR}/${subset}
    
    python ${UTILS_DIR}/convert-n2c2-sdoh-brat-to-omop-cdm.py \
           --types-file ${TYPESYSTEM_FILE} \
           --txt-root ${SDOH_DIR}/${subset} \
           --brat-root ${SDOH_DIR}/${subset} \
           --cas-root ${OMOP_DIR}/${subset}

    python ${UTILS_DIR}/convert-omop-cdm-to-n2c2-sdoh-brat.py \
           --types-file ${TYPESYSTEM_FILE} \
           --cas-root ${OMOP_DIR}/${subset} \
           --txt-root ${ROUNDTRIP_DIR}/${subset} \
           --brat-root ${ROUNDTRIP_DIR}/${subset}
    
    python ${SCORING_DIR}/run_sdoh_scoring.py \
           ${SDOH_DIR}/${subset} \
           ${ROUNDTRIP_DIR}/${subset} \
           /tmp/scoringRoundTrip-${subset}.csv \
           --score_trig overlap \
           --score_span exact \
           --score_labeled label;
done
