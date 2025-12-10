configfile: "config.yaml"
container: "docker://broome/genetics-tools:ACT-ROSMAP-NACC-meta"

COVAR_NAMES = ",".join(config.get("covar_names", []))
# Hard-coded args common across all study-level GWAS.
ADDITIONAL_ARGS = "--linear hide-covar --adjust --ci 0.95 --noweb"
# Defaults to `plink` because that is the name of the executable in the
# container, but it may be `plink1.9` on some systems. PLINK v1.07 is not
# supported, not tested on PLINK v2.0.
plink_exe = config.get("plink_exe", "plink")
CHROMOSOMES = [str(i) for i in range(1, 23)]

rule all:
    input:
        assoc_linear=expand("results/chr{chr_num}.assoc.linear", chr_num=CHROMOSOMES),
        adjusted=expand("results/chr{chr_num}.adjusted", chr_num=CHROMOSOMES),
        log=expand("results/chr{chr_num}.log", chr_num=CHROMOSOMES),

rule gwas:
    threads: config.get("threads", 8)
    resources:
        mem_mib=config.get("mem_mib", 6000),
    input:
        bed=config["bed"],
        bim=config["bim"],
        fam=config["fam"],
        covar=config["covar_file"],
    output:
        assoc_linear="results/chr{chr_num}.assoc.linear",
        adjusted="results/chr{chr_num}.adjusted",
        log="results/chr{chr_num}.log",
    wildcard_constraints:
        chr_num="[0-9]+",
    params:
        additional_args=ADDITIONAL_ARGS,
        covar_names=COVAR_NAMES,
        missing_pheno=config.get("missing_pheno", "-9"),
    shell:
        """
        {plink_exe} \
            --bed {input.bed} \
            --bim {input.bim} \
            --fam {input.fam} \
            --covar {input.covar} \
            --covar-name {COVAR_NAMES} \
            {params.additional_args} \
            --chr {wildcards.chr_num} \
            --out results/chr{wildcards.chr_num}
        """