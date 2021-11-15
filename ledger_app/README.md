# ledger_app

An example app that interact with ledger wasm

## How to run
1. deploy ledger wasm, see `backend` folder and `dfx.json` settings
 ```bash
   rm -rf .dfx &&
   dfx deploy \
            --argument "record { minting_account = \"ea2d973e67dcbcb00f1cfb36d05d600eef68c7513c18dac8ef52d165c1d38c36\"; initial_values = vec { record { \"a32bf2912509d0561f3394009ba5b062ac3f607d6bf171f48841ebbc5005c82a\"; record { e8s = 18446744073709551615 } } }; max_message_size_bytes = null; transaction_window = null; archive_options = null; send_whitelist = vec {}}" \
            --network=local \
            --no-wallet \
            ledger
```

    take down the "ledger" canister id.

2. modify `AgentFactory` settings in `main.dart`
```dart
Future<AgentFactory> getAgent() async {
    return await AgentFactory.createAgent(
        canisterId:
            "rwlgt-iiaaa-aaaaa-aaaaa-cai", // local ledger canister id, should change accourdingly
        url: "http://localhost:8000/", // For Android emulator, please use 10.0.2.2 as endpoint
        idl: ledgerIdl,
        identity: _signer?.account.ecIdentity,
        debug: true);
  }

```

3. `flutter run` and import phrase
   use this 
   `steel obey anxiety vast clever relax million girl cost pond elbow bridge hill health toilet desk sleep grid boost flavor shy cry armed mass`
   You will see balance minted with some ICPs
