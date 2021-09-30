import Principal "mo:base/Principal";
import Error "mo:base/Error";

actor {
    stable var currentValue: Nat = 0;

    public shared (msg) func increment(): async () {
        let anon = Principal.fromText("2vxsx-fae");
        switch (Principal.equal(anon,msg.caller)) {
            case (true) {throw Error.reject("Principal is not authenticated")};
            case (false) { currentValue += 1; };
        }
    };

    public query func getValue(): async Nat {
        return currentValue;
    };
};
