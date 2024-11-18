sealed abstract class Position {}

public open class Positioned {
    Positioned(var pos!:Position = NoPosition()) {}
    func getPos(): Position {this.pos}
    func setPos(pos:Position): Unit {this.pos = pos}
}

class SourcePostion <: Position {
    SourcePostion(let file:String, let line: Int, let col: Int) {}
    func toString():String {"${this.file}:${this.line}:${this.col}"}
}

class NoPosition <: Position {
    func toString():String {"?:?"}
}

main() {
    
}
