
import sys
import os
import json
import pickle

sys.path.append(os.path.dirname(sys.path[0]))

from nodes.TreeModule import *
from nodes.TreeEncoder import TreeJsonEncoder
from SyntaxImport import SyntaxImporter

BASE_DIR = r"E:\BaiduSyncDisk\modeling\\syntax"
FILEPATH = BASE_DIR + r"\\demo\base.syntax"
PROJ_DIR = BASE_DIR + r"\\main\\python"
SAVE_DIR = PROJ_DIR + r"\\out"
OBJECT_DIR = SAVE_DIR + "\\object"
OBJECT_DIR_GLOBAL = OBJECT_DIR+ "\\global"

class SyntaxReader:
    '''
    demo$base.syntax.pkl
    imported: demo$base$.syntax.pkl
    builtin: $base$.syntax.pkl
    '''
    def __init__(self, filepath, save=True) -> None:
        names = {}
        metadata = {}
        import_list = []

        for each in open(filepath, 'r', encoding='utf-8').readlines():
            each = each.strip()
            if not each:
                continue
            if each.startswith("[") and each.endswith("]"):
                key, value = each[1:-1].split(' ', 1)
                metadata[key] = value
            if each.startswith("import "):
                import_list.append(each[7:])
            if " ::= " in each:
                name, pattern = each.split(" ::= ", 1)
                if name in names:
                    raise Exception(f"Syntax name {name} already exists")
                if "[" in name and name.endswith("]"):
                    name, view = name[:-1].split("[")
                    names[name] = {
                        "view": view,
                        "pat": SyntaxPattern.buildfrom(pattern)
                    }
                else:
                    names[name] = {
                        "view": None,
                        "pat": SyntaxPattern.buildfrom(pattern)
                    }

        if save:
            tree = {
                "metadata": metadata,
                "names": names,
            }
            filename = filepath.replace(os.sep, '$') + '.pkl'
            if os.path.exists(OBJECT_DIR):
                object_dir = OBJECT_DIR
            else:
                object_dir = OBJECT_DIR_GLOBAL
            with open(os.path.join(object_dir, filename), 'wb') as f:
                pickle.dump(tree, f)

        importer = SyntaxImporter(sys.path[0])
        for each in import_list:
            names = importer.conbine(self, names, each)

        self.tree = {
            "metadata": metadata,
            "names": names,
        }

    def to_json(self):
        return json.dumps(self.tree, indent=4, cls=TreeJsonEncoder)

    def save_json(self, save_dir="", filename=""):
        if save_dir == "":
            save_dir = os.path.join(".", "syntax", "out")
        filename = os.path.join(save_dir, 'json', "syntax_reader@" + filename + '.json')
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.to_json())


if __name__ == '__main__':
    reader = SyntaxReader(FILEPATH, True)
    reader.save_json(SAVE_DIR, os.path.basename(FILEPATH))
    