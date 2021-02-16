import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HM "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import RBTree "mo:base/RBTree";

module {

  public type PrimaryKey = Nat;
  public type ForeignKey = Nat;

  public type Relation<A> = {
    data : RBTree.RBTree<Nat, A>
  };

  public func find<A>(rel : Relation<A>, pk : Nat) : ?A {
    rel.data.get(pk)
  };

  // func alterRB<K, A>(rb : RBTree.RBTree<K, A>, k : K, f : (?A -> ?A)) {
  //   switch (f(rb.get(k))) {
  //     case null { ignore rb.remove(k) };
  //     case (?a) { rb.put(k, a) }
  //   }
  // };

  // Scream emoji
  public func cartesian<A, B>(
    relA : Relation<A>,
    relB : Relation<B>
  ) : [((Nat, A), (Nat, B))] {
    let as : [(Nat, A)] = Iter.toArray(relA.data.entries());
    let bs : [(Nat, B)] = Iter.toArray(relB.data.entries());
    Array.tabulate<((Nat, A), (Nat, B))>(as.size() * bs.size(), func (n) {
      let i = Nat.div(n, as.size());
      let j = Nat.rem(n, as.size());
      (as[i], bs[j])
    })
  };

  public func join<A, B, C>(
    relA : Relation<A>, 
    relB : Relation<B>, 
    projectA : A -> C,
    projectB : B -> C,
    eq : (C, C) -> Bool
  ) : [((Nat, A), (Nat, B))] {
    // This is terrible, and should generally be avoided. Speed it up with indices
    Array.filter<((Nat, A), (Nat, B))>(cartesian(relA, relB), func((_, a), (_, b)) {
      eq(projectA(a), projectB(b))
    })
  };

  public func joinPK<A, B>(
    relA : Relation<A>, 
    relB : Relation<B>, 
    fk : B -> PrimaryKey
  ) : Relation<(B, A)> {
    
    let res : RBTree.RBTree<Nat, (B, A)> = RBTree.RBTree(Nat.compare);

    for ((bPk, b) in relB.data.entries()) {
      switch (relA.data.get(fk(b))) {
        case null {};
        case (?a) {
          res.put(bPk, (b, a));
        }
      }
    };
    { data = res }
  };

  public func mkRelation<A>(data : [(Nat, A)]) : Relation<A> {
    let res : RBTree.RBTree<Nat, A> = RBTree.RBTree(Nat.compare);
    for ((k, a) in data.vals()) {
      res.put(k, a);
    };
    { data = res }
  }
}
