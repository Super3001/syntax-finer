from Trees import *

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
                    assert token[0] == token[-1] == '"'
                    elements.append(Terminal(token[1:-1]))
            choices.append(Sequence(elements))
        
        grammar[lhs] = Choice(choices)
    
    return grammar