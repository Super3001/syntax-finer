
package simple_finer.regex

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
            case None => Err("Invalid Input!")
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