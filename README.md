# Contents for readfish

The contents of wf-trial are:
- **benchmarking**: Contains the readfish repository in a past version, where readfish align was still in use. This allows to do live yield enrichment for the bern dataset (currently not running)
    - readfish_benchmarking.yml: File to create the conda environment required to run reasfish in the past commit. The user should create the enviromnent using this yml file and activate it when running _readfish align_. 
    - readfish: Folder containing past commit of readfish. The user should go inside of this folder and run _readfish align_. To run readfish align:
    
    ```
    readfish align --device MS00000 --experiment-name "add_desired_name" --toml path_to_toml
    ```
    One can check the help for optional commands:
    ```
    readfish align --help
    ```
- **bern_selection.toml**: Toml file required to run enrichment of bern dataset. The user should change the _targets_ variable and add between quotes the names of the organisms they want to enrich for. If one wants to do depletion, the conditions of unblock and proceed should be changed (see toml file with conditions for depletion in https://github.com/LooseLab/readfish/tree/main/docs/_static/example_tomls and file human_chr_depletion.toml). See the possible target names in the [bern target section](#bern-data-reference-file-possible-targets).

    To run the experiment with this toml file the user should use the code below while a simulated run is active in MinKnow.

    ```
    guppy_basecall_server --config dna_r10.4.1_e8.2_400bps_5khz_hac.cfg --port 5555 --log_path . -x cuda:all
    readfish validate bern_selection.toml
    readfish targets --toml /home/pilar/wf-trial/bern_selection.toml  --device MS00000 --log-file test.log --experiment-name experiment_name
    ```

    **Outputs**

    - fastq_files_bern: Folder containing the basecalled reads. 
        1. *live_reads.fastq*: Basecalled reads. The user should keep it if they want to run *readfish stats* for benchmarking. 

- **human_chr_selection.toml**: Toml file for running enrichment of human data. The user should change the _targets_ variable and add between quotes the names of the chromosomes they want to enrich for. If one wants to do depletion, the conditions of unblock and proceed should be changed (see toml file with conditions for depletion in https://github.com/LooseLab/readfish/tree/main/docs/_static/example_tomls and file human_chr_depletion.toml).

    To run the experiment with this toml file the user should use the code below while a simulated run is active in MinKnow.

    ```
    guppy_basecall_server --config dna_r10.4.1_e8.2_400bps_5khz_hac.cfg --port 5555 --log_path . -x cuda:all
    readfish validate human_chr_selection.toml
    readfish targets --toml /home/pilar/wf-trial/human_chr_selection.toml  --device MS00000 --log-file test.log --experiment-name human_selection
    ``` 
    **Outputs**

    - fastq_files_human: Folder containing the basecalled reads. 
        1. *live_reads.fastq*: Basecalled reads. The user should keep it if they want to run *readfish stats* for benchmarking. 

- **ny_suggestion.toml**: File suggesting the next steps for the New York data (might need some tunning depending on the desired output).

    In this file two regions are defined:
    1. ny_test_readfish: It enriches for ecoli in the left side of the flow cell.
    2. no_action: It sequences everything in the left side of the flow cell.

    *Considerations:*
    - The user will need to check if the reference genomes match the ones from the NY dataset. The reference genomes used in this case were obtained from the official documentation of the company.
    - The user will need to change the enrichment targets to match the sequencing conditions
    - The user might need to adjust the regions where the no_action and enrichment take place.

- **create_hash_table.sh**: This contains the trial code for the creation of the hash table. It takes as an input the folder where the basecalled reads are stored, in our case either *fastq_files_bern* or *fastq_files_human*. It is required to be able to run the becnchmarking module of readfish *readfish stats*. It is run as follows:

    ```
    bash create_hash_table.sh name_of_folder
    ```

    The code first takes the output of *readfish targets* and obtain the run names. It outputs a file called *reads_header.txt* located within the provided folder. Then, it creates the hash table from the unique read headers, and stores it in *hash_table_reads.txt* in that same folder. Finally, it updates the basecalled reads with the read_id in the header, and stores the file in *fastq_stats/live_reads_readid.fq*.


## Bern data reference file: Possible targets

First the species is shown and then the names of the possible targets as appearing in the merged reference fasta file stored in: /scratch/Backup/data/mmi_idx/D6322.refseq/Genomes/merge_genomes.

One should add the desired target names in the target field of the toml files between quotes.

- Bacillus subtilis: Bacillus_subtilis
- Escherichia coli: Escherichia_coli_plasmid, Escherichia_coli_chromosome
- Pseudomonas aeruginosa: Pseudomonas_aeruginosa
- Salmonella enterica: Salmonella_enterica
- Enterococcus faecalis: Enterococcus_faecalis
- Listeria monocytogenes: Listeria_monocytogenes
- Saccharomyces cerevisiae: tig00000001, tig00000003, tig00000004, tig00000006, tig00000011, tig00000018, tig00000019, tig00000023, tig00000025, tig00000027, tig00000031, tig00000036, tig00000038, tig00000042, tig00000047, tig00000050 ,tig00000051, tig00000054, tig00000055 , tig00000063 , tig00000069, tig00000071 , tig00000072 , tig00000075 , tig00000078 , tig00000079 , tig00000080 , tig00000086, tig00000091, tig00000093, tig00000094, tig00000096, tig00000104, tig00000105, tig00000109, tig00000114, tig00000123, tig00000125, tig00000128, tig00000132, tig00000134, tig00000136, tig00000139, tig00000140, tig00000161, tig00000163, tig00000172, tig00000304, tig00000306, tig00000307, tig00000308
- Staphylococcus_aureus: Staphylococcus_aureus_chromosome, Staphylococcus_aureus_plasmid1, Staphylococcus_aureus_plasmid2, Staphylococcus_aureus_plasmid3

# Contents for readfish integration with epi2me

- **main.nf**: Main epi2me code. Here one can create workflows and pipelines that will be performed by Epi2Me. In this file, there are two main workflows: *pipeline_human* and *pipeline_bern*.
    - *pipeline_human*: It performs the enrichment of the selected chromosomes in the human toml file described above. It then creates the hash table and add the read ids to the output, and finally call readfish stats and display a table for benchmarking of the selection.
    - *pipeline_bern*:  It performs the enrichment of the selected species in the bern toml file described above. It then creates the hash table and add the read ids to the output, and finally call readfish stats and display a table for benchmarking of the selection.

    The user should select in the main workflow the pipeline that they want to run. Then, they should launch the Epi2Me workflow by running:

    ```
    export PATH=$PATH:/home/pilar/utils/
    nextflow run main.nf -profile local
    ```

    This will launch the epi2me workflow that will run the *readfish targets* and output the stats.

- **bin**: Folder containing some codes used in epi2me. For being able to directly call codes from the main nextflow file _main.nf_, the code should be located in this folder.
    - **create_hash_table.sh**: Code required to create a hash table from readfish targets output, so that _readfish stats_ works on the output data. This is the code used in the pipelines contained in _main.nf_.
    - **read_until_code.py**: Code used to test the read until api integration with epi2me. This is a simple code where the server connects to the MinKnow device in real time and unblocks all the reads.

- **nextflow.config**: Configuration file required in Epi2Me. One can define here the use of docker containers or singularity, amongst others.

- **nextflow_schema.json**: File used to define parameters required to run the workflow, and shown in the Epi2Me user interface. In this schema no fields are required. However, one could add fields like toml file or device name so that the user can easily introduce them in the user interface and pass them to Epi2Me in an easy wy, rather than manually editting them in main.nf. 

- **output_definition.json**: File to define the output of the Epi2Me workflow.


