package chatgpt

// Custom Exceptions for Parsing Errors
class ParsingException(message: String) extends Exception(message)
class InvalidElementException(element: String) extends ParsingException(s"Invalid element: $element")
class InvalidRuleDefinitionException(line: String) extends ParsingException(s"Invalid rule definition: $line")
class UnbalancedBracketsException(bracketType: String, line: String) extends ParsingException(s"Unbalanced $bracketType in line: $line")

object ParsingException
