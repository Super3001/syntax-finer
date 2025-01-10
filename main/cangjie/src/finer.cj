
package simple_finer

import simple_finer.ext.*
import simple_finer.nfa.*

enum Finer {
    | StringAndSyntaxPath(String, String)
    | StringAndSyntaxPathWithName(String, String, String)
    | StringAndNfa(String, NfaEntry)
}

extend Finer {
    func fine() { 
        let obj = match (this) {
            case StringAndNfa(text, entry) => (text, entry)
            case _ => throw Exception("Not implemented")
        }
        
        let text = List<Rune>.fromArray(obj[0].toRuneArray())
        let entry = obj[1]
        entry.runOn(text)
    }
}


