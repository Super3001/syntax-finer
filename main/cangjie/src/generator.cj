package simple_finer

import std.collection.{HashMap, HashSet}
import simple_finer.ext.*

enum SymbolicPattern {
    | SimplePattern(String)
    | RegexPattern(String)
    | ConcatPattern(List<SymbolicPattern>)
    | OrPattern(List<SymbolicPattern>)
    | StarPattern(SymbolicPattern)
    | OptPattern(SymbolicPattern)
    | PlusPattern(SymbolicPattern)
    | UnQualifiedPattern
}

enum SyntaxEntry {
    | FileEntry(String, SymbolicPattern)
    | SimpleEntry(String, SymbolicPattern)
    | UndefinedEntry(String, String, SymbolicPattern)
}

func nominalToSymbolicPattern(expr: List<SyntaxExpr>): Result<List<SyntaxEntry>, String> {
    let _mapNominal = HashMap<String, SyntaxPattern>()
    let _mapSymbolic = HashMap<String, SymbolicPattern>()
    let _testSet = HashSet<String>()

    expr.map { 
        x: SyntaxExpr => match(x) {
            case SyntaxDefExpr(name, modifier, pat) => 
                if (let Some(old) <- _mapNominal.put(name, pat)) {
                    throw Exception("SyntaxDef name collision: ${old}")
                }
            case ImportExpr(_) => throw Exception("SyntaxImport should have been already removed here")
        }
    }

    func testAndSetFunc(name: String) {
        if (!_testSet.put(name)) {
            throw Exception("NamePattern contains itself currently not supported")
        }
    }

    func unsetFunc(name: String) {
        if (!_testSet.remove(name)) {
            throw Exception("unsetFunc with no previous setFunc")
        }
    }

    func qualifyAndLink(pat: SyntaxPattern): SymbolicPattern {
        match (pat) {
            case SimplePattern(s) => SimplePattern(s)
            case RegexPattern(s) => RegexPattern(s)
            case NamePattern(s) =>
                var ret: SymbolicPattern = UnQualifiedPattern
                if (let Some(qualified) <- _mapSymbolic.get(s)) {
                    ret = qualified
                }
                else if (let Some(sub) <- _mapNominal.get(s)) {
                    // circular reference detection
                    testAndSetFunc(s)
                    let qualified = qualifyAndLink(sub)
                    unsetFunc(s)
                    _mapSymbolic.put(s, qualified)
                    ret = qualified
                }
                else {
                    throw Exception("SyntaxDef name not found: ${s}")
                }
                ret
            case ConcatPattern(l) => ConcatPattern(l.map(qualifyAndLink))
            case OrPattern(l) => OrPattern(l.map(qualifyAndLink))
            case StarPattern(p) => StarPattern(qualifyAndLink(p))
            case OptPattern(p) => OptPattern(qualifyAndLink(p))
            case PlusPattern(p) => PlusPattern(qualifyAndLink(p))
        }
    }

    Ok(expr.reduce<List<SyntaxEntry>> ({
        acc, x => 
            let entry = match(x) {
                case SyntaxDefExpr(name, Some("file"), pat) => 
                    FileEntry(name, qualifyAndLink(pat))
                case SyntaxDefExpr(name, Some(modifier), pat) =>
                    println("warn: modifier `${modifier}` undefined")
                    UndefinedEntry(modifier, name, qualifyAndLink(pat))
                case SyntaxDefExpr(name, None, pat) => 
                    SimpleEntry(name, qualifyAndLink(pat))
                case _ => throw Exception("unreachable here");
            }
            Cons(entry, acc)
    }, List<SyntaxEntry>.empty()).reverse())

}

extend SyntaxEntry <: ToString {
    public func toString(): String {
        match (this) {
            case SimpleEntry(name, pat) => '<${name}> -> ${pat}'
            case FileEntry(name, pat) => '[qualified:file] <${name}> -> ${pat}'
            case UndefinedEntry(modifier, name, pat) => '[undefined:${modifier}] <${name}> -> ${pat}'
        }
    }
}


extend SymbolicPattern <: ToString {
    public func toString(): String {
        match (this) {
            case UnQualifiedPattern => "UnQualified!"
            case SimplePattern(s) => "SimplePattern{${s}}";
            case RegexPattern(s) => "RegexPattern{${s}}"
            case ConcatPattern(l) => "ConcatPattern{${l.join(', ')}}"
            case OrPattern(l) => "OrPattern{${l.join(', ')}}"
            case StarPattern(p) => "StarPattern{${p}}"
            case OptPattern(p) => "OptPattern{${p}}"
            case PlusPattern(p) => "PlusPattern{${p}}"
        }
    }
}

func evalSymbolic(str: String): Result<Unit, String>  {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).andThen(SyntaxExpr.fromTokens).andThen(SyntaxExpr.resolveLinks).andThen(nominalToSymbolicPattern).map {
        l => println(l.join('\n'))
    }
}

class Connector {
    private var _id: Int = -1
    private var _dest: NfaNode = EmptyNode

