# run.py

import argparse
import os
import sys

sys.path.append('./main/python/finer')
sys.path.append('./main/python/finer/parsing')
from main.python.finer.parsing.BasicFiner import BasicFiner

def main():
    # 创建解析器
    parser = argparse.ArgumentParser(description=' transform plain text to structural text (in json formmat), according to a dynamic BNF grammer template')

    parser.add_argument('syntax_file', help='the BNF definition')
    parser.add_argument('text_file', help='the text to parse')

    parser.add_argument('--interpret', action='store_true', help='use interpret version')
    
    args = parser.parse_args()

    # print(args)

    if args.interpret:
    
        finer = BasicFiner(args.syntax_file)
        # finer.syntax_reader.save_json(SAVE_DIR, "test1")
        finer.fine(args.text_file, "$file")
        finer.save_json('.', os.path.splitext(os.path.basename(args.text_file))[0])

    else:
        print("compile version still under development, please use --interpret instead")

if __name__ == '__main__':
    main()
