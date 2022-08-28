

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

