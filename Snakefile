configfile: "config.yaml"
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
CHROMOSOMES = [str(i) for i in range(1, 23)]

rule all:
    input:
        assoc_linear=expand("results/chr_{chr_num}_gwas.assoc.linear", chr_num=CHROMOSOMES),
        adjusted=expand("results/chr_{chr_num}_gwas.adjusted", chr_num=CHROMOSOMES),
        log=expand("results/chr_{chr_num}_gwas.log", chr_num=CHROMOSOMES),
        vcf_assoc_linear=expand("results/chr_{chr_num}_vcf_gwas.assoc.linear", chr_num=CHROMOSOMES),
        vcf_adjusted=expand("results/chr_{chr_num}_vcf_gwas.adjusted", chr_num=CHROMOSOMES),
        vcf_log=expand("results/chr_{chr_num}_vcf_gwas.log", chr_num=CHROMOSOMES),

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
    params:
        pheno_name=config["pheno_name"],
        covar_names=", ".join(config["covar_names"]),
        missing_pheno=config["missing_pheno"],
        additional_args="--linear hide-covar --adjust --ci 0.95",
    shell:
        """
        plink \
            --bed {input.bed} \
            --bim {input.bim} \
            --fam {input.fam} \
            --chr {wildcards.chr_num} \
            --pheno {input.pheno_file} \
            --pheno-name {params.pheno_name} \
            --covar {input.covar_file} \
            --covar-name {params.covar_names} \
            --missing-phenotype {params.missing_pheno} \
            {params.additional_args} \
            --out results/chr_{wildcards.chr_num}_gwas
        """

rule results_dir:
    output: directory("results")
    shell: "mkdir -p {output}"


rule gwas_vcf:
    threads: config.get("threads", 8)
    resources:
        mem_mb=config.get("mem_mb", 4000)
    input:
        vcf="vcf/chr_{chr_num}.vcf.gz",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output:
        assoc_linear="results/chr_{chr_num}_vcf_gwas.assoc.linear",
        adjusted="results/chr_{chr_num}_vcf_gwas.adjusted",
        log="results/chr_{chr_num}_vcf_gwas.log",
    params:
        pheno_name=config["pheno_name"],
        covar_names=", ".join(config["covar_names"]),
        missing_pheno=config["missing_pheno"],
        additional_args="--linear hide-covar --adjust --ci 0.95",
    shell:
        """
        plink \
            --vcf {input.vcf} \
            --pheno {input.pheno_file} \
            --pheno-name {params.pheno_name} \
            --covar {input.covar_file} \
            --covar-name {params.covar_names} \
            --missing-phenotype {params.missing_pheno} \
            {params.additional_args} \
            --out results/chr_{wildcards.chr_num}_vcf_gwas
        """