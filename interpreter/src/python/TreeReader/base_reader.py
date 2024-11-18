import sys
import os
sys.path.append(os.path.dirname(sys.path[0]))

from reader import TextReaderTree

pat_NL = '\n'

class BaseReader(TextReaderTree):
    def __init__(self, path):
        super().__init__(path)
        
    
    def parse(self, text="", scope="toplevel"):
        if scope == "toplevel":
            self.tree = self.parse(self.text, "file")
        if scope == "file":
            tree = {
                "Linespace": [],
                "ending": None
            }
            while pat_NL in text:
                head, NL, tail = self.take_one_turn(pat_NL, text)
                tree["Linespace"].append({
                    "LINE": head,
                    "NL": NL
                })
                text = tail
            tree["ending"] = text
            return tree
        