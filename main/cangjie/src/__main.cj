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
    Ok(str)
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
        let str = Console.stdIn.readln().okOr("Invalid Input!").andThen(readFile)
        str.andThen(evalNfa).mapErr(println)
        // let symbolic = str.andThen(Token.fromString).andThen(SyntaxExpr.fromTokens).andThen(SyntaxExpr.resolveLinks).andThen(nominalToSymbolicPattern)
        // symbolic.map(printOut)
        // symbolic.andThen(NfaEntry.generateFirstFile).map(printOut)
    }
    // Result<String, String>.Ok("E:/BaiduSyncdisk/modeling/syntax/demo/base.syntax").andThen(readFile).andThen(evalNfa).mapErr(println)
    ()
}

// E:/BaiduSyncdisk/modeling/syntax/demo/base.syntax
// E:/BaiduSyncdisk/modeling/syntax/demo/syntaxDef.syntax