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

class ForwardConnector {
    private var _dest: NfaNode = EmptyNode

    public mut prop dest: NfaNode {
        get() {
            _dest
        }
        set(value) {
            _dest = value
        }
    }
}

enum NfaNode {
    | Single(Int, Rune, NfaNode)
    | Sequence(Int, List<Rune>, NfaNode)
    | Set(Int, List<Rune>, NfaNode)
    | Transition(Int, NfaNode, NfaNode)
//     | LastTransition(Int, NfaNode, NfaNode)
//     | Merge(Int, NfaNode)
    | Forward(Int, NfaNode, ForwardConnector)
    | Start(NfaNode)
    | Bridge(Int, NfaNode)
    | EmptyNode
    | End

    public func getId(): Option<Int> {
        match (this) {
            case Single(id, _, _) => Some(id)
            case Sequence(id, _, _) => Some(id)
            case Set(id, _, _) => Some(id)
            case Transition(id, _, _) => Some(id)
            case Forward(id, _, _) => Some(id)
            case Start(_) => None
            case Bridge(id, _) => Some(id)
            case EmptyNode => None
            case End => Some(0)
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
        if (let Some(id) <- this.getId()) {
            if (!Context.testAndSetFunc(id)) {
                return "<${id}>; "
            }
        }

        match (this) {
            case Start(nxt) => "Nfa: \n" + nxt.toString()
            case Single(id, ch, nxt) => "<${id}> '${ch}' -> \n" + nxt.toString()
            case Sequence(id, l, nxt) => "<${id}> \"${l.join('')}\" -> \n" + nxt.toString()
            case Set(id, l, nxt) => "<${id}> [${l.join('')}] -> \n" + nxt.toString()
            case Transition(id, fst, snd) => match (snd.getId()) {
                case Some(id2) => "<${id}> => <${id2}> -> \n" + fst.toString() + snd.toString()
                case None => println("Forward Node to EmptyNode, Start!!!"); "<${id}> => <???> -> \n" + snd.toString()
            }
            case Forward(id, nxt, conn) => "<${id}> => <${conn.dest.getId().map{x => x.toString()}}> -> \n" + nxt.toString()
            case Bridge(id, nxt) => "<${id}> (maybe regex here ...) -> \n" + nxt.toString()
            case EmptyNode => "().\n"
            case End => "<0> End.\n"
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

    /*
    func or_nfa(l: List<SymbolicPattern>, nxt: NfaNode): NfaNode {
        
    }
    */

    func regex_nfa(s: String, nxt: NfaNode): NfaNode {
        Bridge(novel_id(), nxt)
    }

    func gen_nfa(pat: SymbolicPattern, nxt: NfaNode): NfaNode {

        match (pat) {

            case SimplePattern(s) => Sequence(novel_id(), List.fromArray(s.toRuneArray()), nxt)

            case RegexPattern(s) => regex_nfa(s, nxt)

            case ConcatPattern(l) => l.reverse().reduce ({
                acc, x => gen_nfa(x, acc)
            }, nxt)

            case OrPattern(l) =>
                var x = l.reverse()
                var acc = Bridge(novel_id(), nxt)
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(hd, tl) => 
                            acc = Transition(novel_id(), gen_nfa(hd, nxt), acc)
                            x = tl
                    }
                }
                acc       
            
            /*
            l.reverse().reduce<NfaNode> ({
                acc, x => match (acc) {
                    case EmptyNode => gen_nfa(x, nxt)
                    case _ => Transition(novel_id(), gen_nfa(x, nxt), acc)
                }  
            }, EmptyNode)
            */

            case StarPattern(p) => 
                var conn = ForwardConnector()
                let one = gen_nfa(p, Forward(novel_id(), nxt, conn))
                let first = Transition(novel_id(), one, nxt)
                conn.dest = first
                first
            case OptPattern(p) =>
                let one = gen_nfa(p, nxt)
                Transition(novel_id(), one, nxt)
            case PlusPattern(p) =>
                var first = EmptyNode
                let one = gen_nfa(p, Transition(novel_id(), nxt, first))
                first = Bridge(novel_id(), one)
                first

            case UnQualifiedPattern => EmptyNode
        }
    }

    Some(Start(gen_nfa(pat, End)))
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
}

// throw Exception("Circle in Linked Data Structure")
// throw Exception("unsetFunc with no previous setFunc")