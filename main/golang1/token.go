/*
	tokens:
	- Identifier
	- Literal
	- RegExp
	- ::=
	- |
	- (
	- )
	- *
	- ?
	- +
	- [:space:]
	- [:newline:]

	header tokens:
	- .DotLine
	- [BracketLine]
*/

package main

import (
	"fmt"
)

type TokenKind int

// enum
const (
	IdentType TokenKind = iota
	Identifier
	Literal
	RegExp
	Assignment
	Or
	LeftParen
	RightParen
	Star
	Question
	Plus
	Space
	Newline
	DotLine
	BracketLine
	EOF
)

func (tk TokenKind) String() string {
	return [...]string{
		"IdentType",
		"Identifier",
		"Literal",
		"RegExp",
		"Assignment",
		"Or",
		"LeftParen",
		"RightParen",
		"Star",
		"Question",
		"Plus",
		"Space",
		"Newline",
		"DotLine",
		"BracketLine",
		"EOF",
	}[tk]
}

type Token struct {
	tokenKind TokenKind
	rawString string
}

type PositionedToken struct {
	Token
	pos Position
}

func (t Token) String() string {
	return fmt.Sprintf("Token(%s, %s)", t.tokenKind, t.rawString)
}

func (t Token) DigitString() string {
	return fmt.Sprintf("Token(%d, %s)", t.tokenKind, t.rawString)
}

func (t Token) Value() string {
	return t.rawString
}

func (t Token) Kind() TokenKind {
	return t.tokenKind
}

func (t PositionedToken) String() string {
	return fmt.Sprintf("%sToken(%s, %s)", t.pos, t.tokenKind, t.rawString)
}

func (t PositionedToken) DigitString() string {
	return fmt.Sprintf("%sToken(%d, %s)", t.pos, t.tokenKind, t.rawString)
}

func (t PositionedToken) PosStr() string {
	return t.pos.String()
}

func (t PositionedToken) Value() string {
	return t.Token.Value()
}

func (t PositionedToken) Kind() TokenKind {
	return t.Token.Kind()
}

func (t PositionedToken) Pos() Position {
	return t.pos
}