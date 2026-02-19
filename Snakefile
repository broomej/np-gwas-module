rule gwas:
    input:
        bed=config["bed"],
        bim=config["bim"],
        fam=config["fam"],
        covar=config["covar_file"],
    params:
        covar_names=",".join(config.get("covar_names", [])),
        missing_pheno=config["missing_pheno"],
        additional_args=config.get("additional_plink_args", ""),
        plink_exe=config["plink_exe"],
    output:
        assoc_linear="results/gwas/chr{chromosome}.assoc.linear",
        adjusted="results/gwas/chr{chromosome}.assoc.linear.adjusted",
        log="results/gwas/chr{chromosome}.log"
    shell:
        """
        {params.plink_exe} \
            --bed {input.bed} \
            --bim {input.bim} \
            --fam {input.fam} \
            --pheno {input.pheno} \
            --pheno-name {params.pheno_name} \
            --covar {input.covar} \
            --covar-name {params.covar_names} \
            --missing-phenotype {params.missing_pheno} \
            {params.additional_args} \
            --linear hide-covar \
            --adjust \
            --ci 0.95 \
            --geno 0.1 \
            --maf 0.01 \
            --chr {wildcards.chromosome} \
            --out results/gwas/chr{wildcards.chromosome}
        """