# auth_counter

An authorized counter example

## What we do in this example
1. We have a `increment` method in backend motoko code, which requires an non-anonymous identity to call.
2. We try to connect with `internet identity` to fetch user's identity.
3. If the identity is anonymous, the smart contract will return with error
4. If the identity is not anoymous, the smart contract will execute the actual `increment`.


## What we need for this example
* agent_dart
* agent_dart_auth
* internet identity(local or mainnet)
* middle page project([auth_client_demo](https://github.com/AstroxNetwork/auth-client-demo))

## Why so complex settings?
1. `agent_dart` does not provide any UI related feature or components to keep itself `clean` as dart code.
2. `agent_dart_auth` uses an third-party plugin called `flutter_web_auth` to open up a WebView window to display the middle page.
3. `middle page` is used to redirect current authenticating request to `internet identity`, the reasons to do so are as folowing:
   1. `internet identity` ONLY accept browser request, it uses `window` and `postMessage` to complete the authentication flow. Thus third party apps like flutter or mobile apps can not pass parameters to it directly.
   2. Why don't we call its contract/canister directly? Because user keeps their II anchor number in their browsers, there's no way to extract those identities out of the browsers.
   3. The **MOST IMPORTANT** reason is that, when user authorize DApps on Mainnet, the II will calculate the delegation identity using DApps' url. If the url changes or use localhost, the delegation result will change. Thus we have to use a middle page to trick II we had our requests are from our DApps' webpage, which means you have to deploy at least one webpage to mainnet and to the same and stable auth url to II. 
   4. The `middle page` is a very simple example that how do we complete the flow. There are still limitations:
      1. the project is coded by `lit-html`, if you are using React or Vue, you have to transpile yourself.
      2. THere are difference between `android` and `ios` in auto-redirecting. User have to click when `web-to-flutter` flow on Android, but `flutter-to-web` flow on iOS.

## Can we make it easier?
1. If you are tyring to use II, currently, no. Limitation is too much there.
2. AstroX is implementing our own identity service, which will link II as one of the identity providers. After we finish that part, we will make a flutter plugin to call smart-contract method directly, maybe without Webview popup.


## Special Thanks
[Nikola](https://github.com/Nikola1994/) from Distrikt.io, helped us to come up with the solution.
`sidc0des` and `RMCS` from Canistore, helped us to debug latest agent-js dependencies and they complete the service worker for web. Solution and code will come after.