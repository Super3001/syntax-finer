import re
import json
import os

class TextReader:
    def __init__(self, filepath) -> None:
        self.filepath = filepath
        with open(filepath, 'r', encoding='utf-8') as f:
            self.text = f.read()
            # 以空行结尾
            if not self.text.endswith('\n'):
                self.text = self.text + '\n'
        # 进行预处理
        self.clean()
        self.tree = None

    def clean(self):
        ...
        
    def short_text(self, text: str):
        return text[:100] + "..." if len(text) > 100 else text

    def parse(self) -> None:
        ...

    def to_json(self):
        return json.dumps(self.tree, indent=4)

    def output(self):
        print(json.dumps(self.tree, indent=4))
    
    def save_json(self, save_dir="", filename=""):
        if filename == "":
            filename = os.path.basename(self.filepath) + '.tree.json'
        filename = os.path.join(save_dir, 'json', filename)
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.to_json())
          
class TextReaderLinear(TextReader):
    pass         

class TextReaderLLN(TextReader):
    
    def __init__(self, filepath) -> None:
        super().__init__(filepath)
        self.length = len(self.text)
        self.cur: int = 0

    def peek(self) -> str:
        return self.text[self.cur: self.cur+1]
    
    def consume(self):
        char = self.peek()
        self.cur = min(self.cur + 1, self.length)
        return char

    def look(self) -> str:
        return self.text[self.cur:]

    def forward(self, n: int) -> str:
        old = self.cur
        if n == -1:
            self.cur = self.length
        else:
            self.cur = min(old + n, self.length)
        return self.text[old: self.cur]
    
    def eof(self):
        return self.cur >= self.length

class TextReaderLine(TextReaderLLN):
    def __init__(self, filepath) -> None:
        super().__init__(filepath)
        self.func_list = []
        
    def forward_newline(self, from_where: int=0):
        idx = self.look()[from_where:].find('\n')
        return self.forward(idx)
        
    def register(self, callbackObject, priority='last'):
        if priority == 'last':
            self.func_list.append(callbackObject)
        elif priority == 'first':
            self.func_list.insert(0, callbackObject)
        
    def parse(self):
        self.tree = {}
        while not self.eof():
            for obj in self.func_list:
                if obj["method"] == "re":
                    matchObj = re.match(obj["pat"], self.look())
                    if matchObj:
                        line = self.forward_newline(matchObj.span()[1])
                        self.tree = obj["callback"](self.tree, matchObj, line)
                        break
            if self.peek() != '\n':
                self.forward_newline()
            self.consume()
                           
    
