package simple_finer

import simple_finer.ext.*

/*
operators: | *?+ ::=
literal:
regex:
name:
import
importPath

*/

enum Token {
    | Name(String)
    | Literal(String)
    | Regex(String)
    | DefSymbol
    | Blank
    | Pipe
    | Star
    | QMark
    | Plus
    | Modifier(String)
    | Import
    | ImportPath(String)
    | Newline
}

extend Token {
    static func fromRunes(runes: List<Rune>): Result<List<Token>, String> {
        match (tokensFunc(runes).map {t => t[0]}) {
            case Some(l) => Ok(l)
            case None => Err("Invalid Input!")
        }
    }
}

extend Token <: ToString {
    public func toString() {
        "Token{" + match (this) {
            case Name(s) => "Name(" + s + ")"
            case DefSymbol => "DefSymbol"
            case Literal(s) => "Literal(" + s + ")"
            case Regex(s) => "Regex(" + s + ")"
            case Blank => "Blank"
            case Pipe => "Pipe"
            case Star => "Star"
            case QMark => "QMark"
            case Plus => "Plus"
            case Modifier(s) => "Modifier(" + s + ")"
            case Import => "Import"
            case ImportPath(s) => "ImportPath(" + s + ")"
            case Newline => "Newline"
        } + "}"
    }
}

let runeIsNotAlnum = {
    ch: Rune => match {
        case ch.isAsciiNumberOrLetter() => false
        case ch == r'_' => false
        case _ => true
    }
}

let runeIsAlnum = {
    ch: Rune => match {
        case ch.isAsciiNumberOrLetter() => true
        case ch == r'_' => true
        case _ => false
    }
}

let runeIsNewline = {
    ch: Rune => match (ch) {
        case r'\r' => true
        case r'\n' => true
        case _ => false
    }
}

let newline = Combinator<Rune, Rune>.make(
    runeIsNewline
).map {
    _: Rune => // println("parsed newline"); Newline
}

let alnum = Combinator<Rune, Rune>.make(
    runeIsAlnum
)

let name = alnum.many(1).map {
    l => Name(l.join(''))
}

let lbracket = Combinator<Rune, Rune>.make {
    ch => ch == r'['
}

let rbracket = Combinator<Rune, Rune>.make {
    ch => ch == r']'
}

let modifier = lbracket.and(alnum.many(1)).and(rbracket).map {
    x => Modifier(x[0][1].join(''))
}

let defSymbol = Combinator<Rune, Token> {
    input => match(input) {
        case l where l.startsWith(List<Rune>.fromArray(" ::= ".toRuneArray())) =>
            Some((DefSymbol, l.skip(5)))
        case _ => None
    }
}

let pipe = Combinator<Rune, Token> {
    input => match(input) {
        case l where l.startsWith(List<Rune>.fromArray(" | ".toRuneArray())) =>
            Some((Pipe, l.skip(3)))
        case _ => None
    }
}

let singleSymbol = Combinator<Rune, Rune>.make {
    ch => match (ch) {
        case r'*' | r'+' | r'?' | r' ' => true
        case _ => false
    }
}.map {
    ch: Rune => match (ch) {
        case '*' => Star
        case '+' => Plus
        case '?' => QMark
        case ' ' => Blank
        case _ => throw Exception()
    }
}

let singleQuote = Combinator<Rune, Rune>.make {
    ch => ch == r'\''
}

let escapedQuote = Combinator<Rune, Rune> {
    input => match(input) {
        case l where l.startsWith(List.fromArray("\\'".toRuneArray())) =>
            Some((r'\'', l.skip(2)))
        case _ => Option<(Rune, List<Rune>)>.None
    }
}

let charInLiteral = Combinator<Rune, Rune>.make {
    ch => match(ch) {
        case ch where runeIsNewline(ch) => false
        case r'\'' => false
        case _ => true
    }
}

let slash = Combinator<Rune, Rune>.make {
    ch => ch == r'/'
}

let escapedSlash = Combinator<Rune, Rune> {
    input => match(input) {
        case l where l.startsWith(List.fromArray("\\/".toRuneArray())) =>
            Some((r'/', l.skip(2)))
        case _ => Option<(Rune, List<Rune>)>.None
    }
}

