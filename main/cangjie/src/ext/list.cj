package simple_finer.ext

public enum List<A> {
    | Nil
    | Cons(A, List<A>)
}

extend<A> List<A> {
    public static func empty(): List<A> {
        Nil
    }

    public static func cons(hd: A, tl: List<A>): List<A> {
        Cons(hd, tl)
    }

    public static func makeBy(n: Int64, f: (Int64) -> A): List<A> {
        var acc = List<A>.empty()
        for (i in 0..n) {
            acc = acc.add(f(i))
        }
        acc.reverse()
    }

    public static func fromArray(arr: Array<A>): List<A> {
        List<A>.makeBy(arr.size, {i => arr[i]})
    }

    public func add(x: A): List<A> {
        cons(x, this)
    }

    public func append(x: A): List<A> {
        this.concat(Cons(x, Nil))
    }

    public func concat(other: List<A>): List<A> {
        this.reverse().reduce<List<A>>({acc, x => cons(x, acc)}, other)
    }

    public func reduce<B>(f: (B, A) -> B, base: B): B {
        var acc = base
        var x = this
        while (true) {
            match (x) {
                case Nil => break
                case Cons(hd, tl) =>
                    acc = f(acc, hd)
                    x = tl
            }
        }
        acc
    }

    public func filter(f: (A) -> Bool): List<A> {
        this.reduce ({
            acc, x => match(f(x)) {
                case true => Cons(x, acc)
                case false => acc
            }
        }, List<A>.empty()).reverse()
    }

    public func map<B>(f: (A) -> B): List<B> {
        var acc = List<B>.empty()
        var x = this
        while (true) {
            match(x) {
                case Nil => break
                case Cons(hd, tl) =>
                    acc = Cons(f(hd), acc)
                    x = tl
            }
        }
        acc.reverse()
        // this.reduce ({
        //     acc, x => Cons(f(x), acc)
        // }, List<B>.empty()).reverse()
    }

    public func map2<B>(f: (A) -> B): List<B> {
        match (this) {
            case Nil => List<B>.empty()
            case Cons(hd, tl) => Cons(f(hd), tl.map2(f))
        }
    }

    public func foldLeft<B>(f: (B, A) -> B, base: B): B {
        this.reduce(f, base)
    }

    public func foldRight<B>(f: (B, A) -> B, base: B): B {
        this.reverse().reduce(f, base)
    }

    /*
    递归调用，小心爆栈
    public func foldRight<B>(f: (A, B) -> B, base: B): B {
        match (this) {
            case Nil => base
            case Cons(hd, tl) => f(hd, tl.foldRight(f, base))
        }
    }
    */

    public func reverse(): List<A> {
        this.reduce({acc, x => List<A>.cons(x, acc)}, Nil)
    }

    public func isEmpty(): Bool {
        match (this) {
            case Nil => true
            case _ => false
        }
    }

    public func lenth(): Int64 {
        this.reduce({acc, _ => acc + 1}, 0)
    }

    public func skip(num: Int): List<A> {
        var x = this
        for (_ in 0..num) {
            match(x) {
                case Nil => break
                case Cons(hd, tl) =>
                    x = tl
            }
        }
        x
    }

    public func take(num: Int): (List<A>, List<A>) {
        var x = this
        var y = List<A>.Nil
        for (_ in 0..num) {
            match(x) {
                case Nil => break
                case Cons(hd, tl) =>
                    y.add(hd)
                    x = tl
            }
        }
        (y, x)
    }

    public func splitOnce(condition: (A) -> Bool): Option<(List<A>, List<A>)> {
        var x: List<A> = Nil
        var y = this
        while (true) {
            match (y) {
                case Nil => 
                    return None
                case Cons(hd, tl) where condition(hd) =>
                    break
                case Cons(hd, tl) => 
                    x = Cons(hd, x)
                    y = tl
            }
        }
        Some((x, y))
    }

    public func head(): A {
        match (this) {
            case Cons(hd, _) => hd
            case Nil => throw Exception("call head() on empty list!")
        }
    }
}

extend<A> List<A> <: ToString where A <: ToString {
    public func join(sp: String): String {
        match(this) {
            case Nil => ""
            case Cons(hd, tl)=> tl.reduce<String>({ acc: String, x: A => "${acc}${sp}${x}" }, "${hd}")
        }
    }

    public func toString() {
        "List: [${this.join(",")}]"
    }

    public func join(sp: String, maxItem!: Int): String {
        var count = 0
        var x = this
        var res = ""
        while (count < maxItem) {
            match (x) {
                case Cons(hd, tl) => 
                    res = "${res}${sp}${hd}"
                    x = tl
                case Nil => break
            }
        }
        res
    }
}

extend<A> List<A> where A <: Equatable<A> {
    public func startsWith(other: List<A>): Bool {
        other.reduce({acc: Option<List<A>>, x: A => match(acc) {
            case Some(Cons(hd, tl)) where hd == x => Some(tl)
            case _ => Option<List<A>>.None
        }}, this).isSome()
    }
}

extend<B> List<List<B>> {
    public func flatten(): List<B> {
        this.reduce ({acc, x => acc.concat(x)}, List<B>.Nil)
    }
}

extend List<Rune> {
    public func takeStr(s: String): Option<(List<Rune>, List<Rune>)> {
        var x = this
        var y = List<Rune>.Nil
        for (ch in s.runes()) {
            match (x) {
                case Cons(ch, tail) =>
                    y.add(ch)
                    x = tail
                case _ => return None
            }
        }
        Some((y, x))
    }
}