class TextReaderTree(TextReader):
    def __init__(self, filepath) -> None:
        super().__init__(filepath)

    def clean(self, text: str):
        raise NotImplementedError("Not implemented")

    def escape_front(self, esc_pat, text):
        if esc_pat is None:
            return text
        matchObj = re.search(esc_pat, text)
        if matchObj.span()[0] == 0:
            text = text[matchObj.span()[1]:]
        return text

    def split_by_header(self, pat, text):
        return self.split_by_given_name(pat, text=text, head_name="header", body_name="content")
    
    def split_by_given_name(self, pat, text, head_name="head", body_name="body"):
        matches = re.findall(pat, text)
        splits = re.split(pat, text)
        return [{head_name: x, body_name: y} for x, y in zip([''] + matches, splits) if x or y]
    
    def part_by_given_name(self, pat, text, pre_name="preface", body_name="main_body", mode="with"):
        matches = re.findall(pat, text)
        splits = re.split(pat, text)
        # with preface
        if mode == "with":
            if not splits[0]:
                return {pre_name: '', body_name: [x + y for x, y in zip(matches, splits[1:]) if x or y]}
            else:
                return {pre_name: splits[0], body_name: [x + y for x, y in zip(matches, splits[1:]) if x or y]}
        elif mode == "ignore":
            return [x + y for x, y in zip(matches, splits[1:]) if x or y]
        
    def part_multiple(self, text, name_pat_list: list[tuple[str, re.Pattern]], head_rest_name="head", mode="preserve", esc_pat=None):
        if mode not in ["preserve", "drop", "ignore", "strict"]:
            raise ValueError("mode must be one of 'preserve', 'drop', 'ignore', 'strict'")
        if esc_pat:
            self.escape_front(esc_pat=esc_pat, text=text)
        
        obj = {}
        for i in range(len(name_pat_list)):
            name, pat = name_pat_list[i]
            if i == 0:
                head, body, tail = self.take_one_turn(pat, text)
                if mode == "strict" and head:
                    raise ValueError("head not match: {} in {}".format(pat, self.short_text(text)))
                if mode == "preserve":
                    obj[head_rest_name] = head
                pre_name = name
            else:
                pre_body = body
                head, body, tail = self.take_one_turn(pat, tail)
                pre_body = pre_body + head
                obj[pre_name] = pre_body
                pre_name = name
        obj[name] = body + tail
        return obj

    def take_by_given_name(self, pat, text, head_name="head", body_name="body", tail_name="tail", mode="triple") -> dict[str, str]:
        matchObj = re.search(pat, text)
        span: tuple[int, int] = matchObj.span() if matchObj else (0, 0)
        # ignore body
        if mode == "ignore":
            return {head_name: text[:matchObj.span()[0]], tail_name: text[matchObj.span()[1]:]} if matchObj else {head_name: '', tail_name: text}
        # ignore head
        elif mode == "escape":
            return {body_name: text[matchObj.span()[0]:matchObj.span()[1]], tail_name: text[matchObj.span()[1]:]} if matchObj else {body_name: '', tail_name: text}
        # ignore tail
        elif mode == "drop":
            return {head_name: text[:matchObj.span()[0]], body_name: text[matchObj.span()[0]:matchObj.span()[1]]} if matchObj else {head_name: '', body_name: text}
        # preserve three parts
        elif mode == "merge_before":
            return {body_name: text[:span[1]], tail_name:text[span[1]:]} if matchObj else {body_name: '', tail_name: text}
        elif mode == "merge_after":
            return {head_name: text[:span[0]], body_name:text[span[0]:]} if matchObj else {head_name: '', body_name: text}
        elif mode == "triple":
            return {head_name: text[:span[0]], body_name: text[span[0]:span[1]], tail_name: text[span[1]:]} if matchObj else {head_name: '', body_name: '', tail_name: text}
        elif mode == "only":
            return {"body": text[span[0]:span[1]]} if matchObj else {"body": ''}
        else:
            raise ValueError("mode should be one of 'ignore', 'escape', 'drop', 'merge_before', 'merge_after', 'triple', 'only'")
        
    def take_one_turn(self, pat, text):
        matchObj = re.search(pat, text)
        span: tuple[int, int] = matchObj.span() if matchObj else (0, 0)
        return text[:span[0]], text[span[0]:span[1]], text[span[1]:]

    def start_by_given_name(self, pat, text, esc_pat=None):
        text = self.escape_front(esc_pat, text)
        matchObj = re.search(pat, text)
        if matchObj:
            span = matchObj.span()
            if span[0] == 0:
                return {"head": text[:span[1]], "body": text[span[1]:]}
            else:
                pass
        return {"head": '', "body": text}
        
    def end_by_given_name(self, pat, text, esc_pat=None):
        text = self.escape_back(esc_pat, text)
        matchObj = re.search(pat, text)
        if matchObj:
            span = matchObj.span()
            if span[1] == len(text):
                return {"body": text[:span[0]], "tail": text[span[0]:]}
            else:
                pass
        return {"body": text, "tail": ''}

    def split_metadata(self, pat, text, esc_pat=None):
        flag = True
        metadata = []
        if esc_pat:
            text = self.escape_front(esc_pat, text)
        while flag:
            matchObj = re.search(pat, text)
            if matchObj is None:
                break
            if matchObj.span()[0] > 0:
                break
            metadata.append(matchObj.group())
            text = text[matchObj.span()[1]:]
            text = self.escape_front(esc_pat, text) if esc_pat else text
        return {"metadata": metadata, "content": text}
    
    def extract_param(self, pat: str, text_list: list[str]):
        param_dict = {}
        for text in text_list:
            key, value = text.split(pat)
            param_dict[key] = value
        return param_dict

    def deal_direct(self, text, func):
        return func(text)
    
