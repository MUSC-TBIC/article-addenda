
Related repositories:

  - `Off-the-Shelf Ensemble Systems <https://github.com/MUSC-TBIC/ots-ensemble-systems>`_
    
  - `ETUDE engine <https://github.com/MUSC-TBIC/etude-engine>`_
    
  - Additional `ETUDE engine configs <https://github.com/MUSC-TBIC/etude-engine-configs>`_
  
Corrections
===========

We describe the `term_exists` field in the OMOP CDM as the best map
for the polarity flag. Upon further review, that analysis should be
considered a simplification.  The full description of `term_exists`
indicates it should be used to encode a composite picture of most of
the contextual attribute values indicating whether this should be a
current (pressing) concern:

    "Term_exists is defined as a flag that indicates if the patient
    actually has or had the condition. Any of the following modifiers
    would make Term_exists false: Negation = true Subject = [anything
    other than the patient] Conditional = true/li> Rule_out = true
    Uncertain = very low certainty or any lower certainties A complete
    lack of modifiers would make Term_exists true."

    -- `NOTE_NLP Table Definition <https://ohdsi.github.io/CommonDataModel/cdm53.html#NOTE_NLP>`_

In future updates to this work, we will indicate the polarity in the
`term_modifiers` field just as we did `uncertainty`.

Scripts
=======

Each corpus has a set of scripts that need to be customized to your
local directory structure.

The first script is called `prep-X.sh` and converts the corpus from
its source format into a standard format usable by the rest of the
scripts. An oracle or reference standard corpus is then created from
this standard format. Finally, all individual classifier outputs are
evaluated (that is, k=1).

The second script is called `score-X.sh` and models how you can set up
a husk around the third script to run a large batch of tests at
once. This script sets the appropriate environment variables for
testing the ensembling of a set of classifiers, which is actually done
by the third script.

The third script is called `score-X-kernel.sh`. It first generates an
oracle output for the given set of classifiers such that if the
correct reference annotations is provided by any of the classifiers,
it chooses that annotation.  Otherwise, it does nothing. This provides
a grounded performance ceiling for the given set of classifiers. The
classifiers are ensembled together, according to the parameters, and
their consensus output is scored.

- 2008 i2b2 Obesity Challenge Scripts
  
  - prep-context-attributes.sh
    
  - score-context-attributes.sh
    
    - score-context-attributes-kernel.sh

- 2009 i2b2 Medication Challenge Scripts

  - prep-spans.sh

  - score-spans.sh

    - score-spans-kernel.sh

- 2019 n2c2 Track 3 Challenge Scripts

  - prep-cuis.sh

  - score-cuis.sh

    - score-cuis-kernel.sh

      
Evaluation
==========

A R script (`score_classifiers.R`) has been provided that can be used
to generate plots similar to those presented. A few paths at the head
of the script will need to be adjusted. For instance, the path
`paperRoot` should point to whichever folder your wrote the output
evaluation data to. The `data-final` folder contains all the
consolidated data used in plotting. The `figures` folder contains all
output figures. Both of these directories will need to be created.
