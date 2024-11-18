
class Position:  
    LINE_BITS = 20
    COLUMN_BITS = 31 - LINE_BITS
    LINE_MASK = (1 << LINE_BITS) - 1
    COLUMN_MASK = (1 << COLUMN_BITS) - 1

    def lineOf(self, pos): 
        return (pos >> self.COLUMN_BITS) & self.LINE_MASK
    def columnOf(self, pos): 
        return pos & self.COLUMN_MASK

    
class SourcePosition(Position):
    def __init__(self,file:str, line: int, col: int) -> None:
        self.file = file
        self.line = line
        self.col = col

    def __str__(self) -> str:
        return "{}:{}:{}".format(self.file, self.line, self.col)

class NoPosition(Position):
    def __str__(self) -> str:
        return "?:?"


class Positioned:
    pass

class Positioned:
    def __init__(self) -> None:
        self.pos_: Position = NoPosition()

    def hasPosition(self):
        return isinstance(self.pos_, NoPosition)
    
    @property
    def pos(self):
        return self.pos_

    def setPos(self, other: Position | Positioned):
        if isinstance(other, Positioned):
            return self.setPos(other.position)
        else:
            self.pos_ = other
            return self
    