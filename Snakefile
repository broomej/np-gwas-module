configfile: "config.yaml"
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
CHROMOSOMES = [str(i) for i in range(1, 23)]

# common arguments. Hard coded, _not_ supplied by config
COMMON_ADDITIONAL_ARGS = "--linear hide-covar --adjust --ci 0.95"
COVAR_NAMES = ", ".join(config.get("covar_names", []))

# Construct arguments common to both BED and VCF commands
def _make_common_args(input):
    pheno_name = config["pheno_name"]
    missing_pheno = config["missing_pheno"]
    additional_args = COMMON_ADDITIONAL_ARGS
    return (
        f"--pheno {input['pheno_file']} "
        f"--pheno-name {pheno_name} "
        f"--covar {input.get('covar_file','')} "
        f"--covar-name {COVAR_NAMES} "
        f"--missing-phenotype {missing_pheno} "
        f"{additional_args}"
    )


def _make_plink_cmd_bed(wildcards, input):
    common = _make_common_args(input)
    out_prefix = f"results/chr_{wildcards.chr_num}"
    return f"plink --bed {input['bed']} --bim {input['bim']} --fam {input['fam']} --chr {wildcards.chr_num} {common} --out {out_prefix}"


def _make_plink_cmd_vcf(wildcards, input):
    common = _make_common_args(input)
    out_prefix = f"results/chr_{wildcards.chr_num}_vcf"
    return f"plink --vcf {input['vcf']} {common} --out {out_prefix}"


# Conditionally define targets based on which input is configured
USE_BFILE = "bfile" in config
USE_VCF = "vcffile" in config

rule all:
    input:
        assoc_linear=expand("results/chr_{chr_num}.assoc.linear", chr_num=CHROMOSOMES) if USE_BFILE else [],
        adjusted=expand("results/chr_{chr_num}.adjusted", chr_num=CHROMOSOMES) if USE_BFILE else [],
        log=expand("results/chr_{chr_num}.log", chr_num=CHROMOSOMES) if USE_BFILE else [],
        vcf_assoc_linear=expand("results/chr_{chr_num}_vcf.assoc.linear", chr_num=CHROMOSOMES) if USE_VCF else [],
        vcf_adjusted=expand("results/chr_{chr_num}_vcf.adjusted", chr_num=CHROMOSOMES) if USE_VCF else [],
        vcf_log=expand("results/chr_{chr_num}_vcf.log", chr_num=CHROMOSOMES) if USE_VCF else [],


rule bfile:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 8000)
    input:
        bed=config["bfile"] + ".bed" if USE_BFILE else "",
        bim=config["bfile"] + ".bim" if USE_BFILE else "",
        fam=config["bfile"] + ".fam" if USE_BFILE else "",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output:
        assoc_linear="results/chr_{chr_num}.assoc.linear",
        adjusted="results/chr_{chr_num}.adjusted",
        log="results/chr_{chr_num}.log",
    wildcard_constraints:
        chr_num="[0-9]+",
    params:
        pheno_name=config["pheno_name"],
        missing_pheno=config["missing_pheno"],
        additional_args=COMMON_ADDITIONAL_ARGS,
        out_prefix=lambda wildcards: f"results/chr_{wildcards.chr_num}",
        cmd=lambda wildcards, input: _make_plink_cmd_bed(wildcards, input),
    shell:
        "{params.cmd}"


rule vcf:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 8000)
    input:
        vcf=config["vcffile"].replace("{chr}", "{chr_num}") if USE_VCF else "",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output:
        assoc_linear="results/chr_{chr_num}_vcf.assoc.linear",
        adjusted="results/chr_{chr_num}_vcf.adjusted",
        log="results/chr_{chr_num}_vcf.log",
    wildcard_constraints:
        chr_num="[0-9]+",
    params:
        pheno_name=config["pheno_name"],
        missing_pheno=config["missing_pheno"],
        additional_args=COMMON_ADDITIONAL_ARGS,
        out_prefix=lambda wildcards: f"results/chr_{wildcards.chr_num}_vcf",
        cmd=lambda wildcards, input: _make_plink_cmd_vcf(wildcards, input),
    shell:
        "{params.cmd}"
