process HLAHD {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b4/b41b403e81883126c3227fc45840015538e8e2212f13abc9ae84e4b98891d51c/data'
        : 'community.wave.seqera.io/library/bowtie2_htslib_samtools_pigz:edeb13799090a2a6'}"

    containerOptions "${task.ext.containerOptions ?: ''}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_final.result.txt"), emit: hla
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def hlahd_p = task.ext.path ? "${task.ext.path}" : ''
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if (meta.single_end) {
        in_reads = [reads, reads].join(' ')
    }
    else {
        in_reads = reads
    }
    """
    export PATH=\$PATH:${hlahd_p}
    hlahd.sh \\
        -t ${task.cpus} \\
        ${args} \\
        ${in_reads} \\
        ${args2} \\
        ${prefix} \\
        ./

    cp ${prefix}/result/${prefix}_final.result.txt ./${prefix}_final.result.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hlahd: \$(echo \$(hlahd.sh 2>&1 | sed -n 's/.*version \\([0-9.]*\\).*/\\1/p'))
    END_VERSIONS

    """

    stub:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo ${args}
    echo ${args2}

    mkdir -p ${prefix}_output
    echo "Simulated hlahd output" > ${prefix}_final.result.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hlahd: \$(echo \$(hlahd.sh 2>&1 | sed -n 's/.*version \\([0-9.]*\\).*/\\1/p'))
    END_VERSIONS

    """
}
