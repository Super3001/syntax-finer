# Defining the classes and functions to read BNF grammar, build a parser, and parse an example string

class BNFGrammarNode:
    pass

class NonTerminal(BNFGrammarNode):
    def __init__(self, name=None):
        super().__init__()
        self.name = name
        # self.children = children if children is not None else []

    def __str__(self):
        return f"NonTerminal('{self.name}')"

class Terminal(BNFGrammarNode):
    def __init__(self, value):
        super().__init__()
        self.value = value

    def __str__(self):
        return f"Terminal('{self.value}')"

class Sequence(NonTerminal):
    def __init__(self, elements):
        super().__init__()
        self.elements = elements

    def __str__(self):
        return f"Sequence({self.elements})"

class Choice(NonTerminal):
    def __init__(self, alternatives):
        super().__init__()
        self.alternatives = alternatives

    def __str__(self):
        return f"Choice({self.alternatives})"


class ParseNode:
    pass

class ParseNonTerminal(ParseNode):
    def __init__(self, name, children=None):
        self.name = name
        self.children = children if children is not None else []

    def __str__(self):
        super().__init__()
        return f"NonTerminal({self.name}, {self.children})"

class ParseTerminal(ParseNode):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        super().__init__()
        return f"Terminal('{self.value}')"
