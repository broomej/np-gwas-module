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
use rule gwas from np_gwas_module with:
    input:
        bed=config["bed"],
        bim=config["bim"],
        fam=config["fam"],
        covar=config["covar_file"],
        pheno=config["pheno"],
    params:
        pheno_name=config["pheno_name"],
        covar_names=",".join(config.get("covar_names", [])),
        missing_pheno=config["missing_pheno"],
        plink_exe=config["plink_exe"],
        additional_args="--noweb",
    output:
        assoc_linear="results/chr{chromosome}.assoc.linear",
        adjusted="results/chr{chromosome}.assoc.linear.adjusted",
        log="results/chr{chromosome}.log",
```

* `params.additional_args`: This will be passed verbatim to PLINK. It can be
  empty (i.e. `""`), but the parameter must be defined in order for Snakemake's
  shell expansion to work.
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
covar_names:
  - age_at_death
  - sex
  - PC1
  - PC2
  - PCn
```

* No multi-thread computations are invoked. That is because rule `gwas` is a
  single-thread operation, and parallelization is handled by the Snakemake
  meta-structure via wildcard expansion, i.e. seperate jobs are created for
  chromosome 1, chromosome 2, etc, each only requiring a single thread, and can
  be run in parallel if threads are available.
* Each study may have a different number of PCs to include, and variable names
  may be different.