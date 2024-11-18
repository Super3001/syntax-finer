# Defining the grammar structure classes

class GrammarNode:
    pass

class NonTerminal(GrammarNode):
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return f"NonTerminal('{self.name}')"

class Terminal(GrammarNode):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return f"Terminal('{self.value}')"

class Sequence(GrammarNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Sequence({self.elements})"

class Choice(GrammarNode):
    def __init__(self, alternatives):
        self.alternatives = alternatives

    def __repr__(self):
        return f"Choice({self.alternatives})"

# Function to parse BNF text and produce the AST-like structure

import re

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
                    elements.append(Terminal(token))
            choices.append(Sequence(elements))
        
        grammar[lhs] = Choice(choices)
    
    return grammar

# Example BNF input
bnf_text = """
<expression> ::= <term> | <term> "+" <expression>
<term> ::= <factor> | <factor> "*" <term>
<factor> ::= <digit> | "(" <expression> ")"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""

# Parse the BNF
grammar = parse_bnf(bnf_text)
grammar
