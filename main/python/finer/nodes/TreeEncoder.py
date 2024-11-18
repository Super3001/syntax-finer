import json

from nodes.TreeModule import SyntaxPattern
from utils.DefinedClasses import ParsedList

class TreeJsonEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, SyntaxPattern):
            return str(obj)
        if isinstance(obj, ParsedList):
            return list(obj)
        return super().default(obj)
