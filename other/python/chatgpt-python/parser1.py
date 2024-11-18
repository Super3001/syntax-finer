# Define the AST Node Classes
class ASTNode:
    pass

class Rule(ASTNode):
    def __init__(self, name, definition):
        self.name = name
        self.definition = definition

    def __repr__(self):
        return f"Rule({self.name}, {self.definition})"

class Sequence(ASTNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Sequence({self.elements})"

class Choice(ASTNode):
    def __init__(self, options):
        self.options = options

    def __repr__(self):
        return f"Choice({self.options})"

class Terminal(ASTNode):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return f"Terminal('{self.value}')"

class NonTerminal(ASTNode):
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return f"NonTerminal({self.name})"


# Parsing Function
def parse_bnf(bnf_text):
    rules = {}
    for line in bnf_text.strip().splitlines():
        name, definition = line.split("::=")
        name = name.strip()
        rules[name] = parse_definition(definition.strip())
    return rules

def parse_definition(definition):
    if '|' in definition:
        return Choice([parse_sequence(part.strip()) for part in definition.split('|')])
    else:
        return parse_sequence(definition)

def parse_sequence(sequence):
    elements = [parse_element(element.strip()) for element in sequence.split()]
    return Sequence(elements)

def parse_element(element):
    if element.startswith('"') and element.endswith('"'):
        return Terminal(element[1:-1])
    elif element.startswith('<') and element.endswith('>'):
        return NonTerminal(element[1:-1])
    else:
        raise ValueError(f"Invalid element: {element}")

# Testing the Parser with a Simple BNF Example
bnf_example = """
<expression> ::= <term> | <expression> "+" <term>
<term> ::= <factor> | <term> "*" <factor>
<factor> ::= <digit> | "(" <expression> ")"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""

ast = parse_bnf(bnf_example)
print(ast)
