# Snakemake module for 2026 NP AD GWAS

This is an analysis-specific module with certain parameters hard-coded; it is
not recommended to import this as a general GWAS rule.

## Usage

### Snakefile or .smk file

Here is is sample Snakemake code to include in your workflow:

```snakemake
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
configfile: "config/gwas.yaml"

module np_gwas_module:
    snakefile: github("broomej/np-gwas-module", path="Snakefile", tag = "v1")

CHROMOSOMES = [str(i) for i in range(1, 23)] + ["X"]
module np_gwas_module:
    snakefile: github("broomej/np-gwas-module", path="Snakefile", branch = "main")
    config: config

use rule gwas from np_gwas_module
```

To supply inputs, outputs, parameters or resources, add `with:` to the last line
and define them e.g.:

```snakemake
use rule gwas from np_gwas_module with:
    output:
        assoc_linear="gwas/chr{chromosome}.assoc.linear",
        adjusted="gwas/chr{chromosome}.assoc.linear.adjusted",
        log="gwas/chr{chromosome}.log"
```

* Please include the `container: ` line, and invoke apptainer when
  executing this workflow.
* Update the GitHub tag to the appropriate version.

### Configuration

Include a configuration file following Snakemake conventions, `config/gwas.yaml`
in this example. Study-specific parameters should go inside the configuration
file. Here is a sample:

```yaml
bed: data/np.bed
bim: data/np.bim
fam: data/np.fam
covar_file: data/covar.txt
plink_exe: plink
pheno: data/covar.txt
pheno_name: bps
missing_pheno: -9
mem_mib: 2000
additional_plink_args: "--noweb"
covar_names:
  - age_at_death
  - sex
  - PC1
  - PC2
  - PCn
```

* _Unless the user supplies inputs, outputs or parameters via
  `use rule ... with:`, the imported rule will expect all of the previous items
  to be defined in the configuration file._
* No multi-thread computations are invoked. That is because rule `gwas` is a
  single-thread operation, and parallelization is handled by the Snakemake
  meta-structure via wildcard expansion, i.e. seperate jobs are created for
  chromosome 1, chromosome 2, etc, each only requiring a single thread, and can
  be run in parallel if threads are available.
* Each study may have a different number of PCs to include, and variable names
  may be different.
* `additional_plink_args` will be passed verbatim to PLINK. It can be
  empty (i.e. `""`), but the parameter must be defined in order for Snakemake's
  shell expansion to work.