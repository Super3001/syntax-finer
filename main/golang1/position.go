package main

import "fmt"

type Position struct {
	line int
	col  int
}

func (pos Position) String() string {
	return fmt.Sprintf("(%d,%d)", pos.line, pos.col)
}

func (pos Position) Pos() Position {
	return pos
}
