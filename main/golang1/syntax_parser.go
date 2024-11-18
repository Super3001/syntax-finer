/*
	patterns syntax order:
	0. Brackets
	1. OrPattern
	2. SequencePattern
	3. TrailingPattern
	4. AtomicPattern
*/

package main

import (
	"fmt"
	"os"
	"strings"
)

type HeaderKind int

const (
	DotHeaderKind HeaderKind = iota
	BracketHeaderKind
)

func (hk HeaderKind) String() string {
	return [2]string{
		"DotHeader",
		"BracketHeader",
	}[hk]
}

type HeaderT struct {
	kind  HeaderKind
	key   string
	value string
}

func (ht HeaderT) String() string {
	return fmt.Sprintf("(%v) %s '%s", ht.kind, ht.key, ht.value)
}

func DotHeader(key string, value string) HeaderT {
	return HeaderT{kind: DotHeaderKind, key: key, value: value}
}

func BracketHeader(key string, value string) HeaderT {
	return HeaderT{kind: BracketHeaderKind, key: key, value: value}
}

type SyntaxParserMode int

const (
	ModeAll SyntaxParserMode = iota
	ModeIter
)

func (spm SyntaxParserMode) String() string {
	return [2]string{
		"ModeAll",
		"ModeIter",
	}[spm]
}

type SyntaxParser struct {
	mode    SyntaxParserMode
	lexer   *SyntaxLexer
	tokens  []PositionedToken
	idx     int
	idTable map[string]*Pattern
	sTable  map[string]string
	ids     []string
	headers []HeaderT
}

func (p *SyntaxParser) BaseParsingError(posStr string, expected string, found string, scope string) {
	fmt.Printf("Parsing error at %s: expected %s, found %s in scope %s\n", posStr, expected, found, scope)
}

func (p *SyntaxParser) ParsingError(expected string, scope string) {
	p.BaseParsingError(p.peek().PosStr(), expected, p.peek().Kind().String(), scope)
}

func (p *SyntaxParser) UnExpectedEOFError(expected string, scope string) {
	p.BaseParsingError(p.peek().PosStr(), expected, "None", scope)
}

func (p *SyntaxParser) IllegalStateError(funcName string) {
	fmt.Printf("Illegal token kind is %s in function %s\n", p.peek().Kind(), funcName)
}

func (p *SyntaxParser) SetMode(mode SyntaxParserMode) {
	p.mode = mode
}

func (p *SyntaxParser) SetSourceFile(filepath string, mode SyntaxParserMode) {
	lexer := GetSyntaxLexer(filepath)
	p.SetMode(mode)
	p.SetSource(lexer)
}

func (p *SyntaxParser) SetSource(lexer *SyntaxLexer) {
	if p.mode == ModeAll {
		p.tokens = lexer.Lex()
	} else if p.mode == ModeIter {
		p.lexer = lexer
	}
	p.idx = 0
}

func (p *SyntaxParser) peek() PositionedToken {
	if p.idx < len(p.tokens) {
		return p.tokens[p.idx]
	}
	return p.eofToken()
}

func (p *SyntaxParser) consume(kind TokenKind) PositionedToken {
	token := p.peek()
	if token.Kind() == kind {
		p.idx++
		return token
	} else {
		p.ParsingError(kind.String(), "consume")
		return p.eofToken()
	}
}

func (p *SyntaxParser) eofToken() PositionedToken {
	return PositionedToken{Token{EOF, ""}, Position{-1, -1}}
}

func (p *SyntaxParser) PrependOrPattern(first *Pattern, other *Pattern) *Pattern {
	subPatterns := make([]*Pattern, len(other.Subs())+1)
	subPatterns[0] = first
	for i, sub := range other.Subs() {
		subPatterns[i+1] = sub
	}
	return CompositePattern(OrPattern, subPatterns, first.Pos())
}

func (p *SyntaxParser) PrependSequencePattern(first *Pattern, other *Pattern) *Pattern {
	subPatterns := make([]*Pattern, len(other.Subs())+1)
	subPatterns[0] = first
	for i, sub := range other.Subs() {
		subPatterns[i+1] = sub
	}
	return CompositePattern(SequencePattern, subPatterns, first.Pos())
}

func (p *SyntaxParser) Parse() {
	p.parseFile()
}

func (p *SyntaxParser) parseFile() {
	p.parseMetaData()
	p.parseBody()
	p.consume(EOF)
}

func (p *SyntaxParser) parseMetaData() {
	if p.peek().Kind() == BracketLine {
		p.parseBracketLine()
	} else if p.peek().Kind() == DotLine {
		p.parseDotLine()
	} else {
		return
	}
	p.parseMetaData()
}

func (p *SyntaxParser) parseBracketLine() {
	lineToken := p.consume(BracketLine)
	kvPair := strings.SplitN(lineToken.Value(), " ", 2)
	p.headers = append(p.headers, BracketHeader(kvPair[0], kvPair[1]))
}

func (p *SyntaxParser) parseDotLine() {
	lineToken := p.consume(DotLine)
	kvPair := strings.SplitN(lineToken.Value(), " ", 2)
	p.headers = append(p.headers, DotHeader(kvPair[0], kvPair[1]))
}

func (p *SyntaxParser) parseBody() {
	if p.peek().Kind() == Newline {
		p.parseLine()
		p.parseBody()
	} else {
		return
	}
}

