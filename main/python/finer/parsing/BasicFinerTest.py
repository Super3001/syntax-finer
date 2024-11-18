import sys
import os
from BasicFiner import BasicFiner

PROJ_ROOT = r"E:\BaiduSyncdisk\research\cockroach"

os.chdir(PROJ_ROOT)
print("cwd:", os.getcwd())

SYNTAXPATH = r"traj.modeling\points.raw.syntax"
FILEPATH = r"traj.modeling\out-feature-1.txt"
SAVE_DIR = r"traj.modeling\out"

def test1():
    reader = BasicFiner(SYNTAXPATH)
    reader.syntax_reader.save_json(SAVE_DIR, "test1")
    reader.fine(FILEPATH, "$file")
    reader.save_json(SAVE_DIR, "test1")
    
    
if __name__ == "__main__":
    test1()
    sys.exit(0)
