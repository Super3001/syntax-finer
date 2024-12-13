
package simple_finer.regex

import std.convert.*

import simple_finer.ext.*

enum Token {
    | Plain(Rune)
    | Escaped(Rune)
    | Dot
    | Star
    | QMark
    | Plus
    | LParen
    | RParen
    | LBracket
    | RBracket
    | Pipe
    | Caret
    | Dollar
    | Dash
    | Unknown
}

/*
enum Token {
    | Tk(Token, Int)

    public func kind() {
        match (this) {
            case Tk(kind, _) => kind
        }
    }

    public func pos() {
        match (this) {
            case Tk(_, position) => position
        }
    }
}
*/

extend Token {
    static func fromRunes(runes: List<Rune>): Result<List<Token>, String> {
        match (regexTokensFunc(runes).map {t => t[0]}) {
            case Some(l) => Ok(l)
            case None => Err("Regex parse failed!")
        }
    }

    static func fromString(str: String): Result<List<Token>, String> {
        let runes = List<Rune>.fromArray(str.toRuneArray())
        Token.fromRunes(runes)
    }
}

extend Token <: ToString {
    public func toString() {
        "Token{" + match (this) {
            case Plain(ch) => "Plain(${ch})"
            case Escaped(ch) => "Escaped(${ch})"
            case Dot => "Dot"
            case Star => "Star"
            case QMark => "QMark"
            case Plus => "Plus"
            case LParen => "LParen"
            case RParen => "RParen"
            case LBracket => "LBracket"
            case RBracket => "RBracket"
            case Pipe => "Pipe"
            case Caret => "Caret"
            case Dollar => "Dollar"
            case Dash => "Dash"
            case Unknown => "?"
        } + "}"
    }
}

/*
extend Token <: ToString {
    public func toString() {
        "Token{${this.kind()}, ${this.pos()}}"
    }
}
*/

let singleSymbol = Combinator<Rune, Rune>.make {
    ch => match (ch) {
        case r'.' | r'*' | r'?' | r'+' | r'(' | r')' | r'|' | r'^' | r'$' => true
        case _ => false
    }
}.map {
    ch: Rune => match (ch) {
        case '.' => Dot
        case '*' => Star
        case '?' => QMark
        case '+' => Plus
        case '(' => LParen
        case ')' => RParen
        case '|' => Pipe
        case '^' => Caret
        case '$' => Dollar
        case _ => throw Exception()
    }
}

let trailingEscaped = Combinator<Rune, Rune>.make {
    ch => match (ch) {
        case r'n' | r't' | r'r' | r'w' | r's' | r'd' | r'W' | r'S' | r'D' | r'a' => true
        case _ => false
    }
}.map {
    ch: Rune => match (ch) {
        case 'n' => Plain(r'\n')
        case 't' => Plain(r'\t')
        case 'r' => Plain(r'\r')
        case 'w' => Escaped(r'w')
        case 's' => Escaped(r's')
        case 'd' => Escaped(r'd')
        case 'W' => Escaped(r'W')
        case 'S' => Escaped(r'S')
        case 'D' => Escaped(r'D')
        case 'a' => Escaped(r'a')
        case ch  => Plain(ch)
    }
}

let backSlash = Combinator<Rune, Rune>.make {
    ch => ch == r'\\'
}

let escaped = backSlash.and(trailingEscaped).map {
    group => match (group) {
        case (_, tk) => tk
    }
}

let lbracket = Combinator<Rune, Rune>.make {
    ch => ch == r'['
}

let rbracket = Combinator<Rune, Rune>.make {
    ch => ch == r']'
}

let caret = Combinator<Rune, Rune>.make {
    ch => ch == r'$'
}

let charInChoiceSet = Combinator<Rune, Rune>.make {
    ch => match (ch) {
        case r']' => false
        case r'\\' => false
        case _ => true
    }
}.map {
    ch => Plain(ch)
}.or(escaped)

