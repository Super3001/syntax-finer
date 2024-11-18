import std.fs.{File, Path}
import std.math.max
import Node

open class Parser {
    let name: String
    let tree: Option<Node> = None // TreeNode("File")
    func parse(): Unit {}
    func toJson(): String {'"Not Implemented"'}
    func output(): Unit {println(toJson())}
    func saveJson(filepath!:Path = Path("./${this.name}.tree.json")): Unit {
        File.writeTo(filepath, toJson().toArray())
    }
    Parser(name: String) {this.name = name}
}

/*
encoding should be utf-8
*/
class BasicReader <: Parser{
    let text: String

    BasicReader(let filepath: Path, let save!: Bool = true) {
        super("BasicReader")
        text = match(String.fromUtf8(File.readFrom(filepath))) {
            case s where s.endsWith("\n") => s
            case w => w + "\n"
        }

    }

    func shortText(text: String) {
        text[Range(0, max(100, text.size), 1, true, true, false)]
    }

}
