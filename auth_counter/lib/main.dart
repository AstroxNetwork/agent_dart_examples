import 'package:agent_dart/agent_dart.dart';
import 'package:agent_dart_auth/agent_dart_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import Counter class with canister call
import 'counter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  bool _loading = false;
  String? _error;
  String? _status;
  // setup state class variable;
  Counter? counter;
  Identity? _identity;

  @override
  void initState() {
    initCounter();
    super.initState();
  }

  Future<void> initCounter({Identity? identity}) async {
    // initialize counter, change canister id here
    counter = Counter(
        canisterId: 'si2b5-pyaaa-aaaaa-aaaja-cai',
        url: 'http://localhost:8000');
    // set agent when other paramater comes in like new Identity
    await counter?.setAgent(newIdentity: identity);
    isAnon();
    await getValue();
  }

  void isAnon() {
    if (_identity == null || _identity!.getPrincipal().isAnonymous()) {
      setState(() {
        _status = 'You have not logined';
      });
    } else {
      setState(() {
        _status = 'Login principal is :${_identity!.getPrincipal().toText()}';
      });
    }
  }

  // get value from canister
  Future<void> getValue() async {
    var counterValue = await counter?.getValue();
    setState(() {
      _error = null;
      _counter = counterValue ?? _counter;
      _loading = false;
    });
  }

  // increment counter
  Future<void> _incrementCounter() async {
    setState(() {
      _loading = true;
    });
    try {
      await counter?.increment();
      await getValue();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> authenticate() async {
    try {
      var authClient = WebAuthProvider(
          scheme: "identity",
          path: 'auth',
          authUri:
              Uri.parse('http://qvhpv-4qaaa-aaaaa-aaagq-cai.localhost:8000'),
          useLocalPage: true);

      await authClient.login(
          // AuthClientLoginOptions()..canisterId = "rwlgt-iiaaa-aaaaa-aaaaa-cai"
          );
      // var loginResult = await authClient.isAuthenticated();

      _identity = authClient.getIdentity();
      await counter?.setAgent(newIdentity: _identity);
      isAnon();
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Got error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var logginButton =
        (_identity == null || _identity!.getPrincipal().isAnonymous())
            ? MaterialButton(
                onPressed: () async {
                  await authenticate();
                },
                child: Text('Login Button'),
              )
            : SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _status ?? '',
            ),
            Text(
              _error ?? 'The canister counter is now:',
            ),
            Text(
              _loading ? 'loading...' : '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            logginButton
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
