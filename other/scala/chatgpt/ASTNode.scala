package chatgpt

// Define the AST Node Classes
trait ASTNode { self =>
  case class Rule(name: String, definition: ASTNode) extends ASTNode {
    override def toString: String = s"Rule($name, $definition)"
  }

  case class Sequence(elements: List[ASTNode]) extends ASTNode {
    override def toString: String = s"Sequence($elements)"
  }

  case class Choice(options: List[ASTNode]) extends ASTNode {
    override def toString: String = s"Choice($options)"
  }

  case class Terminal(value: String) extends ASTNode {
    override def toString: String = s"Terminal('$value')"
  }

  case class NonTerminal(name: String) extends ASTNode {
    override def toString: String = s"NonTerminal($name)"
  }

  case class Optional(element: ASTNode) extends ASTNode {
    override def toString: String = s"Optional($element)"
  }

  case class Repetition(element: ASTNode) extends ASTNode {
    override def toString: String = s"Repetition($element)"
  }

  case class Group(elements: ASTNode) extends ASTNode {
    override def toString: String = s"Group($elements)"
  }
}

object ASTNode{
  
}
