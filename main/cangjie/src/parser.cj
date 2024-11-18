enum Expr {
    | Number(Int64),
    | Plus(BinOp<Expr>)
    | Minus(BinOp<Expr>)
    | Multiply(BinOp<Expr>)
    | Divide(BinOp<Expr>)
}

enum 