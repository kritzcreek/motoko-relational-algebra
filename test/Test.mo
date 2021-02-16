import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import M "mo:matchers/Matchers";
import R "../src/Relation";
import S "mo:matchers/Suite";

type User = {
    name : Text;
    location : Nat;
};

type Location = {
    name : Text;
};

let users : R.Relation<User> = R.mkRelation(
    [
        (1, { name = "Matthew"; location = 1 }),
        (2, { name = "Christoph"; location = 2}),
        // Here we have a location FK that doesn't match an existing location. 
        // Database systems will typically prevent this from happening with 
        // constraints on insert/delete. My implementation of `joinPK` just ignores this one.
        (3, { name = "Claudio"; location = 4 }),
        (4, { name = "Yan"; location = 1 })
    ]
);
let locations : R.Relation<Location> = R.mkRelation(
    [
        (1, { name = "Murica" }), 
        (2, { name = "Germany" }),
        (3, { name = "Switzerland"})
    ]
);

// Let's look at a simple 1 to N relation first.
// Every User has a location, but a location might have N users.
let usersPerCountry = R.joinPK(locations, users, func(u : User) : Nat { u.location });

Debug.print(debug_show(Iter.toArray(usersPerCountry.data.entries())));

type Follows = {
    user : Nat;
    follower : Nat;
};

let follows : R.Relation<Follows> = R.mkRelation(
    [
        (1, { user = 1; follower = 2 }),
        (2, { user = 1; follower = 3 }),
        (3, { user = 2; follower = 3 })
    ]
);

// Now here's the more interesting N to M relation. The usual way of modeling this is to have a "join table". 
// Our join table is the follows relation. 
// What makes this work is that the result of `joinPK` is a relation itself, so we can join it again.
let followGraph = R.joinPK(
    users,
    R.joinPK(users, follows, func(f : Follows) : Nat { f.user }),
    func ((f : Follows, u : User)) : Nat { f.follower }
);

for ((_, ((_, user), follower)) in followGraph.data.entries()) {
    Debug.print(follower.name # " follows " # user.name);
};


