package simple_finer.nfa

import simple_finer.ext.*
import std.regex

protected extend NfaEntry {
    protected func runOn(l: List<Rune>) {
        
        func run(node: NfaNode, rest: List<Rune>): Option<List<MatchResult>> {
            match (node) {
                case Start(nxt, _) => run(nxt, rest)
                case End => 
                    if (!rest.empty()) {
                        return None
                    }
                    Some(List<MatchResult>.Nil)
                case Single(nxt, ch, _) =>
                    match (rest) {
                        case Cons(ch, tail) => run(nxt, tail).add(Char(ch))
                        case _ => None
                    }
                case All(nxt, _) =>
                    match (rest) {
                        case Cons(any, tail) => run(nxt, tail).add(Char(any))
                        case _ => None
                    }
                case Sequence(nxt, s, _) =>
                    if (rest.startsWith(s)) {
                        run(nxt, rest.skip(s.length)).add(Chars(s))
                    }
                    None
                case Set(nxt, rec, _) => 
                    match (rest) {
                        case Cons(head, tail) where rec.contains(head) => run(nxt, tail).add(Char(head))
                        case _ => None
                    }
                case InvSet(nxt, rec, _) =>
                    match (rest) {
                        case Cons(head, tail) where !rec.contains(head) => 
                        case _ => None
                    }
                case Regex(nxt, s, _) => 
                    // control string length
                    let str = rest.join('', maxItem: 1024)
                    let r = regex.Regex(s)
                    match (r.matcher(str).matchStart()) {
                        case Some(matchData) =>
                            matched = matchData.matchStr()
                            run(nxt, rest.skip(matched.length)).add(Chars(matched))
                        case None => None
                    }
                case Tracker(nxt, name, mod, _) => 
                    match (mod) {
                        case File => 
                    }
            }
        }
    }
} 