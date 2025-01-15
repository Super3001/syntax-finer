
package simple_finer

import simple_finer.ext.*
import simple_finer.nfa.*
import std.fs.File

enum Finer {
    | StringAndSyntaxPath(String, String)
    | StringAndSyntaxPathWithName(String, String, String)
    | StringAndNfa(String, NfaEntry)
}

extend Finer {
    func fine() { 
        let obj = match (this) {
            case StringAndNfa(text, entry) => (text, entry)
            case StringAndSyntaxPath(text, path) => (text, readFile(path).andThen(fileEntryFromString).getOrThrow())
            case _ => throw Exception("Not implemented")
        }
        
        let text = List<Rune>.fromArray(obj[0].toRuneArray())
        let entry = obj[1]
        // println(text)
        let result = entry.runOn(text)
        // result.deduplication()
        println(result)
        writeToJson(result.toJson())
    }

    static func writeToJson(text: String, filename!: String = "finer_result.json") {
        let filepath = "text_out\\" + filename
        File.writeTo(filepath, text.toArray())
    }

}


