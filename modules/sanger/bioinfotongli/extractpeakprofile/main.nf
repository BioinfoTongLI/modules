container_version = "0.1.0"

process BIOINFOTONGLI_EXTRACTPEAKPROFILE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/extract_peak_profile:${container_version}":
        "quay.io/bioinfotongli/extract_peak_profile:${container_version}" }"
    publishDir params.out_dir + "/peak_profiles/"

    input:
    tuple val(meta), path(image), path(peaks)

    output:
    tuple val(meta), path("${prefix}.npy"), path("${prefix}_locations.csv"), emit: peak_profile
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_peak_profile"
    """
    /opt/conda/bin/python /scripts/extract_peak_profile.py run \\
        --image ${image} \\
        --peaks ${peaks} \\
        --stem ${prefix} \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/extract_peak_profile.py version |& sed '1!d ; s//extract_peak_profile.py //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_peak_profile"
    """
    touch ${prefix}.npy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/extract_peak_profile.py version |& sed '1!d ; s//extract_peak_profile.py //')
    END_VERSIONS
    """
}