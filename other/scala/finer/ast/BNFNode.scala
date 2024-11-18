package finer.ast

abstract class BNFNode(val name: String) {
  def toBNF: String = {
    val children = this match {
      case node: BNFNode => node.children.map(_.toBNF).mkString(" ")
      case _ => ""
    }
    s"$name $children"
  }

  def children: List[BNFNode]
}

object BNFNode {
  def apply(name: String, children: BNFNode*): BNFNode = {
    val node = new BNFNode(name) {
      override def children: List[BNFNode] = children.toList
    }
    node
  }
}

// TODO: add support for optional nodes