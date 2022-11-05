

Replicating Table 1 and Figure 1
--------------------------------

Running the `synthetic_data_proof-of-concept.R` script will replicate
the calculations used to generate Table 1 and Figure 1 with the same
underlying sample data.  Due to the nature of re-sampling, the exact
numbers and shape of the curve may vary slightly.  



```

RScript synthetic_data_proof-of-concept.R

```

*NB:* The sample size in this script is set to a very low number to
allow casual users to easily run the script.  Near the top of the file
is a variable called `bootstrapPower`.  It is used to calculate `nt`
(near line 108).  The value of `nt` determines the sample size.  We
have included the rough timings for different values to help gage how
long the algorithm will take to run at different levels of complexity.
If an `*.rds` file matching the experimental settings is present in
the `data-final` folder, the script will load that generated data for
analysis rather than requiring a recalculation of the sample
distribution every time.

```

bootstrapPower <- 10
##             100 =  1.5 secs
## 2**10 =    1024 = 15   secs
## 2**15 =   32768 =  8.2 minutes
## 2**20 = 1048576 =  4.9 hours

```

This script generates an additional table not in the abstract
including the probability that each of four reported metrics happened
by chance.

| Technique        | RecallProb | PrecisionProb | F1Prob | AccuracyProb |
|------------------|-----------:|--------------:|-------:|-------------:|
| Yeh              |     0.0010 |        0.0254 | 0.0176 |       0.0195 |
| Berg-Kirkpatrick |     0.0010 |        0.0351 | 0.0088 |       0.0088 |

In other words, 1.76 % of the samples generated using Yeh's algorithm
and 0.88 % of those from Berg-Kirkpatrick's algorithm had differences
in F1-measure more extreme than those observed.

Running Simulations with 2019 n2c2 Data
---------------------------------------

First, we'll need to convert the n2c2 dataset into something that
ETUDE can score.  To do that, we'll use a script available in the
`Off-the-Shelf Ensemble Systems
<https://github.com/musc-tbic/ots-ensemble-systems>`_ repository.

```

## We'll need to initialize our output folder
mkdir -f /tmp/n2c2-2019/train_merged

## The `top10_outputs` is a folder containing 10 `.txt` files 
## (one for each of the top teams).

python n2c2-2019-track3-converter.py \
    --input-text /path/to/2019_n2c2_track-3/train/train_note \
    --input-norm /path/to/2019_n2c2_track-3/train/train_norm \
    --input-systems /path/to/2019_n2c2_track-3/top10_outputs \
    --file-list /path/to/2019_n2c2_track-3/train/train_file_list.txt \
    --output-dir /tmp/n2c2-2019/train_merged

```

Running a simple voting ensemble with a mininum vote of 1 and passing
it a single classifier to ensemble into the cohort is equivalent to a
pass-through of the classifier.  It's may seem like an over-engineered
way to get the classifier's output but it means we can keep the same
scripting regardless of whether we're doing an initial run with just
one classifier or with an arbitrary number of classifiers.

```

for CLASSIFIER in 1 2 3;do \
  mkdir -f /tmp/n2c2-2019/train_${CLASSIFIER}
  ## Simple voting ensemble system
  python \
      votingEnsemble.py \
      --types-dir ../types \
      --input-dir /tmp/n2c2-2019/train_merged \
      --voting-unit span \
      --classifier-list ${CLASSIFIER} \
      --min-votes 1 \
      --overlap-strategy rank \
      --zero-strategy drop \
      --output-dir /tmp/n2c2-2019/train_${CLASSIFIER};done

```

We'll also need to check out ETUDE and some standar ETUDE evaluation
config files available in the following repositories, respectively:

- `ETUDE <https://github.com/musc-tbic/etude-engine>`_
- `ETUDE configs <https://github.com/musc-tbic/etude-engine-configs>`_

For convenience, we can assign the directory that these tools were
check out to to ENVIRONMENT variables:

