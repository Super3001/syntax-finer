
package simple_finer

import simple_finer.ext.*

enum Finer {
    | StringAndSyntaxPath(String, String)
    | StringAndSyntaxPathWithName(String, String, String)
    | StringAndNfa(String, NfaEntry)
}

extend Finer {
    func fine() { 
        let obj = match (this) {
            case StringAndSyntaxPath(text, path) => (text, )
            case StringAndNfa(text, entry) => (text, entry)
        }
        
        let text = List<Rune>.fromArray(obj[0].toRuneArray())
        let entry = obj[1]
        entry.runOn(text)

    }
}