    public mut prop id: Int {
        get() {
            _id
        }
        set(value) {
            _id = value
        }
    }

    public mut prop dest: NfaNode {
        get() {
            _dest
        }
        set(value) {
            _dest = value
        }
    }

    public func init() {}
    public func init(id: Int, dest: NfaNode) {
        this.id = id
        this.dest = dest
    }
}

class MergeConnector <: Connector
class ForwardConnector <: Connector

enum NfaNode {
    | Single(Int, Rune, NfaNode)
    | Sequence(Int, List<Rune>, NfaNode)
    | Set(Int, List<Rune>, NfaNode)
    | Regex(Int, String, NfaNode)
    | Branch(Int, NfaNode, NfaNode)
    | LastBranch(Int, NfaNode, NfaNode)
    | Merge(MergeConnector)
    | Forward(Int, NfaNode, ForwardConnector)
    | Start(Int, NfaNode)
    | EmptyNode
    | End

    public func getId(): Int {
        match (this) {
            case Single(id, _, _) => id
            case Sequence(id, _, _) => id
            case Set(id, _, _) => id
            case Regex(id, _, _) => id
            case Branch(id, _, _) => id
            case LastBranch(id, _, _) => id
            case Merge(conn) => conn.id
            case Forward(id, _, _) => id
            case Start(id, _) => id
            case EmptyNode => -1
            case End => 0
        }
    }
}

extend NfaNode {
    static func fromPattern(pat: SymbolicPattern): Result<NfaNode, String> {
        match (generateNfaFunc(pat)) {
            case Some(nfa) => Ok(nfa)
            case None => Err("Invalid SyntaxPattern!")
        }
    }
}

extend NfaNode <: ToString {
    public func toString(): String {
        
        match (this) {
            case Start(id, nxt) => "Nfa: \n<${id}> Start" + nxt.toString()
            case Single(id, ch, nxt) => "\n<${id}> c'${Context.printable(ch)}' -> " + nxt.toString()
            case Sequence(id, l, nxt) => "\n<${id}> s'${l.join('')}' -> " + nxt.toString()
            case Set(id, l, nxt) => "\n<${id}> [${l.join('')}] -> " + nxt.toString()
            case Regex(id, s, nxt) => "\n<${id}> /${s}/ -> " + nxt.toString()
            case Branch(id, fst, snd) => match (snd) {
                case n where n.getId() >= 0 => "\n<${id}> => <${snd.getId()}> -> " + fst.toString() + snd.toString()
                case _ => println("<${id}> Branch connect to Start or EmptyNode!!!"); "\n<${id}> => <???> -> " + fst.toString()
            }
            case LastBranch(id, fst, snd) => match (snd) {
                case Merge(id2, nxt) => "\n<${id}> -> " + fst.toString() + nxt.toString()
                case _ => println("LastBranch must connect to Merge node!!!"); "\n<${id}> -> " + fst.toString()
            }
            case Merge(conn) => "<${conn.id}>"
            case Forward(id, nxt, conn) => "\n<${id}> => <${conn.id}> -> " + nxt.toString()
            case EmptyNode => "\n()."
            case End => "\n<0> End."
        }
    }
}

extend NfaNode {
    public func safeToString(): String {
        Context.clearSet()
        this.toString()
    }
}

