
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
including section headers. [1]_[2]_

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

Table 1. Performance by Classifier on different corpora
-------------------------------------------------------

+-------------------------------+------------+----------+--------+-----------+-------+--------+
|                               | Corpus     | Accuracy | Recall | Precision | F1    | Change |
+===============================+============+==========+========+===========+=======+========+
| Rule-Based (medspaCy)         | Test set   | 0.253    | 0.275  | 0.763     | 0.404 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| SVM (libSVM/WEKA)             | Test set   | 0.897    | 0.944  | 0.948     | 0.946 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| SVM (Scikit-learn/spaCy)      | Test set   | 0.207    | 0.224  | 0.736     | 0.343 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| Simple Voting (Threshold = 1) | Test set   | 0.212    | 0.299  | 0.422     | 0.350 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| Simple Voting (Threshold = 2) | Test set   | 0.096    | 0.096  | 0.994     | 0.175 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| Simple Voting (Threshold = 3) | Test set   | 0.085    | 0.085  | 1.000     | 0.157 |        |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| Rule-Based (medspaCy)         | Additional | 0.152    | 0.159  | 0.767     | 0.263 | -0.141 |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| SVM (libSVM/WEKA)             | Additional | 0.020    | 0.029  | 0.059     | 0.039 | -0.907 |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| SVM (Scikit-learn/spaCy)      | Additional | 0.121    | 0.122  | 0.959     | 0.216 | -0.127 |
+-------------------------------+------------+----------+--------+-----------+-------+--------+
| Simple Voting (Threshold = 1) | Additional | 0.195    | 0.226  | 0.591     | 0.327 | -0.023 |
+-------------------------------+------------+----------+--------+-----------+-------+--------+

References
==========

.. [1] H.-J. Dai, S. Syed-Abdul, C.-W. Chen, and C.-C. Wu, "Recognition and Evaluation of Clinical Section Headings in Clinical Documents Using Token-Based Formulation with Conditional Random Fields," BioMed Research International, vol. 2015, Article ID 873012, 10 pages, 2015. doi:10.1155/2015/873012
.. [2] C.-W. Chen, N.-W. Chang, Y.-C. Chang, and H.-J. Dai, "Section Heading Recognition in Electronic Health Records Using Conditional Random Fields," in Technologies and Applications of Artificial Intelligence. vol. 8916, S.-M. Cheng and M.-Y. Day, Eds., ed: Springer International Publishing, 2014, pp. 47-55.