let charInRegex = Combinator<Rune, Rune>.make {
    ch => match(ch) {
        case ch where runeIsNewline(ch) => false
        case r'/' => false
        case _ => true
    }
}
let literal = singleQuote.and(escapedQuote.or(charInLiteral).many(1)).and(singleQuote).map {
    x => Literal(x[0][1].join(''))
}

let regex = slash.and(escapedSlash.or(charInRegex).many(1)).and(slash).map {
    x => Regex(x[0][1].join(''))
}

let syntaxDef = name.and(modifier.opt()).and(defSymbol).and(
    literal.or(regex).or(pipe).or(singleSymbol).or(name).many(1)
).and(newline.many(1)).map {
    input => match(input) {
        case ((((name, None), defSymbol), values), _) => 
            // println("parsed SyntaxDef: ${name} without modifier")
            Cons(name, Cons(defSymbol, Nil)).concat(values)
        case ((((name, Some(modifier)), defSymbol), values), _) => 
            // println("parsed SyntaxDef: ${name} with modifier: ${modifier}")
            Cons(name, Cons(modifier, Cons(defSymbol, Nil))).concat(values)
        // case _ => throw Exception()
    }
}

let keywordImport = Combinator<Rune, Token> {
    input => match(input) {
        case l where l.startsWith(List.fromArray("import".toRuneArray())) =>
            Some((Import, l.skip(6)))
        case _ => Option<(Token, List<Rune>)>.None
    }
}

let blank = Combinator<Rune, Rune>.make {
    ch => ch == r' '
}.map {
    _: Rune => Blank
}

let importPath = Combinator<Rune, Token> {
    input => match(input.splitOnce(runeIsNewline)) {
        case Some((path, rest)) where path.lenth() > 0 =>
            Some((ImportPath(path.join('')), rest))
        case _ => None
    }
}

let syntaxImport = keywordImport.and(blank).and(importPath).and(newline.many(1)).map {
    input => match(input) {
        case (((kw, blank), path), _) =>
            Cons(kw, Cons(blank, Cons(path, Nil)))
        // case _ => throw Exception()
    }
}

let tokens = syntaxImport.many(0).and(newline.many(0)).and(syntaxDef.many(1)).map {
    x => x[0][0].flatten().concat(x[1].flatten())
}

func tokensFunc(input: List<Rune>): Option<(List<Token>, List<Rune>)> {
    tokens.parseFunc(input)
}

public func evalToken(str: String): Result<Unit, String> {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).map {l => l.reduce({_, tk => println(tk)}, ())}
    // Ok(())
}


enum SyntaxPattern {
    | SimplePattern(String)
    | RegexPattern(String)
    | NamePattern(String)
    | ConcatPattern(List<SyntaxPattern>)
    | OrPattern(List<SyntaxPattern>)
    | StarPattern(SyntaxPattern)
    | OptPattern(SyntaxPattern)
    | PlusPattern(SyntaxPattern)
}

extend SyntaxPattern <: ToString {
    public func toString(): String {
        match (this) {
            case SimplePattern(s) => "SimplePattern{${s}}"
            case RegexPattern(s) => "RegexPattern{${s}}"
            case NamePattern(s) => "NamePattern{${s}}"
            case ConcatPattern(l) => "ConcatPattern{${l.join(', ')}}"
            case OrPattern(l) => "OrPattern{${l.join(', ')}}"
            case StarPattern(p) => "StarPattern{${p}}"
            case OptPattern(p) => "OptPattern{${p}}"
            case PlusPattern(p) => "PlusPattern{${p}}"
        }
    }
}

enum SyntaxExpr {
    | SyntaxDefExpr(String, Option<String>, SyntaxPattern)
    | ImportExpr(String)
}

extend SyntaxExpr {
    static func fromTokens(tokens: List<Token>): Result<List<SyntaxExpr>, String> {
        match (expressionFunc(tokens).map {t => t[0]}) {
            case Some(e) => Ok(e)
            case None => Err("Invalid Expression!")
        }
    }

    static func resolveLinks(expr: List<SyntaxExpr>): Result<List<SyntaxExpr>, String> {
        Ok(expr.filter {
            x => match(x) {
                case SyntaxDefExpr(_, _, _) => true
                case _ => false
            }
        })
    }
}

