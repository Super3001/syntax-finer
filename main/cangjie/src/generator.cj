package simple_finer

import std.collection.{HashMap, HashSet}
import simple_finer.ext.*
import simple_finer.nfa.*
import simple_finer.regex.fun as regexFun

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

    func isFileEntry(): Bool {
        match(this) {
            case FileEntry(_, _) => true
            case _ => false
        }
    } 
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

func printOut(l: List<SyntaxEntry>) {
    println(l.join('\n'))
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


enum NfaEntry {
    | FileEntry(String, NfaNode)
    | SimpleEntry(String, NfaNode)
    | UndefinedEntry(String, String, NfaNode)

    func isFileEntry(): Bool {
        match(this) {
            case FileEntry(_, _) => true
            case _ => false
        }
    } 

    func getNfa(): NfaNode {
        match (this) {
            case FileEntry(_, nfa) => nfa
            case SimpleEntry(_, nfa) => nfa
            case UndefinedEntry(_, _, nfa) => nfa
        }
    }

    func getSymbol(): String {
        match (this) {
            case SimpleEntry(name, nfa) => '<${name}>'
            case FileEntry(name, nfa) => '[qualified:file] <${name}>'
            case UndefinedEntry(modifier, name, nfa) => '[undefined:${modifier}] <${name}>'
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


extend NfaEntry {
    static func generateFirstFile(l: List<SyntaxEntry>): Result<NfaEntry, String> {
        if (let Some((hd, Cons(FileEntry(s, pat), tl))) <- l.splitOnce { x => x.isFileEntry() } ) {
            if (let Ok(nfa) <- NfaNode.fromPattern(pat)) {
                return Ok(FileEntry(s, nfa))
            }
            throw Exception("symbol ${s}:\nError when generate Nfa!")
        }
        throw Exception("using `NfaEntry.generateFirstFile()`, but no SyntaxEntry::FileEntry found.\nProbably: No SyntaxDef has `file` modifier!")
    }

    static func generateSeparatedFiles() {}

    static func generateLinkedAll() {}
}

extend NfaEntry <: ToString {
    public func toString(): String {
        this.getSymbol() + " -> Nfa{${this.getNfa().getId()} nodes}"
    }
}

extend NfaEntry {
    public func stringifyNfa(): String {
        return this.getSymbol() + " -> " + this.getNfa().stringifyNfa()
    }
}

func printOut(entry: NfaEntry) {
    println(entry.stringifyNfa())
}


func generateNfaFunc(pat: SymbolicPattern): Option<NfaNode> {
    var id = 0

    func novel_id(): Int {
        id += 1
        id
    }

    func reset_id(): Unit {
        id = 0
    }
    
    // 将 regex 转为普通的 NfaNode
    func regexFunc(nxt: NfaNode, s: String, base_id: Int): (NfaNode, Int) {
        regexFun(s, nxt, base_id).getOrThrow()
        // let id = novel_id(); (Regex(nxt, s, id), id)
    }

    // func deal_regex() {
    // }

    // 处理 literal 中的转义字符
    func literalFunc(nxt: NfaNode, s: String, id: Int): NfaNode{

        let sequence = List.fromArray(s.toRuneArray())

        let escaped = Combinator<Rune, Rune> {
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

        let plain = Combinator<Rune, Rune>.make {
            _ => true
        }

        let literal = escaped.or(plain).many(1)

        match (literal.parseFunc(sequence)) {
            case Some((l, _)) => 
                var acc = nxt
                var x = l.reverse()
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(hd, tl) =>
                            acc = Single(acc, hd, novel_id())
                            x = tl
                    }
                }
                acc
            case None => throw Exception("<${id}> Literal not accepted: ${sequence.join('')}")
        }
    }

    func deal_literal(head: NfaNode) {
        let idMap = HashMap<Int, NfaNode>()
        let forwardQueue = List<(Int, Connector)>.empty()

        func add_map(id: Int, node: NfaNode) {
            if (let Some(old) <- idMap.put(id, node)) {
                throw Exception("<${id}> id collision!")
            }
            node
        }

        func add_queue(id: Int, conn: Connector) {
            forwardQueue.add((id, conn))
        }


        func gen_dl(node: NfaNode): NfaNode {
            match (node) {
                case Start(nxt, id) =>              add_map(id, Start(gen_dl(nxt), novel_id()))
                case All(nxt, id) =>                add_map(id, All(gen_dl(nxt), novel_id()))
                case Single(nxt, ch, id) =>         add_map(id, Single(gen_dl(nxt), ch, novel_id()))
                case Sequence(nxt, l, id) =>        add_map(id, literalFunc(gen_dl(nxt), l, id))
                case Set(nxt, rec, id) =>           add_map(id, Set(gen_dl(nxt), rec, novel_id()))
                case InvSet(nxt, rec, id) =>        add_map(id, InvSet(gen_dl(nxt), rec, novel_id()))
                case Regex(nxt, s, id) =>           add_map(id, Regex(gen_dl(nxt), s, novel_id()))
                case Branch(down, inner, id) =>     add_map(id, Branch(gen_dl(down), gen_dl(inner), novel_id()))
                case Merge(nxt) => 
                    if (let Some(dest) <- idMap.get(nxt.getId())) { return Merge(dest) } 
                    else { throw Exception("${node}:\nMerge connot connect to destination") }
                case Forward(near, far, id) => 
                    let nxt = gen_dl(near)    
                    if (let Some(one) <- idMap.get(far.getId())) { return add_map(id, Forward(nxt, one, novel_id())) } 
                    else { throw Exception("${node}:\nForward connot connect to the front") }
                case Backward(nxt, conn, id) =>     let newConn = Connector(); add_queue(conn.id, newConn); add_map(id, Backward(gen_dl(nxt), newConn, novel_id()))
                case AssertAhead(nxt, anxt, id) =>  add_map(id, AssertAhead(gen_dl(nxt), gen_dl(anxt), novel_id()))
                case AssertBack(nxt, anxt, id) =>   add_map(id, AssertBack(gen_dl(nxt), gen_dl(anxt), novel_id()))
                case AssertEnd(id) =>               
                    if (let Some(one) <- idMap.get(id)) { return AssertEnd(one.getId()) }
                    else { throw Exception("${node}:\nAssertEnd connot connect to the front") }
                case EmptyNode =>                   EmptyNode
                case End =>                         add_map(0, End)
            }
        }

        reset_id()
        let res = gen_dl(head)
        forwardQueue.map {
            group: (Int, Connector) => 
                match (group) {
                    case (id, conn) =>
                        if (let Some(node) <- idMap.get(id)) {
                            conn.dest = node
                            conn.id = node.getId()
                            return ()
                        }
                        throw Exception("<${id}> node not found!")
                }
            
        }
        res
    }

    func gen_nfa(pat: SymbolicPattern, nxt: NfaNode): NfaNode {

        match (pat) {

            // case SimplePattern(s) => Sequence(nxt, List.fromArray(s.toRuneArray()), novel_id())
            case SimplePattern(s) => literalFunc(nxt, s, -1)

            // case RegexPattern(s) => Regex(nxt, s, novel_id())
            case RegexPattern(s) => let t = regexFunc(nxt, s, id); id = t[1]; t[0]

            case ConcatPattern(l) => 
                // l.reverse().reduce({ acc, x => gen_nfa(x, acc) }, nxt)
                var x = l.reverse()
                var acc = nxt
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(hd, tl) =>
                            acc = gen_nfa(hd, acc)
                            x = tl
                    }
                }
                acc
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
                Forward(one, nxt, novel_id())
            case OptPattern(p) =>
                let one = gen_nfa(p, nxt)
                Forward(one, nxt, novel_id())
            case PlusPattern(p) =>
                var conn = Connector()
                let one = gen_nfa(p, Backward(nxt, conn, novel_id()))
                conn.id = one.getId()
                conn.dest = one
                one
            case UnQualifiedPattern => EmptyNode
        }
    }

    let nfa = Start(gen_nfa(pat, End), novel_id())
    // println(nfa.stringifyNfa())
    Some(deal_literal(nfa))
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

// throw Exception("Circle in Linked Data Structure")
// throw Exception("unsetFunc with no previous setFunc")