```

export ETUDE_DIR=/path/to/etude-engine
export CONFIG_DIR=/path/to/etude-engine-configs

```

Now that we have the output of three systems, we can compare any two
of them at a time to generate score cards as output.  These score
cards are medium verbose audit trails of how/why ETUDE generates the
scores that it does. 

```

for CLASSIFIER in 2 3;do \
    mkdir /tmp/n2c2c-2019/train_score-cards_${CLASSIFIER}; \
    python ${ETUDE_DIR}/etude.py \
      --reference-conf ${CONFIG_DIR}/uima/ensemble_note-nlp_xmi.conf \
      --reference-input /tmp/n2c2-2019/train_1 \
      --test-conf ${CONFIG_DIR}/uima/ensemble_note-nlp_xmi.conf \
      --test-input /tmp/n2c2-2019/train_${CLASSIFIER} \
      --file-suffix ".xmi" \
      --fuzzy-match-flags exact \
      --score-normalization note_nlp_source_concept_id \
      -m Accuracy TP FP FN TN \
      --test-out /tmp/n2c2-2019/train_score-cards_${CLASSIFIER} \
      --write-score-cards;done
      
```



Running Simulations with 2009 i2b2 Data
---------------------------------------

First, we'll need to convert the i2b2 dataset into something that
ETUDE can score.  To do that, we'll use a script available in the
`Off-the-Shelf Ensemble Systems
<https://github.com/musc-tbic/ots-ensemble-systems>`_ repository.

```

## We'll need to initialize our output folder
mkdir -f /tmp/i2b2-2009/test_merged

## The `top_subs` is a folder containing one folder per team 
## containing `.entries` files for each input document.

python i2b2-2009-medications-converter.py \
    --input-text /path/to/2009_i2b2_challenge_medications/test_corpus \
    --input-ref /path/to/2009_i2b2_challenge_medications/test_annotations/converted.noduplicates.sorted \
    --input-systems /path/to/2009_i2b2_challenge_medications/team_submissions/top_subs \
    --output-dir /tmp/i2b2-2009/test_merged

```

Running a simple voting ensemble with a mininum vote of 1 and passing
it a single classifier to ensemble into the cohort is equivalent to a
pass-through of the classifier.  It's may seem like an over-engineered
way to get the classifier's output but it means we can keep the same
scripting regardless of whether we're doing an initial run with just
one classifier or with an arbitrary number of classifiers.

```

for CLASSIFIER in 1 2 3;do \
  mkdir -p /tmp/i2b2-2009/test_${CLASSIFIER}
  ## Simple voting ensemble system
  python \
    votingEnsemble.py \
    --types-dir ../types \
    --input-dir /tmp/i2b2-2009/test_merged \
    --voting-unit span \
    --classifier-list ${CLASSIFIER} \
    --min-votes 1 \
    --overlap-strategy rank \
    --zero-strategy drop \
    --output-dir /tmp/i2b2-2009/test_${CLASSIFIER};done

```

We'll also need to check out ETUDE and some standar ETUDE evaluation
config files available in the following repositories, respectively:

- `ETUDE <https://github.com/musc-tbic/etude-engine>`_
- `ETUDE configs <https://github.com/musc-tbic/etude-engine-configs>`_

For convenience, we can assign the directory that these tools were
check out to to ENVIRONMENT variables:

```

export ETUDE_DIR=/path/to/etude-engine
export CONFIG_DIR=/path/to/etude-engine-configs

```

Now that we have the output of three systems, we can compare any two
of them at a time to generate score cards as output.  These score
cards are medium verbose audit trails of how/why ETUDE generates the
scores that it does. 

