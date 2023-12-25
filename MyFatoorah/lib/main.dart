import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:http/http.dart' as http;

const String testAPIKey =
    "rLtt6JWvbUHDDhsZnfpAhpYk4dxYDQkbcPTyGaKp2TYqQgG7FGZ5Th_WD53Oq8Ebz6A53njUoo1w3pjU1D4vs_ZMqFiz_j0urb_BH9Oq9VZoKFoJEDAbRZepGcQanImyYrry7Kt6MnMdgfG5jn4HngWoRdKduNNyP4kzcp3mRv7x00ahkm9LAK7ZRieg7k1PDAnBIOG3EyVSJ5kK4WLMvYr7sCwHbHcu4A5WwelxYK0GMJy37bNAarSJDFQsJ2ZvJjvMDmfWwDVFEVe_5tOomfVNt6bOg9mexbGjMrnHBnKnZR1vQbBtQieDlQepzTZMuQrSuKn-t5XZM7V6fCW7oP-uXGX-sMOajeX65JOf6XVpk29DP6ro8WTAflCDANC193yof8-f5_EYY-3hXhJj7RBXmizDpneEQDSaSz5sFk0sV5qPcARJ9zGG73vuGFyenjPPmtDtXtpx35A-BVcOSBYVIWe9kndG3nclfefjKEuZ3m4jL9Gg1h2JBvmXSMYiZtp9MR5I6pvbvylU_PP5xJFSjVTIz7IQSjcVGO41npnwIxRXNRxFOdIUHn0tjQ-7LwvEcTXyPsHXcMD8WtgBh-wxR8aKX7WPSsT1O8d8reb2aR7K3rkV3K82K_0OgawImEpwSvp9MNKynEAJQS6ZHe_J_l77652xwPNxMRTMASk1ZsJL";

String? invoiceId;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _response = '';
  MFInitiateSessionResponse? session;

  List<MFPaymentMethod> paymentMethods = [];
  List<bool> isSelected = [];
  int selectedPaymentMethodIndex = -1;

  String cardNumber = "5453010000095489";
  String expiryMonth = "05";
  String expiryYear = "21";
  String securityCode = "100";
  String cardHolderName = "Test Account";

  String amount = "5.00";
  bool visibilityObs = false;
  late MFCardPaymentView mfCardView;
  late MFApplePayButton mfApplePayButton;

  @override
  void initState() {
    super.initState();
    initiate();
  }

  @override
  void dispose() {
    super.dispose();
  }

//initiate
  initiate() async {
    if (testAPIKey.isEmpty) {
      setState(() {
        _response =
            "Missing API Token Key.. You can get it from here: https://myfatoorah.readme.io/docs/test-token";
      });
      return;
    }

    await MFSDK.init(testAPIKey, MFCountry.SAUDIARABIA, MFEnvironment.TEST);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initiatePayment();
    });
  }

//log
  log(Object object) {
    var json = const JsonEncoder.withIndent('  ').convert(object);
    setState(() {
      debugPrint(json);
      _response = json;
    });
  }

// Initiate Payment
  initiatePayment() async {
    var request = MFInitiatePaymentRequest(
        invoiceAmount: double.parse(amount),
        currencyIso: MFCurrencyISO.KUWAIT_KWD);

    await MFSDK
        .initiatePayment(request, MFLanguage.ENGLISH)
        .then((value) => {
              log(value),
              paymentMethods.addAll(value.paymentMethods!),
              for (int i = 0; i < paymentMethods.length; i++)
                isSelected.add(false)
            })
        .catchError((error) => {log(error.message)});
  }

// Execute Regular Payment
  executeRegularPayment(int paymentMethodId) async {
    var request = MFExecutePaymentRequest(
        paymentMethodId: paymentMethodId, invoiceValue: double.parse(amount));
    request.displayCurrencyIso = MFCurrencyISO.KUWAIT_KWD;

    await MFSDK
        .executePayment(request, MFLanguage.ENGLISH, (invoiceId) {
          log(invoiceId);
        })
        .then((value) => log(value))
        .catchError((error) => {log(error.message)});
  }

