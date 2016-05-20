# QIIME_utilities
A bunch of scripts to make QIIMists' life easier.

## Id_to_tax map maker
It is a simple script that makes QIIME-compatible id_to_tax maps starting from a fasta file containing the ids. 
Usage:
```
./id_to_tax_mapmaker.sh [fasta file] > id_to_tax.map
```
Here's the steps it goes through:

**1)**The script looks for the names.dmp and nodes.dmp files from the **taxdump** archive (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz) and for the big **gi_taxid_nucl.dmp** file (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/gi_taxid_nucl.dmp.gz); if not found in the same folder of the executable, it downloads them from NCBI.

**2)** The script cleans nodes.dmp and names.dmp of the non-scientific names that are essentially duplicates of the scientific ones, and could create confusion later on.

**3)** It reads the fasta file provided as argument, and matches the gi accession number (required) to the entire taxonomy from the db. The fasta header should be in the format:
```
>gi|XXXXXXX| Description...
```
or
```
>gi|XXXXXXX|ref|XXXXXXXX| Description...
```
The **output** will be a tab-separated table (as required by QIIME) with the identifier on the first column and the taxa levels on the second, e.g.:
```
gi|444303911|ref|NR_074334.1|	Archaea;Euryarchaeota;Archaeoglobi;Archaeoglobales;Archaeoglobaceae;Archaeoglobus;Archaeoglobus fulgidus;Archaeoglobus fulgidus DSM 4304
```
The script has been tested on the NCBI's 16SMicrobial dataset (ftp://ftp.ncbi.nlm.nih.gov/blast/db/16SMicrobial.tar.gz) after converting it from blast_db format to fasta format. This allowed to run QIIME's [assign_taxonomy.py](http://qiime.org/scripts/assign_taxonomy.html) using the following parameters:
```
--assignment_method blast
--id_to_taxonomy_fp id_to_tax.map
--reference_seqs_fp 16sMicrobial.fasta
```
obtaining results down to the species level.
