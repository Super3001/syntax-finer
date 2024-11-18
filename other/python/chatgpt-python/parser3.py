# Defining the classes and parser to transform BNF expressions into ASTs

class BNFParseNode:
    pass

class BNFParseNonTerminal(BNFParseNode):
    def __init__(self, name, children=None):
        self.name = name
        self.children = children if children is not None else []

    def __repr__(self):
        return f"NonTerminal({self.name}, {self.children})"

class BNFParseTerminal(BNFParseNode):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return f"Terminal('{self.value}')"

class BNFParser:
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
            node = BNFParseNonTerminal('expression', [node, BNFParseTerminal(operator), right])
        return node

    def parse_term(self):
        node = self.parse_factor()
        while self.current_token() in ('*', '/'):
            operator = self.current_token()
            self.pos += 1
            right = self.parse_factor()
            node = BNFParseNonTerminal('term', [node, BNFParseTerminal(operator), right])
        return node

    def parse_factor(self):
        if self.consume('('):
            node = self.parse_expression()
            if node and self.consume(')'):
                return BNFParseNonTerminal('factor', [BNFParseTerminal('('), node, BNFParseTerminal(')')])
        return self.parse_digit()

    def parse_digit(self):
        current = self.current_token()
        if current in "0123456789":
            self.pos += 1
            return BNFParseTerminal(current)
        return None

    def parse(self):
        result = self.parse_expression()
        if result and self.pos == len(self.tokens):
            return result
        raise ValueError("Parsing failed")

# Tokenizing and parsing the expression with the BNF parser
tokens = list("3+5*(2-1)")
parser = BNFParser(tokens)
parse_tree = parser.parse()

print(parse_tree)