extend SyntaxExpr <: ToString {
    public func toString() {
        match(this) {
            case SyntaxDefExpr(name, Some(modifier), pat) => "[${modifier}] `${name}` -> ${pat}"
            case SyntaxDefExpr(name, None, pat) => "`${name}` -> ${pat}"
            case ImportExpr(s) => "(import) ${s}"
        }
    }
}

let importExpr = Combinator<Token, SyntaxExpr> {
    input => match(input) {
        case Cons(Import, Cons(ImportPath(path), tail)) =>
            Some((ImportExpr(path), tail)) 
        case _ => None
    }
}

let simplePattern = Combinator<Token, SyntaxPattern> {
    input => match(input) {
        case Cons(Literal(s), tail) =>
            Some((SimplePattern(s), tail)) 
        case _ => None
    }
}

let regexPattern = Combinator<Token, SyntaxPattern> {
    input => match(input) {
        case Cons(Regex(s), tail) =>
            Some((RegexPattern(s), tail)) 
        case _ => None
    }
}

let namePattern = Combinator<Token, SyntaxPattern> {
    input => match(input) {
        case Cons(Name(s), tail) =>
            Some((NamePattern(s), tail)) 
        case _ => None
    }
}

let atomicPattern = simplePattern.or(regexPattern).or(namePattern)

let unaryPattern = Combinator<Token, SyntaxPattern> {
    input => match(atomicPattern.parseFunc(input)) {
        case Some((atomic, rest)) => match(rest) {
            case Cons(Star, tail) => Some((StarPattern(atomic), tail))
            case Cons(QMark, tail) => Some((OptPattern(atomic), tail))
            case Cons(Plus, tail) => Some((PlusPattern(atomic), tail))
            case _ => Some((atomic, rest))
        }
        case None => None
    }
}

let blankToken = Combinator<Token, Token>.make {
    token => match (token) {
        case Blank => true
        case _ => false
    }
}

let concatPattern = unaryPattern.and(blankToken).map {
    x => x[0]  
}.many(0).and(unaryPattern).map {
    input => match(input) {
        case (Nil, pat) => pat
        case (l, pat) => ConcatPattern(l.append(pat))
    }
}

let pipeToken = Combinator<Token, Token>.make {
    token => match (token) {
        case Pipe => true
        case _ => false
    }
}

let orPattern = concatPattern.and(pipeToken).map {
    x => x[0]
}.many(0).and(concatPattern).map {
    input: (List<SyntaxPattern>, SyntaxPattern) => match(input) {
        case (Nil, pat) => pat
        case (l, pat) => OrPattern(l.add(pat))
    }
}

let nameToken = Combinator<Token, Token>.make {
    token => match (token) {
        case Name(_) => true
        case _ => false
    }
}

let modifierToken = Combinator<Token, Token>.make {
    token => match (token) {
        case Modifier(_) => true
        case _ => false
    }
}


let defSymbolToken = Combinator<Token, Token>.make {
    token => match (token) {
        case DefSymbol => true
        case _ => false
    }
}

let syntaxDefExpr = nameToken.and(modifierToken.opt()).and(defSymbolToken).map {
    x => x[0]
}.and(orPattern).map {
    x: ((Token, Option<Token>), SyntaxPattern) => match(x) {
        case ((Name(s), Some(Modifier(m))), p) => SyntaxDefExpr(s, Some(m), p)
        case ((Name(s), None), p) => SyntaxDefExpr(s, None, p)
        case _ => throw Exception()
    }
}

let expressions = importExpr.many(0).and(syntaxDefExpr.many(1)).map {
    x => x[0].concat(x[1])
}

func expressionFunc(input: List<Token>): Option<(List<SyntaxExpr>, List<Token>)> {
    expressions.parseFunc(input)
}

public func evalExpression(str: String): Result<Unit, String> {
    let runes = List<Rune>.fromArray(str.toRuneArray())
    Token.fromRunes(runes).andThen(SyntaxExpr.fromTokens).map {l => println(l.join('\n'))}
}
