from Trees import *

from dynamic_1 import parse_bnf

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
    
    def parse_nonterminal(self, nonterminal: NonTerminal):
        print("parsing Nonterminal: {}".format(nonterminal.name if nonterminal.name else nonterminal))
        if isinstance(nonterminal, Sequence):
            nodes = []
            for each in nonterminal.elements:
                if isinstance(each, Terminal):
                    print(f"  Consuming Terminal: {each.value}")
                    if self.consume(each.value):
                        nodes.append(each.value)
                    else:
                        print(f"   Failed to consume: {each.value}")
                        return None
                else:
                    print(f"  Parsing nested NonTerminal: {each}")
                    node = self.parse_nonterminal(each)
                    if node:
                        nodes.append(node)
                    else:
                        print(f"   Failed to parse: {each}")
                        return None
            return nodes
        elif isinstance(nonterminal, Choice):
            start_pos = self.pos
            for each in nonterminal.alternatives:
                self.pos = start_pos
                print(f" Trying choice: {each}")
                if isinstance(each, Terminal):
                    print(f"  Consuming Terminal: {each.value}")
                    if self.consume(each.value):
                        return each.value
                    else:
                        print(f"   Failed to consume: {each.value}")
                else:
                    print(f"  Parsing nested NonTerminal: {each}")
                    node = self.parse_nonterminal(each)
                    if node:
                        return node
                    else:
                        print(f"   Failed to parse: {each}")
        else:
            name = nonterminal.name
            if name in self.grammar:
                start = self.grammar[name]
                return self.parse_nonterminal(start)
            else:
                raise Exception("Nonterminal {} is not defined".format(name))

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
parse_tree = parser.parse(tokens, "<expression>")
print(parse_tree)
