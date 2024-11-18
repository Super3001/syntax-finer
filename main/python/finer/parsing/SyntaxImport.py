
import os, sys

SUFFIX = ".syntax"

IMPORT_NAME = 'base'
SYNTAX_PATH = r"E:\BaiduSyncdisk\modeling\syntax"

IMPORT_PATH = [sys.path[0], SYNTAX_PATH]
IMPORT_PATH_RECUR = [SYNTAX_PATH]

class SyntaxImporter:
    '''
import支持：
dot_separator: demo.base
wildcard pattern: demo.* | *.base (with no recursive import)
special symbols: . => .syntax | [] => .*.syntax (with no recursive import)
TODO: comma composition: demo.base, demo.items
'''
    suffix_ = SUFFIX
    dot_symbol = '.'
    dotall_symbol = '[]'
    wildcard = '*'
    
    def __init__(self, import_path, import_path_recur=IMPORT_PATH_RECUR) -> None:
        self.import_path = import_path
        self.import_path_recur = import_path_recur

    def resolve0(self, root_dir, objfile: str):
        if os.sep in objfile:
            dirname = objfile.split(os.sep)[0]
            if dirname == self.wildcard:
                res = []
                for each in os.listdir(root_dir):
                    if os.path.isdir(each):
                        res.extend(self.resolve0(os.path.join(root_dir, dirname), objfile[2:]))
                return res
            if dirname in os.listdir(root_dir) and os.path.isdir(os.path.join(root_dir, dirname)):
                return self.resolve0(os.path.join(root_dir, dirname), objfile[len(dirname)+1:])
            return []
        else:
            if objfile == self.wildcard + self.suffix_:
                res = []
                for each in os.listdir(root_dir):
                    if os.path.isfile(each) and each.endswith(self.suffix_):
                        res.append(each)
                return res
            if objfile in os.listdir(root_dir) and os.path.isfile(os.path.join(root_dir, objfile)):
                return [os.path.join(root_dir, objfile)]
            return []

    def resolve1(self, root_dir, objfile):
        for each in os.listdir(root_dir):
            if each == objfile and os.path.isfile(each):
                return [os.path.join(root_dir, each)]
        for eachdir in os.listdir(root_dir):
            if os.path.isdir(eachdir):
                eachdir = os.path.join(root_dir, eachdir)
                res = self.resolve1(eachdir, objfile)
                if res:
                    return res
        return []
    
    def resolve_from_file(self, filepath, recur=True):
        wild = False
        if self.wildcard in filepath:
            wild = True
        res = []
        try:
            for path in IMPORT_PATH:
                res.extend(self.resolve0(path, filepath))
                if len(res) > 0: # wild suppresses recursive
                    return res
            if recur and not wild:
                for root_dir in IMPORT_PATH_RECUR:
                    for dirpath, dirnames, filenames in os.walk(root_dir):
                        for each in filenames:
                            fullpath = os.path.join(dirpath, each)
                            if fullpath.endswith(filepath) and fullpath[-(len(filepath)+1)] == os.sep:
                                return [os.path.join(dirpath, each)]
        except Exception as e:
            print("No Such path: {}".format(e))
        return []
    
    # 将import_name中的'.'换为操作系统具体的路径分隔符，并解析
    def resolve_from_name(self, name):
        if name == self.dot_symbol:
            return self.resolve_from_file(self.suffix_, recur=False)
        if name == self.dotall_symbol:
            return self.resolve_from_file(self.wildcard + self.suffix_)
        platform_specific =  os.path.join(*name.split('.'), recur=False)
        filename = platform_specific + self.suffix_
        return self.resolve_from_file(filename)
    
    def combline(names, import_name):
        pass


if __name__ == "__main__":
    name = IMPORT_NAME
    filename = name + SUFFIX
    importer = SyntaxImporter(IMPORT_PATH, IMPORT_PATH_RECUR)
    print(importer.resolve1(filename))
