configfile: "config.yaml"
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
CHROMOSOMES = [str(i) for i in range(1, 23)]

# common arguments. Hard coded, _not_ supplied by config
COMMON_ADDITIONAL_ARGS = "--linear hide-covar --adjust --ci 0.95 --noweb"
COVAR_NAMES = ", ".join(config.get("covar_names", []))

# Construct arguments common to both BED and VCF commands. Read pheno/covar from config
def _make_common_args():
    pheno_name = config["pheno_name"]
    missing_pheno = config["missing_pheno"]
    additional_args = COMMON_ADDITIONAL_ARGS
    pheno_file = config["pheno_file"]
    covar_file = config.get("covar_file", "")
    return (
        f"--pheno {pheno_file} "
        f"--pheno-name {pheno_name} "
        f"--covar {covar_file} "
        f"--covar-name {COVAR_NAMES} "
        f"--missing-phenotype {missing_pheno} "
        f"{additional_args}"
    )


def _make_plink_cmd_bed(wildcards):
    common = _make_common_args()
    bfile_prefix = config["bfile"]
    bed = bfile_prefix + ".bed"
    bim = bfile_prefix + ".bim"
    fam = bfile_prefix + ".fam"
    out_prefix = f"results/chr_{wildcards.chr_num}"
    return f"plink --bed {bed} --bim {bim} --fam {fam} --chr {wildcards.chr_num} {common} --out {out_prefix}"


def _make_plink_cmd_vcf(wildcards):
    common = _make_common_args()
    vcf = config["vcffile"].replace("{chr}", wildcards.chr_num)
    out_prefix = f"results/chr_{wildcards.chr_num}"
    return f"plink --vcf {vcf} {common} --out {out_prefix}"


# Enforce mutual exclusivity: user must supply either bfile OR vcffile, but not both
USE_BFILE = "bfile" in config
USE_VCF = "vcffile" in config

if USE_BFILE and USE_VCF:
    raise ValueError("Error: supply either 'bfile' or 'vcffile' in config.yaml, not both")
if not USE_BFILE and not USE_VCF:
    raise ValueError("Error: must supply either 'bfile' or 'vcffile' in config.yaml")


def _make_plink_cmd(wildcards):
    """Wrapper that chooses the proper PLINK command builder based on config."""
    if USE_BFILE:
        return _make_plink_cmd_bed(wildcards)
    else:
        return _make_plink_cmd_vcf(wildcards)


rule all:
    input:
        assoc_linear=expand("results/chr_{chr_num}.assoc.linear", chr_num=CHROMOSOMES),
        adjusted=expand("results/chr_{chr_num}.adjusted", chr_num=CHROMOSOMES),
        log=expand("results/chr_{chr_num}.log", chr_num=CHROMOSOMES),


rule gwas:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 8000)

    input:
        lambda wildcards: (
            [
                config["vcffile"].replace("{chr}", wildcards.chr_num),
                config["pheno_file"],
            ]
            + ([config.get("covar_file")] if config.get("covar_file") else [])
            if USE_VCF
            else
            [
                config["bfile"] + ".bed",
                config["bfile"] + ".bim",
                config["bfile"] + ".fam",
                config["pheno_file"],
            ]
            + ([config.get("covar_file")] if config.get("covar_file") else [])
        ),

    output:
        assoc_linear="results/chr_{chr_num}.assoc.linear",
        adjusted="results/chr_{chr_num}.adjusted",
        log="results/chr_{chr_num}.log",

    wildcard_constraints:
        chr_num="[0-9]+",

    params:
        cmd=lambda wildcards, input: _make_plink_cmd(wildcards),

    shell:
        "{params.cmd}"
