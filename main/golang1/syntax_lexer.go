package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

type SyntaxLexerState int

const (
	HeaderState SyntaxLexerState = iota
	LineState
	LeftIdentState
	IdentTypeState
	AssignmentState
	RightValueState
	ValueState
	LiteralState
	RegExpState
)

type SyntaxLexer struct {
	inputFile string
	rawString string
	idx       int
	state     SyntaxLexerState
	Position
}

func (s *SyntaxLexer) PosStr() string {
	return fmt.Sprintf("(%d, %d)", s.line, s.col)
}

func (s *SyntaxLexer) Pos() Position {
	return Position{s.line, s.col}
}

func (s *SyntaxLexer) NextChar() byte {
	if s.idx >= len(s.rawString) {
		return '\000'
	}
	char := s.rawString[s.idx]
	s.idx++
	if char == '\n' {
		s.line++
		s.col = 0
	} else {
		s.col++
	}
	return char
}

func (s *SyntaxLexer) PeekChar() byte {
	if s.idx >= len(s.rawString) {
		return '\000'
	}
	return s.rawString[s.idx]
}

func (s *SyntaxLexer) UnreadChar() {
	if s.idx == 0 {
		return
	}
	s.idx--
	if s.PeekChar() == '\n' {
		s.line--
		s.col = -1
	}
	s.col--
}

func (s *SyntaxLexer) readFile(path string) {
	s.inputFile = path
	content, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	// dos2unix
	s.rawString = strings.ReplaceAll(string(content), "\r\n", "\n")
}

func (s *SyntaxLexer) IsSpace(c byte) bool {
	return c == ' ' || c == '\t' || c == '\r' || c == '\n'
}

func (s *SyntaxLexer) IsAlNumUnder(c byte) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'
}

func (s *SyntaxLexer) isReturn(c byte) bool {
	return c == '\n' || c == '\r'
}

func (s *SyntaxLexer) LexicalError(posStr string, expected string) {
	fmt.Printf("Lexical error at %s: expected %s\n", posStr, expected)
}

func (s *SyntaxLexer) UnClosedError(posStr string, expected string) {
	fmt.Printf("Lexical error at %s: unclosed %s\n", posStr, expected)
}

func (s *SyntaxLexer) UnExpectedEOFError(posStr string, scope string) {
	fmt.Printf("Lexical error at %s: unexpected EOF in scope %s\n", posStr, scope)
}

func (s *SyntaxLexer) UnExpectedWhiteSpaceError(posStr string, scope string) {
	fmt.Printf("Lexical error at %s: unexpected whitespace in scope %s\n", posStr, scope)
}