//Execute Direct Payment
  // isToken save or not
  executeDirectPayment(
      int paymentMethodId, bool isToken, String CallBackUrl) async {
    var callBackResponse = await http.post(Uri.parse(CallBackUrl));
    var request = MFExecutePaymentRequest(
      paymentMethodId: paymentMethodId,
      CallBackUrl: callBackResponse.body,
      invoiceValue: double.parse(amount),
    );

    var token = isToken ? "TOKEN210282" : null;
    var mfCardRequest = isToken
        ? null
        : MFCard(
            cardHolderName: cardHolderName,
            number: cardNumber,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            securityCode: securityCode,
          );

    var directPaymentRequest = MFDirectPaymentRequest(
        executePaymentRequest: request, token: token, card: mfCardRequest);
    log(directPaymentRequest);
    await MFSDK.executeDirectPayment(directPaymentRequest, MFLanguage.ENGLISH,
        (invoiceId) {
      debugPrint("-----------$invoiceId------------");
      log(invoiceId);
    }).then((value) {
      print('********value*********');
      log(value);
     getPaymentStatus(value.mfPaymentStatusResponse!.invoiceId.toString());
            log(value.mfPaymentStatusResponse!.invoiceId.toString());

              showAlert(context, 'Payment successful!'); 

    //       var invoiceId = await MFSDK.executeDirectPayment(
    //   directPaymentRequest,
    //   MFLanguage.ENGLISH,
    //   (invoiceId) {
    //     debugPrint(invoiceId);
    //     showAlert(context, 'Payment successful!'); // Show alert on success
    //   },
    // );

    //debugPrint(invoiceId.toString());
    }).catchError((error) {
                showAlert(context, error.message);

    });
  }

// Payment Enquiry
  getPaymentStatus( String? id ) async {
    debugPrint(
        "************************************************************************ invoiceId $id");
    MFGetPaymentStatusRequest request =
        MFGetPaymentStatusRequest(key: id, keyType: MFKeyType.INVOICEID);

    await MFSDK.getPaymentStatus(request, MFLanguage.ENGLISH).then((value) {
      log(value);
      debugPrint(
          "*****************************************************Payment Status: $value");
    }).catchError((error) => {log(error.message)});
  }

// Cancel Token
  cancelToken() async {
    await MFSDK
        .cancelToken("Put your token here", MFLanguage.ENGLISH)
        .then((value) => log(value))
        .catchError((error) => {log(error.message)});
  }

//setPaymentMethodSelected
  setPaymentMethodSelected(int index, bool value) {
    for (int i = 0; i < isSelected.length; i++) {
      if (i == index) {
        isSelected[i] = value;
        if (value) {
          selectedPaymentMethodIndex = index;
          visibilityObs = paymentMethods[index].isDirectPayment!;
        } else {
          selectedPaymentMethodIndex = -1;
          visibilityObs = false;
        }
      } else {
        isSelected[i] = false;
      }
    }
  }

//executePayment
  executePayment() {
    if (selectedPaymentMethodIndex == -1) {
      setState(() {
        _response = "Please select payment method first";
      });
    } else {
      if (amount.isEmpty) {
        setState(() {
          _response = "Set the amount";
        });
      } else if (paymentMethods[selectedPaymentMethodIndex].isDirectPayment!) {
        if (cardNumber.isEmpty ||
            expiryMonth.isEmpty ||
            expiryYear.isEmpty ||
            securityCode.isEmpty) {
          setState(() {
            _response = "Fill all the card fields";
          });
        } else {
          executeDirectPayment(
              paymentMethods[selectedPaymentMethodIndex].paymentMethodId!,
              false,
              "https://docs.myfatoorah.com/docs/direct-payment");
        }
      } else {
        executeRegularPayment(
            paymentMethods[selectedPaymentMethodIndex].paymentMethodId!);
      }
    }
    print("*******************************************_response ${_response}");

    // getPaymentStatus();
  }

  MFCardViewStyle cardViewStyle() {
    MFCardViewStyle cardViewStyle = MFCardViewStyle();
    cardViewStyle.cardHeight = 200;
    cardViewStyle.hideCardIcons = false;
    cardViewStyle.input?.inputMargin = 3;
    cardViewStyle.label?.display = true;
    cardViewStyle.input?.fontFamily = MFFontFamily.TimesNewRoman;
    cardViewStyle.label?.fontWeight = MFFontWeight.Light;
    return cardViewStyle;
  }

