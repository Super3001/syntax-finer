package simple_finer.ext

public interface OptionExt {}

    /*
    // for cangjie below 0.57
    public func map<U>(f: (T) -> U): Option<U> {
        match (this) {
            case Some(v) => Some(f(v))
            case None => None
        }
    }
    */

extend Option<Int64> {
    public func getStr(): String {
        match (this) {
            case Some(v) => v.toString()
            case None => "(None!)"
        }
    }
}

/*
extend<T> Option<T> where T <: ToString {
    public func getStr(): String {
        match (this) {
            case Some(v) => v.toString()
            case None => "(None!)"
        }
    }
}
*/

