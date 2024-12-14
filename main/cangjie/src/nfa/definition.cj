
package simple_finer.nfa

import simple_finer.context.Context
import simple_finer.ext.*

protected enum NfaNode {
    | Single(NfaNode, Rune, Int)
    | Sequence(NfaNode, String, Int)
    | Set(NfaNode, List<Rune>, Int)
    | Regex(NfaNode, String, Int)
    | Branch(NfaNode, NfaNode, Int)
    | Merge(NfaNode)
    | Forward(NfaNode, NfaNode, Int)
    | Backward(NfaNode, Connector, Int)
    | Start(NfaNode, Int)
    | EmptyNode
    | End

    public func getId(): Int {
        match (this) {
            case Single(_, _, id) => id
            case Sequence(_, _, id) => id
            case Set(_, _, id) => id
            case Regex(_, _, id) => id
            case Branch(_, _, id) => id
            case Merge(nxt) => nxt.getId()
            case Forward(_, _, id) => id
            case Backward(_, _, id) => id
            case Start(_, id) => id
            case EmptyNode => -1
            case End => 0
        }
    }
}

protected class Connector {
    private var _id: Int = -1
    private var _dest: NfaNode = EmptyNode

    public mut prop id: Int {
        get() {
            _id
        }
        set(value) {
            _id = value
        }
    }

    public mut prop dest: NfaNode {
        get() {
            _dest
        }
        set(value) {
            _dest = value
        }
    }

    public init() {}
    public init(id: Int, dest: NfaNode) {
        this._id = id
        this._dest = dest
    }
}

extend NfaNode <: ToString {
    public func toString(): String {
        match (this) {
            case Single(nxt, ch, id) => "<${id}> Single{c'${ch}'} -> <${nxt.getId()}>"
            case Sequence(nxt, s, id) => "<${id}> Sequence{s'${s}'} -> <${nxt.getId()}>"
            case Set(nxt, l, id) => "<${id}> Set{[${l.join('')}]} -> <${nxt.getId()}>"
            case Regex(nxt, s, id) => "<${id}> Regex{/${s}/} -> <${nxt.getId()}>"
            case Branch(fst, snd, id) => "<${id}> Branch{<${fst.getId()}>} -> <${snd.getId()}>"
            case Merge(nxt) => "<-2> Merge -> <${nxt.getId()}>"
            case Forward(near, far, id) => "<${id}> Forward{<${far.getId()}>} -> <${near.getId()}>"
            case Backward(nxt, conn, id) => "<${id}> Backward{<${conn.id}>} -> <${nxt.getId()}>"
            case Start(nxt, id) => "<${id}> Start -> <${nxt.getId()}>"
            case EmptyNode => "<-1> EmptyNode."
            case End => "<0> End."
        }
    }
}

extend NfaNode {
    public func stringifyNfa(): String {

        func nfa2string(node: NfaNode): String {

            match (node) {
                case Start(nxt, id) => "Nfa: \n<${id}> Start ->" + nfa2string(nxt)
                case Single(nxt, ch, id) => "\n<${id}> c'${Context.printable(ch)}' -> " + nfa2string(nxt)
                case Sequence(nxt, s, id) => "\n<${id}> s'${s}' -> " + nfa2string(nxt)
                case Set(nxt, l, id) => "\n<${id}> [${l.join('')}] -> " + nfa2string(nxt)
                case Regex(nxt, s, id) => "\n<${id}> /${s}/ -> " + nfa2string(nxt)
                case Branch(fst, snd, id) => match (fst) {
                    case n where n.getId() >= 0 => "\n<${id}> => <${fst.getId()}> -> " + nfa2string(snd) + nfa2string(fst)
                    case _ => println("<${id}> Branch connect to Start or EmptyNode!!!"); "\n<${id}> => <???> -> " + nfa2string(snd)
                }
                case Merge(nxt) => "<${nxt.getId()}>"
                case Forward(near, far, id) => "\n<${id}> => <${far.getId()}> -> " + nfa2string(near)
                case Backward(nxt, conn, id) => "\n<${id}> => <${conn.id}> -> " + nfa2string(nxt)
                case EmptyNode => "\n()."
                case End => "\n<0> End."
            }
        }

        nfa2string(this)   
    }
}
