/*
	define the patterns of an .syntax file
	atomic: (3)
	=> simple pattern
	=> regexp pattern
	=> name pattern
	composite: (5)
	=> or pattern
	=> sequence pattern
	=> star pattern
	=> opt pattern
	=> plus pattern
*/

package main

import (
	_ "errors"
	"fmt"
	"strings"
)

// deal := "fmt.Errorf"

type PatternKind int

const (
	SimplePattern PatternKind = iota
	RegexpPattern
	NamePattern
	StarPattern
	OptPattern
	PlusPattern
	SequencePattern
	OrPattern
)

func (pk PatternKind) String() string {
	return [...]string{
		"SimplePattern",
		"RegexpPattern",
		"NamePattern",
		"StarPattern",
		"OptPattern",
		"PlusPattern",
		"SequencePattern",
		"OrPattern",
	}[pk]
}

type Pattern struct {
	kind    PatternKind
	content string
	inner   *Pattern
	subs    []*Pattern
	pos     Position
}

func AtomicPattern(kind PatternKind, content string, pos Position) *Pattern {
	return &Pattern{kind, content, nil, make([]*Pattern, 0), pos}
}

func TrailingPattern(kind PatternKind, inner *Pattern, pos Position) *Pattern {
	return &Pattern{kind, "", inner, make([]*Pattern, 0), pos}
}

func CompositePattern(kind PatternKind, subs []*Pattern, pos Position) *Pattern {
	return &Pattern{kind, "", nil, subs, pos}

}

func patternNoSubError(pat *Pattern) []Pattern {
	err := fmt.Errorf(pat.String() + " has no sub patterns")
	fmt.Println(err)
	return nil
}

func patternNoInnerError(pat *Pattern) *Pattern {
	err := fmt.Errorf(pat.String() + " has no inner pattern")
	fmt.Println(err)
	return nil
}

func patternNoContentError(pat *Pattern) string {
	err := fmt.Errorf(pat.String() + " has no content")
	fmt.Println(err)
	return ""
}

func (p *Pattern) Content() string {
	if p.content == "" {
		patternNoContentError(p)
		return ""
	}
	return p.content
}

func (p *Pattern) Inner() *Pattern {
	if p.inner == nil {
		patternNoInnerError(p)
		return nil
	}
	return p.inner
}

func (p *Pattern) Subs() []*Pattern {
	if len(p.subs) == 0 {
		patternNoSubError(p)
		return nil
	}
	return p.subs
}

func (p *Pattern) Evaluate() int {
	return int(p.kind)
}

func (p *Pattern) PlainString() string {
	if p.content == "" {
		return p.kind.String() + "@" + p.pos.String()
	}
	return p.kind.String() + "(" + p.content + ")" + "@" + p.pos.String()
}

func (p *Pattern) String() string {
	if p.inner != nil {
		return p.kind.String() + "(" + p.inner.String() + ")"
	} else if len(p.subs) > 0 {
		subStrings := make([]string, len(p.subs))
		for i, sub := range p.subs {
			subStrings[i] = sub.String()
		}
		return p.kind.String() + "{" + strings.Join(subStrings, ", ") + "}"
	} else {
		return p.kind.String() + "(" + p.content + ")"
	}
}

func (p *Pattern) Kind() PatternKind {
	return p.kind
}

func (p *Pattern) Pos() Position {
	return p.pos
}

func (p *Pattern) PosStr() string {
	return p.pos.String()
}

// tests

func DisplayPattern(p *Pattern) {
	fmt.Println(p.kind)
	fmt.Println(p)
	fmt.Println(p.String())
	fmt.Println()
}

func TestPatterns() {
	fmt.Println("Testing patterns...")
	fmt.Println("SimplePattern")
	simple := AtomicPattern(SimplePattern, "'hello'", Position{0, 0})
	DisplayPattern(simple)

	fmt.Println("RegexpPattern")
	regexp := AtomicPattern(RegexpPattern, "/hello/", Position{0, 0})
	DisplayPattern(regexp)

	fmt.Println("NamePattern")
	hello := AtomicPattern(NamePattern, "hello", Position{0, 0})
	world := AtomicPattern(NamePattern, "world", Position{0, 0})
	DisplayPattern(hello)

	fmt.Println("StarPattern")
	star := TrailingPattern(StarPattern, hello, Position{0, 0})
	DisplayPattern(star)

	fmt.Println("OptPattern")
	opt := TrailingPattern(OptPattern, hello, Position{0, 0})
	DisplayPattern(opt)

	fmt.Println("PlusPattern")
	plus := TrailingPattern(PlusPattern, hello, Position{0, 0})
	DisplayPattern(plus)

	fmt.Println("SequencePattern")
	seq := CompositePattern(SequencePattern, []*Pattern{hello, world}, Position{0, 0})
	DisplayPattern(seq)

	fmt.Println("OrPattern")
	or := CompositePattern(OrPattern, []*Pattern{hello, world}, Position{0, 0})
	DisplayPattern(or)

	fmt.Println("Testing patterns...done")
}
