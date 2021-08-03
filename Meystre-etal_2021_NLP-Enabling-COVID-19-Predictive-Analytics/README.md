
This directory contains RMarkdown files, model details, and sample
data related to and in support of the following publication:

Natural Language Processing Enabling COVID-19 Predictive Analytics to
Support Data-Driven Patient Advising and Pooled Testing

Stéphane M. Meystre, MD, PhD, Paul M. Heider, PhD, Youngjun Kim, PhD,
Matthew Davis, Jihad Obeid, MD, James Madory, DO, Alexander
V. Alekseyenko, PhD

Medical University of South Carolina, Charleston, SC

[full citation forthcoming]

Work for this publication used data extracted by
[DECOVRI](https://github.com/MUSC-TBIC/decovri) (Data Extraction for
COVID-19 Related Information), a software application based on natural
language processing (NLP) which targets COVID-19 related information
in clinical text notes.

RMarkdown Code
==============

To enable more efficient SARS-CoV-2 diagnostic testing based on
pooling, these R markdown files implement a new straight-forward Monte
Carlo approximation that provides reasonable and practical estimates
of the number of SARS-CoV-2 diagnostic tests required based on
predicted risk values. The simulation directly calculates the number
of resulting test pools that are positive and the total number of
tests needed. 

The `.html` version of all RMarkdown files are presented in their
original format. The source RMarkdown files for these are available in
the `RMarkdown` folder.

Spoofed data has been provided in the `sample_data` directory. Due to
patient privacy concerns, the provided values were generated using
Excel's `randarray( n , 1 , 0 , 1 )`. The format is otherwise consistent
with what the RMarkdown files require to run.

Model Details
=============

The full set of features, intercept, and weights is provided for all
logistic regression models in the `model_details` folder. Simpler
descriptive details are provided for the SVM models.

The provided Python script `print_model_details.py` can be used to
print the same model details.

Model Name Mappings
===================

The table below indicates the mapping from model names used in Table 4
to our original (internal) model naming schema.

| “Spring” dataset training (10% negatives; all features)                       | Original Name |
|-------------------------------------------------------------------------------|---------------|
| Logistic Regression                                                           | v0020         |
| Support Vector Machine                                                        | v0021         |
|-------------------------------------------------------------------------------|---------------|
| “Summer” dataset training (40% negatives, features without age)               |               |
|-------------------------------------------------------------------------------|---------------|
| Logistic Regression                                                           | v0041_0.4     |
| Support Vector Machine                                                        | v0051_0.4     |
|-------------------------------------------------------------------------------|---------------|
| “Spring+Summer” dataset training (positives subset to reach 5%, top features) |               |
|-------------------------------------------------------------------------------|---------------|
| Logistic Regression                                                           | v0406_0.05    |


