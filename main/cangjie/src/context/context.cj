
package simple_finer.context

import std.collection.{HashSet, ArrayList}
import simple_finer.ext.List

protected class Context {
    static let _testSet = HashSet<Int>()
    static let _nameMap = ArrayList<String>()

    protected static func clearSet(): Unit {
        _testSet.clear()
    }

    protected static func testAndSetFunc(id: Int): Bool {
        if (!_testSet.put(id)) {
            return false
        }
        return true
    }

    protected static func unsetFunc(id: Int): Bool {
        if (!_testSet.remove(id)) {
            return false
        }
        return true
    }

    protected static func printable(c: Rune): String {
        match (c) {
            case r'\n' => "\\n"
            case r'\t' => "\\t"
            case r'\r' => "\\r"
            case r'\0' => "<EOF>"
            case _ => c.toString()
        }
    }

    protected static func printable(s: String): String {
        var res = List<String>.empty()
        for (ch in s.runes()) {
            res = res.add(printable(ch))
        }
        res.reverse().join('')
    }

    protected static func jsonEscapeChar(c: Rune): String {
        match (c) {
            case r'\n' => "\\n"
            case r'\t' => "\\t"
            case r'\r' => "\\r"
            case r'\\' => "\\\\"
            case _ => c.toString()
        }
    }

    protected static func jsonEscapeString(s: String): String {
        var res = List<String>.empty()
        for (ch in s.runes()) {
            res = res.add(jsonEscapeChar(ch))
        }
        res.reverse().join('')
    }
}
