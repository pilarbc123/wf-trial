#!/usr/bin/env nextflow

// Developer notes
//
// This template workflow provides a basic structure to copy in order
// to create a new workflow. Current recommended practices are:
//     i) create a simple command-line interface.
//    ii) include an abstract workflow scope named "pipeline" to be used
//        in a module fashion
//   iii) a second concrete, but anonymous, workflow scope to be used
//        as an entry point when using this workflow in isolation.

import groovy.json.JsonBuilder
nextflow.enable.dsl = 2

include { fastq_ingress; xam_ingress } from './lib/ingress'
include {
    getParams;
} from './lib/common'


OPTIONAL_FILE = file("$projectDir/data/OPTIONAL_FILE")

process getVersions {
    label "wftemplate"
    cpus 1
    output:
        path "versions.txt"
    script:
    """
    python -c "import pysam; print(f'pysam,{pysam.__version__}')" >> versions.txt
    fastcat --version | sed 's/^/fastcat,/' >> versions.txt
    """
}


process makeReport {
    label "wftemplate"
    input:
        val metadata
        tuple path(stats, stageAs: "stats_*"), val(no_stats)
        path client_fields
        path "versions/*"
        path "params.json"
        val wf_version
    output:
        path "wf-template-*.html"
    script:
        String report_name = "wf-template-report.html"
        String metadata = new JsonBuilder(metadata).toPrettyString()
        String stats_args = no_stats ? "" : "--stats $stats"
        String client_fields_args = client_fields.name == OPTIONAL_FILE.name ? "" : "--client_fields $client_fields"
    """
    echo '${metadata}' > metadata.json
    workflow-glue report $report_name \
        --versions versions \
        $stats_args \
        $client_fields_args \
        --params params.json \
        --metadata metadata.json \
        --wf_version $wf_version
    """
}


// See https://github.com/nextflow-io/nextflow/issues/1636. This is the only way to
// publish files from a workflow whilst decoupling the publish from the process steps.
// The process takes a tuple containing the filename and the name of a sub-directory to
// put the file into. If the latter is `null`, puts it into the top-level directory.
process output {
    // publish inputs to output directory
    label "wftemplate"
    publishDir (
        params.out_dir,
        mode: "copy",
        saveAs: { dirname ? "$dirname/$fname" : fname }
    )
    input:
        tuple path(fname), val(dirname)
    output:
        path fname
    """
    """
}

process readuntil {
    
    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """
    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"
    readfish validate /home/pilar/wf-trial/human_chr_selection.toml

    """
}

process readfish_unblockall {

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"

    readfish unblock-all --device MS00000 --experiment-name "Testing readfish Unblock All"
    """

}

process readfish_enrich1_20_21 {

    echo true

    output:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"

    readfish targets --toml /home/pilar/wf-trial/human_chr_selection.toml  --device MS00000 --log-file test.log --experiment-name human_selection 

    """

}

process create_hash_table_human {

    echo true 

    input:
    val ""
    output:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    bash create_hash_table.sh /home/pilar/wf-trial/fastq_files_human

    """

}



process stats_run_human {

    echo true
    input:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"

    readfish stats --toml /home/pilar/wf-trial/human_chr_selection.toml --fastq-directory /home/pilar/wf-trial/fastq_stats/ --no-paf-out --no-demultiplex

    """

}


process readfish_enrich_ecoli {

    echo true

    output:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"

    readfish targets --toml /home/pilar/wf-trial/bern_selection.toml  --device MS00000 --log-file test.log --experiment-name ecoli_selection 

    """

}

process create_hash_table_ecoli {

    echo true 

    input:
    val ""
    output:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    bash create_hash_table.sh /home/pilar/wf-trial/fastq_files_bern

    """

}



process stats_run_ecoli {

    echo true
    input:
    val ""

    conda "/home/pilar/miniconda3/envs/readfish"
    script:

    """

    python -c "import sys ; sys.path.insert(0,'/home/pilar/miniconda3/envs/readfish/lib/python3.10/site-packages')"

    readfish stats --toml /home/pilar/wf-trial/bern_selection.toml --fastq-directory /home/pilar/wf-trial/fastq_stats/ --no-paf-out --no-demultiplex

    """

}

// workflow module
workflow pipeline_human {
    
    main:
        readfish_enrich1_20_21()
        create_hash_table_human(readfish_enrich1_20_21.out.collect() )
        stats_run_human(create_hash_table_human.out.collect())
        

        
}

workflow pipeline_bern {
    
    main:
        readfish_enrich_ecoli()
        create_hash_table_ecoli(readfish_enrich_ecoli.out.collect() )
        stats_run_ecoli(create_hash_table_ecoli.out.collect())
        

        
}

// entrypoint workflow
WorkflowMain.initialise(workflow, params, log)
workflow {

    Pinguscript.ping_start(nextflow, workflow, params)
    pipeline_bern()
}

workflow.onComplete {
    Pinguscript.ping_complete(nextflow, workflow, params)
}
workflow.onError {
    Pinguscript.ping_error(nextflow, workflow, params)
}
