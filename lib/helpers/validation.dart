import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nmobile/helpers/utils.dart';
import 'package:nmobile/l10n/localization_intl.dart';

class Validator {
  final BuildContext context;

  Validator.of(context) : this(context);

  NMobileLocalizations _localizations;
  Validator(this.context) {
    _localizations = NMobileLocalizations.of(context);
  }

  keystore() {
    return (value) {
      var jsonFormat;
      try {
        jsonDecode(value.trim());
        jsonFormat = true;
      } on FormatException catch (e) {
        jsonFormat = false;
      }

      return value.trim().length == 0 ? _localizations.error_required : !jsonFormat ? _localizations.error_keystore_format : null;
    };
  }

  seed() {
    return (value) {
      return value.trim().length == 0 ? _localizations.error_required : value.trim().length != 64 || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value) ? _localizations.error_seed_format : null;
    };
  }

  walletName() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  pubKey() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  contactName() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  amount() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  required() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  nknAddress() {
    return (value) {
      bool addressFormat = false;
      try {
        addressFormat = verifyAddress(value.trim());
      } catch (e) {
        debugPrint(e);
        debugPrintStack();
      }
      return value.trim().length == 0 ? _localizations.error_required : !addressFormat ? _localizations.error_nkn_address_format : null;
    };
  }

  nknIdentifier() {
    return (value) {
      return value.trim().length == 0 ? _localizations.error_required : !RegExp(r'^[^.]*.?[0-9a-f]{64}$').hasMatch(value) ? _localizations.error_client_address_format : null;
    };
  }

  password() {
    return (value) {
      return value.trim().length > 0 ? null : _localizations.error_required;
    };
  }

  confrimPassword(password) {
    return (value) {
      return value.trim().length == 0 ? _localizations.error_required : value != password ? _localizations.error_confirm_password : null;
    };
  }
}