////////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    mfCardView = MFCardPaymentView(cardViewStyle: cardViewStyle());
    mfApplePayButton = MFApplePayButton(applePayStyle: MFApplePayStyle());

    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 1,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Flex(
              direction: Axis.vertical,
              children: [
                Text("Payment Amount", style: textStyle()),
                amountInput(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          paymentMethodsList(),
                          const SizedBox(height: 20),
                          visibilityObs
                              ? directPaymentCardDetails()
                              : const Column(),
                          const SizedBox(height: 40),
                          if (selectedPaymentMethodIndex != -1)
                            btn("Bay", executePayment),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

////////////////////////////////////////////////////////////////////////////////////////

//directPaymentCardDetails
  Widget directPaymentCardDetails() {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(2.5),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Card Number"),
          controller: TextEditingController(text: cardNumber),
          onChanged: (value) {
            cardNumber = value;
          },
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Expiry Month"),
          controller: TextEditingController(text: expiryMonth),
          onChanged: (value) {
            expiryMonth = value;
          },
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Expiry Year"),
          controller: TextEditingController(text: expiryYear),
          onChanged: (value) {
            expiryYear = value;
          },
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Security Code"),
          controller: TextEditingController(text: securityCode),
          onChanged: (value) {
            securityCode = value;
          },
        ),
        TextField(
          keyboardType: TextInputType.name,
          decoration: const InputDecoration(labelText: "Card Holder Name"),
          controller: TextEditingController(text: cardHolderName),
          onChanged: (value) {
            cardHolderName = value;
          },
        ),
      ],
    );
  }

//paymentMethodsList 
  Widget paymentMethodsList() {
    return Column(
      children: [
        Text("Select payment method", style: textStyle()),
        SizedBox(
          height: 85,
          child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: paymentMethods.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return paymentMethodsItem(ctxt, index);
              }),
        ),
      ],
    );
  }

//paymentMethodsItem
  Widget paymentMethodsItem(BuildContext ctxt, int index) {
    return SizedBox(
      width: 70,
      height: 75,
      child: Container(
        decoration: isSelected[index]
            ? BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2))
            : const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            children: <Widget>[
              Image.network(
                paymentMethods[index].imageUrl!,
                height: 35.0,
              ),
              SizedBox(
                height: 24.0,
                width: 24.0,
                child: Checkbox(
                    checkColor: Colors.blueAccent,
                    activeColor: const Color(0xFFC9C5C5),
                    value: isSelected[index],
                    onChanged: (bool? value) {
                      setState(() {
                        setPaymentMethodSelected(index, value!);
                      });
                    }),
              ),
              Text(
                paymentMethods[index].paymentMethodEn ?? "",
                style: TextStyle(
                  fontSize: 8.0,
                  fontWeight:
                      isSelected[index] ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget btn(String title, Function onPressed) {
    return SizedBox(
      width: double.infinity,
      child: elevatedButton(title, onPressed),
    );
  }

  Widget elevatedButton(String title, Function onPressed) {
    return ElevatedButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        backgroundColor:
            MaterialStateProperty.all<Color>(const Color(0xff0495ca)),
        shape: MaterialStateProperty.resolveWith<RoundedRectangleBorder>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: Colors.red, width: 1.0),
              );
            } else {
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: Colors.white, width: 1.0),
              );
            }
          },
        ),
      ),
      child: (title.isNotEmpty)
          ? Text(title, style: textStyle())
          : const Icon(Icons.refresh),
      onPressed: () async {
        await onPressed();
      },
    );
  }

  Widget amountInput() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: amount),
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color(0xff0495ca),
        hintText: "0.00",
        contentPadding: EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      onChanged: (value) {
        amount = value;
      },
    );
  }

  TextStyle textStyle() {
    return const TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic);
  }

  //showAlert
void showAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); 
            },
          ),
        ],
      );
    },
  );
}
}








