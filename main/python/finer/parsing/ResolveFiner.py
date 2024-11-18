
import sys
import os
import json

sys.path.append(os.path.dirname(sys.path[0]))

SYNTAXPATH = r"syntax\demo\base.syntax"
FILEPATH = r"D:\data-platform\collect\跳板机.txt"
SAVE_DIR = r"syntax\out"
ENTRY = "File"

from parsing.SyntaxReader import SyntaxReader
# from nodes.LinkedTreeModule import *
from nodes.TreeModule import *

class ResolveFiner:
    def __init__(self, syntaxfile: str) -> None:
        self.syntaxpath = syntaxfile

    def fine(self, filepath, name_entry):

        ast = SyntaxReader(self.syntaxpath).tree

        names = ast["names"]

        name_files = [each for each in names if names[each]["view"] == "file"]

        assert name_entry in name_files

        def resolve(pat):
            if isinstance(pat, SimplePattern):
                return pat.content[1:-1]
            if isinstance(pat, RegexpPattern):
                return pat.content[1:-1]
            if isinstance(pat, NamePattern):
                name = pat.content
                return f"(?'{name}'{resolve(names[name]['pat'])})"
            if isinstance(pat, StarPattern):
                return f"(?:{resolve(pat.content[0])})*"
            if isinstance(pat, OptPattern):
                return f"(?:{resolve(pat.content[0])})?"
            if isinstance(pat, OrPattern):
                return "|".join(
                    map(lambda x: '(?:' + resolve(x) + ')', pat.content)
                )
            if isinstance(pat, ConcatPattern):
                return "".join(
                    map(lambda x: '(?:' + resolve(x) + ')', pat.content)
                )
            else:
                raise Exception("not allowed")
        resolved_regexp = resolve(names[name_entry]["pat"])

        print(resolved_regexp)

        with open(filepath, 'r', encoding='utf-8') as f:
            text = f.read()
            if not text.endswith('\n'):
                text = text + '\n'
        tree = None

        '''
        def parse(text: str, pat: SyntaxPattern, rollback=False):
            # print('.')
            if isinstance(pat, SimplePattern):
                # strip "'"
                if text.startswith(pat.content[1:-1]):
                    length = len(pat.content) - 2
                    return text[:length], text[length:]
                elif rollback:
                    return None, text
                else:
                    raise Exception("parsing error: {} on {}".format(pat, text))
            if isinstance(pat, RegexpPattern):
                # strip "/"
                matchObj = re.match("^" + pat.content[1:-1], text)
                if matchObj is not None:
                    return matchObj.group(), text[matchObj.span()[1]:]
                elif rollback:
                    return None, text
                else:
                    raise Exception("parsing error: {} on {}".format(pat, text))
            if isinstance(pat, NamePattern):
                name = pat.content
                parsed, rest = parse(text, names[name]["pat"], rollback=rollback)
                if parsed is not None:
                    # return {name: parsed}, rest
                    return parsed, rest
                elif rollback:
                    # return {name: None}, text
                    return None, text
                else:
                    raise Exception("parsing error: {} on {}".format(pat, text))
            if isinstance(pat, StarPattern):
                content = pat.content[0]
                assert isinstance(content, NamePattern)
                parsedList = []
                rest = text
                while rest:
                    parsed, rest = parse(rest, content, rollback=True)
                    if parsed is not None:
                        parsedList.append(parsed)
                    else:
                        break
                return {content.content: parsedList}, rest
            if isinstance(pat, OptPattern):
                content = pat.content[0]
                assert isinstance(content, NamePattern)
                parsed, rest = parse(text, content, rollback=True)
                if parsed is not None:
                    return {content.content: parsed}, rest
                else:
                    return None, text
            if isinstance(pat, OrPattern):
                parsed_list, rest_list = [], []
                cnt = 0
                match_idx = -1
                for i, each in enumerate(pat.content):
                    parsed, rest = parse(text, each, rollback=rollback)
                    if parsed is not None:
                        cnt += 1
                        match_idx = i
                    parsed_list.append(parsed)
                    rest_list.append(rest)
                if cnt == 1:
                    if isinstance(pat.content[match_idx], NamePattern):
                        return {pat.content[match_idx].content: parsed_list[match_idx]}, rest_list[match_idx]
                    else:
                        return parsed_list[match_idx], rest_list[match_idx]
                elif cnt > 1:
                    raise Exception("match confusion: {} parsed when parsing {}".format(parsed_list, pat))
                elif rollback:
                    return None, text
                else:
                    raise Exception("parsing error: {} on {}".format(pat, text))
            if isinstance(pat, ConcatPattern):
                # parsed_list = []
                parsed_dict = {}
                rest = text
                for i, each in enumerate(pat.content):
                    parsed, rest = parse(rest, each, rollback=rollback)
                    if parsed is None:
                        if rollback:
                            return None, text
                        else:
                            raise Exception("parsing error: {} on {}".format(pat, text))
                    if isinstance(each, NamePattern):
                        parsed_dict[each.content] = parsed
                    elif isinstance(each, StarPattern) or isinstance(each, OptPattern) or isinstance(each, OrPattern):
                        if isinstance(parsed, dict):
                            for key, value in parsed.items():
                                parsed_dict[key] = value
                        else:
                            parsed_dict["_" + str(i)] = parsed
                    else:
                        parsed_dict["_" + str(i)] = parsed
                return parsed_dict, rest
            
        tree, rest = parse(text=text, pat=names[name_entry]['pat'], rollback=False)
        if rest:
            raise Exception("expected EOF, the rest is {}".format(rest))
        self.tree = {name_entry: tree}
        '''
        self.tree = tree

    def to_json(self):    
        return json.dumps(self.tree, indent=4)
    
    def output(self):
        print(json.dumps(self.tree, indent=4))
    
    def save_json(self, save_dir="", filename=""):
        if filename == "":
            filename = 'basic_finer.tree.json'
        filename = os.path.join(save_dir, 'json', filename)
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.to_json())


if __name__ == '__main__':
    reader = ResolveFiner(SYNTAXPATH)
    reader.fine(FILEPATH, "File")
    # reader.save_json(SAVE_DIR)
