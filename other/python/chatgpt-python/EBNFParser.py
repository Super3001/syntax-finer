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

class Optional(GrammarNode):
    def __init__(self, element):
        self.element = element

    def __repr__(self):
        return f"Optional({self.element})"

class Repetition(GrammarNode):
    def __init__(self, element):
        self.element = element

    def __repr__(self):
        return f"Repetition({self.element})"

class Group(GrammarNode):
    def __init__(self, element):
        self.element = element

    def __repr__(self):
        return f"Group({self.element})"

# Function to parse EBNF text and produce the AST-like structure

import re

def parse_ebnf(ebnf_text):
    grammar = {}
    rules = ebnf_text.strip().split('\n')
    
    for rule in rules:
        lhs, rhs = rule.split('::=')
        lhs = lhs.strip()
        rhs_choices = re.split(r'\s*\|\s*', rhs)
        
        choices = []
        for choice in rhs_choices:
            elements = parse_sequence(choice.strip())
            choices.append(Sequence(elements))
        
        grammar[lhs] = Choice(choices)
    
    return grammar

def parse_sequence(sequence):
    elements = []
    while sequence:
        if sequence.startswith('['):
            matched, sequence = extract_bracketed(sequence, '[', ']')
            elements.append(Optional(parse_sequence(matched)))
        elif sequence.startswith('{'):
            matched, sequence = extract_bracketed(sequence, '{', '}')
            elements.append(Repetition(parse_sequence(matched)))
        elif sequence.startswith('('):
            matched, sequence = extract_bracketed(sequence, '(', ')')
            elements.append(Group(parse_sequence(matched)))
        else:
            token, sequence = extract_token(sequence)
            if token.startswith('<') and token.endswith('>'):
                elements.append(NonTerminal(token))
            else:
                elements.append(Terminal(token))
    return elements

def extract_bracketed(sequence, open_bracket, close_bracket):
    count = 0
    for i, char in enumerate(sequence):
        if char == open_bracket:
            count += 1
        elif char == close_bracket:
            count -= 1
        if count == 0:
            return sequence[1:i], sequence[i+1:].strip()
    raise ValueError(f"Mismatched brackets in sequence: {sequence}")

def extract_token(sequence):
    match = re.match(r'\s*([^\s\[\]\{\}\(\)]+)\s*(.*)', sequence)
    if not match:
        raise ValueError(f"Invalid token in sequence: {sequence}")
    return match.group(1), match.group(2).strip()

# Example EBNF input
ebnf_text = """
<expression> ::= <term> | <term> "+" <expression>
<term> ::= <factor> | <factor> "*" <term>
<factor> ::= <digit> | "(" <expression> ")" | "[" <expression> "]"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "{" <digit> "}"
"""

# Parse the EBNF
grammar = parse_ebnf(ebnf_text)
print(grammar)
