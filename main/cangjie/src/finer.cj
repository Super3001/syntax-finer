
package simple_finer

import simple_finer.ext.*

enum Finer {
    | WithSyntax(String)
    | WithNfa(NfaEntry)
}
