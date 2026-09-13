d"""
A lightweight Moss module for working with FASTA sequence records.

FASTA record is represented by class `FASTA`.
To read a file or string, pass it into `dict_reader` or `list_reader`, which
will return either Dict or List of FASTA objects from this file/string. 
"""

class FASTA {
    d"""
    Class that represents a single FASTA record.
    """

    fun FASTA(id:String, seq:String, desc:[String,NilType]=nil) {
        this.id = id
        this.seq = seq
        this.desc = desc
        // TODO: Add alphabet type to check passed sequences
    }

    fun complement() {
        d"""
        Returns a new FASTA record that will be complemented sequence from this
        one.
        This method does not check if the sequence is only DNA.
        This method is case insensitive and will map:
            A -> T
            T -> A
            C -> G
            G -> C
        """
        comp_seq = []
        for (c: this.seq) {
            cc = c
            switch(c) {
                case "a": cc = "t"
                case "A": cc = "T"
                case "t": cc = "a"
                case "T": cc = "A"
                case "c": cc = "g"
                case "C": cc = "G"
                case "g": cc = "c"
                case "G": cc = "C"
            }
            ~comp_seq.append(cc)
        }
        return FASTA(this.id, "".join(comp_seq), this.desc)
    }

    fun count(pattern:String) {
        d"Returns amount of appearances of `pattern` in this sequence."
        return this.seq.count(pattern)
    }

    fun find(pattern:String) {
        d"""
        Returns index of first appearance of `pattern` in this sequence or -1 if
        it was not found.
        """
        return this.seq.index(pattern)
    }

    fun find(pattern:String, start:Int, end:Int) {
        d"""
        Returns index of first appearance of `pattern` in this sequence from
        `start` to `end` or -1 if it was not found.
        """
        return this.seq.index(pattern, start, end)
    }

    fun find_all(pattern:String, overlapping:Bool=true) {
        d"""
        Returns indices of all appearance of `pattern` in this sequence as a
        list.
        """
        indicies = []
        i = this.seq.index(pattern)
        while (i >= 0) {
            ~indicies.append(i)
            i = this.seq.index(pattern, i + (overlapping ? 1 : pattern.length()), this.seq.length())
        }
        return indicies
    }

    fun frequency(pattern:String) {
        d"""
        Returns frequency of appearance of `pattern` in this sequence.
        Length of this sequence cannot be 0.
        """
        return this.seq.count(pattern) / Float(this.length())
    }

    fun gc_count() {
        d"""
        Returns how many Gs and Cs are in this sequence.
        This method is case insensitive. 
        """
        return this.seq.count("G") + this.seq.count("C") + this.seq.count("g") + this.seq.count("c")
    }

    fun gc_frequency() {
        d"""
        Returns frequency of appearance of Gs and Cs in this sequence.
        This method is case insensitive. 
        """
        return (this.seq.count("G") + this.seq.count("C") + this.seq.count("g") + this.seq.count("c")) / Float(this.length())
    }

    fun is_dna() {
        d"""
        Returns true if all the characters in sequence are either A, T, C or G.
        This method is case insensitive.
        """
        return all(this.seq, fun(c)=c in ["A", "a", "G", "g", "C", "c", "T", "t"])
    }

    fun is_rna() {
        d"""
        Returns true if all the characters in sequence are either A, T, C or U.
        This method is case insensitive.
        """
        return all(this.seq, fun(c)=c in ["A", "a", "G", "g", "C", "c", "U", "u"])
    }

    fun length() {
        d"Returns character length of this sequence."
        return this.seq.length()
    }

    fun reverse() {
        d"""
        Returns a new FASTA record with this sequence reversed.
        """
        return FASTA(this.id, this.seq[-1..-this.seq.length()-1], this.desc)
    }

    fun reverse_complement() {
        d"""
        Returns a new FASTA record that will be a reversed and complemented
        sequence from this one.
        This method does not check if the sequence is only DNA.
        This method is case insensitive and will map:
            A -> T
            T -> A
            C -> G
            G -> C
        """
        comp_seq = []
        for (i: this.seq.length()-1..-1) {
            c = this.seq[i]
            cc = c
            switch(c) {
                case "a": cc = "t"
                case "A": cc = "T"
                case "t": cc = "a"
                case "T": cc = "A"
                case "c": cc = "g"
                case "C": cc = "G"
                case "g": cc = "c"
                case "G": cc = "C"
            }
            ~comp_seq.append(cc)
        }
        return FASTA(this.id, "".join(comp_seq), this.desc)
    }

    fun subsequence(r:Range) {
        d"""
        Returns a new FASTA record with the same id and description, just the
        sequence will be a subsequence from the current one.
        """
        return FASTA(this.id, this.seq[r], this.desc)
    }

