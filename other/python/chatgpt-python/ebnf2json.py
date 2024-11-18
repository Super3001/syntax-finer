import json
import os

os.chdir(r"D:\BaiduSyncdisk\modeling")

SAVE_DIR = r"syntax\out"

class GrammarNode:
    def to_dict(self):
        raise NotImplementedError("Must be implemented by subclasses")

class NonTerminal(GrammarNode):
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return f"NonTerminal('{self.name}')"

    def to_dict(self):
        return {"NonTerminal": self.name}

class Terminal(GrammarNode):
    def __init__(self, value):
        assert value[0] == value[-1] == '"'
        self.value = value[1:-1]

    def __repr__(self):
        return f"Terminal('{self.value}')"

    def to_dict(self):
        return {"Terminal": self.value}

class Sequence(GrammarNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Sequence({self.elements})"

    def to_dict(self):
        return {"Sequence": [element.to_dict() for element in self.elements]}

class Choice(GrammarNode):
    def __init__(self, alternatives):
        self.alternatives = alternatives

    def __repr__(self):
        return f"Choice({self.alternatives})"

    def to_dict(self):
        return {"Choice": [alternative.to_dict() for alternative in self.alternatives]}

class Optional(GrammarNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Optional({self.elements})"

    def to_dict(self):
        return {"Optional": [element.to_dict() for element in self.elements]}

class Repetition(GrammarNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Repetition({self.elements})"

    def to_dict(self):
        return {"Repetition": [element.to_dict() for element in self.elements]}

class Group(GrammarNode):
    def __init__(self, elements):
        self.elements = elements

    def __repr__(self):
        return f"Group({self.elements})"

    def to_dict(self):
        return {"Group": [element.to_dict() for element in self.elements]}

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
    match = re.match(r'\s*(".*?"|\'.*?\'|[^\s\[\]\{\}\(\)]+)\s*(.*)', sequence)
    if not match:
        raise ValueError(f"Invalid token in sequence: {sequence}")
    return match.group(1), match.group(2).strip()

def grammar_to_json(grammar):
    return {lhs: rhs.to_dict() for lhs, rhs in grammar.items()}

# Example EBNF input
ebnf_text = """
<expression> ::= <term> { "+" <term> }
<term> ::= <factor> { "*" <factor> }
<factor> ::= "(" <expression> ")" | <digit> { <digit> }
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""

# Parse the EBNF
grammar = parse_ebnf(ebnf_text)
grammar_json = grammar_to_json(grammar)
with open(SAVE_DIR + "\\json\\ebnf1.json", "w") as f:
    json.dump(grammar_json, f, indent=4)
