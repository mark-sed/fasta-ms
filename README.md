# FASTA

A lightweight [Moss](https://github.com/mark-sed/moss-lang) module for working
with FASTA sequence records.

## Usage examples

```cpp
import fasta

// Read fasta into Dict
records = with_open("betaglobin.fasta", fasta.dict_reader)
// Get record by ID
betag = records["U01317.1"]
// Get a subsequence of the tail
tail = betag[betag.length()-200..betag.length()]
// Create a new record with new ID and description
tail_record = fasta.FASTA("U01317.1.TAIL_REV", tail, "Reversed tail of U01317.1")
// Get reverse complement of the tail (as String)
tail_rev_comp = tail_record.reverse_complement()
// Write the new record
~fasta.write_fasta(tail_rev_comp, "matching_tail.fasta")
```
