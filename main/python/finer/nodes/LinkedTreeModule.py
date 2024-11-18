
import re

class LinkedPattern:
    pass

class LinkedNamePattern(LinkedPattern):
    def __init__(self, string: str, content=None) -> None:
        super().__init__()
        self.name = string
        self.content = content
        