```

for CLASSIFIER in 2 3;do \
    mkdir -p /tmp/i2b2-2009/test_score-cards_${CLASSIFIER}; \
    python ${ETUDE_DIR}/etude.py \
      --reference-conf ${CONFIG_DIR}/uima/ensemble_note-nlp_xmi.conf \
      --reference-input /tmp/i2b2-2009/test_1 \
      --test-conf ${CONFIG_DIR}/uima/ensemble_note-nlp_xmi.conf \
      --test-input /tmp/i2b2-2009/test_${CLASSIFIER} \
      --file-suffix ".xmi" \
      --fuzzy-match-flags partial \
      -m Accuracy TP FP FN TN \
      --test-out /tmp/i2b2-2009/test_score-cards_${CLASSIFIER} \
      --write-score-cards;done
      
```



Running Simulations with 2008 i2b2 Data
---------------------------------------

First, we'll need to convert the i2b2 dataset into something that
ETUDE can score.  To do that, we'll use a script available in the
`Off-the-Shelf Ensemble Systems
<https://github.com/musc-tbic/ots-ensemble-systems>`_ repository.

```

## We'll need to initialize our output folder
mkdir -f /tmp/i2b2-2008/test_merged

## The `top_subs` is a folder containing one files per per team.

python i2b2-2008-obesity-converter.py \
	  --input-text /path/to/2008_i2b2_challenge_obesity/obesity_corpus_test.xml \
	  --input-ref /path/to/2008_i2b2_challenge_obesity/obesity_annotations_test.xml \
	  --input-systems /path/to/2008_i2b2_challenge_obesity/team_submissions/top_subs \
	  --output-dir /tmp/i2b2-2008/test_merged

```

Running a simple voting ensemble with a mininum vote of 1 and passing
it a single classifier to ensemble into the cohort is equivalent to a
pass-through of the classifier.  It's may seem like an over-engineered
way to get the classifier's output but it means we can keep the same
scripting regardless of whether we're doing an initial run with just
one classifier or with an arbitrary number of classifiers.

```

for CLASSIFIER in 1 2 3;do \
  mkdir -p /tmp/i2b2-2008/test_${CLASSIFIER}
  ## Simple voting ensemble system
  python \
    votingEnsemble.py \
    --types-dir ../types \
    --input-dir /tmp/i2b2-2008/test_merged \
    --voting-unit doc \
    --classifier-list ${CLASSIFIER} \
    --min-votes 1 \
    --overlap-strategy rank \
    --zero-strategy drop \
    --output-dir /tmp/i2b2-2008/test_${CLASSIFIER};done

```

We'll also need to check out ETUDE and some standar ETUDE evaluation
config files available in the following repositories, respectively:

- `ETUDE <https://github.com/musc-tbic/etude-engine>`_
- `ETUDE configs <https://github.com/musc-tbic/etude-engine-configs>`_

For convenience, we can assign the directory that these tools were
check out to to ENVIRONMENT variables:

```

export ETUDE_DIR=/path/to/etude-engine
export CONFIG_DIR=/path/to/etude-engine-configs

```

Now that we have the output of three systems, we can compare any two
of them at a time to generate score cards as output.  These score
cards are medium verbose audit trails of how/why ETUDE generates the
scores that it does. 

```

for CLASSIFIER in 2 3;do \
    mkdir -p /tmp/i2b2-2008/test_score-cards_${CLASSIFIER}; \
    python ${ETUDE_DIR}/etude.py \
      --reference-conf ${CONFIG_DIR}/i2b2/i2b2-2008-obesity_doc-level_note-nlp.conf \
      --reference-input /tmp/i2b2-2008/test_1 \
      --test-conf ${CONFIG_DIR}/i2b2/i2b2-2008-obesity_doc-level_note-nlp.conf \
      --test-input /tmp/i2b2-2008/test_${CLASSIFIER} \
      --file-suffix ".xmi" \
      --fuzzy-match-flags doc-property \
      -m Accuracy TP FP FN TN \
      --test-out /tmp/i2b2-2008/test_score-cards_${CLASSIFIER} \
      --write-score-cards;done
      
```

