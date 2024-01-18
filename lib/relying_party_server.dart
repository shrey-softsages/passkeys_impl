import 'dart:convert';

import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:passkeys/relying_party_server/relying_party_server.dart';
import 'package:passkeys/relying_party_server/types/authentication.dart';
import 'package:passkeys/relying_party_server/types/registration.dart';
import 'package:http/http.dart' as https;

class PersonalRelyingPartyServer
    extends RelyingPartyServer<RpRequest, RpResponse> {
  String? username;
  final client = https.Client();
  String? cookie;
  void init() {}

  @override
  Future<AuthenticationInitResponse> initAuthenticate(RpRequest request) async {
    Map<String, dynamic> body = {"username": request.email};
    final resposne = await client.post(
        Uri.parse("https://79ec-115-246-26-148.ngrok-free.app/login"),
        body: body);
    Map<String, dynamic> credentials = {};
    if (resposne.statusCode == 200) {
      credentials = json.decode(resposne.body);
      print(credentials);
    } else {
      print("FAILLLLLLLLLLLLLL");
    }
    final allowcredentials = credentials['publicKey']['allowCredentials'];
    return AuthenticationInitResponse(
        rpId: credentials['publicKey']['rpId'],
        challenge: credentials['publicKey']['challenge'],
        allowCredentials: [
          AllowCredential(
              type: allowcredentials[0]['type'],
              id: allowcredentials[0]['id'],
              transports: ['platform', 'cross-platform'])
        ]);
  }

  @override
  Future<RpResponse> completeAuthenticate(
      AuthenticationCompleteRequest request) async {
    return RpResponse(success: true);
  }

  @override
  Future<RegistrationInitResponse> initRegister(RpRequest request) async {
    username = request.email;
    Map<String, String> body = {
      "username": request.email,
      "display": request.email
    };
    final response = await client.post(
        Uri.parse("https://79ec-115-246-26-148.ngrok-free.app/register"),
        body: body);
    cookie = response.headers['set-cookie'];
    Map<String, dynamic> credentialCreationRequestoptions = {};
    if (response.statusCode == 200) {
      credentialCreationRequestoptions = json.decode(response.body);
      credentialCreationRequestoptions['publicKey']['origin'] =
          "https://79ec-115-246-26-148.ngrok-free.app";
      print(credentialCreationRequestoptions);
    } else {
      print("FAILLLLLLLLLLLLLL");
    }
    // List<PubKeyCredParam> pubKeyCredParams =
    //     credentialCreationRequestoptions['publicKey']['pubKeyCredParams']
    //         .map((credparams) =>
    //             PubKeyCredParam(credparams['alg'], credparams['type']))
    //         .toList();

    return RegistrationInitResponse(
      RelyingParty(credentialCreationRequestoptions['publicKey']['rp']['name'],
          credentialCreationRequestoptions['publicKey']['rp']['id']),
      User(
          credentialCreationRequestoptions['publicKey']['user']['displayName'],
          credentialCreationRequestoptions['publicKey']['user']['name'],
          credentialCreationRequestoptions['publicKey']['user']['id']),
      credentialCreationRequestoptions['publicKey']['challenge'],
      AuthenticatorSelection("platform", false, "preferred", "preferred"),
      timeout: 60000,
    );
  }

  @override
  Future<RpResponse> completeRegister(
      RegistrationCompleteRequest request) async {
    // print(request.id + "\n" + request.clientDataJSON + "\n" + request.rawId);
    Map<String, dynamic> body = {
      "username": username,
      "credential": jsonEncode({
        "id": request.id,
        "response": {
          "clientDataJSON": request.clientDataJSON,
          "attestationObject": request.attestationObject
        },
        "type": "public-key",
        "clientExtensionResults": {
          "credProps": {"rk": true}
        }
      }),
      "credname": username
    };
    final resposne = await client.post(
        Uri.parse("https://79ec-115-246-26-148.ngrok-free.app/finishauth"),
        body: body,
        headers: {'Cookie': cookie!});
    print(resposne.body);
    print(resposne.headers['set-cookie']);
    return RpResponse(success: true);
  }
}

class RpRequest {
  const RpRequest({required this.email});

  final String email;
}

class RpResponse {
  const RpResponse({required this.success});

  final bool success;
}
