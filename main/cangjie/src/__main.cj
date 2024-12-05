package simple_finer

import std.console.*
import simple_finer.ext.*
import std.fs.File

func readFile(path: String): Result<String, String> {
    let bytesBuf = File.readFrom(path)
    let str = match(String.fromUtf8(bytesBuf)) {
        case str where str.endsWith('\n') => str.replace("\r\n", "\n")
        case str => str.replace("\r\n", "\n") + '\n'
    }
    // println("str: ${str}")
    Ok(str)
}

main() {
    println(
        """
###################################################
##  this is a simple finer                       ##
##                                               ##
##  please input .syntax file path               ##
##  press Ctrl-C to exit                         ##
###################################################
"""
    )

    while (true) {
        Console.stdIn.readln().okOr("Invalid Input!").andThen(readFile).andThen(evalExpression).mapErr(println)
    }
    // Result<String, String>.Ok("E:/BaiduSyncdisk/modeling/syntax/demo/base.syntax").andThen(readFile).andThen(evalExpression).mapErr(println)
    ()
}
