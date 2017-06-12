# Overview

This is the code and data for "The discovery and comparison of symbolic magnitudes" (Chen, Lu, & Holyoak, 2014, *Cognitive Psychology*). You can read the paper [here](https://www.researchgate.net/publication/260218564_The_discovery_and_comparison_of_symbolic_magnitudes). This version of the BARTlet model includes code to:

1. Run RankSVM
2. Learn one-place predicates using the weights learned by RankSVM as an empirical prior
3. Calculate the magnitude means and variances for animals using the learned one-place predicates
4. Test the distance effect
5. Test the congruity effect
6. Test the influence of stimulus range on the congruity effect

All outputs are saved in the `results/<input>/` directory, where `<input>` is `leuven` or `topics`. Both input directories have the same structure:

```
results
   |__ <input>
          |__ congruity
          |__ distance
          |__ magnitudes
          |__ weights
                 |_ ranksvm
```

# Specific Files

The following scripts carry out the main aspects of the model:

* `ranksvm_mags.m`: This script runs RankSVM using the specified ordered pairs to be given to RankSVM. It also calculates magnitudes on the four continua for all animals (either 44 for Leuven or 77 for topics) using the weights learned by RankSVM. Several parameters can be set at the top of the file, including which input to use (Leuven or topics) and which ordered pairs to provide as input to RankSVM (specified as a string by the variable `which_pairs`). The variable currently specifies the pairs formed by the top 3 and bottom 3 animals on each continuum and all other animals, plus an additional 100 randomly chosen pairs. Several other examples are also given in the file. The weights learned by RankSVM are saved in the `results/<input>/weights/ranksvm` folder, whereas the calculated magnitudes are saved in the `results/<input>/magnitudes` folder.

* `learn_predicates_rankprior.m`: Once `ranksvm_mags.m` has been run, this script can be run to learn the four "positive" one-place predicates (e.g., *large*) using the weights learned by RankSVM as a prior for the weight means. The resulting weight distributions are saved in the `results/<input>/weights` folder.

* `all_animal_mags.m`: Once `learn_predicates_rankprior.m` has been run, this script can be run to calculate the magnitude means and variances for all animals using the learned one-place predicates. Results are saved in the `results/<input>/magnitudes` folder.

* `distbins_magnitude_feat.m`: Once `learn_predicates_rankprior.m` has been run, this script can be run to test the distance effect. The alpha and beta parameters (`a` and `b` in the code, respectively) can be changed in this file. Results are saved in the `results/<input>/distance` folder.

* `congruity_reference_magnitude_feat_selpairs.m`: Once `learn_predicates_rankprior.m` has been run, this script can be run to test the congruity effect as well as the influence of stimulus range on the congruity effect (for Leuven inputs and the size continuum). When the variable `levels` is set to `''`, all four sets of pairs varying in size are presented to the model (full range); when `levels` is set to `'_middle2'`, only Sets 2 and 3 are presented to the model (restricted range), and only the size continuum is examined. The alpha and beta parameters can also be changed in this file. Results are saved in the `results/<input>/congruity` folder. The restricted-range results are saved in a file with `middle2` in its name.

* Other files include the `data*.mat` files, which are various input files, and `ranksvm_with_sim.m`, which contains the RankSVM code.
