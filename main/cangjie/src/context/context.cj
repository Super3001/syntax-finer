
package simple_finer.context

import std.collection.{HashMap, HashSet}


protected class Context {
    static let _testSet = HashSet<Int>()

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
            case _ => c.toString()
        }
    }

}
