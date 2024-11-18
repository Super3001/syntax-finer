
# logspec_reader
# date: 20240712
# version: 1.0.0

FILEPATH = r"syntax\demo\forwardx\process.log.spec"
SAVE_DIR = r"syntax\interpreter\out"

import sys
import os
import re
import json
sys.path.append(os.path.dirname(sys.path[0]))

from reader import TextReaderTree

pat_paragraph_header = re.compile('//[^\n]*\n')
pat_paragraph_metadata = re.compile('[#%]\\(\\w?[, ?\\w]*\\)\n|%-> ?\\w*\n')
pat_item_header = re.compile('\n[ \\t]*- \\([\\.\\+\\|>][, ?\\.\\+\\|>]*\\)')
pat_itemcond_symbol1 = re.compile(' ?::= ?')
pat_itemcond_symbol2 = re.compile(' ?:=> ?')
pat_itemcond_header = re.compile(" ?::= ?| ?:=> ?|\n[ \t]*=> ?")
pat_source_code_pos = re.compile(r'\{"?[^"]*"?\[\d+,? ?\d*\]\}|\{ ?\? ?\}')
# pat_filepath = '[^\\\\/:\\*\\?"<>\\|\n\t]+'


class LogspecReader(TextReaderTree):
    def __init__(self, filepath) -> None:
        super().__init__(filepath)
        self.specs = []

    def clean(self):
        ...

    def parse(self, text="", scope="file"):
        print(".")
        if scope == "file":
            self.specs = self.split_by_header(pat_paragraph_header, self.text)
            for each in self.specs:
                if each["header"]:
                    each["content"] = self.parse(each["content"], "spec")
                    # each["content"] = self.split_metadata(pat_paragraph_metadata, each["content"])
                    # each["content"] = self.parse(, "item")
            self.tree = self.specs
            # return self.tree
        elif scope == "spec":
            spec = self.split_metadata(pat_paragraph_metadata, text=text)
            if spec["content"]:
                spec["content"] = self.parse(spec["content"], "item")
            return spec
        elif scope == "item":
            item = self.split_by_header(pat_item_header, text=text)
            for each in item:
                if each["content"]:
                    each["content"] = self.parse(each["content"], "itemcond")
            return item
        elif scope == "itemcond":      
            itemcond = self.split_by_header(pat_itemcond_header, text=text)
            if itemcond[0]["header"] == "":
                itemcond[0]["content"] = self.parse(itemcond[0]["content"], "source_code")
            return itemcond   
        elif scope == "source_code":
            source_code = self.split_by_given_name(pat_source_code_pos, text, "pos", "code")
            return source_code

    @property 
    def ast(self):
        return self.tree
    

if __name__ == '__main__':
    filepath = FILEPATH
    save_dir = SAVE_DIR

    reader = LogspecReader(filepath)

    reader.parse()

    reader.save_json(os.path.join(save_dir, "json"))