func (s *SyntaxLexer) NextToken() (Token, error) {
	if s.state == HeaderState {
		if s.PeekChar() == '.' {
			s.Forward(1)
			content := ""
			for s.PeekChar() != '\n' {
				if s.PeekChar() == '\000' {
					s.UnExpectedEOFError(s.PosStr(), "header")
				}
				content += string(s.NextChar())
			}
			s.NextChar()
			return Token{tokenKind: DotLine, rawString: content}, nil
		}
		if s.PeekChar() == '[' {
			s.Forward(1)
			content := ""
			for s.PeekChar() != ']' {
				if s.PeekChar() == '\000' {
					s.UnExpectedEOFError(s.PosStr(), "header")
				}
				if s.isReturn(s.PeekChar()) {
					s.UnClosedError(s.PosStr(), "{BracketLine} \"[\"")
				}
				content += string(s.NextChar())
			}
			s.NextChar()
			for s.PeekChar() != '\n' && s.PeekChar() != '\000' {
				s.NextChar()
			}
			s.NextChar()
			return Token{tokenKind: BracketLine, rawString: content}, nil
		} else {
			s.state = LineState
			return s.NextToken()
		}
	} else if s.state == LineState {
		for s.IsSpace(s.PeekChar()) {
			s.Forward(1)
		}
		if s.PeekChar() == '\000' {
			return Token{tokenKind: EOF, rawString: ""}, nil
		}
		if s.IsAlNumUnder(s.PeekChar()) {
			s.state = LeftIdentState
			return Token{tokenKind: Newline, rawString: ""}, nil
		} else {
			s.LexicalError(s.PosStr(), "{Identifier} alphanumeric character or \"_\"")
		}
	} else if s.state == LeftIdentState {
		content := ""
		for s.IsAlNumUnder(s.PeekChar()) {
			content += string(s.NextChar())
		}
		s.state = IdentTypeState
		return Token{tokenKind: Identifier, rawString: content}, nil
	} else if s.state == IdentTypeState {
		if s.PeekChar() != '[' {
			s.state = AssignmentState
			return s.NextToken()
		} else {
			s.Forward(1)
			content := ""
			for s.IsAlNumUnder(s.PeekChar()) {
				content += string(s.NextChar())
			}
			if s.PeekChar() != ']' {
				s.UnClosedError(s.PosStr(), "{IdentType} \"[\"")
			}
			s.Forward(1)
			s.state = AssignmentState
			return Token{tokenKind: IdentType, rawString: content}, nil
		}
	} else if s.state == AssignmentState {
		if s.PeekString(" ::= ") {
			s.state = RightValueState
			return Token{tokenKind: Assignment, rawString: ""}, nil
		} else {
			s.LexicalError(s.PosStr(), "{Assignment} \" ::= \"")
		}
	} else if s.state == RightValueState {
		now := s.PeekChar()
		if s.IsAlNumUnder(now) || now == '\'' || now == '/' || now == '(' {
			s.state = ValueState
			return s.NextToken()
		} else {
			s.LexicalError(s.PosStr(), "{RightValue} alphanumeric character or \"_\" or \"'\" or \"/\" or \"(\"")
		}
	} else if s.state == ValueState {
		if s.PeekChar() == '\'' {
			s.Forward(1)
			s.state = LiteralState
			return s.NextToken()
		} else if s.PeekChar() == '/' {
			s.Forward(1)
			s.state = RegExpState
			return s.NextToken()
		} else if s.PeekChar() == '(' {
			s.Forward(1)
			return Token{tokenKind: LeftParen, rawString: ""}, nil
		} else if s.PeekChar() == ')' {
			s.Forward(1)
			return Token{tokenKind: RightParen, rawString: ""}, nil
		} else if s.PeekChar() == '*' {
			s.Forward(1)
			return Token{tokenKind: Star, rawString: ""}, nil
		} else if s.PeekChar() == '?' {
			s.Forward(1)
			return Token{tokenKind: Question, rawString: ""}, nil
		} else if s.PeekChar() == '+' {
			s.Forward(1)
			return Token{tokenKind: Plus, rawString: ""}, nil
		} else if s.PeekString(" | ") {
			return Token{tokenKind: Or, rawString: ""}, nil
		} else if s.PeekChar() == ' ' {
			s.Forward(1)
			return Token{tokenKind: Space, rawString: ""}, nil
		} else if s.isReturn(s.PeekChar()) {
			s.Forward(1)
			s.state = LineState
			return s.NextToken()
		} else if s.IsAlNumUnder(s.PeekChar()) {
			// Identifier
			content := ""
			for s.IsAlNumUnder(s.PeekChar()) {
				content += string(s.NextChar())
			}
			return Token{tokenKind: Identifier, rawString: content}, nil
		} else {
			s.LexicalError(s.PosStr(), "{Value} alphanumeric character or \"_\" or \"*\" or etc.")
		}
	} else if s.state == LiteralState {
		content := ""
		for s.PeekChar() != '\'' {
			if s.PeekChar() == '\\' {
				s.Forward(1)
				if s.PeekChar() == '\'' {
					content += string(s.NextChar())
				} else {
					content += "\\" + string(s.NextChar())
				}
			} else if s.isReturn(s.PeekChar()) {
				s.UnClosedError(s.PosStr(), "{Literal} \"'\"")
			} else if s.PeekChar() == '\000' {
				s.UnExpectedEOFError(s.PosStr(), "{Literal}")
			} else {
				content += string(s.NextChar())
			}
		}
		s.Forward(1)
		s.state = ValueState
		return Token{tokenKind: Literal, rawString: content}, nil
	} else if s.state == RegExpState {
		content := ""
		for s.PeekChar() != '/' {
			if s.PeekChar() == '\\' {
				s.Forward(1)
				if s.PeekChar() == '/' {
					content += string(s.NextChar())
				} else {
					content += "\\" + string(s.NextChar())
				}
			} else if s.isReturn(s.PeekChar()) {
				s.UnClosedError(s.PosStr(), "{RegExp} \"/\"")
			} else if s.PeekChar() == '\000' {
				s.UnExpectedEOFError(s.PosStr(), "{RegExp}")
			} else {
				content += string(s.NextChar())
			}
		}
		s.Forward(1)
		s.state = ValueState
		return Token{tokenKind: RegExp, rawString: content}, nil
	}
	return Token{tokenKind: EOF, rawString: ""}, errors.New("SyntaxLexer: unknown state at " + s.PosStr())
}

