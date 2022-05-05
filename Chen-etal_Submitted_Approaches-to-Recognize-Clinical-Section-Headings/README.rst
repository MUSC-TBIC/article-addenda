
Scripts
=======

The sectionizer the employs medspaCy's rule-based approach and the
SVM-based system based on spaCy's features can be run using the
scripts provided in our `Off-the-Shelf Clinical Sectionizer
<https://github.com/MUSC-TBIC/ots-clinical-sectionizer>`_
repository.

The libSVM sectionizer (using WEKA on the back-end) is not (yet)
publicly available.

Sample evaluation scripts using the `ETUDE engine
<https://github.com/MUSC-TBIC/etude-engine>`_ are also available in
the clinical sectionizer repository.

Corpora
=======

Primary corpus
--------------

The primary corpus is an augmentation on top of the i2b2 2014 corpus
including normalized section headers. [1]_[2]_

- 1304 [3]_ notes
  
  - 790 [3]_ in train split (60%)

  - 514 in test split (40%)

- 13133 section headers

  - 7981 in train split (61%)

  - 5152 in test split (39%)

.. [3] Listed as 1299 and 785, respectively, in the original abstract
       
Additional corpus
-----------------

- 86 notes
  
  - 100% used for testing
    
- 2920 section headers

Results
=======

Table 1. Top five models and their precision, recall, F1-score
--------------------------------------------------------------

+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+
| Corpus |   Engine     | BoW    |  Vocab  | Training    |  SVM   |   P   |   R   |   F   |
|        |              | source |  size   | approach    | Kernel |       |       |       |
+========+==============+========+=========+=============+========+=======+=======+=======+
| BigODM | scikit-learn | Header | Larger  |  Two-step   |  RBF   | 0.860 | 0.865 | 0.863 |
+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+
| BigODM | scikit-learn | Header | Smaller |  Two-step   |  RBF   | 0.825 | 0.810 | 0.818 |
+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+
| BigODM | scikit-learn | Header | Smaller | Two-step:   |  RBF   | 0.824 | 0.808 | 0.816 |
|        |              |        |         |  As Feature |        |       |       |       |
+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+
| BigODM | scikit-learn | Header | Larger  | Two-step:   |  RBF   | 0.823 | 0.807 | 0.815 |
|        |              |        |         |  As Feature |        |       |       |       |
+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+
| BigODM | scikit-learn | Whole  | Smaller |  Two-step   |  RBF   | 0.830 | 0.801 | 0.815 |
|        |              | corpus |         |             |        |       |       |       |
+--------+--------------+--------+---------+-------------+--------+-------+-------+-------+


References
==========

.. [1] H.-J. Dai, S. Syed-Abdul, C.-W. Chen, and C.-C. Wu, "Recognition and Evaluation of Clinical Section Headings in Clinical Documents Using Token-Based Formulation with Conditional Random Fields," BioMed Research International, vol. 2015, Article ID 873012, 10 pages, 2015. doi:10.1155/2015/873012
.. [2] P.M Heider and SM Meystre. "Overview and descriptive analysis of a new ontology for normalizing section types in unstructured clinical notes," In: AMIA Annual Symposium. 2021.
