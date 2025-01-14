package simple_finer.nfa

import simple_finer.context.Context
import simple_finer.ext.*
import std.regex

extend NfaEntry {
    protected func runOn(l: List<Rune>): MatchResult {

        var history = List<Rune>.Nil
        func past(ch: Rune, enable: Bool) {
            if (enable) {
                history.add(ch)
            }
        }
        func past(chars: List<Rune>, enable: Bool) {
            if (enable) {
                history = chars.concat(history)
            }
        }

        func run(node: NfaNode, rest: List<Rune>, record: Bool): MatchResult {
            println("${Context.printable(rest.head_or(r'\0'))} |> ${node}")
            match (node) {
                case Start(nxt, _) => run(nxt, rest, record).add(BOD(""))
                case End => 
                    if (!rest.isEmpty()) {
                        return None
                    }
                    Some(List<MatchItem>.empty().add(EOD))
                case Single(nxt, ch, _) =>
                    match (rest) {
                        case Cons(ch2, tail) where ch2 == ch => past(ch, record); run(nxt, tail, record).add(Char(ch))
                        case _ => None
                    }
                case All(nxt, _) =>
                    match (rest) {
                        case Cons(any, tail) => past(any, record); run(nxt, tail, record).add(Char(any))
                        case _ => None
                    }
                case Sequence(nxt, s, _) =>
                    match (rest.takeStr(s)) {
                        case Some((fst, snd)) =>
                            past(fst, record)
                            run(nxt, snd, record).add(Chars(s))
                        case None => None
                    }
                case Set(nxt, rec, _) => 
                    match (rest) {
                        case Cons(head, tail) where rec.contains(head) => past(head, record); run(nxt, tail, record).add(Char(head))
                        case _ => None
                    }
                case InvSet(nxt, rec, _) =>
                    match (rest) {
                        case Cons(head, tail) where !rec.contains(head) => past(head, record); run(nxt, tail, record)
                        case _ => None
                    }
                case Regex(nxt, s, _) => 
                    // control string length
                    let str = rest.join('', maxItem: 1024)
                    let r = regex.Regex(s)
                    match (r.matcher(str).matchStart()) {
                        case Some(matchData) =>
                            let matched = matchData.matchStr()
                            let pair = rest.take(matched.size)
                            past(pair[0], record)
                            run(nxt, pair[1], record).add(Chars(matched))
                        case None => None
                    }
                case Branch(fst, snd, _) => 
                    match (run(snd, rest, record)) {
                        case Some(res) => Some(res)
                        case None => run(fst, rest, record)
                    }
                case Merge(nxt) => run(nxt, rest, record)
                case Forward(near, far, id) => 
                    match (run(near, rest, record)) {
                        case Some(res) => Some(res)
                        case None => run(far, rest, record)
                    }
                case Backward(nxt, conn, id) => 
                    match (run(conn.dest, rest, record)) {
                        case Some(res) => Some(res)
                        case None => run(nxt, rest, record)
                    }
                case AssertAhead(nxt, anxt, _) =>
                    match (run(anxt, rest, false)) {
                        case Some(_) => run(nxt, rest, record)
                        case None => None
                    }
                case AssertBack(nxt, anxt, _) =>
                    match (run(anxt, history, false)) {
                        case Some(_) => run(nxt, rest, record)
                        case None => None
                    }
                case AssertEnd(_) => Some(List<MatchItem>.Nil)
                case EmptyNode => None
                case Tracker(nxt, name, mod, _) => 
                    match (mod) {
                        case File => run(nxt, rest, record).add(BOD("file"))
                        case F => run(nxt, rest, record).add(BOD(name))
                        case Dict => run(nxt, rest, record).add(BOD(name))
                        case List => run(nxt, rest, record).add(BOL(name))
                        case Str => run(nxt, rest, record).add(BOS(name))
                        case Undefined(s) => throw Exception("nfa runtime error: modifier undefined: ${s}")
                    }
                case TrackerEnd(nxt, mod, _) =>
                    match (mod) {
                        case File => run(nxt, rest, record).add(EOD)
                        case F => run(nxt, rest, record).add(EOD)
                        case Dict => run(nxt, rest, record).add(EOD)
                        case List => run(nxt, rest, record).add(EOL)
                        case Str => run(nxt, rest, record).add(EOS)
                        case Undefined(s) => throw Exception("nfa runtime error: modifier undefined: ${s}")
                    }
            }
        }

        run(getNfa(), l, true)
    }
} 