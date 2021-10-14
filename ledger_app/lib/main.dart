import 'package:intl/intl.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:agent_dart/wallet/ledger.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

final e8sNumber = NumberFormat("#,##0", "en_US");
final icpNumber = NumberFormat('#,##0.00000000', 'en_US');

String _formatBalance(BigInt balance, {bool icp = false}) {
  var rawString = balance.toInt();
  return !icp ? e8sNumber.format(rawString) : icpNumber.format((balance / BigInt.from(100000000)));
}

String _formatAccountAddress(String address) {
  var front = address.substring(0, 16);
  var tail = address.substring(address.length - 16, address.length);
  return front + '...' + tail;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger App Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Ledger App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ICPSigner? _signer; // a32bf2912509d0561f3394009ba5b062ac3f607d6bf171f48841ebbc5005c82a
  String? _receiver; // 9efbf2f05081dcae470c1f3b8781c4030bb7fe17297dbdf10dcbcd3841d0a3f1;
  BigInt? _amount;
  BigInt _fee = BigInt.from(10000);
  String? _memo;
  AgentFactory? _agent;
  ICPTs? _senderBalance;
  ICPTs? _receiverBalance;
  bool _confirm = false;
  List<Widget>? prints;

  final TextEditingController senderController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController feeController = TextEditingController()
    ..value = TextEditingValue(text: _formatBalance(BigInt.from(10000), icp: true));
  final TextEditingController memoController = TextEditingController();

  @override
  void dispose() {
    senderController.dispose();
    receiverController.dispose();
    amountController.dispose();
    feeController.dispose();
    memoController.dispose();
    super.dispose();
  }

  bool isOk() {
    if (_signer == null || _receiver == null || _receiver!.isEmpty || _amount == null) {
      return false;
    }
    return true;
  }

  Future<AgentFactory> getAgent() async {
    return await AgentFactory.createAgent(
        canisterId:
            "rwlgt-iiaaa-aaaaa-aaaaa-cai", // local ledger canister id, should change accourdingly
        url: "http://localhost:8000/", // For Android emulator, please use 10.0.2.2 as endpoint
        idl: ledgerIdl,
        identity: _signer?.account.ecIdentity,
        debug: true);
  }

  Future<void> setSigner(ICPSigner signer) async {
    setState(() {
      _signer = signer;
    });
    print(_signer!.ecChecksumAddress);
    if (_signer != null) {
      var agent = await getAgent();
      setState(() {
        _agent = agent;
      });
      await setSignerBalance();
    }
  }

  Future<void> setSignerBalance() async {
    var senderBalance =
        await Ledger.getBalance(agent: _agent!, accountId: _signer!.ecChecksumAddress!);
    setState(() {
      _senderBalance = senderBalance;
    });
  }

  Future<void> setReceiverBalance() async {
    var receiverBalance = await Ledger.getBalance(agent: _agent!, accountId: _receiver!);
    setState(() {
      _receiverBalance = receiverBalance;
    });
  }

  void setReceiver(String receiver) {
    if (receiver.isNotEmpty) {
      setState(() {
        _receiver = receiver;
      });
    }
  }

  void setAmount(String amount) {
    if (amount.isNotEmpty) {
      setState(() {
        _amount = BigInt.from(num.parse(amount) * 100000000);
      });
    }
  }

  void setFee(String fee) {
    if (fee.isNotEmpty) {
      setState(() {
        _amount = BigInt.from(num.parse(fee) * 100000000);
      });
    }
  }

  void setMemo(String memo) {
    if (memo.isNotEmpty) {
      setState(() {
        _memo = memo;
      });
    }
  }

  void setConfirm(bool confirm) {
    setState(() {
      _confirm = confirm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Prepare transaction',
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            SizedBox(
              height: 32,
            ),
            Container(
                decoration: BoxDecoration(color: Colors.black12),
                padding: EdgeInsets.all(16.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    _signer == null
                        ? 'Please create or import account'
                        : _formatAccountAddress(_signer!.ecChecksumAddress.toString()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MaterialButton(
                        onPressed: () async {
                          var signer =
                              await Navigator.of(context).push(MaterialPageRoute<ICPSigner?>(
                                  builder: (BuildContext context) => const ImportAccountPage(
                                        title: 'Import Account',
                                      )));
                          if (signer is ICPSigner) {
                            setSigner(signer);
                          }
                        },
                        child: Text(
                          'Import Account',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      MaterialButton(
                        onPressed: () {
                          // print(ICPSigner.create().ecChecksumAddress);
                          setSigner(ICPSigner.create());
                        },
                        child: Text(
                          'Create Random',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    ],
                  )
                ])),
            SizedBox(
              height: 16,
            ),
            _senderBalance == null
                ? SizedBox.shrink()
                : Text(_formatBalance(_senderBalance!.e8s, icp: true) + ' ICP'),
            SizedBox(
              height: 32,
            ),
            TextFormField(
              key: const Key('_receiver'),
              // enabled: !_validating,
              controller: receiverController,
              decoration: InputDecoration(
                hintText: 'Input Recipient Address',
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              ),
              validator: (val) {
                return val == '' || val == null ? 'Mnemonic phrase must not be empty' : null;
              },
              onChanged: (val) async {
                setReceiver(val);
                await setReceiverBalance();
              },
            ),
            SizedBox(
              height: 16,
            ),
            _receiverBalance == null
                ? SizedBox.shrink()
                : Text(_formatBalance(_receiverBalance!.e8s, icp: true) + ' ICP'),
            SizedBox(
              height: 32,
            ),
            TextFormField(
              key: const Key('_amount'),
              // enabled: !_validating,
              controller: amountController,
              decoration: InputDecoration(
                  hintText: 'Input Amount',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  suffixText: 'ICP'),
              validator: (val) {
                return val == '' || val == null ? 'Input Amount must not be empty' : null;
              },
              onChanged: (val) {
                setAmount(val);
              },
            ),
            SizedBox(
              height: 32,
            ),
            TextFormField(
              key: const Key('_fee'),
              // enabled: !_validating,
              // initialValue: _formatBalance(_fee),

              controller: feeController,
              decoration: InputDecoration(
                  hintText: 'Input Fee',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  suffixText: 'ICP'),
              validator: (val) {
                return val == '' || val == null ? 'Input Amount must not be empty' : null;
              },
              onChanged: (val) {
                setFee(val);
              },
            ),
            SizedBox(
              height: 32,
            ),
            TextFormField(
              key: const Key('_memo'),
              // enabled: !_validating,
              // initialValue: _formatBalance(_fee),
              controller: memoController,
              decoration: InputDecoration(
                  hintText: 'Input Memo',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  suffixText: 'Default: Empty or length <= 8'),
              onChanged: (val) {
                setMemo(val);
              },
              autovalidateMode: AutovalidateMode.always,
              validator: (val) {
                return val != null
                    ? val.plainToHex().hexToBn() > BigInt.from(2).pow(64)
                        ? 'Memo Too long'
                        : null
                    : null;
              },
            ),
            SizedBox(
              height: 32,
            ),
            MaterialButton(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                color: Colors.black,
                child: Text(
                  'Confirm and send transaction',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: !isOk()
                    ? null
                    : () async {
                        var dialogConfirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text('Confirm To Send'),
                                  actionsPadding: EdgeInsets.all(16),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: Text(
                                          'Confirm',
                                          style: TextStyle(fontSize: 24, color: Colors.black),
                                        ))
                                  ],
                                  content: Column(children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sender: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(_formatAccountAddress(_signer!.ecChecksumAddress!))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Receiver: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(_formatAccountAddress(_receiver!))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Amount: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(_formatBalance(_amount!, icp: true))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Fee: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(_formatBalance(_fee, icp: true))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Memo: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(_memo ?? 'EMPTY')
                                      ],
                                    )
                                  ]),
                                ));

                        if (dialogConfirm) {
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Transaction Processing'),
                                  actionsPadding: EdgeInsets.all(16),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: Text(
                                          'Confirm',
                                          style: TextStyle(fontSize: 24, color: Colors.black),
                                        ))
                                  ],
                                  content: SendingWidget(
                                    agent: _agent,
                                    receiver: _receiver!,
                                    amount: _amount,
                                    fee: _fee,
                                    memo: _memo,
                                    signer: _signer!,
                                    senderBalance: _senderBalance,
                                    receiverBalance: _receiverBalance,
                                  ),
                                );
                              });
                          await setSignerBalance();
                          await setReceiverBalance();
                        }
                      })
          ],
        ),
      )),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({Key? key, required this.title}) : super(key: key);

  final String title;
  @override
  _ImportAccountPageState createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  final TextEditingController _phraseController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _validating = false;
  SourceType _sourceType = SourceType.II;
  String? _phrase;
  // 'steel obey anxiety vast clever relax million girl cost pond elbow bridge hill health toilet desk sleep grid boost flavor shy cry armed mass';

  void setValidating(bool validate_state) {
    setState(() {
      _validating = validate_state;
    });
  }

  void setSourceType(SourceType type) {
    setState(() {
      _sourceType = type;
    });
  }

  void setPhrase(String phrase) {
    setState(() {
      _phrase = phrase;
    });
  }

  void validateRecoverForm() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
    }
  }

  bool verifyPhrases(String phrases) {
    try {
      return validateMnemonic(phrases);
    } catch (e) {
      rethrow;
    }
  }

  Widget ddBtn() {
    return DropdownButton<SourceType>(
      value: _sourceType,
      icon: const Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (SourceType? newValue) {
        setState(() {
          _sourceType = newValue!;
        });
      },
      items: <SourceType>[SourceType.II, SourceType.Base, SourceType.Plug]
          .map<DropdownMenuItem<SourceType>>((SourceType value) {
        return DropdownMenuItem<SourceType>(
          value: value,
          child: Text('Type: ' + value.toString().replaceAll('SourceType.', '')),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Please input phrases to import account',
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            SizedBox(
              height: 32,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    key: const Key('_phrase'),
                    enabled: !_validating,
                    controller: _phraseController,
                    decoration: InputDecoration(
                        hintText: 'Input Mnemonic phrase',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        suffix: ddBtn()),
                    validator: (val) {
                      return val == '' || val == null ? 'Mnemonic phrase must not be empty' : null;
                    },
                    onChanged: (val) {
                      setPhrase(val);
                      _formKey.currentState!.save();
                      validateRecoverForm();
                    },
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  MaterialButton(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      color: Colors.black,
                      child: Text(
                        'Validate and import account',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () {
                        setValidating(true);
                        if (_phrase == null || !validateMnemonic(_phrase!)) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text('Error'),
                                    content: Text('Mnemonic phrase is not correct'),
                                  ));
                        } else {
                          print(_sourceType);
                          Navigator.pop(
                              context, ICPSigner.importPhrase(_phrase!, sourceType: _sourceType));
                        }
                      })
                ],
              ),
            )
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SendingWidget extends StatefulWidget {
  final ICPSigner? signer; // 6d8ab6a716046a5a7ff21165fd6649067e07998c1ce3bd3581dba290cedb8b53
  final String? receiver; // 9efbf2f05081dcae470c1f3b8781c4030bb7fe17297dbdf10dcbcd3841d0a3f1;
  final BigInt? amount;
  final BigInt? fee;
  final String? memo;
  final AgentFactory? agent;
  final ICPTs? senderBalance;
  final ICPTs? receiverBalance;
  SendingWidget(
      {this.signer,
      this.receiver,
      this.amount,
      this.fee,
      this.memo,
      this.agent,
      this.senderBalance,
      this.receiverBalance});
  @override
  _SendingWidgetState createState() => _SendingWidgetState();
}

class _SendingWidgetState extends State<SendingWidget> {
  List<Widget>? prints;

  @override
  void initState() {
    sending();
    super.initState();
  }

  sending() async {
    printWidget("\n----- test fetch balance and send -----");
    printWidget("\n---👩 sender Balance before send:");
    printWidget(widget.senderBalance!.e8s.toString());

    printWidget("\n---🧑 receiver balance before send:");
    printWidget(widget.receiverBalance!.e8s.toString());

    printWidget("\n---📖 payload:");
    printWidget("amount:  ${widget.amount}");
    printWidget("fee:     ${widget.fee}");
    printWidget("from:    ${_formatAccountAddress(widget.signer!.ecChecksumAddress.toString())}");
    printWidget("to:      ${_formatAccountAddress(widget.receiver!.toString())}");

    printWidget("\n---🤔 sending start=====>");
    var blockHeight = await Ledger.send(
        agent: widget.agent!,
        to: widget.receiver!,
        amount: widget.amount!,
        sendOpts: SendOpts()
          ..fee = widget.fee
          ..memo = widget.memo == null ? null : widget.memo!.plainToHex().hexToBn());
    printWidget("\n---✅ sending end=====>");
    printWidget("\n---🔢 block height: $blockHeight");

    var receiverAfterSend =
        await Ledger.getBalance(agent: widget.agent!, accountId: widget.receiver!);
    printWidget("\n---🧑 receiver balance after send:");
    printWidget(receiverAfterSend.e8s.toString());
    var senderBalanceAfter =
        await Ledger.getBalance(agent: widget.agent!, accountId: widget.signer!.ecChecksumAddress!);
    printWidget("\n---👩 sender balance after send:");
    printWidget(senderBalanceAfter.e8s.toString());
    printWidget("\n---💰 balance change:");
    printWidget((senderBalanceAfter.e8s - widget.senderBalance!.e8s).toString());
  }

  void printWidget(String str) {
    var _prints = prints ?? [];
    var newPrint = Text(
      str,
      style: TextStyle(fontSize: 16),
    );
    _prints.add(newPrint);
    setState(() {
      prints = _prints;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: prints ?? []);
  }
}
