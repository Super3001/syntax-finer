package chatgpt

import chatgpt.ASTNode._
import chatgpt.Exceptions._

// Parsing Functions
object BNFParser {
  def parseBNF(bnfText: String): Map[String, ASTNode] = {
    val lines = bnfText.stripMargin.split("\n").map(_.trim).filter(_.nonEmpty)
    lines.map { line =>
      val parts = line.split("::=").map(_.trim)
      if (parts.length != 2) throw new InvalidRuleDefinitionException(line)
      val name = parts(0)
      val definition = parseDefinition(parts(1))
      name -> definition
    }.toMap
  }

  def parseDefinition(definition: String): ASTNode = {
    if (definition.contains("|")) {
      Choice(definition.split('|').map(part => parseSequence(part.trim)).toList)
    } else {
      parseSequence(definition)
    }
  }

  def parseSequence(sequence: String): ASTNode = {
    val elements = sequence.split(" ").map(element => parseElement(element.trim)).toList
    Sequence(elements)
  }

  def parseElement(element: String): ASTNode = {
    if (element.startsWith("\"") && element.endsWith("\"")) {
      Terminal(element.substring(1, element.length - 1))
    } else if (element.startsWith("<") && element.endsWith(">")) {
      NonTerminal(element.substring(1, element.length - 1))
    } else {
      throw new InvalidElementException(element)
    }
  }
}

// Testing the Parser with a Simple BNF Example
object BNFParserTest extends App {
  val bnfExample = """
    <expression> ::= <term> | <expression> "+" <term>
    <term> ::= <factor> | <term> "*" <factor>
    <factor> ::= <digit> | "(" <expression> ")"
    <digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
  """

  try {
    val ast = BNFParser.parseBNF(bnfExample)
    println(ast)
  } catch {
    case e: ParsingException => println(s"Parsing error: ${e.getMessage}")
  }
}
