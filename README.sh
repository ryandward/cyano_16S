#!/bin/bash


######################################

while read entry<&3; do
search -db nuccore -query "$entry" |
efetch -format docsum -mode json |
  jq -r '.result[.result.uids[]] |
        del(.[] | select(. == "")) |
        [       .accessionversion // "-",
                .organism // "-",
                .strain // "-",
                .sourcedb // "-"
        ] |
        @tsv'; done 3<all_accs.txt |
  tee -a all_metadata.tsv

  ##################################

  while read entry<&3; do
    esearch -db nuccore -query "$entry" |
    efetch -format fasta
  done 3<all_accs.txt |
  tee -a all_16S.fasta

####################################

awk -v ORS= '/^>/ { $0 = (NR==1 ? "" : RS) $0 RS } END { printf RS }1' all_16S.fasta > tmp && mv tmp all_16S.fasta

####################################

awk 'NR == FNR && FNR % 2 == 1 {
  gsub (">", "", $0);
  split($0, parts, " ");
  acc = parts[1];
  getline;
  fasta[acc]=$0
}
NR != FNR {
  split($2, parts, " ");
  print ">"$1, parts[1]"_"parts[2], $3, $4; print fasta[$1]
}' all_16S.fasta all_metadata.tsv |
sed 's/ /_/g' |
sed 's/\t/ /g' > 16S_rebuilt.fasta

####################################

awk 'BEGIN{FS= " "; OFS = "\t";} NR%2==1 {print $2, $3, $1, $4}' 16S_rebuilt.fasta |
sed 's/>//g' > 16S_metadata.tsv
