
package simple_finer

import simple_finer.ext.*

public class Printer {    
    static func printRes(res: Result<List<SyntaxExpr>, String>) {
        res.map { l => println(l.join('\n')) }
    }

    static func printRes(res: Result<List<Token>, String>) {
        res.map { l => println(l.join('\n')) }
    }

}