func (p *SyntaxParser) parseLine() {
	// consume Newline
	p.consume(Newline)
	// identifier
	ident := p.consume(Identifier)
	identTypeStr := ""
	if p.peek().Kind() == IdentType {
		identTypeStr = p.consume(IdentType).rawString
	}
	p.consume(Assignment)
	ast := p.parseRightValue()
	p.idTable[ident.Value()] = ast
	p.sTable[ident.Value()] = identTypeStr
	p.ids = append(p.ids, ident.Value())
}

func (p *SyntaxParser) parseRightValue() *Pattern {
	switch p.peek().Kind() {
	case Or:
		p.consume(Or)
		return p.parseRightValue()
	case Literal, LeftParen, RegExp, Identifier:
		first := p.parseOrItem()
		other := p.parseRightValue()
		if other == nil {
			return first
		}
		switch other.kind {
		case OrPattern:
			return p.PrependOrPattern(first, other)
		default:
			return CompositePattern(OrPattern, []*Pattern{first, other}, first.Pos())
		}
	case Newline, EOF:
		return nil
	default:
		p.ParsingError("[Or, Literal, LeftParen, RegExp, Identifier, Newline, EOF]", "RightValue")
		return nil
	}
}

func (p *SyntaxParser) parseOrItem() *Pattern {
	switch p.peek().Kind() {
	case Space:
		p.consume(Space)
		return p.parseOrItem()
	case Literal, LeftParen, RegExp, Identifier:
		first := p.parseSeqItem()
		other := p.parseOrItem()
		if other == nil {
			return first
		}
		switch other.kind {
		case SequencePattern:
			return p.PrependSequencePattern(first, other)
		default:
			return CompositePattern(SequencePattern, []*Pattern{first, other}, first.pos)
		}
	case Or, Newline, EOF:
		return nil
	default:
		p.ParsingError("[Space, Or, Literal, LeftParen, RegExp, Identifier, Newline, EOF]", "OrItem")
		return nil
	}
}

func (p *SyntaxParser) parseSeqItem() *Pattern {
	switch p.peek().Kind() {
	case Literal:
		token := p.consume(Literal)
		return AtomicPattern(SimplePattern, token.Value(), token.Pos())
	case RegExp:
		token := p.consume(RegExp)
		return AtomicPattern(RegexpPattern, token.Value(), token.Pos())
	case Identifier:
		return p.parseTrailingItem()
	case LeftParen:
		return p.parseParenthesesItem()
	default:
		p.ParsingError("[Literal, RegExp, LeftParen, Identifier]", "SeqItem")
		return nil
	}
}

func (p *SyntaxParser) parseTrailingItem() *Pattern {
	token := p.consume(Identifier)
	switch p.peek().Kind() {
	case Star:
		star := p.consume(Star)
		return TrailingPattern(StarPattern, AtomicPattern(NamePattern, token.Value(), token.Pos()), star.Pos())
	case Question:
		question := p.consume(Question)
		return TrailingPattern(OptPattern, AtomicPattern(NamePattern, token.Value(), token.Pos()), question.Pos())
	case Plus:
		plus := p.consume(Plus)
		return TrailingPattern(PlusPattern, AtomicPattern(NamePattern, token.Value(), token.Pos()), plus.Pos())
	default:
		return AtomicPattern(NamePattern, token.Value(), token.Pos())
	}
}

func (p *SyntaxParser) parseParenthesesItem() *Pattern {
	p.consume(LeftParen)
	ast := p.parseRightValue()
	p.consume(RightParen)
	return ast
}

func (p *SyntaxParser) Display() {
	fmt.Println("headers:")
	if p.headers != nil {
		fmt.Println("(None)")
	} else {
		for _, header := range p.headers {
			fmt.Println(header)
		}
	}

	for id, pattern := range p.idTable {
		if p.sTable[id] != "" {
			fmt.Printf("%s(%s): %v\n", id, p.sTable[id], pattern)
		} else {
			fmt.Printf("%s: %v\n", id, pattern)
		}
	}
}

func NeoSyntaxParser() *SyntaxParser {
	return &SyntaxParser{
		mode:    ModeAll,
		idTable: make(map[string]*Pattern),
		sTable:  make(map[string]string),
		headers: make([]HeaderT, 0),
	}
}

func GetSyntaxParser(filepath string, mode SyntaxParserMode) *SyntaxParser {
	parser := NeoSyntaxParser()
	parser.SetSourceFile(filepath, mode)
	return parser
}

func GetDefaultSyntaxParser(filepath string) *SyntaxParser {
	return GetSyntaxParser(filepath, ModeAll)
}

func (p *SyntaxParser) ParseToJson() string {
	p.Parse()
	builder := GetDefaultJsonBuilder()
	builder.BuildSyntaxParserResult(p)
	return builder.ToJson()
}

func (p *SyntaxParser) ParseToFile(filepath string) {
	jsonString := p.ParseToJson()
	err := os.WriteFile(filepath, []byte(jsonString), 0644)
	if err != nil {
		panic(err)
	}
}

func TestSyntaxParser() {
	parser := GetDefaultSyntaxParser("E:/BaiduSyncDisk/modeling/syntax/demo/base.syntax")
	parser.Parse()
	parser.Display()
}

func TestSyntaxParserToFile() {
	parser := GetDefaultSyntaxParser("E:/BaiduSyncDisk/modeling/syntax/demo/syntaxDef.syntax")
	parser.ParseToFile("output/parse_output.json")
}
