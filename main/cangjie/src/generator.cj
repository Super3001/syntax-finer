package simple_finer

import std.collection.{HashMap, HashSet}
import simple_finer.ext.*
import simple_finer.nfa.*
import simple_finer.regex.*

enum SymbolicPattern {
    | SimplePattern(String)
    | RegexPattern(String)
    | ConcatPattern(List<SymbolicPattern>)
    | OrPattern(List<SymbolicPattern>)
    | StarPattern(SymbolicPattern)
    | OptPattern(SymbolicPattern)
    | PlusPattern(SymbolicPattern)
    | NamePattern(SymbolicPattern, String, TMod)
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

    func pattern(): SymbolicPattern {
        match (this) {
            case FileEntry(_, p) => p
            case SimpleEntry(_, p) => p
            case UndefinedEntry(_, _, p) => p
        }
    }
}

extend TMod {
    static func default(pat: SymbolicPattern): TMod {
        match (pat) {
            case SimplePattern(_) => Str
            case RegexPattern(_) => Str
            case ConcatPattern(_) => Dict
            case OrPattern(_) => Dict
            case StarPattern(_) => List
            case OptPattern(p) => default(p)
            case PlusPattern(_) => List
            case NamePattern(p, _, _) => default(p)
            case UnQualified => throw Exception("UnQualified SymbolicPattern should not occur at link stage")
        }
    }
}

func nominalToSymbolicPattern(expr: List<SyntaxExpr>): Result<List<SyntaxEntry>, String> {
    let _mapNominal = HashMap<String, SyntaxExpr>()
    let _mapSymbolic = HashMap<String, SyntaxEntry>()
    let _testSet = HashSet<String>()
    
    /*
    let _mapNameId = HashMap<String, Idklass>()
    let _mapIdName = HashMap<Idklass, String>()
    func init_nameId(): Idklass {
        /*
        0
        */
        ""
    }
    var nameId = init_nameId()
    func add_name(name: String) {
        func novel_name_id(): Idklass {
            /*
            nameId += 1
            nameId
            */
            name
        }
        /*
        id = novel_name_id()
        _mapNameId.put(name, id)
        _mapIdName.put(id, name)
        */
    }
    func name2id(name: String): Idklass {
        /*
        if (let Some(id) <- _mapNameId.get(name)) {
            return id
        }
        throw Exception("name not found: ${name}")
        */
        name
    }
    func id2name(id: Idklass): String {
        id
    } 
    */

    /*
    expr.map { 
        x: SyntaxExpr => match(x) {
            case SyntaxDefExpr(name, _, _) => 
                if (let Some(old) <- _mapNominal.put(name, x)) {
                    throw Exception("SyntaxDef name collision: ${old}")
                }
                add_name(name)
            case ImportExpr(_) => throw Exception("SyntaxImport should have been already removed here")
        }
    }
    */

    var x = expr
    while (true) {
        match (x) {
            case Nil => break
            case Cons(hd, tl) =>
                match(hd) {
                    case SyntaxDefExpr(name, _, _) => 
                        if (let Some(old) <- _mapNominal.put(name, hd)) {
                            throw Exception("SyntaxDef name collision: ${old}")
                        }
                    case ImportExpr(_) => throw Exception("SyntaxImport should have been already removed here")
                }
                x = tl
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

    func entryFromExpr(expr: SyntaxExpr): SyntaxEntry {

        func qualifyAndLink(pat: SyntaxPattern): SymbolicPattern {
            match (pat) {
                case SimplePattern(s) => SimplePattern(s)
                case RegexPattern(s) => RegexPattern(s)
                case NamePattern(s) =>
                    var ret: SymbolicPattern = UnQualifiedPattern
                    if (let Some(qualified) <- _mapSymbolic.get(s)) {
                        ret = qualified.pattern()
                    }
                    else if (let Some(expr) <- _mapNominal.get(s)) {
                        // circular reference detection
                        testAndSetFunc(s)
                        let entry = entryFromExpr(expr)
                        unsetFunc(s)
                        _mapSymbolic.put(s, entry)
                        ret = entry.pattern()
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

        match (expr) {
            case SyntaxDefExpr(name, modifier, pat) => 
                let symbolic = qualifyAndLink(pat)
                match (modifier) {
                    case Some("file") => FileEntry(name, NamePattern(symbolic, name, File))
                    case Some("f") => FileEntry(name, NamePattern(symbolic, name, F))
                    case Some(other) => UndefinedEntry(name, other, NamePattern(symbolic, name, Undefined(other)))
                    case None => SimpleEntry(name, NamePattern(symbolic, name, TMod.default(symbolic)))
                }
            case _ => throw Exception("`entryFromExpr`: unreachable here");
        }
    }

    /*
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
    */

    Ok(expr.map(entryFromExpr))
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

func dump(l: List<SyntaxEntry>) {
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
            // case NamePattern(p, id, mod) => "NamePattern[${id}, ${mod}]{${p}}"
            case NamePattern(p, id, mod) => "${p}"
        }
    }
}

func evalSymbolic(str: String): Result<Unit, String>  {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).andThen(SyntaxExpr.fromTokens).andThen(SyntaxExpr.resolveLinks).andThen(nominalToSymbolicPattern).map {
        l => println(l.join('\n'))
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

func dump(entry: NfaEntry) {
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
        let id = novel_id(); (Regex(nxt, s, id), id)
    }

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

    func gen_nfa(pat: SymbolicPattern, nxt: NfaNode): NfaNode {

        match (pat) {
            case SimplePattern(s) => literalFunc(nxt, s, -1) // case SimplePattern(s) => Sequence(nxt, List.fromArray(s.toRuneArray()), novel_id())

            case RegexPattern(s) => let t = regexFunc(nxt, s, id); id = t[1]; t[0] // case RegexPattern(s) => Regex(nxt, s, novel_id())

            case ConcatPattern(l) => // l.reverse().reduce({ acc, x => gen_nfa(x, acc) }, nxt)
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
            case NamePattern(p, id, mod) => 
                Tracker(gen_nfa(p, TrackerEnd(nxt, mod, novel_id())), id, mod, novel_id())
            case UnQualifiedPattern => EmptyNode
        }
    }

    let nfa = Start(gen_nfa(pat, End), novel_id())
    Some(nfa)
}


func evalNfa(str: String): Result<Unit, String>  {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    // println(runes)
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