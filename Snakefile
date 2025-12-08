configfile: config.yaml
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"
rule gwas:
    input:
        bed=config["bfile"] + ".bed",
        bim=config["bfile"] + ".bim",
        fam=config["bfile"] + ".fam",
        pheno_file=config["pheno_file"],
        covar_file=config["covar_file"],
    output: assoc_linear=config["output_prefix"] + ".assoc.linear",
            adjusted=config["output_prefix"] + ".adjusted",
            log=config["output_prefix"] + ".log",
    params:
        pheno_name=config["pheno_name"],
        covar_names=config["covar_names"],
        missing_pheno=config["missing_pheno"],
        additional_args="--linear hide-covar --adjust --ci 0.95",
    shell: 
        """
        plink \
            --bed {input.bed} \
            --bim {input.bim} \
            --fam {input.fam} \
            --pheno {input.pheno_file} \
            --pheno-name {params.pheno_name} \
            --covar {input.covar_file} \
            --covar-name {params.covar_names} \
            --missing-phenotype {params.missing_pheno} \
            {params.additional_args} \
            --out {output.log[:-4]}
        """