let choiceSet = lbracket.and(caret.opt()).and(charInChoiceSet.many(0)).and(rbracket).map {
    input => match (input) {
        // []
        case (((_, None), Nil), _) => throw Exception("deal_egex: Nothing in brackets is not acceptable")
        case (((_, None), l), _) => l.concat(Cons(RBracket, Nil)).add(LBracket)
        // [^]
        case (((_, Some(_)), Nil), _) => throw Exception("Only '^' in brackets is not acceptable")
        case (((_, Some(_)), l), _) => l.concat(Cons(RBracket, Nil)).add(Caret).add(LBracket)
    }
}

let charOutOfChoiceSet = Combinator<Rune, Rune>.make {
    ch => match (ch) {
        case r'[' => false
        case r'\\' => false
        case _ => true
    }
}.map {
    ch => Plain(ch)
}.or(escaped)

let tokensOutOfChoiceSet = singleSymbol.or(charOutOfChoiceSet).many(1)

let tokens = tokensOutOfChoiceSet.or(choiceSet).many(1).map {
    l => l.flatten()
}

func regexTokensFunc(input: List<Rune>): Option<(List<Token>, List<Rune>)> {
    tokens.parseFunc(input)
}

public func evalToken(str: String): Result<Unit, String> {
    Token.fromString(str).map {l => l.reduce({_, tk => println(tk)}, ())}
}

/*

extend Rune {
    func isAlnum(): Bool {
        this.isAsciiNumberOrLetter() || this == r'_'
    }

    func toInt(): Int {
        match {
            case this.isAscii() =>
                let arr = Array<Byte>(1, item: 0)
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
}

type Rec = BoolArrayRecord

class BoolArrayRecord {
    static let w = Rec.madeFrom { ch => ch.isAlnum() }
    static let d = Rec.madeFrom { ch => ch.isAsciiNumber() }
    static let s = Rec.madeFrom { ch => ch.isAsciiWhiteSpace() }
    static let W = Rec.madeFrom { ch => !ch.isAlnum() }
    static let S = Rec.madeFrom { ch => !ch.isAsciiWhiteSpace() }
    static let D = Rec.madeFrom { ch => !ch.isAsciiNumber() }

    let _dest: Array<Bool> = Array(128, item: false)

    public prop dest: Array<Bool> {
        get() {
            _dest
        }
    }

    public func runeContains(ch: Rune): Bool {
        match {
            case ch.isAscii() => this.dest[ch.toInt()]
            case _ => false
        }
    }

    static func madeFrom(cond: (Byte) -> Bool): Rec {
        let p = Rec()
        var b: Byte = 0
        for( i in 0..128 ) {
            if ( cond(b) ) {
                p._dest[i] = true
            }
            b += 1
        }
        p
    }

    func toRuneList() {
        var ls = List<Rune>.Nil
        ls
    }

    func repr(): String {
        match (this) {
            case Rec.w => "\\w"
            case Rec.s => "\\s"
            case Rec.d => "\\d"
            case Rec.W => "\\W"
            case Rec.S => "\\S"
            case Rec.D => "\\D"
            case _ => "TODO"
        }
    }
}

extend Rec <: ToString {
    public func toString(): String {
        "Rec{${this.toRuneList().join('')}}"
    }
}

*/

enum RegexPattern {
    | SimplePattern(Rune)
    | SetPattern(List<Token>)
    | DotPattern
    | PositionPattern(Bool)
    | ConcatPattern(List<RegexPattern>)
    | OrPattern(List<RegexPattern>)
    | StarPattern(RegexPattern)
    | OptPattern(RegexPattern)
    | PlusPattern(RegexPattern)
    | EmptyPattern
}

extend RegexPattern {
    static func fromTokens(tokens: List<Token>): Result<RegexPattern, String> {
        match (expressionFunc(tokens).map {t => t[0]}) {
            case Some(e) => Ok(e)
            case None => Err("Invalid Expression!")
        }
    }
}

