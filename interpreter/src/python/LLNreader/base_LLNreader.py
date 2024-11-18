
import sys
import os
sys.path.append(os.path.dirname(sys.path[0]))

from reader import TextReaderLLN

FILEPATH = r"D:\data-platform\collect\跳板机.txt"
SAVE_DIR = r"syntax\interpreter\out"


class BaseReaderLLN(TextReaderLLN):
    def __init__(self, filepath) -> None:
        super().__init__(filepath)

    def EOF(self):
        if not self.eof():
            raise Exception("Unexpected Token {} at {}, expect EOF".format(self.peek(), self.cur))
        
    def notnullcheck(func):
        def wrapper(self, *args, **kwargs):
            if self.eof():
                raise Exception("EOF occurs when parsing Element {}".format(func.__name__))
            result = func(self, *args, **kwargs)
            return result
        return wrapper
    
    def notnullcheck(self, element="<elem>", rollback=False):
        if self.eof():
            if rollback:
                return False
            raise Exception("EOF occurs when parsing Element {}".format(element))
        return True

    def nullable(func):
        return func

    def notnull(func):
        return func

    def file(func):
        return func

    @notnull
    def LINE(self, rollback=False):
        if not self.notnullcheck("LINE", rollback=rollback):
            return ''
        if self.peek() in [' ', '\n', '\t']:
            if rollback:
                return ''
            else:
                raise Exception("Unexpected Token {}, expect /\\S/".format(self.peek()))
        idx = self.look().find('\n')
        # idx == -1: all
        return self.forward(idx)
        
    @nullable
    def LineBlank(self):
        lineblank = ''
        while not self.eof():
            if self.peek() in [' ', '\n', '\t']:
                lineblank += '\\' + hex(ord(self.consume()))[1:]
            else:
                break
        return lineblank

    @notnull
    def NL(self, rollback=False):
        if not self.notnullcheck("NL", rollback=rollback):
            return ''
        if self.peek() not in ['\n']:
            if rollback:
                return ''
            else:
                raise Exception("Unexpected Token {}, expect '\n'".format(self.peek()))
        return self.consume()

    @notnull
    def LineSpace(self, rollback=False):
        lineblank = self.LineBlank()
        line = self.LINE(rollback)
        if line:
            return {
                "LineBlank": lineblank,
                "LINE": line
            }
        elif rollback:
            return None
        
    @notnull
    def LineFull(self, rollback=False):
        linespace = self.LineSpace(rollback)
        nl = self.NL(rollback)
        if linespace and nl:
            return {
                "LineSpace": linespace,
                "NL": nl
            }
        elif rollback:
            return None

    @file
    def File(self):
        LineFullList = []
        while True:
            linefull = self.LineFull(True)
            if linefull:
                LineFullList.append(linefull)
            else:
                break
        lineblank = self.LineBlank()
        self.EOF()
        return {
            "LineFull": LineFullList,
            "LineBlank": lineblank
        }
    
    def parse(self):
        self.tree = self.File()


if __name__ == '__main__':
    reader = BaseReaderLLN(FILEPATH)
    reader.parse()
    # reader.output()
    reader.save_json(SAVE_DIR)
