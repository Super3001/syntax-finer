package simple_finer.nfa

import std.convert.*
import simple_finer.ext.*

extend Rune {
    func toInt(): Int {
        match {
            case this.isAscii() =>
                let arr = Array<Byte>(1, repeat: 0)
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

    func isNewLine(): Bool {
        this == b'\n' || this == b'\r'
    }
}

protected type Rec = BoolArrayRecord

protected class BoolArrayRecord {
    
    var _name = "unknown"

    protected init(name: String) {
        this._name = name
    }

    static let dot = Rec.madeFrom(".") { ch => !ch.isNewLine() }
    static let nl = Rec.madeFrom("newline") { ch => ch.isNewLine() }
    static let w = Rec.madeFrom("\\w") { ch => ch.isAlnum() }
    static let d = Rec.madeFrom("\\d") { ch => ch.isAsciiNumber() }
    static let s = Rec.madeFrom("\\s") { ch => ch.isAsciiWhiteSpace() }
    static let W = Rec.madeFrom("\\W") { ch => !ch.isAlnum() }
    static let S = Rec.madeFrom("\\S") { ch => !ch.isAsciiWhiteSpace() }
    static let D = Rec.madeFrom("\\D") { ch => !ch.isAsciiNumber() }
    static let a = Rec.madeFrom("\\a") { ch => ch.isAscii() }
    static let none = Rec("none")

    public static func newline(): Rec {
        Rec.nl
    }

    let _dest: Array<Bool> = Array(128, repeat: false)

    public prop dest: Array<Bool> {
        get() {
            _dest
        }
    }

    public prop name: String {
        get() {
            _name
        }
    }

    public func contains(ch: Rune): Bool {
        match {
            case ch.isAscii() => this.dest[ch.toInt()]
            case _ => false
        }
    }

    protected func or(other: Rec) {
        let o = other.dest
        for (i in 0..128) {
            _dest[i] = _dest[i] || o[i]
        }
    }

    protected func or(ch: Rune) {
        match {
            case ch.isAscii() => _dest[ch.toInt()] = true
            case _ => println("warn: non-ascii character in regex [] syntax is currently not supported")
        }
    }

    protected static func fromEscaped(ch: Rune): Rec {
        match (ch) {
            case r'w' => Rec.w
            case r's' => Rec.s
            case r'd' => Rec.d
            case r'W' => Rec.W
            case r'S' => Rec.S
            case r'D' => Rec.D
            case r'a' => Rec.a
            case _ => throw Exception("regex generator: Escaped character \\${ch} is not allowed")
        }
    }

    protected static func fromRange(c1: Rune, c2: Rune): Rec {
        // let p = Rec("${Context.printable(c1)}-${Context.printable(c2)}")
        let p = Rec("")
        match {
            case !c1.isAscii() || !c2.isAscii() => throw Exception("")
            case c1.toInt() > c2.toInt() => throw Exception("")
            case _ =>
                let low = c1.toInt()
                let high = c2.toInt()
                for (i in low..=high) {
                    p._dest[i] = true
                }
        }
        p
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
        "Rec{${this.name}}"
    }
}