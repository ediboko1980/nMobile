import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nmobile/blocs/client/client_bloc.dart';
import 'package:nmobile/blocs/client/client_event.dart';
import 'package:nmobile/blocs/wallet/wallets_bloc.dart';
import 'package:nmobile/blocs/wallet/wallets_state.dart';
import 'package:nmobile/components/box/body.dart';
import 'package:nmobile/components/button.dart';
import 'package:nmobile/components/header/header.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/consts/theme.dart';
import 'package:nmobile/event/eventbus.dart';
import 'package:nmobile/helpers/global.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/schemas/wallet.dart';
import 'package:nmobile/utils/common_native.dart';
import 'package:nmobile/utils/nlog_util.dart';

class NoConnectScreen extends StatefulWidget {
  static const String routeName = '/chat/no_connect';

  @override
  _NoConnectScreenState createState() => _NoConnectScreenState();
}

class _NoConnectScreenState extends State<NoConnectScreen> with WidgetsBindingObserver {
  ClientBloc _clientBloc;
  WalletSchema _currentWallet;
  bool isShow = true;
  AppLifecycleState state;
  StreamSubscription tabSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    tabSubscription = eventBus.on<MainTabIndex>().listen((event) {
//      NLog.d(event.index);
//      getPassword();
    });
    _clientBloc = BlocProvider.of<ClientBloc>(context);
    initData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (this.state == AppLifecycleState.inactive && state == AppLifecycleState.resumed) {
      getPassword();
    }
    this.state = state;
    NLog.d(state.toString());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultTheme.primaryColor,
      appBar: Header(
        titleChild: Padding(
          padding: EdgeInsets.only(left: 20.h),
          child: Label(
            NMobileLocalizations.of(context).menu_chat.toUpperCase(),
            type: LabelType.h2,
          ),
        ),
        hasBack: false,
        backgroundColor: DefaultTheme.primaryColor,
        leading: null,
      ),
      body: Builder(
        builder: (BuildContext context) => BodyBox(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 100.h),
          color: DefaultTheme.backgroundColor1,
          child: Container(
            child: Flex(
              direction: Axis.vertical,
              children: <Widget>[
                Expanded(
                  flex: 0,
                  child: Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: Image(
                        image: AssetImage(
                          "assets/chat/messages.png",
                        ),
                        width: 198.w,
                        height: 144.h),
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: 32.h,
                        ),
                        child: Label(
                          NMobileLocalizations.of(context).chat_no_wallet_title,
                          type: LabelType.h2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 0, right: 0),
                        child: Label(
                          NMobileLocalizations.of(context).click_connect,
                          type: LabelType.bodyRegular,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: 80,
                        ),
                        child: BlocBuilder<WalletsBloc, WalletsState>(builder: (context, state) {
                          if (state is WalletsLoaded) {
                            _currentWallet = state.wallets.first;
                            return Button(
                              width: double.infinity,
                              text: NMobileLocalizations.of(context).connect,
                              onPressed: () {
                                _next();
                              },
                            );
                          }
                          return null;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _next() async {
    var password = await _currentWallet.getPassword();
    if (password != null) {
      _clientBloc.add(CreateClient(_currentWallet, password));
    } else {
      isShow = true;
    }
  }

  initData() async {
    WidgetsBinding.instance.addPostFrameCallback((mag) async {
      await getPassword();
    });
  }

  getPassword() async {
    bool isActive = await CommonNative.isActive();
    if (ModalRoute.of(context).settings.name == '/' && Global.currentPageIndex == 0) {
      if (isShow && isActive && _currentWallet != null) {
        isShow = false;
        _next();
      }
    }
  }
}
