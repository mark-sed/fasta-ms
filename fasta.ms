d"""
A lightweight Moss module for working with FASTA sequence records.

FASTA record is represented by class `FASTA`.
To read a file or string, pass it into `dict_reader` or `list_reader`, which
will return either Dict or List of FASTA objects from this file/string. 
"""

class FASTA {

    fun FASTA(id:String, seq:String, desc:String=nil) {
        this.id = id
        this.seq = seq
        this.desc = desc
        // TODO: Add alphabet type to check passed sequences
    }

    /*
    TODO:

    length()
    operator[]
    substring()
    contains()
    find()
    count()

    complement()
    reverse()
    reverse_complement()

    is_dna()
    is_rna()

    frequency(char)
    find_all(pattern)
    */
}

fun dict_reader(s:String) {
    d"""
    Reads FASTA string `s` and returns it's records as a dictionary.
    """
    // Raise on missing header (>)
    // Raise when duplicate IDs when parsed to dict
    // Accept just header (empty sequence) or empty header
}

fun dict_reader(f:File) {
    d"""
    Reads FASTA file `f` and returns it's records as a dictionary.
    """
    s = f.read()
    return ::dict_reader(s)
}

fun list_reader() {
    // TODO:
}