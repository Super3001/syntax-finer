# Defining the updated parser classes with subtraction handling

class ParseNode:
    pass

class ParseNonTerminal(ParseNode):
    def __init__(self, name, children=None):
        self.name = name
        self.children = children if children is not None else []

    def __repr__(self):
        return f"NonTerminal({self.name}, {self.children})"

class ParseTerminal(ParseNode):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return f"Terminal('{self.value}')"

class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.pos = 0

    def current_token(self):
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return None

    def consume(self, expected):
        if self.current_token() == expected:
            self.pos += 1
            return True
        return False

    def parse_expression(self):
        node = self.parse_term()
        while self.current_token() in ('+', '-'):
            operator = self.current_token()
            self.pos += 1
            right = self.parse_term()
            node = ParseNonTerminal('expression', [node, ParseTerminal(operator), right])
        return node

    def parse_term(self):
        node = self.parse_factor()
        while self.current_token() in ('*', '/'):
            operator = self.current_token()
            self.pos += 1
            right = self.parse_factor()
            node = ParseNonTerminal('term', [node, ParseTerminal(operator), right])
        return node

    def parse_factor(self):
        if self.consume('('):
            node = self.parse_expression()
            if node and self.consume(')'):
                return ParseNonTerminal('factor', [ParseTerminal('('), node, ParseTerminal(')')])
        return self.parse_digit()

    def parse_digit(self):
        current = self.current_token()
        if current in "0123456789":
            self.pos += 1
            return ParseTerminal(current)
        return None

    def parse(self):
        result = self.parse_expression()
        if result and self.pos == len(self.tokens):
            return result
        raise ValueError("Parsing failed")

# Tokenizing and parsing the expression with the updated parser
tokens = list("3+5*(2-1)")
parser = Parser(tokens)
parse_tree = parser.parse()

parse_tree
