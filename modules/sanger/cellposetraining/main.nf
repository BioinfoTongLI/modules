process CELLPOSETRAINING {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "docker.io/biocontainers/cellpose:3.1.0_cv1":
        "docker.io/biocontainers/cellpose:3.1.0_cv1" }"

    input:
    tuple val(meta), path(dir, stageAs: 'train'), path(test_dir, stageAs: 'test')
    val(model)
    val(learning_rate)
    val(weight_decay)
    val(n_epochs)

    output:
    tuple val(meta), path("test/models/${prefix}_retrained"), emit: retrained_model
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def original_model = model? "${model}" : "cyto3"
    """
    python3 -m cellpose --train  \\
        --dir "./train" \\
        --test_dir "./test" \\
        --pretrained_model ${original_model} \\
        --learning_rate ${learning_rate} \\
        --weight_decay ${weight_decay} \\
        --n_epochs ${n_epochs} \\
        --model_name_out ${prefix}_retrained \\
        --SGD 1 \\
        --use_gpu \\
        --mask_filter '_seg.npy' \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellposetraining: \$(python3 -m cellpose --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch test/models/${prefix}_retrained

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellposetraining: \$(python3 -m cellpose --version)
    END_VERSIONS
    """
}