extend RegexPattern <: ToString {
    public func toString(): String {
        match (this) {
            case SimplePattern(ch) => "SimplePattern{${ch}}"
            case SetPattern(l) => "SetPattern{${l.join(', ')}}"
            case DotPattern => "Any"
            case PositionPattern(flag) => "PositionPattern{${flag}}"
            case ConcatPattern(l) => "ConcatPattern{${l.join(', ')}}"
            case OrPattern(l) => "OrPattern{${l.join(', ')}}"
            case StarPattern(p) => "StarPattern{${p}}"
            case OptPattern(p) => "OptPattern{${p}}"
            case PlusPattern(p) => "PlusPattern{${p}}"
            case EmptyPattern => "Empty!"
        }
    }
}

let simplePattern = Combinator<Token, RegexPattern> {
    input => match(input) {
        case Cons(Plain(s), tail) =>
            Some((SimplePattern(s), tail))
        case Cons(Escaped(s), tail) => 
            Some((SetPattern(Cons(Escaped(s), Nil)), tail))
        case _ => None
    }
}

let lbracketToken = Combinator<Token, Token>.make {
    tk => match(tk) {
        case LBracket => true
        case _ => false
    }
}

let rbracketToken = Combinator<Token, Token>.make {
    tk => match(tk) {
        case RBracket => true
        case _ => false
    }
}

let tokenInChoiceSet = Combinator<Token, Token>.make {
    tk => match(tk) {
        case RBracket => false
        case LBracket => throw Exception("LBracket with no balanced RBracket")
        case _ => true
    }
}

let setPattern = lbracketToken.and(tokenInChoiceSet.many(0)).and(rbracketToken).map {
    t => SetPattern(t[0][1])
}

let dotPattern = Combinator<Token, Token>.make {
    tk => match (tk) {
        case Dot => true
        case _ => false
    }
}.map {
    _ => DotPattern
}

let positionPattern = Combinator<Token, RegexPattern> {
    input => match(input) {
        case Cons(Caret, tail) => 
            Some((PositionPattern(true), tail))
        case Cons(Dollar, tail) => 
            Some((PositionPattern(false), tail))
        case _ => Option<(RegexPattern, List<Token>)>.None
    }
}

let lparenToken = Combinator<Token, Token>.make {
    token => match (token) {
        case LParen => true
        case _ => false
    }
}
let rparenToken = Combinator<Token, Token>.make {
    token => match (token) {
        case RParen => true
        case _ => false
    }
}

func atomicFunc(input: List<Token>): Option<(RegexPattern, List<Token>)> {
    let expression = Combinator(expressionFunc)
    lparenToken.and(expression).and(rparenToken).map {t => t[0][1]}.or(simplePattern).or(setPattern).or(dotPattern).or(positionPattern).parseFunc(input)
}

func unaryFunc(input: List<Token>): Option<(RegexPattern, List<Token>)> {

    let atomic = Combinator(atomicFunc)
    match(atomic.parseFunc(input)) {
        case Some((atomic, rest)) => match(rest) {
            case Cons(Star, tail) => Some((StarPattern(atomic), tail))
            case Cons(QMark, tail) => Some((OptPattern(atomic), tail))
            case Cons(Plus, tail) => Some((PlusPattern(atomic), tail))
            case _ => Some((atomic, rest))
        }
        case None => None
    }
}

let pipe = Combinator<Token, Token>.make {
    token => match (token) {
        case Pipe => true
        case _ => false
    }
}

func expressionFunc(input: List<Token>): Option<(RegexPattern, List<Token>)> {
    let unary = Combinator(unaryFunc)
    let concat = unary.many(0).map {
        l => match(l) {
            case Nil => EmptyPattern
            case Cons(head, Nil) => head
            case _ => ConcatPattern(l)
        }
    }
    concat.and(pipe.and(concat).many(0)).map {
        t: (RegexPattern, List<(Token, RegexPattern)>) => match(t) {
            case (t1, Nil) => t1
            case _ => OrPattern(t[1].map{ v => v[1] }.add(t[0]))
        }
    }.parseFunc(input)
}

public func evalExpression(str: String): Result<Unit, String> {
    Token.fromString(str).map{l => println(l); l}.andThen(RegexPattern.fromTokens).map { e => println(e) }.mapErr { e => println(e); e }
}