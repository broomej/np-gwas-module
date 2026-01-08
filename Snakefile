rule gwas:
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
            --out results/chr{wildcards.chromosome}
        """