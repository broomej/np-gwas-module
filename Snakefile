configfile: "config.yaml"
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
CHROMOSOMES = [str(i) for i in range(1, 23)]

# Centralized constants/helpers (evaluated at parse time)
COMMON_ADDITIONAL_ARGS = "--linear hide-covar --adjust --ci 0.95"
COVAR_NAMES = ", ".join(config.get("covar_names", []))

def _make_common_args(input):
    # Read static values from config at parse time
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
    out_prefix = f"results/chr_{wildcards.chr_num}_gwas"
    return f"plink --bed {input['bed']} --bim {input['bim']} --fam {input['fam']} --chr {wildcards.chr_num} {common} --out {out_prefix}"

def _make_plink_cmd_vcf(wildcards, input):
    common = _make_common_args(input)
    out_prefix = f"results/chr_{wildcards.chr_vcf}_vcf_gwas"
    return f"plink --vcf {input['vcf']} {common} --out {out_prefix}"

rule all:
    input:
        assoc_linear=expand("results/chr_{chr_num}_gwas.assoc.linear", chr_num=CHROMOSOMES),
        adjusted=expand("results/chr_{chr_num}_gwas.adjusted", chr_num=CHROMOSOMES),
        log=expand("results/chr_{chr_num}_gwas.log", chr_num=CHROMOSOMES),
        vcf_assoc_linear=expand("results/chr_{chr_vcf}_vcf_gwas.assoc.linear", chr_vcf=CHROMOSOMES),
        vcf_adjusted=expand("results/chr_{chr_vcf}_vcf_gwas.adjusted", chr_vcf=CHROMOSOMES),
        vcf_log=expand("results/chr_{chr_vcf}_vcf_gwas.log", chr_vcf=CHROMOSOMES),


rule gwas:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 4000)
    input:
        bed=config["bfile"] + ".bed",
        bim=config["bfile"] + ".bim",
        fam=config["bfile"] + ".fam",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output:
        assoc_linear="results/chr_{chr_num}_gwas.assoc.linear",
        adjusted="results/chr_{chr_num}_gwas.adjusted",
        log="results/chr_{chr_num}_gwas.log",
    wildcard_constraints:
        chr_num="[0-9]+",
    params:
        pheno_name=config["pheno_name"],
        missing_pheno=config["missing_pheno"],
        additional_args=COMMON_ADDITIONAL_ARGS,
        out_prefix=lambda wildcards: f"results/chr_{wildcards.chr_num}_gwas",
        cmd=lambda wildcards, input: _make_plink_cmd_bed(wildcards, input),
    shell:
        "{params.cmd}"


rule gwas_vcf:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 4000)
    input:
        vcf="vcf/chr_{chr_vcf}.vcf.gz",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output:
        assoc_linear="results/chr_{chr_vcf}_vcf_gwas.assoc.linear",
        adjusted="results/chr_{chr_vcf}_vcf_gwas.adjusted",
        log="results/chr_{chr_vcf}_vcf_gwas.log",
    wildcard_constraints:
        chr_vcf="[0-9]+",
    params:
        pheno_name=config["pheno_name"],
        missing_pheno=config["missing_pheno"],
        additional_args=COMMON_ADDITIONAL_ARGS,
        out_prefix=lambda wildcards: f"results/chr_{wildcards.chr_vcf}_vcf_gwas",
        cmd=lambda wildcards, input: _make_plink_cmd_vcf(wildcards, input),
    shell:
        "{params.cmd}"