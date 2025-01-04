
package simple_finer.nfa

import simple_finer.context.Context
import simple_finer.ext.*

public enum TMod {
    | File
    | F
    | Dict
    | List
    | Str
    | Intt
    | Booll
    | Undefined(String)
}

extend TMod <: ToString {

    public func toString(): String {
        match (this) {
            case File => "File"
            case F => "F"
            case Dict => "Dict"
            case List => "List"
            case Str => "Str"
            case Intt => "Int"
            case Booll => "Bool"
            case Undefined(s) => "Tmod{${s}}(Undefined!)"
        }
    }
}

// protected type Idklass = Int
protected type Idklass = String

protected enum NfaNode {
    | Single(NfaNode, Rune, Int)
    | All(NfaNode, Int)
    | Sequence(NfaNode, String, Int)
    | Set(NfaNode, Rec, Int)
    | InvSet(NfaNode, Rec, Int)
    | Regex(NfaNode, String, Int)
    | Branch(NfaNode, NfaNode, Int)
    | Merge(NfaNode)
    | Forward(NfaNode, NfaNode, Int)
    | Backward(NfaNode, Connector, Int)
    | AssertAhead(NfaNode, NfaNode, Int)
    | AssertBack(NfaNode, NfaNode, Int)
    | AssertEnd(Int)
    | Start(NfaNode, Int)
    | EmptyNode
    | End
    | Tracker(NfaNode, Idklass, TMod, Int) // name number constant
    | TrackerEnd(NfaNode, Idklass, Int) // end of the tracker name

    public func getId(): Int {
        match (this) {
            case Single(_, _, id) => id
            case All(_, id) => id
            case Sequence(_, _, id) => id
            case Set(_, _, id) => id
            case InvSet(_, _, id) => id
            case Regex(_, _, id) => id
            case Branch(_, _, id) => id
            case Merge(nxt) => nxt.getId()
            case Forward(_, _, id) => id
            case Backward(_, _, id) => id
            case AssertAhead(_, _, id) => id
            case AssertBack(_, _, id) => id
            case AssertEnd(id) => id
            case Start(_, id) => id
            case EmptyNode => -1
            case End => 0
            case Tracker(_, _, _, id) => id
            case TrackerEnd(_, _, id) => id
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
            case All(nxt, id) => "<${id}> All -> <${nxt.getId()}>"
            case Sequence(nxt, s, id) => "<${id}> Sequence{s'${s}'} -> <${nxt.getId()}>"
            case Set(nxt, rec, id) => "<${id}> Set{${rec.name}} -> <${nxt.getId()}>"
            case InvSet(nxt, rec, id) => "<${id}> InvSet{${rec.name}} -> <${nxt.getId()}>"
            case Regex(nxt, s, id) => "<${id}> Regex{/${s}/} -> <${nxt.getId()}>"
            case Branch(fst, snd, id) => "<${id}> Branch{<${fst.getId()}>} -> <${snd.getId()}>"
            case Merge(nxt) => "<-2> Merge -> <${nxt.getId()}>"
            case Forward(near, far, id) => "<${id}> Forward{<${far.getId()}>} -> <${near.getId()}>"
            case Backward(nxt, conn, id) => "<${id}> Backward{<${conn.id}>} -> <${nxt.getId()}>"
            case AssertAhead(nxt, anxt, id) => "<${id}> AssertAhead{<${nxt.getId()}>} -> <${anxt.getId()}>"
            case AssertBack(nxt, anxt, id) => "<${id}> AssertBack{<${nxt.getId()}>} -> <${anxt.getId()}>"
            case AssertEnd(id) => "<-3> AssertEnd{~<${id}>}."
            case Start(nxt, id) => "<${id}> Start -> <${nxt.getId()}>"
            case EmptyNode => "<-1> EmptyNode."
            case End => "<0> End."
            case Tracker(nxt, name, mod, id) => "<${id}> Tracker{${name}, ${mod}} -> <${nxt.getId()}>"
            case TrackerEnd(nxt, name, id) => "<${id}> TrackerEnd{~(${name})}"
        }
    }
}

extend NfaNode {
    public func stringifyNfa(): String {

        var tabSpace = ""
        func tabIn(): String {
            tabSpace = tabSpace + "\t"
            ""
        }
        func tabOut(): String {
            tabSpace = tabSpace[0..tabSpace.size-1]
            ""
        }

        func nfa2string(node: NfaNode): String {

            match (node) {
                case Start(nxt, id) => "Nfa: \n<${id}> Start ->" + nfa2string(nxt)
                case Single(nxt, ch, id) => "\n${tabSpace}<${id}> c'${Context.printable(ch)}' -> " + nfa2string(nxt)
                case All(nxt, id) => "\n${tabSpace}<${id}> All ->" + nfa2string(nxt)
                case Sequence(nxt, s, id) => "\n${tabSpace}<${id}> s'${s}' -> " + nfa2string(nxt)
                case Set(nxt, rec, id) => "\n${tabSpace}<${id}> [${rec.name}] -> " + nfa2string(nxt)
                case InvSet(nxt, rec, id) => "\n${tabSpace}<${id}> ^[${rec.name}] -> " + nfa2string(nxt)
                case Regex(nxt, s, id) => "\n${tabSpace}<${id}> /${s}/ -> " + nfa2string(nxt)
                case Branch(fst, snd, id) => match (fst) {
                    case n where n.getId() >= 0 => "\n${tabSpace}<${id}> => <${fst.getId()}> -> " + nfa2string(snd) + nfa2string(fst)
                    case _ => println("<${id}> Branch connect to Start or EmptyNode!!!"); "\n<${id}> => <???> -> " + nfa2string(snd)
                }
                case Merge(nxt) => "<${nxt.getId()}>"
                case Forward(near, far, id) => "\n${tabSpace}<${id}> => <${far.getId()}> -> " + nfa2string(near)
                case Backward(nxt, conn, id) => "\n${tabSpace}<${id}> => <${conn.id}> -> " + nfa2string(nxt)
                case AssertAhead(nxt, anxt, id) => "\n${tabSpace}Assert(->) <${id}> => <${nxt.getId()}> -> " + nfa2string(anxt) + nfa2string(nxt)
                case AssertBack(nxt, anxt, id) => "\n${tabSpace}Assert(<-) <${id}> => <${nxt.getId()}> -> " + nfa2string(anxt) + nfa2string(nxt)
                case AssertEnd(id) => "(~<${id}>)."
                case EmptyNode => "\n${tabSpace}()."
                case End => "\n<0> End."
                case Tracker(nxt, name, mod, id) => "\n${tabSpace}<${id}> Tracker{${name}, ${mod}} -> " + tabIn() + nfa2string(nxt)
                case TrackerEnd(nxt, name, id) => tabOut() + "\n${tabSpace}<${id}> TrackerEnd{${name}} -> " + nfa2string(nxt)
            }
        }

        nfa2string(this)
    }
}
