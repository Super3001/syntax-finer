import std.collection.{ArrayList, map}
import std.ast.{Position, ParseASTException}
import std.regex.Regex

abstract sealed class Node {
    public var beginPos = Position()
    public var endPos = Position()

    public func setPos(begin: Position, end: Position) {
        beginPos = begin
        endPos = end
    }
    public func dump(): Unit
    public func toJson(): String

}

abstract sealed class SyntaxPattern <: Node {
    SyntaxPattern(let atomic:Bool, let string: String) {}
    public func isAtomic(): Bool {this.atomic}
    public func dump() {
        println("SyntaxPattern(atomic:${atomic})")
    }
    public func toJson(): String {
        "\"SyntaxPattern\": {\n\t\"atomic\": ${atomic}\n}\n"
    }
}

abstract class AtomicPattern <: SyntaxPattern {
    AtomicPattern(string: String) {
        super(true, string)
    }
    
}

abstract class ComposePattern <: SyntaxPattern {
    ComposePattern(string: String) {
        super(false, string)
    }

}

class SimplePattern <: AtomicPattern {
    SimplePattern(string: String) {super(string)}
}

class RegexPattern <: AtomicPattern {
    RegexPattern(string: String) {super(string)}
}

class NamePattern <: AtomicPattern {
    NamePattern(string: String) {super(string)}
    static func build(string: String): NamePattern {NamePattern(string)}
}

class StarPattern <: ComposePattern {
    let content: SyntaxPattern
    StarPattern(string: String) {
        super(string)
        SyntaxPatternObject.requireEndsWith(string, "*")
        content = NamePattern.build(string[Range(0, -1, 1, true, true, false)])
    }
}

class OptPattern <: ComposePattern {
    let content: SyntaxPattern
    OptPattern(string: String) {
        super(string)
        SyntaxPatternObject.requireEndsWith(string, "?")
        content = NamePattern.build(string[Range(0, -1, 1, true, true, false)])
    }
}

class OrPattern <: ComposePattern {
    let content: ArrayList<SyntaxPattern> = ArrayList()
    OrPattern(string: String) {
        super(string)
        let rawContent: Collection<String> = SyntaxPatternObject.preserveQuoteSplit(string, " | ")
        for (each in rawContent) {
            content.append(SyntaxPatternObject.buildFrom(each))
        }
    }
}

class ConcatPattern <: ComposePattern {
    let content: ArrayList<SyntaxPattern> = ArrayList()
    ConcatPattern(string: String) {
        super(string)
        let rawContent: Collection<String> = SyntaxPatternObject.preserveQuoteSplit(string, " ")
        for (each in rawContent) {
            content.append(SyntaxPatternObject.buildFrom(each))
        }
    }
}

struct SyntaxPatternObject {
    static func checkInput(obj: SyntaxPattern) {
        if ( ! match (obj) {
            case p: StarPattern => obj.string.endsWith("*")
            case _ => true
        }
        ) {throw ParseASTException()}
    }
    static func requireEndsWith(string: String, pat: String){
        if(!string.endsWith(pat)) {throw ParseASTException()}
    }
    static func preserveQuoteSplit(s: String, pat: String): ArrayList<String> {
        var quoted: Bool = false
        let length: Int = pat.size
        let res: ArrayList<String> = ArrayList()
        var last: String = ''
        var after: String = s
        while (after.size > 0) {
            if            
        }
        res
    }
    static func buildFrom(s: String): SyntaxPattern {
        if s.endsWith("/")
    }
}
