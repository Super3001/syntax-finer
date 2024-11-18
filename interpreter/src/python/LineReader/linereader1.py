
import sys
import os
sys.path.append(os.path.dirname(sys.path[0]))

from reader import TextReaderLine

FILEPATH = r"E:\BaiduSyncdisk\modeling\syntax\demo\forwardx\ruixing.less.out"
SAVE_DIR = r"syntax\interpreter\out"

def callback1(tree, mobj, line):
    if "watchdog_cmd" not in tree:
        tree["watchdog_cmd"] = []
    tree["watchdog_cmd"].append(line)
    return tree

def callback2(tree, mobj, line):
    if "es_error" not in tree:
        tree["es_error"] = []
    idx = len(tree["es_error"])
    tree["es_error"].append({})
    tree["es_error"][idx]["errmsg"] = mobj.group(2)
    tree["es_error"][idx]["es_action"] = mobj.group(1)
    return tree

def callback3(tree, mobj, line):
    if "pyerr" not in tree:
        tree["pyerr"] = []
    tree["pyerr"].append(mobj.group(2))
    return tree

_ = [
    {
        "method": "re",
        "pat": r"^\++ ",
        "callback": callback1
    },
    {
        "method": "re",
        "pat": r"^es( \\w*)? exception, (.*)",
        "callback": callback2
    },
    {
        "method": "re",
        "pat": r"^Traceback \(most recent call last\):\n(\s.*\n)*(.*)",
        "callback": callback3
    }
]

reader = TextReaderLine(FILEPATH)

for each in _:
    reader.register(each)

reader.parse()
reader.save_json(SAVE_DIR, "linereader1.tree.json")
