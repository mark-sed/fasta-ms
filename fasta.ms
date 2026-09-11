d"""
A lightweight Moss module for working with FASTA sequence records.

FASTA record is represented by class `FASTA`.
To read a file or string, pass it into `dict_reader` or `list_reader`, which
will return either Dict or List of FASTA objects from this file/string. 
"""

class FASTA {
    d"""
    Class that represents single FASTA record.
    """

    fun FASTA(id:String, seq:String, desc:[String,NilType]=nil) {
        this.id = id
        this.seq = seq
        this.desc = desc
        // TODO: Add alphabet type to check passed sequences
    }

    fun complement() {
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
        return this.seq.count(pattern)
    }

    fun find(pattern:String) {
        return this.seq.index(pattern)
    }

    fun find(pattern:String, start:Int, end:Int) {
        return this.seq.index(pattern, start, end)
    }

    fun find_all(pattern:String, overlapping:Bool=true) {
        indicies = []
        i = this.seq.index(pattern)
        while (i >= 0) {
            ~indicies.append(i)
            i = this.seq.index(pattern, i + (overlapping ? 1 : pattern.length()), this.seq.length())
        }
        return indicies
    }

    fun frequency(pattern:String) {
        return this.seq.count(pattern) / Float(this.length())
    }

    fun gc_count() = this.seq.count("G") + this.seq.count("C") + this.seq.count("g") + this.seq.count("c")
    fun gc_frequency() = (this.seq.count("G") + this.seq.count("C") + this.seq.count("g") + this.seq.count("c")) / Float(this.length())

    fun is_dna() {
        return all(this.seq, fun(c)=c in ["A", "a", "G", "g", "C", "c", "T", "t"])
    }

    fun is_rna() {
        return all(this.seq, fun(c)=c in ["A", "a", "G", "g", "C", "c", "U", "u"])
    }

    fun length() {
        return this.seq.length()
    }

    fun reverse() {
        return this.seq[-1..-this.seq.length()-1]
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
    /*
    TODO:
    complement()
    reverse_complement()
    */
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