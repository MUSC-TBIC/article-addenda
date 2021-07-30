
Natural Language Processing Enabling COVID-19 Predictive Analytics to
Support Data-Driven Patient Advising and Pooled Testing

Stéphane M. Meystre, MD, PhD, Paul M. Heider, PhD, Youngjun Kim, PhD,
Matthew Davis, Jihad Obeid, MD, James Madory, DO, Alexander
V. Alekseyenko, PhD

Medical University of South Carolina, Charleston, SC

[full citation forthcoming]

RMarkdown Code
==============

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

Model Name Mappings
===================

The table below indicates the mapping from model names used in Table 4
to our original (internal) model naming schema.

|-------------------------------------------------------------------------------|---------------|
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
|-------------------------------------------------------------------------------|---------------|
