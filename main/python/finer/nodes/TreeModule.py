
import re
import sys
import os

sys.path.append(os.path.dirname(sys.path[0]))

from utils.Position import Positioned


'''
SimplePattern: ['a'] / ["abc"]  / ["a-z"]

RegexpPattern: /\\w+/


'''

class SyntaxPattern(Positioned):
    def __init__(self, atomic: bool) -> None:
        super().__init__()
        self.atomic = atomic
        self.content: str | list[SyntaxPattern] = None
        self.nullable = False

    def require(self, start: str='', end: str=''):
        return self.require1(self.content, start, end)
        
    def require1(self, target: str, start: str='', end: str=''):
        if not target.endswith(start):
            raise ValueError("{}: Construction Error at {}".format(type(self), self.pos))
        if not target.endswith(end):
            raise ValueError("{}: Construction Error at {}".format(type(self), self.pos))
        
    def requirepat(self, pat: str | re.Pattern):
        return self.requirepat1(self.content, pat)
        
    def requirepat1(self, target:str, pat: str | re.Pattern):
        if not re.match(pat, target):
            raise ValueError('''{}: Construction Error at {}
required: {}, got: {}'''.format(type(self), self.pos, pat, target))

    def resolve(self) -> re.Pattern:
        pass

    def __str__(self) -> str:
        return '{}({})'.format(type(self).__name__, self.content)
    
    def __repr__(self) -> str:
        return '{}({})'.format(type(self).__name__, self.content)
    
    def preserve_quotes_split(self, text:str, pat):
        quoted = False
        length = len(pat)
        res = []
        last = ''
        after = text
        while after:
            if after.startswith(pat) and not quoted:
                res.append(last)
                after = after[length:]
                last = ''
                continue
            elif after.startswith("\\'"):
                pass
            elif after[0] == "'":
                quoted = not quoted
            last += after[0]
            after = after[1:]
        res.append(last)
        return res
        '''
        # protected = re.sub(r"('[^']*')", lambda mobj: mobj.group().replace('|', '\\|').replace(' ', '|'), text)
        # for each in re.split(pat, protected):
        #     res = ''
        #     i = 0
        #     while i < len(each):
        #         if each[i] == '\\' and i+1 < len(each):
        #             if each[i+1] == '|':
        #                 res += '|'
        #             elif each[i+1] == '\\':
        #                 res += '\\'
        #             else:
        #                 raise Exception("doesn't allow single backslash('\\') in quoted pattern, got {} at {}".format(text, self.pos))
        #             i += 1
        #         elif each[i] == '|':
        #             res += ' '
        #         else:
        #             res += each[i]
        #         i += 1
        #     yield res 
        '''  
                    
    @classmethod
    def not_in_quotes(cls, text, pat):
        return re.sub(r"'[^']*'", '', text).find(pat) >= 0
        # return re.sub(r"(?<!')(?:'[^']*')", '', text).find(pat) == -1
    
    @classmethod
    def buildfrom(cls, patstr: str):
        if patstr.startswith("/") and patstr.endswith("/"):
            return RegexpPattern(patstr)
        if cls.not_in_quotes(patstr, ' | '):
            return OrPattern(patstr)
        if cls.not_in_quotes(patstr, ' '):
            return ConcatPattern(patstr)
        if patstr.endswith("*"):
            return StarPattern(patstr)
        if patstr.endswith("?"):
            return OptPattern(patstr)
        if patstr.startswith("'") and patstr.endswith("'"):
            return SimplePattern(patstr)
        return NamePattern(patstr)
        

class AtomicPattern(SyntaxPattern):
    def __init__(self, string: str) -> None:
        super().__init__(True)
        self.content = string

class ComposePattern(SyntaxPattern):
    def __init__(self) -> None:
        super().__init__(False)

class SimplePattern(AtomicPattern):
    def __init__(self, string: str) -> None:
        super().__init__(string)
        self.require("'", "'")
        # double backslash to represent a backslash in quoted pattern in #(.syntax)
        self.content = self.content.replace('\\\\', '\\')

    def resolve(self):
        return re.compile(self.content)
    
'''
class DoubleQuotePattern(AtomicPattern):
    def __init__(self, string: str) -> None:
        super().__init__(string)
        self.require('"', '"')

    def resolve(self) -> re.Pattern:
        return super().resolve()
'''

class RegexpPattern(AtomicPattern):
    def __init__(self, string: str) -> None:
        super().__init__(string)

    def resolve(self):
        return re.compile(self.content[1:-1])
    
class NamePattern(AtomicPattern):
    def __init__(self, string: str) -> None:
        super().__init__(string)
        self.requirepat(r'^[a-zA-Z_]\w*$')

class StarPattern(ComposePattern):
    def __init__(self, string: str) -> None:
        super().__init__()
        self.require1(string, '', '*')
        self.content = [NamePattern(string[:-1])]

class OptPattern(ComposePattern):
    def __init__(self, string: str) -> None:
        super().__init__()
        self.require1(string, '', '?')
        self.content = [NamePattern(string[:-1])]

class OrPattern(ComposePattern):
    def __init__(self, string: str) -> None:
        super().__init__()
        self.content = []
        for each in self.preserve_quotes_split(string, ' | '):
            self.content.append(SyntaxPattern.buildfrom(each))
        
class ConcatPattern(ComposePattern):
    def __init__(self, string: str) -> None:
        super().__init__()
        self.content = []
        for each in self.preserve_quotes_split(string, ' '):
            self.content.append(SyntaxPattern.buildfrom(each))
