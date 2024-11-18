# Defining the classes and functions to read BNF grammar, build a parser, and parse an example string

class GrammarNode:
    pass

class NonTerminal(GrammarNode):
    def __init__(self, name, children=None):
        self.name = name
        # self.children = children if children is not None else []

    def __repr__(self):
        return f"NonTerminal('{self.name}', {self.children})"

class Terminal(GrammarNode):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return f"Terminal('{self.value}')"

class Sequence(NonTerminal):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Sequence({self.elements})"

class Choice(NonTerminal):
    def __init__(self, alternatives):
        self.alternatives = alternatives

    def __repr__(self):
        return f"Choice({self.alternatives})"

# Function to parse BNF text and produce the AST-like structure
def parse_bnf(bnf_text):
    grammar = {}
    rules = bnf_text.strip().split('\n')
    
    for rule in rules:
        lhs, rhs = rule.split('::=')
        lhs = lhs.strip()
        rhs_choices = rhs.split('|')
        
        choices = []
        for choice in rhs_choices:
            sequence = [token.strip() for token in choice.strip().split()]
            elements = []
            for token in sequence:
                if token.startswith('<') and token.endswith('>'):
                    elements.append(NonTerminal(token))
                else:
                    elements.append(Terminal(token.strip('"')))
            choices.append(Sequence(elements))
        
        grammar[lhs] = Choice(choices)
    
    return grammar

# Dynamic parser construction and parsing example string
class DynamicParser:
    def __init__(self, grammar):
        self.grammar = grammar
        self.pos = 0
        self.tokens = []

    def current_token(self):
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return None

    def consume(self, expected):
        if self.current_token() == expected:
            self.pos += 1
            return True
        return False

    def parse_nonterminal(self, nonterminal):
        print(f"Parsing NonTerminal: {nonterminal.name}")
        if isinstance(nonterminal, Choice):
            choices = nonterminal.alternatives
            start_pos = self.pos
            for choice in choices:
                self.pos = start_pos
                nodes = []
                print(f" Trying choice: {choice}")
                for element in choice.elements:
                    if isinstance(element, NonTerminal):
                        print(f"  Parsing nested NonTerminal: {element.name}")
                        node = self.parse_nonterminal(element)
                        if node is None:
                            print(f"   Failed to parse: {element.name}")
                            break
                    elif isinstance(element, Terminal):
                        print(f"  Consuming Terminal: {element.value}")
                        if not self.consume(element.value):
                            print(f"   Failed to consume: {element.value}")
                            break
                        node = element
                    nodes.append(node)
            return nodes
        elif isinstance(nonterminal, Sequence):
            elements = nonterminal.elements
            nodes = []
            for element in elements:
                if isinstance(element, NonTerminal):
                    print(f"  Parsing nested NonTerminal: {element.name}")
                    node = self.parse_nonterminal(element)
                    if node is None:
                        print(f"   Failed to parse: {element.name}")
                        break
                elif isinstance(element, Terminal):
                    print(f"  Consuming Terminal: {element.value}")
                    if not self.consume(element.value):
                        print(f"   Failed to consume: {element.value}")
                        break
                    node = element
                nodes.append(node)
            return nodes
        return None

    def parse(self, tokens, start_symbol):
        self.tokens = tokens
        self.pos = 0
        if start_symbol in self.grammar:
    
            start = self.grammar[start_symbol]
            parse_tree = self.parse_nonterminal(start)
            if parse_tree and self.pos == len(self.tokens):
                return parse_tree
            raise ValueError("Parsing failed")
        else:
            raise ValueError(f"Invalid start symbol: {start_symbol}")

# Example BNF input
bnf_text = """
<expression> ::= <term> | <term> "+" <expression> | <term> "-" <expression>
<term> ::= <factor> | <factor> "*" <term> | <factor> "/" <term>
<factor> ::= <digit> | "(" <expression> ")"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""

# Parse the BNF to create the grammar
grammar = parse_bnf(bnf_text)

# Create the dynamic parser
parser = DynamicParser(grammar)

# Example string to parse
example_string = "3+5*(2-1)"
tokens = list(example_string)

# Parse the example string
try:
    parse_tree = parser.parse(tokens, "<expression>")
    print("Parse Tree:", parse_tree)
except ValueError as e:
    print(e)
