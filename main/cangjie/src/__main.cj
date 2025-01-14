package simple_finer

import std.console.*
import simple_finer.ext.*
import simple_finer.regex.{evalToken as evalTokenRegex, evalExpression as evalExprRegex /*, evalNfa as evalNfaRegex */ }
import std.fs.File

func readFile(path: String): Result<String, String> {
    let bytesBuf = File.readFrom(path)
    let str = match(String.fromUtf8(bytesBuf)) {
        case str where str.endsWith('\n') => str.replace("\r\n", "\n")
        case str => str.replace("\r\n", "\n") + '\n'
    }
    Ok(str)
}

extend<T> Option<T> {
    public func okOr<E>(e: E): Result<T, E> {
        match (this) {
            case Some(v) => Ok(v)
            case None => Err(e)
        }
    }
}

main() {
    println(
        """
###################################################
##  this is a simple finer                       ##
##  press Ctrl-C to exit                         ##
###################################################"""
    )

    while (true) {
        println("please input .syntax file:")
        // Console.stdIn.readln().okOr("Invalid Input!").andThen(readFile).andThen(evalNfa)

        let entry = Console.stdIn.readln().okOr("Invalid Input!").andThen(readFile).andThen(fileEntryFromString).getOrThrow("")
        println("please input text file:")
        let text = Console.stdIn.readln().okOr("Invalid Input!").andThen(readFile).getOrThrow("")
        Finer.StringAndNfa(text, entry).fine()
    }
    ()
}

// E:/BaiduSyncdisk/modeling/syntax/demo/base.syntax
// E:/BaiduSyncdisk/modeling/syntax/demo/syntaxDef.syntax
// E:/BaiduSyncdisk/modeling/syntax/demo/test.syntax