package ast

/*
SimplePattern: 'abc'
RegExpPattern: /\w+/
NamePattern
StarPattern: Line*
OptPattern: Line?
OrPattern: 'a' | 'b' | 'c'
ConcatPattern: This That '...'
*/

abstract class SyntaxPattern {
  def toRegExp = ???
}

abstract class AtomicPattern extends SyntaxPattern
case class SimplePattern(string: String)
case class RegexpPattern(string: String)

abstract class ComposePattern extends SyntaxPattern
case class NamePattern(name: String)
case class StarPattern(string: String)
case class OptPattern(string: String)
case class OrPattern(string: String)
case class ConcatPattern(string: String)
