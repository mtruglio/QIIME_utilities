#!/bin/bash

## Download NCBI's taxonomic data and GI (GenBank ID) taxonomic
## assignation, create a id-to-taxonomy tab-separated file. 

## Variables
NCBI="ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/"
TAXDUMP="taxdump.tar.gz"
TAXID="gi_taxid_nucl.dmp.gz"
NAMES="names.dmp"
NODES="nodes.dmp"
GI_TO_TAXID="gi_taxid_nucl.dmp"
FASTA_FILE="${1}"
DMP=$(echo {citations,division,gencode,merged,delnodes}.dmp)
USELESS_FILES="${TAXDUMP} ${DMP} gc.prt readme.txt"

#######################
## Preparation steps ##
#######################

if ! [ -e names.dmp ] || ! [ -e nodes.dmp ] ; then 
	echo "names.dmp or nodes.dmp not present; downloading..." >&2;
	#Download taxdump
	rm -rf ${USELESS_FILES} "${NODES}" "${NAMES}"
	wget "${NCBI}${TAXDUMP}" && \
	tar zxvf "${TAXDUMP}" && \
	rm -rf ${USELESS_FILES}
fi

if grep --quiet "common name" "${NAMES}" ; then
	echo "The names database needs to be cleaned of non-scientific names. Processing..." >&2
	## Limit search space to scientific names
	grep "scientific name" "${NAMES}" > "${NAMES/.dmp/_reduced.dmp}" && \
 	rm -f "${NAMES}" && \
  	mv "${NAMES/.dmp/_reduced.dmp}" "${NAMES}"
	echo "Done." >&2
fi

if ! [ -e gi_taxid_nucl.dmp ] ; then 
	## Download gi_taxid_nucl
	rm -f "${TAXID/.gz/}*"
	wget "${NCBI}${TAXID}" && \
	gunzip "${TAXID}"
fi



########################
##    Actual work     ##
########################

# Obtain the name corresponding to a taxid or the taxid of the parent taxa
get_name_or_taxid()
{
    grep --max-count=1 "^${1}"$'\t' "${2}" | cut --fields="${3}"
}

grep '^>' "$FASTA_FILE" | while read -r line ; do
    echo "$line"| grep -o 'gi|[0-9A-Za-z]*[|ref|[0-9A-Za-z\_\-\.\,]*|]*'| while read -r ENTIRE_ID; do
        
	    echo "Looking for $ENTIRE_ID">&2
	    GI=$(echo $ENTIRE_ID| grep -o '^gi|[0-9]*|' | grep -o '[0-9]*')
	    echo "gi is $GI">&2

	    TAXONOMY=""
	    TAXID=$(get_name_or_taxid "${GI}" "${GI_TO_TAXID}" "2")

	    if [[ -z "${TAXID// }" ]]; then
		echo "$GI is obsolete, skipping.">&2 
		continue
	    fi 

	    while [[ "${TAXID}" -gt 1 ]] ; do
		# Obtain the scientific name corresponding to a taxid
		NAME=$(get_name_or_taxid "${TAXID}" "${NAMES}" "3")
		# Obtain the parent taxa taxid
		PARENT=$(get_name_or_taxid "${TAXID}" "${NODES}" "3")
		# Build the taxonomy path
		TAXONOMY="${NAME};${TAXONOMY}"
		TAXID="${PARENT}"
	    done
	    # Getting rid of 'cellular organisms' tax level - QIIME does not need that
	    TAXONOMY="${TAXONOMY#$'cellular organisms;'}"
	 
	    # Checking TAXONOMY string size; if 1, discard.
	    size=${#TAXONOMY} 
	    if [[ $size<=1 ]]; then
		echo "$GI is empty, skipping.">&2 
		continue
	    else     echo -e "${ENTIRE_ID}\t${TAXONOMY::-1}"
	    fi 

	    ##echo -e "${GI}\t${TAXONOMY::-1}"
    done

done


exit 0