    fun subsequence(start:Int, end:Int) {
        d"""
        Returns a new FASTA record with the same id and description, just the
        sequence will be a subsequence from the current one.
        """
        return FASTA(this.id, this.seq[start..end], this.desc)
    }

    fun ([])(index:[Int,Range]) {
        return this.seq[index]
    }

    fun (in)(value:String) {
        return value in this.seq
    }

    fun __String() {
        return f""">{this.id} {this.desc != nil ? this.desc : ""}\n{this.seq}"""
    }
}

class FastaParsingError : Exception {

    fun FastaParsingError(msg:String, line:Int, file=nil) {
        ~super(msg)
        this.line = line
        this.file = file
    }

    fun __String() {
        msg = "FastaParsingError: "
        if (file != nil)
            msg += file.path ++ ": "
        msg += "line " ++ this.line ++ ": " ++ msg
        return msg
    }
}

space {
    // Internals for parsing
    import sys
    _PLATFORM = sys.platform

    fun _parse_header(l:String) {
        // just ">" as a header
        if (l.length() <= 1)
            return ["", nil]
        id = nil
        for (sp_i: 1..l.length()) {
            if (l[sp_i].isspace()) {
                id = l[1..sp_i]
                break;
            }
        }
        if (id == nil)
            return [l[1..sp_i], nil]
        
        return [id, l[sp_i+1..l.length()]]
    }

    fun _parse_to(to_dict:Bool, lines:List, file=nil) {
        // Raise on missing header (>)
        // Raise when duplicate IDs when parsed to dict
        // Accept just header (empty sequence) or empty header
        fun add_record() {
            if ($to_dict && id in result) {
                // FIXME: Once this works remove assert
                assert(false, "Duplicate IDs when parsing into Dict.")
                raise FastaParsingError("Duplicate IDs when parsing into Dict.", line_num, file)
            }
            if ($to_dict) 
                result[id] = FASTA(id, seq, desc)
            else
                ~result.append(FASTA(id, seq, desc))
            // Reset parsed record values
            id = desc = nil
            seq = ""
        }

        result = to_dict ? {:} : []
        id = nil
        desc = nil
        seq = ""
        line_num = 0
        for (l: lines) {
            line_num += 1
            if (l.empty() || l.isspace()) {
                if (id != nil) {
                    ~add_record()
                }
                continue
            }
            // ID is not set or we encounter > then there is header expected
            if (id == nil) {
                if (l[0] != ">") {
                    assert(false, "Expected FAST header before sequence (starting with '>').")
                    // FIXME: This causes issues, fix.
                    raise FastaParsingError("Expected FAST header before sequence (starting with '>').", line_num, file)
                }
                id, desc = _parse_header(l)
            } else if (l[0] == ">") {
                ~add_record()
                id, desc = _parse_header(l)
            } else {
                // What is not empty/space line nor header is a sequence line
                seq ++= l
            }
        }
        if (id != nil) {
            ~add_record()
        }
        return result
    }
}

fun dict_reader(s:String) {
    d"""
    Reads FASTA string `s` and returns it's records as a dictionary.
    """
    nl = _PLATFORM == sys.Platform.Windows ? "\r\n" : "\n"
    return _parse_to(true, s.split(nl))
}

fun dict_reader(f:File) {
    d"""
    Reads FASTA file `f` and returns it's records as a dictionary.
    """
    l = f.readlines()
    return _parse_to(true, l, f)
}

fun list_reader(s:String) {
    d"""
    Reads FASTA string `s` and returns it's records as a list.
    """
    nl = _PLATFORM == sys.Platform.Windows ? "\r\n" : "\n"
    return _parse_to(false, s.split(nl))
}

fun list_reader(f:File) {
    d"""
    Reads FASTA file `f` and returns it's records as a list.
    """
    l = f.readlines()
    return _parse_to(false, l, f)
}

fun write_fasta(records, f:File) {
    d"""
    Writes multiple FASTA records into file `f`. There will be empty line
    between records.
    Argument `records` has to be iterable.
    File `f` has to be open for writing and won't be closed by this method.
    """
    first = true
    for (r: records) {
        if (not first)
            ~f.write("\n")
        first = false
        ~::write_fasta(r, f)
    }
}

fun write_fasta(records, path:String) {
    d"""
    Creates a new file on `path` and writes FASTA records into it.
    There will be empty line between records.
    Argument `records` has to be iterable.
    """
    ~with_open(path, fun(f) = ::write_fasta(records, f), "w")
}

fun write_fasta(record:FASTA, f:File) {
    d"""
    Writes a FASTA record into file `f`.
    File `f` has to be open for writing and won't be closed by this method.
    """
    ~f.write(String(record)++"\n")
}

fun write_fasta(record:FASTA, path:String) {
    d"""
    Creates a new file on `path` and writes a FASTA record into it.
    """
    ~with_open(path, fun(f) = ::write_fasta(record, f), "w")
}