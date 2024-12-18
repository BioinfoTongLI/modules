process STARDIST {
    tag "${meta.id}"
    debug params.debug
    cache true

    label "gpu"
    label "medium_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/tiled_stardist:${container_version}":
        "quay.io/bioinfotongli/tiled_stardist:${container_version}"}"
    containerOptions = {
            workflow.containerEngine == "singularity" ? "--cleanenv --nv -B ${params.stardist_model_dir}:/stardist_models":
            ( workflow.containerEngine == "docker" ? "--gpus all -v ${params.stardist_model_dir}:/stardist_models": null )
    }

    publishDir params.out_dir + "/naive_stardist_segmentation"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(image), val(cell_diameter)

    output:
    tuple val(meta), val(cell_diameter), path("${stem}/${stem}_cp_outlines.wkt"), emit: wkts
    tuple val(meta), val(cell_diameter), path("${stem}/${stem}*png"), emit: cp_plots, optional: true
    path "versions.yml"           , emit: versions

    script:
    stem = "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}-diam_${cell_diameter}"
    def args = task.ext.args ?: ''  
    """
    export NUMBA_CACHE_DIR=/tmp/numba_cache
    /opt/conda/bin/python /scripts/stardist_seg.py run \
        --image ${image} \
        --x_min ${x_min} \
        --y_min ${y_min} \
        --x_max ${x_max} \
        --y_max ${y_max} \
        --out_dir "${stem}" \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/stardist_seg.py version 2>&1) | sed 's/^.*stardist_seg.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}