func (s *SyntaxLexer) NextTokenWithPos() (PositionedToken, error) {
	token, err := s.NextToken()
	if err != nil {
		return PositionedToken{}, err
	}
	return PositionedToken{token, Position{s.line, s.col}}, nil
}

func (s *SyntaxLexer) PeekString(str string) bool {
	originalPosition := s.idx
	for i := 0; i < len(str); i++ {
		if s.PeekChar() != str[i] {
			s.idx = originalPosition
			return false
		}
		s.Forward(1)
	}
	return true
}

func (s *SyntaxLexer) Forward(n int) {
	for i := 0; i < n; i++ {
		s.NextChar()
	}
}

func (s *SyntaxLexer) Backward(n int) {
	for i := 0; i < n; i++ {
		s.UnreadChar()
	}
}

func (s *SyntaxLexer) SkipLine() {
	for s.PeekChar() != '\n' && s.PeekChar() != '\000' {
		s.Forward(1)
	}
	s.Forward(1)
}

func (s *SyntaxLexer) SkipSpace() {
	for s.IsSpace(s.PeekChar()) {
		s.Forward(1)
	}
}

func NeoSyntaxLexer() *SyntaxLexer {
	return &SyntaxLexer{}
}

func GetSyntaxLexer(filepath string) *SyntaxLexer {
	lexer := NeoSyntaxLexer()
	lexer.readFile(filepath)
	return lexer
}

func (s *SyntaxLexer) Lex() []PositionedToken {
	if s.inputFile == "" {
		panic("SyntaxLexer: input file not set")
	}
	tokens := make([]PositionedToken, 0)
	for {
		token, err := s.NextTokenWithPos()
		if err != nil {
			panic(err)
		}
		tokens = append(tokens, token)
		if token.Kind() == EOF {
			break
		}
	}
	return tokens
}

func (s *SyntaxLexer) LexToJson() string {
	tokens := s.Lex()
	jsonString := "[\n"
	for _, token := range tokens {
		jsonString += "    \"" + strings.ReplaceAll(token.DigitString(), "\\", "\\\\") + "\",\n"
	}
	jsonString = jsonString[:len(jsonString)-2] + "\n]"
	return jsonString
}

func (s *SyntaxLexer) LexToFile(filename string) {
	jsonString := s.LexToJson()
	err := os.WriteFile(filename, []byte(jsonString), 0644)
	if err != nil {
		panic(err)
	}
}

// TestSyntaxLexer tests
func TestSyntaxLexer() {
	lexer := GetSyntaxLexer("E:/BaiduSyncDisk/modeling/syntax/demo/base.syntax")
	for {
		token, err := lexer.NextTokenWithPos()
		if err != nil {
			println(err.Error())
			break
		}
		if token.Kind() == EOF {
			fmt.Println("EOF")
			break
		}
		fmt.Println(token)
	}
}

func TestSyntaxLexerToFile() {
	lexer := GetSyntaxLexer("E:/BaiduSyncDisk/modeling/syntax/demo/base.syntax")
	lexer.LexToFile("output/lex_output.json")
}
