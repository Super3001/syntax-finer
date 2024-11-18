import sys
import os
import json

sys.path.append(os.path.dirname(sys.path[0]))

BASE_DIR = r"E:\BaiduSyncDisk\modeling\syntax\\"
SYNTAXPATH = BASE_DIR + r"demo\syntaxdef.syntax"
FILEPATH = BASE_DIR + r"demo\base.syntax"
PROJ_DIR = BASE_DIR + r"main\python\\"
SAVE_DIR = PROJ_DIR + r"out"
ENTRY = "SyntaxFile"

from parsing.SyntaxReader import SyntaxReader
from nodes.TreeModule import *
from nodes.TreeEncoder import TreeJsonEncoder
from utils.DefinedClasses import ParsedList


def full_match(regexp, text):
    return re.match("^" + regexp + "$", text) is not None


class BasicFiner:
    def __init__(self, syntaxfile: str) -> None:
        self.syntaxpath = syntaxfile
        self.syntax_reader = SyntaxReader(self.syntaxpath)

    def fine(self, filepath, name_entry):

        ast = self.syntax_reader.tree

        names = ast["names"]

        name_files = [each for each in names if names[each]["view"] == "file"]

        if name_entry[0] == '$':
            view_entry = name_entry[1:]
            view_targets = [each for each in names if names[each]["view"] == view_entry]
            if len(view_targets) == 0:
                raise Exception("No Such View: {}".format(view_entry))
            elif len(view_targets) > 1:
                raise Exception('I could not determine which symbol from view: {}, targets are: {}'.format(view_entry, view_targets))
            else:
                name_entry = view_targets[0]
        else:
            assert name_entry in name_files

        with open(filepath, 'r', encoding='utf-8') as f:
            text = f.read()
            if not text.endswith('\n'):
                text = text + '\n'
        tree = None

        def parse(text: str, pat: SyntaxPattern, rollback=False) -> tuple[str, str] | tuple[None, str] | tuple[dict, str]:
            # print('.')
            if isinstance(pat, SimplePattern):
                # strip "'"
                content = pat.content[1:-1].replace("\\\\", '\\').replace("\\'", "'").replace("\\n", '\n').replace("\\t", '\t').replace('\\r', '\r').replace('\\f', '\f').replace('\\v', '\v').replace('\\a', '\a').replace('\\b', '\b')
                if text.startswith(content):
                    length = len(content)
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
                    return {content.content: None}, text
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
                        if each.content in parsed_dict:
                            if not isinstance(parsed_dict[each.content], ParsedList):
                                parsed_dict[each.content] = ParsedList([parsed_dict[each.content]])
                            parsed_dict[each.content].append(parsed)
                        else:
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
            raise Exception("expected EOF, the rest is '''{}'''".format(rest))
        self.tree = {name_entry: tree}

    def to_json(self):
        return json.dumps(self.tree, indent=4, cls=TreeJsonEncoder)
    
    def output(self):
        print(json.dumps(self.tree, indent=4))
    
    def save_json(self, save_dir="", filename=""):
        if save_dir == "":
            save_dir = os.path.join(".", "syntax", "out", "json")
        if filename == "":
            filename = 'basic_finer'
        filename = os.path.join(save_dir, filename + '.tree.json')
        # if not os.path.exists(os.path.join(save_dir, 'json')):
            # os.makedirs(os.path.join(save_dir, 'json')) 
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.to_json())


if __name__ == '__main__':
    reader = BasicFiner(SYNTAXPATH)
    reader.fine(FILEPATH, ENTRY)
    reader.save_json(SAVE_DIR)
