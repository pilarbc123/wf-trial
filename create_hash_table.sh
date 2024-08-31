path=$1
grep "ch=" $path/live_reads.fastq | awk '{print $1}' | uniq > $path/reads_header.txt

declare -A read_table

counter=1

# Populate the hash table with read names as keys and numbers as values
while read -r read_name; do
    read_table["$read_name"]=$counter
    counter=$((counter + 1))
done < "$path/reads_header.txt"

#TODO: Change so that it creates the file from scratch every time, now it just appends
output_file="$path/hash_table_reads.txt"
for key in "${!read_table[@]}"; do
    echo "$key=${read_table[$key]}" >> "$output_file"
done

echo "Hash table saved to $output_file"

mkdir "fastq_stats"
output_file="/home/pilar/wf-trial/fastq_stats/live_reads_readid.fq"

temp_file=$(mktemp)
nlines= grep "ch=" $path/live_reads.fastq  | wc -l

while IFS= read -r line; do
    if [[ $line == *ch=* ]]; then 
    
        read_name=$(echo "$line" | cut -d' ' -f1)
        # Append the number from the hash table to the line
        number="${read_table[$read_name]}"
        if [[ -n $number ]]; then
            echo "$line read=$number" >> "$temp_file"
        else
            echo "$line read=not_found" >> "$temp_file"
        fi
    else 
        echo $line >> "$temp_file"
    fi
done < "$path/live_reads.fastq"

# Move the temp file to the final output file
mv "$temp_file" "$output_file"

echo "Processed file saved to $output_file"



