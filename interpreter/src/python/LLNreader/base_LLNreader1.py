
import json

# FILEPATH = r"syntax\demo\items.syntax"
FILEPATH = r"D:\data-platform\collect\跳板机.txt"
SAVE_DIR = r"syntax\interpreter\out"


def view(behaviour: str):
    def decorator(func):
        return func
    return decorator

def EOF(text):
    if text:
        raise Exception("Unexpected Token {}, expect <EOF>".format(text[0]))
    
@view("preserve")
def LINE(text, rollback=False):
    if not text:
        if rollback:
            return '', text
        raise Exception("Null Element {}".format("LINE"))
    if text[0] in [' ', '\n', '\t']:
        if rollback:
            return '', text
        raise Exception("Unexpected Token {}, expect /\\S/".format(text[0]))
    idx = text.find('\n')
    if idx == -1:
        return text, ''
    else:
        return text[:idx], text[idx:]
    
@view("drop")
def LineBlank(text, rollback=False):
    lineblank = ''
    i = 0
    while i < len(text):
        if text[i] in [' ', '\n', '\t']:
            lineblank += '\\' + hex(ord(text[i]))[1:]
            i += 1
        else:
            break
    return lineblank, text[i:]

@view("drop")
def NL(text, rollback=False):
    if not text:
        if rollback:
            return '', text
        raise Exception("Null Element {}".format("NL"))
    if text[0] not in ['\n']:
        if rollback:
            return '', text
        raise Exception("Unexpected Token {}, expect '\n'".format(text[0]))
    return text[0], text[1:]
    
@view("fold")
def LineSpace(text, rollback=False):
    lineblank, rest = LineBlank(text, rollback=rollback)
    line, rest = LINE(rest, rollback=rollback)
    if line:
        # return {
        #     "LineBlank": lineblank,
        #     "LINE": line
        # }, rest
        return line, rest
    else:
        if rollback:
            return None, text

@view("fold")
def LineFull(text, rollback=False):
    linespace, rest = LineSpace(text, rollback)
    nl, rest = NL(rest, rollback)
    if linespace and nl:
        # return {
        #     "LineSpace": linespace,
        #     "NL": nl
        # }, rest
        return linespace, rest
    else:
        if rollback:
            return None, text

@view("file")
def File(text, rollback=False):
    LineFullList = []
    rest = text
    while rest:
        linefull, rest = LineFull(rest, rollback=True)
        if linefull:
            LineFullList.append(linefull)
        else:
            break
    lineblank, rest = LineBlank(rest)
    EOF(rest)
    # return {
    #     "LineFull": LineFullList,
    #     "LineBlank": lineblank
    # }
    return {
        "lines": LineFullList
    }

if __name__ == '__main__':
    filepath = FILEPATH
    save_dir = SAVE_DIR
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
        # 以空行结尾
        if not text.endswith('\n'):
            text = text + '\n'

    tree = File(text)
    
    # print(json.dumps(tree, indent=4))
    filename = save_dir + '/json/base_LLNreader1.tree.json'
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(json.dumps(tree, indent=4))
    