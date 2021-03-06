import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nmobile/app.dart';
import 'package:nmobile/blocs/wallet/wallets_bloc.dart';
import 'package:nmobile/blocs/wallet/wallets_event.dart';
import 'package:nmobile/components/button.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/components/textbox.dart';
import 'package:nmobile/event/eventbus.dart';
import 'package:nmobile/helpers/validation.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/plugins/nkn_wallet.dart';
import 'package:nmobile/schemas/wallet.dart';
import 'package:oktoast/oktoast.dart';

class ImportSeedNknWallet extends StatefulWidget {
  @override
  _ImportSeedNknWalletState createState() => _ImportSeedNknWalletState();
}

class _ImportSeedNknWalletState extends State<ImportSeedNknWallet> with SingleTickerProviderStateMixin {
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _formValid = false;
  TextEditingController _seedController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  FocusNode _seedFocusNode = FocusNode();
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _confirmPasswordFocusNode = FocusNode();
  WalletsBloc _walletsBloc;
  var _seed;
  var _name;
  var _password;
  StreamSubscription _qrSubscription;

  @override
  void initState() {
    super.initState();
    _walletsBloc = BlocProvider.of<WalletsBloc>(context);
    _qrSubscription = eventBus.on<QMScan>().listen((event) {
      setState(() {
        _seedController.text = event.content;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _qrSubscription.cancel();
  }

  next() async {
    if ((_formKey.currentState as FormState).validate()) {
      (_formKey.currentState as FormState).save();
      EasyLoading.show();

      String keystore = await NknWalletPlugin.createWallet(_seed, _password);
      var json = jsonDecode(keystore);
      String address = json['Address'];
      _walletsBloc.add(AddWallet(WalletSchema(address: address, type: 'nkn', name: _name), keystore));
      EasyLoading.dismiss();
      showToast(NMobileLocalizations.of(context).success);
      Navigator.pushReplacementNamed(context, AppScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: true,
      onChanged: () {
        setState(() {
          _formValid = (_formKey.currentState as FormState).validate();
        });
      },
      child: Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(top: 0),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32, left: 20, right: 20),
                    child: Flex(
                      direction: Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 0,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Label(
                                    NMobileLocalizations.of(context).import_seed_nkn_wallet_title,
                                    type: LabelType.h2,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Label(
                                    NMobileLocalizations.of(context).import_seed_nkn_wallet_desc,
                                    type: LabelType.bodyRegular,
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  ),
                                ),
                                Label(
                                  NMobileLocalizations.of(context).seed,
                                  type: LabelType.h4,
                                  textAlign: TextAlign.start,
                                ),
                                Textbox(
                                  controller: _seedController,
                                  focusNode: _seedFocusNode,
                                  hintText: NMobileLocalizations.of(context).input_seed,
                                  onSaved: (v) => _seed = v,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_nameFocusNode);
                                  },
                                  validator: Validator.of(context).seed(),
                                ),
                                Label(
                                  NMobileLocalizations.of(context).wallet_name,
                                  type: LabelType.h4,
                                  textAlign: TextAlign.start,
                                ),
                                Textbox(
                                  focusNode: _nameFocusNode,
                                  hintText: NMobileLocalizations.of(context).hint_enter_wallet_name,
                                  onSaved: (v) => _name = v,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                                  },
                                  textInputAction: TextInputAction.next,
                                  validator: Validator.of(context).walletName(),
                                ),
                                Label(
                                  NMobileLocalizations.of(context).wallet_password,
                                  type: LabelType.h4,
                                  textAlign: TextAlign.start,
                                ),
                                Textbox(
                                  focusNode: _passwordFocusNode,
                                  controller: _passwordController,
                                  hintText: NMobileLocalizations.of(context).input_password,
                                  onSaved: (v) => _password = v,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                                  },
                                  validator: Validator.of(context).password(),
                                  password: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8, top: 8),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 30, right: 30),
                      child: Button(
                        text: NMobileLocalizations.of(context).import_wallet,
                        disabled: !_formValid,
                        onPressed: next,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
