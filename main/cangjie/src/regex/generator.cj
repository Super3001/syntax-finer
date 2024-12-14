
package simple_finer.regex

import std.convert.*
import simple_finer.ext.*
import simple_finer.nfa.{NfaNode, Connector}

extend Rune {
    func toInt(): Int {
        match {
            case this.isAscii() =>
                let arr = Array<Byte>(1, item: 0)
                Rune.intoUtf8Array(this, arr, 0)
                Int.parse("${arr[0]}")
            case _ => -1
        }
    }
}

extend Byte {
    func isAlnum(): Bool {
        this.isAsciiNumberOrLetter() || this == b'_'
    }
}

type Rec = BoolArrayRecord

class BoolArrayRecord {
    
    BoolArrayRecord(let _rawString: String) {}

    static let w = Rec.madeFrom("\\w") { ch => ch.isAlnum() }
    static let d = Rec.madeFrom("\\d") { ch => ch.isAsciiNumber() }
    static let s = Rec.madeFrom("\\s") { ch => ch.isAsciiWhiteSpace() }
    static let W = Rec.madeFrom("\\W") { ch => !ch.isAlnum() }
    static let S = Rec.madeFrom("\\S") { ch => !ch.isAsciiWhiteSpace() }
    static let D = Rec.madeFrom("\\D") { ch => !ch.isAsciiNumber() }

    let _dest: Array<Bool> = Array(128, item: false)

    public prop dest: Array<Bool> {
        get() {
            _dest
        }
    }

    public prop rawString: String {
        get() {
            _rawString
        }
    }

    public func runeContains(ch: Rune): Bool {
        match {
            case ch.isAscii() => this.dest[ch.toInt()]
            case _ => false
        }
    }

    static func madeFrom(raw: String, cond: (Byte) -> Bool): Rec {
        let p = Rec(raw)
        var b: Byte = 0
        for( i in 0..128 ) {
            if ( cond(b) ) {
                p._dest[i] = true
            }
            b += 1
        }
        p
    }

}

extend Rec <: ToString {
    public func toString(): String {
        "Rec{${this.rawString}}"
    }
}


func generateRegexNfaFunc(pat: RegexPattern): NfaNode {

    func gen_nfa(): NfaNode {
        
        EmptyNode
    }

    EmptyNode
}