func generateNfaFunc(pat: SymbolicPattern): Option<NfaNode> {
    var id = 0

    func novel_id(): Int {
        id += 1
        id
    }

    func clear_count(): Unit {
        id = 0
    }

    func gen_nfa(pat: SymbolicPattern, nxt: NfaNode): NfaNode {

        match (pat) {

            case SimplePattern(s) => Sequence(novel_id(), List.fromArray(s.toRuneArray()), nxt)

            case RegexPattern(s) => Regex(novel_id(), s, nxt)

            case ConcatPattern(l) => l.reverse().reduce ({
                acc, x => gen_nfa(x, acc)
            }, nxt)

            case OrPattern(l) =>
                let merge = Merge(MergeConnector(nxt.getId(), nxt))
                var x = l.reverse()
                var acc = EmptyNode
                match (x) {
                    case Nil => throw Exception("OrPattern with no sub-patterns")
                    case Cons(hd, tl) =>
                        let inner = gen_nfa(hd, merge)
                        acc = LastBranch(novel_id(), inner, merge)
                        x = tl
                }
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(hd, tl) => 
                            let inner = gen_nfa(hd, merge)
                            acc = Branch(novel_id(), inner, acc)
                            x = tl
                    }
                }
                acc            
            /*
            l.reverse().reduce<NfaNode> ({
                acc, x => match (acc) {
                    case EmptyNode => gen_nfa(x, nxt)
                    case _ => Branch(novel_id(), gen_nfa(x, nxt), acc)
                }  
            }, EmptyNode)
            */

            case StarPattern(p) => 
                let merge = Merge(MergeConnector(nxt.getId(), nxt))
                var conn = ForwardConnector()
                let one = gen_nfa(p, Forward(novel_id(), merge, conn))
                let first = Branch(novel_id(), one, nxt)
                conn.id = first.getId()
                conn.dest = first
                first
            case OptPattern(p) =>
                let merge = Merge(MergeConnector(nxt.getId(), nxt))
                let one = gen_nfa(p, merge)
                Branch(novel_id(), one, nxt)
            case PlusPattern(p) =>
                var first = EmptyNode
                let one = gen_nfa(p, Branch(novel_id(), nxt, first))
                first

            case UnQualifiedPattern => EmptyNode
        }
    }

    let nfa = gen_nfa(pat, End)

    // 将 regex 转为普通的 NfaNode
    func deal_regex() {}

    // 处理 literal 中的转义字符
    func deal_literal(node: NfaNode) {
        let idMap = HashMap<Int, NfaNode>()
        let forwardQueue = List<(Int, ForwardConnector)>.empty()

        func add_map(id: Int, node: NfaNode) {
            if (let Some(old) <- idMap.put(id, node)) {
                throw Exception("<${id}> id collision!")
            }
        }

        func add_queue(id: Int, conn: ForwardConnector) {
            forwardQueue.add((id, conn))
        }

        escaped = Combinator<Rune, Rune> {
            input => match(input) {
                case l where l.startsWith(List.fromArray("\\n".toRuneArray())) =>
                    Some((r'\n', l.skip(2)))
                case l where l.startsWith(List.fromArray("\\t".toRuneArray())) =>
                    Some((r'\t', l.skip(2)))
                case l where l.startsWith(List.fromArray("\\r".toRuneArray())) =>
                    Some((r'\r', l.skip(2)))
                case _ => Option<(Rune, List<Rune>)>.None
            }
        }

        plain = Combinator<Rune, Rune>.make {
            ch => true
        }

        literal = escaped.or(plain).many(1)

        func literalFunc(id: Int, sequence: List<Rune>. nxt: NfaNode): NfaNode{
            match (literal.parseFunc(sequence)) {
                case Some((l, _)) => l.reverse().reduce ({
                    acc, x => Single(novel_id(), x, acc)
                }, nxt)
                case None => throw Exception("<${id}> Literal not accepted: ${sequence.join('')}")
            }
        }

        func gen_dl(node: NfaNode) {
            match (node) {
                case Start(id, nxt) =>              let one = gen_dl(nxt); add_map(id, Start(novel_id(), one))
                case Single(id, ch, nxt) =>         let one = gen_dl(nxt); add_map(id, Single(novel_id(), ch, one))
                case Sequence(id, l, nxt) =>        let one = gen_dl(nxt); add_map(id, literalFunc(novel_id(), l, one))
                case Set(id, l, nxt) =>             let one = gen_dl(nxt); add_map(id, Set(novel_id(), l, one))
                case Regex(id, s, nxt) =>           let one = gen_dl(nxt); add_map(id, Regex(novel_id(), s, one))
                case Branch(id, fst, snd) =>        let two = gen_dl(snd); let one = gen_dl(fst); add_map(id, Branch(novel_id(), one, two))
                case LastBranch(id, fst, snd) =>    let two = gen_dl(snd); let one = gen_dl(fst); add_map(id, LastBranch(novel_id(), one, two))
                case Merge(conn) => 
                    // 后面id的结点，应该先生成
                    if (let Some(dest) <- idMap.get(conn.id)) { return Merge(MergeConnector(dest.getId(), dest)) } 
                    else { throw Exception("Merge connot connect to destination") }
                case Forward(id, nxt, conn) =>      let one = gen_dl(nxt); let two_conn = ForwardConnector(); add_queue(conn.id, two_conn); add_map(id, Forward(novel_id(), one, two_conn))
                case EmptyNode =>                   EmptyNode
                case End =>                         End
            }
        }


        

    }

    Some(Start(novel_id(), nfa))
}

func evalNfa(str: String): Result<Unit, String>  {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).andThen(SyntaxExpr.fromTokens).andThen(SyntaxExpr.resolveLinks).andThen(nominalToSymbolicPattern).map {
        l => l.map {
            x => match (x) {
                case FileEntry(s, pat) => 
                    println(pat)
                    match (NfaNode.fromPattern(pat)) {
                        case Ok(nfa) => println(nfa.safeToString())
                        case Err(e) => ()
                    }
                case _ =>
                    ()
            }
        }
    }
    Ok(())
}

class Context {

    static let _testSet = HashSet<Int>()

    static func clearSet(): Unit {
        _testSet.clear()
    }

    static func testAndSetFunc(id: Int): Bool {
        if (!_testSet.put(id)) {
            return false
        }
        return true
    }

    static func unsetFunc(id: Int): Bool {
        if (!_testSet.remove(id)) {
            return false
        }
        return true
    }

    static func printable(c: Rune): String {
        match (c) {
            case r'\n' => "\\n"
            case r'\t' => "\\t"
            case r'\r' => "\\r"
            case _ => c.toString()
        }
    }
}

// throw Exception("Circle in Linked Data Structure")
// throw Exception("unsetFunc with no previous setFunc")