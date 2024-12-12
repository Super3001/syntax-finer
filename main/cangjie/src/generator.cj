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

open class Connector {
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

    public init() {}
    public init(id: Int, dest: NfaNode) {
        this._id = id
        this._dest = dest
    }
}

/*
class MergeConnector <: Connector {}
class BackwardConnector <: Connector {}
*/

enum NfaNode {
    | Single(NfaNode, Rune, Int)
    | Sequence(NfaNode, List<Rune>, Int)
    | Set(NfaNode, List<Rune>, Int)
    | Regex(NfaNode, String, Int)
    | Branch(NfaNode, NfaNode, Int)
    | Merge(NfaNode)
    | Forward(NfaNode, NfaNode, Int)
    | Backward(NfaNode, Connector, Int)
    | Start(NfaNode, Int)
    | EmptyNode
    | End

    public func getId(): Int {
        match (this) {
            case Single(_, _, id) => id
            case Sequence(_, _, id) => id
            case Set(_, _, id) => id
            case Regex(_, _, id) => id
            case Branch(_, _, id) => id
            case Merge(nxt) => nxt.getId()
            case Forward(_, _, id) => id
            case Backward(_, _, id) => id
            case Start(_, id) => id
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
            case Single(nxt, ch, id) => "<${id}> Single{c'${ch}'} -> <${nxt.getId()}>"
            case Sequence(nxt, l, id) => "<${id}> Sequence{s'${l.join('')}'} -> <${nxt.getId()}>"
            case Set(nxt, l, id) => "<${id}> Set{[${l.join('')}]} -> <${nxt.getId()}>"
            case Regex(nxt, s, id) => "<${id}> Regex{/${s}/} -> <${nxt.getId()}>"
            case Branch(fst, snd, id) => "<${id}> Branch{<${fst.getId()}>} -> <${snd.getId()}>"
            case Merge(nxt) => "<-2> Merge -> <${nxt.getId()}>"
            case Forward(fst, snd, id) => "<${id}> Forward{<${fst.getId()}>} -> <${snd.getId()}>"
            case Backward(nxt, conn, id) => "<${id}> Backward{<${conn.id}>} -> <${nxt.getId()}>"
            case Start(nxt, id) => "<${id}> Start -> <${nxt.getId()}>"
            case EmptyNode => "<-1> EmptyNode."
            case End => "<0> End."
        }
    }
}

extend NfaNode {
    public func stringifyNfa(): String {

        func nfa2string(node: NfaNode): String {

            match (node) {
                case Start(nxt, id) => "Nfa: \n<${id}> Start ->" + nfa2string(nxt)
                case Single(nxt, ch, id) => "\n<${id}> c'${Context.printable(ch)}' -> " + nfa2string(nxt)
                case Sequence(nxt, l, id) => "\n<${id}> s'${l.join('')}' -> " + nfa2string(nxt)
                case Set(nxt, l, id) => "\n<${id}> [${l.join('')}] -> " + nfa2string(nxt)
                case Regex(nxt, s, id) => "\n<${id}> /${s}/ -> " + nfa2string(nxt)
                case Branch(fst, snd, id) => match (fst) {
                    case n where n.getId() >= 0 => "\n<${id}> => <${fst.getId()}> -> " + nfa2string(snd) + nfa2string(fst)
                    case _ => println("<${id}> Branch connect to Start or EmptyNode!!!"); "\n<${id}> => <???> -> " + nfa2string(snd)
                }
                case Merge(nxt) => "<${nxt.getId()}>"
                case Forward(fst, snd, id) => "\n<${id}> => <${fst.getId()}> -> " + nfa2string(snd)
                case Backward(nxt, conn, id) => "\n<${id}> => <${conn.id}> -> " + nfa2string(nxt)
                case EmptyNode => "\n()."
                case End => "\n<0> End."
            }
        }

        nfa2string(this)   
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

            case SimplePattern(s) => Sequence(nxt, List.fromArray(s.toRuneArray()), novel_id())

            case RegexPattern(s) => Regex(nxt, s, novel_id())

            case ConcatPattern(l) => l.reverse().reduce ({
                acc, x => gen_nfa(x, acc)
            }, nxt)

            case OrPattern(l) =>
                let merge = Merge(nxt)
                var x = l.reverse()
                var acc = EmptyNode
                match (x) {
                    case Nil => throw Exception("OrPattern with no content!")
                    case Cons(hd, tl) =>
                        acc = gen_nfa(hd, nxt)
                        x = tl
                }
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(hd, tl) => 
                            let inner = gen_nfa(hd, merge)
                            acc = Branch(acc, inner, novel_id())
                            x = tl
                    }
                }
                acc

            case StarPattern(p) => 
                let one = gen_nfa(PlusPattern(p), nxt)
                Forward(nxt, one, novel_id())
            case OptPattern(p) =>
                let one = gen_nfa(p, nxt)
                Forward(nxt, one, novel_id())
            case PlusPattern(p) =>
                var conn = Connector()
                let one = gen_nfa(p, Backward(nxt, conn, novel_id()))
                conn.id = one.getId()
                conn.dest = one
                one
            case UnQualifiedPattern => EmptyNode
        }
    }
    /*

    // 将 regex 转为普通的 NfaNode
    func deal_regex() {}

    // 处理 literal 中的转义字符
    func deal_literal(node: NfaNode) {
        let idMap = HashMap<Int, NfaNode>()
        let forwardQueue = List<(Int, Connector)>.empty()

        func add_map(id: Int, node: NfaNode) {
            if (let Some(old) <- idMap.put(id, node)) {
                throw Exception("<${id}> id collision!")
            }
        }

        func add_queue(id: Int, conn: Connector) {
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
                    if (let Some(dest) <- idMap.get(conn.id)) { return Merge(Connector(dest.getId(), dest)) } 
                    else { throw Exception("Merge connot connect to destination") }
                case Backward(id, nxt, conn) =>      let one = gen_dl(nxt); let two_conn = Connector(); add_queue(conn.id, two_conn); add_map(id, Backward(novel_id(), one, two_conn))
                case EmptyNode =>                   EmptyNode
                case End =>                         End
            }
        }

    }
    */

    let nfa = Start(gen_nfa(pat, End), novel_id())
    Some(nfa)
}

func evalNfa(str: String): Result<Unit, String>  {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).andThen(SyntaxExpr.fromTokens).andThen(SyntaxExpr.resolveLinks).andThen(nominalToSymbolicPattern).map {
        l => l.map {
            x => match (x) {
                case FileEntry(s, pat) => 
                    println(pat)
                    match (NfaNode.fromPattern(pat)) {
                        case Ok(nfa) => println(nfa.stringifyNfa())
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