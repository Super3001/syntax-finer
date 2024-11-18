package chatgpt

import chatgpt.ASTNode._
import chatgpt.Exceptions._

// Parsing Functions
object EBNFParser {
  def parseEBNF(ebnfText: String): Map[String, ASTNode] = {
    val lines = ebnfText.stripMargin.split("\n").map(_.trim).filter(_.nonEmpty)
    lines.map { line =>
      val parts = line.split("::=").map(_.trim)
      if (parts.length != 2) throw new InvalidRuleDefinitionException(line)
      val name = parts(0)
      val definition = parseDefinition(parts(1), line)
      name -> definition
    }.toMap
  }

  def parseDefinition(definition: String, line: String): ASTNode = {
    if (definition.contains("|")) {
      Choice(definition.split('|').map(part => parseSequence(part.trim, line)).toList)
    } else {
      parseSequence(definition, line)
    }
  }

  def parseSequence(sequence: String, line: String): ASTNode = {
    val elements = sequence.split(" ").map(element => parseElement(element.trim, line)).toList
    Sequence(elements)
  }

  def parseElement(element: String, line: String): ASTNode = {
    if (element.startsWith("\"") && element.endsWith("\"")) {
      Terminal(element.substring(1, element.length - 1))
    } else if (element.startsWith("<") && element.endsWith(">")) {
      NonTerminal(element.substring(1, element.length - 1))
    } else if (element.startsWith("[") && element.endsWith("]")) {
      Optional(parseElement(element.substring(1, element.length - 1), line))
    } else if (element.startsWith("{") && element.endsWith("}")) {
      Repetition(parseElement(element.substring(1, element.length - 1), line))
    } else if (element.startsWith("(") && element.endsWith(")")) {
      Group(parseDefinition(element.substring(1, element.length - 1), line))
    } else {
      throw new InvalidElementException(element)
    }
  }

  def checkBalancedBrackets(text: String): Unit = {
    val bracketStack = scala.collection.mutable.Stack[Char]()
    val bracketPairs = Map(']' -> '[', '}' -> '{', ')' -> '(')
    
    text.zipWithIndex.foreach { case (char, idx) =>
      if ("[{(".contains(char)) {
        bracketStack.push(char)
      } else if ("]})".contains(char)) {
        if (bracketStack.isEmpty || bracketStack.pop() != bracketPairs(char)) {
          throw new UnbalancedBracketsException(char.toString, text)
        }
      }
    }
    
    if (bracketStack.nonEmpty) {
      throw new UnbalancedBracketsException(bracketStack.top.toString, text)
    }
  }
}


