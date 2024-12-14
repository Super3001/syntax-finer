
package simple_finer.ext

extend Rune {
    func isAlnum(): Bool {
        this.isAsciiNumberOrLetter() || this == r'_'
    }
}

extend String {
    func isAlnum(): Bool {
        for (c in this.runes()) {
            match {
                case c.isAlnum() => ()
                case _ => return false
            }
        }
        return true
    }
}
