
package simple_finer.regex

import simple_finer.ext.*
import simple_finer.nfa.*

extend Rec {
    
    static func fromTokens(l: List<Token>): Rec {

        func shortListToken(l: List<Token>): String {
            l.toString()
        }

        match(l) {
            case Nil => throw Exception("empty regex [] syntax is not accepted")
            case _ =>
                var x = l
                var acc = Rec(shortListToken(l))
                while (true) {
                    match (x) {
                        case Nil => break
                        case Cons(Plain(c1), Cons(Dash, Cons(Plain(c2), tail))) => 
                            acc.or(Rec.fromRange(c1, c2))
                            x = tail
                        case Cons(_, Cons(Dash, Cons(_, _))) => 
                            throw Exception("regex generate: You cannot create a range with shorthand escape sequences")
                        case Cons(Escaped(ch), tail) =>
                            acc.or(Rec.fromEscaped(ch))
                            x = tail
                        case Cons(Plain(ch), tail) =>
                            acc.or(ch)
                            x = tail
                        case Cons(Dash, tail) =>
                            acc.or(r'-')
                            x = tail
                        case _ => throw Exception("")
                    }
                }
                acc
        }
    }

}

func generateRegexNfaWithBase(pat: RegexPattern, nxt: NfaNode, base: Int): Option<(NfaNode, Int)> {

    var id = base

    func novel_id(): Int {
        id += 1
        id
    }

    func gen_nfa(pat: RegexPattern, nxt: NfaNode): NfaNode {
        
        match (pat) {

            case SimplePattern(ch) => Single(nxt, ch, novel_id())
            case SetPattern(l) => match(l) {
                case Cons(Caret, tail) => InvSet(nxt, Rec.fromTokens(tail), novel_id())
                case l => Set(nxt, Rec.fromTokens(l), novel_id())
            }
            case DotPattern => InvSet(nxt, Rec.newline(), novel_id())

            case PositionPattern(flag) => 
                id = novel_id()
                if (flag) {
                    AssertAhead(nxt, Set(AssertEnd(id), Rec.newline(), novel_id()), id)
                }
                else {
                    AssertBack(nxt, Set(AssertEnd(id), Rec.newline(), novel_id()), id)
                }
            
            case ConcatPattern(l) => 
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

            case EmptyPattern => EmptyNode

        }
        
    }

    Some((gen_nfa(pat, nxt), id))
}

func generateRegexNfaFunc(pat: RegexPattern): Option<NfaNode> {

    generateRegexNfaWithBase(pat, End, 0).map { t => Start(t[0], t[1] + 1) }

}

/*

// ld.exe Error
extend NfaNode {
    public func fromRegexString(s: String): Result<NfaNode, String> {
        match (Some(s).okOr("").andThen(Token.fromString).andThen(RegexPattern.fromTokens)) {
            case Ok(pat) => match(generateRegexNfaFunc(pat)) {
                case Some(nfa) => Ok(nfa)
                case None => Err("regex parse success, generate Nfa failed")
            }
            case Err(e) => Err(e)
        }
    }
}

extend NfaNode {
    public static func fromRegexPattern(pat: RegexPattern): Result<NfaNode, String> {
        match (generateRegexNfaFunc(pat)) {
            case Some(nfa) => Ok(nfa)
            case None => Err("regex parse success, generate Nfa failed")
        }
    }
}

public func evalNfa(input: String): Result<Unit, String> {
    Token.fromString(input).andThen(RegexPattern.fromTokens).andThen(NfaNode.fromRegexPattern).map { x => println(x.stringifyNfa()) }
    Ok(())
}
*/