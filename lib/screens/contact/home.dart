import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nmobile/blocs/contact/contact_bloc.dart';
import 'package:nmobile/blocs/contact/contact_state.dart';
import 'package:nmobile/components/box/body.dart';
import 'package:nmobile/components/button.dart';
import 'package:nmobile/components/dialog/modal.dart';
import 'package:nmobile/components/header/header.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/consts/theme.dart';
import 'package:nmobile/event/eventbus.dart';
import 'package:nmobile/helpers/format.dart';
import 'package:nmobile/helpers/global.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/schemas/chat.dart';
import 'package:nmobile/schemas/contact.dart';
import 'package:nmobile/schemas/topic.dart';
import 'package:nmobile/screens/chat/channel.dart';
import 'package:nmobile/screens/contact/add_contact.dart';
import 'package:nmobile/screens/contact/contact.dart';
import 'package:nmobile/screens/contact/no_contact.dart';
import 'package:nmobile/utils/image_utils.dart';

class ContactHome extends StatefulWidget {
  static const String routeName = '/contact/home';

  @override
  _ContactHomeState createState() => _ContactHomeState();

  bool arguments;

  ContactHome({this.arguments = false}) {
    if (arguments == null) arguments = false;
  }
}

class _ContactHomeState extends State<ContactHome> {
  ScrollController _scrollController = ScrollController();
  List<ContactSchema> _friends = <ContactSchema>[];
  List<ContactSchema> _strangerContacts = <ContactSchema>[];
  List<TopicSchema> _topic = <TopicSchema>[];

  List<ContactSchema> _allFriends = <ContactSchema>[];
  List<ContactSchema> _allStrangerContacts = <ContactSchema>[];
  List<TopicSchema> _allTopic = <TopicSchema>[];
  int _limit = 100;
  int _skip = 20;
  bool loading = false;
  String searchText = '';
  ContactBloc _contactBloc;
  StreamSubscription _addContactSubscription;

  initAsync() async {
    var topic = widget.arguments ? <TopicSchema>[] : await TopicSchema.getAllTopic();
    var friends = await ContactSchema.getContacts(limit: _limit);
    var stranger = await ContactSchema.getStrangerContacts(limit: 10);
    setState(() {
      _friends = friends ?? [];
      _strangerContacts = stranger ?? [];
      _topic = topic ?? [];

      _allFriends = _friends;
      _allStrangerContacts = _strangerContacts;
      _allTopic = _topic;
    });
  }

  @override
  void initState() {
    super.initState();
    _contactBloc = BlocProvider.of<ContactBloc>(context);
    _contactBloc.listen((state) async {
      if (state is ContactLoading) {}
    });

    _addContactSubscription = eventBus.on<AddContactEvent>().listen((event) {
      initAsync();
    });
    initAsync();
  }

  @override
  void dispose() {
    super.dispose();
    _addContactSubscription.cancel();
  }

  Future _itemOnTap(ContactSchema item) async {
    if (widget.arguments) {
      Navigator.of(context).pop(item);
    } else {
      await Navigator.of(context)
          .pushNamed(
        ContactScreen.routeName,
        arguments: item,
      )
          .then((v) {
        initAsync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allTopic.length > 0 || _allStrangerContacts.length > 0 || searchText.length != 0 || _allFriends.length > 0) {
      List<Widget> friendList = getFriendItemView();
      List<Widget> strangerContactList = getStrangeContactList();
      List<Widget> topicList = getTopicList();
      return Scaffold(
        backgroundColor: DefaultTheme.primaryColor,
        appBar: Header(
          titleChild: GestureDetector(
            onTap: () async {
              Navigator.of(context).pushNamed(ContactScreen.routeName, arguments: Global.currentUser);
            },
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.center,
                    child: Hero(
                      tag: 'header_avatar:${Global.currentUser.clientAddress}',
                      child: Global.currentUser.avatarWidget(backgroundColor: DefaultTheme.backgroundLightColor.withAlpha(200), size: 28),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Label(Global.currentUser.name, type: LabelType.h3, dark: true),
                      Label(NMobileLocalizations.of(context).connected, type: LabelType.bodySmall, color: DefaultTheme.riseColor),
                    ],
                  ),
                )
              ],
            ),
          ),
          backgroundColor: DefaultTheme.primaryColor,
          action: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/user-plus.svg',
              color: DefaultTheme.backgroundLightColor,
              width: 24,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AddContact.routeName).then((value) {
                if (value != null) {
                  initAsync();
                }
              });
            },
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: BodyBox(
            padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
            color: DefaultTheme.backgroundLightColor,
            child: Flex(
              crossAxisAlignment: CrossAxisAlignment.start,
              direction: Axis.vertical,
              children: <Widget>[
                Expanded(
                  flex: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DefaultTheme.backgroundColor1,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Flex(
                        direction: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            flex: 0,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: loadAssetIconsImage(
                                'search',
                                color: DefaultTheme.fontColor2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              onChanged: (val) {
                                searchAction(val);
                              },
                              style: TextStyle(fontSize: 14, height: 1.5),
                              decoration: InputDecoration(
                                hintText: NMobileLocalizations.of(context).search,
                                contentPadding: const EdgeInsets.only(left: 0, right: 16, top: 9, bottom: 9),
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                  borderSide: const BorderSide(width: 0, style: BorderStyle.none),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 60),
                    controller: _scrollController,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: friendList,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: topicList,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: strangerContactList,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return NoContactScreen();
    }
  }

  List<Widget> getFriendItemView() {
    List<Widget> contactList = [];
    if (_friends.length > 0) {
      contactList.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        child: Label(
          '(${_friends.length}) ${NMobileLocalizations.of(context).friends}',
          type: LabelType.h3,
          height: 1,
        ),
      ));
    }

    for (var item in _friends) {
      contactList.add(Dismissible(
        key: ObjectKey(item),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            var isDismiss = await ModalDialog.of(context).confirm(
              height: 380,
              title: Label(
                NMobileLocalizations.of(context).delete_contact_confirm_title,
                type: LabelType.h2,
                softWrap: true,
              ),
              content: Column(
                children: <Widget>[
                  Container(
                    child: Container(
                      height: 80,
                      padding: const EdgeInsets.only(),
                      child: Flex(
                        direction: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 0,
                            child: Container(
                              padding: const EdgeInsets.only(right: 16),
                              alignment: Alignment.center,
                              child: Hero(
                                tag: 'avatar:${item.clientAddress}',
                                child: item.avatarWidget(
                                  size: 24,
                                  backgroundColor: DefaultTheme.primaryColor.withAlpha(25),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Flex(
                              direction: Axis.horizontal,
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    height: 50,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Label(
                                          item.name,
                                          type: LabelType.h3,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Label(
                                                item.clientAddress,
                                                softWrap: true,
                                                type: LabelType.bodyRegular,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              agree: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Button(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: loadAssetIconsImage(
                          'trash',
                          color: DefaultTheme.backgroundLightColor,
                          width: 24,
                        ),
                      ),
                      Label(
                        NMobileLocalizations.of(context).delete,
                        type: LabelType.h3,
                      )
                    ],
                  ),
                  backgroundColor: DefaultTheme.strongColor,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
              reject: Button(
                backgroundColor: DefaultTheme.backgroundLightColor,
                fontColor: DefaultTheme.fontColor2,
                text: NMobileLocalizations.of(context).cancel,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
            return isDismiss;
          }
          return false;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            item.deleteContact().then((count) {
              if (count > 0) {
                setState(() {
                  _friends.remove(item);
                });
              }
            });
          }
        },
        background: Container(
          color: Colors.green,
          child: ListTile(
            leading: Icon(
              Icons.bookmark,
              color: Colors.white,
            ),
          ),
        ),
        secondaryBackground: Container(
          color: Colors.red,
          alignment: Alignment.center,
          child: ListTile(
            trailing: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        child: InkWell(
          onTap: () async {
            _itemOnTap(item);
          },
          child: Container(
            height: 72,
            padding: const EdgeInsets.only(),
            child: Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.center,
                    child: item.avatarWidget(
                      size: 24,
                      backgroundColor: DefaultTheme.primaryColor.withAlpha(25),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.only(),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: DefaultTheme.backgroundColor2)),
                    ),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            height: 44,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Label(
                                  item.name,
                                  type: LabelType.h3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Label(
                                  Format.timeFormat(item.updatedTime),
                                  height: 1,
                                  type: LabelType.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: Container(
                            alignment: Alignment.centerRight,
                            height: 44,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Label(
                                      item.isMe ? 'Me' : '',
                                      type: LabelType.bodySmall,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 16,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return contactList;
  }

  List<Widget> getStrangeContactList() {
    List<Widget> strangerContactList = [];
    if (_strangerContacts.length > 0) {
      strangerContactList.add(Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 16),
        child: Label(
          '(${_strangerContacts.length}) ${NMobileLocalizations.of(context).recent}',
          type: LabelType.h3,
          height: 1,
        ),
      ));
    }

    for (var item in _strangerContacts) {
      strangerContactList.add(InkWell(
        onTap: () async {
          _itemOnTap(item);
        },
        child: Container(
          height: 72,
          padding: const EdgeInsets.only(),
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.only(right: 16),
                  alignment: Alignment.center,
                  child: item.avatarWidget(
                    size: 24,
                    backgroundColor: DefaultTheme.primaryColor.withAlpha(25),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: DefaultTheme.backgroundColor2)),
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          height: 44,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Label(
                                item.name,
                                type: LabelType.h3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Label(
                                item.clientAddress,
                                height: 1,
                                type: LabelType.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Container(
                          alignment: Alignment.centerRight,
                          height: 44,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Label(
                                    item.isMe ? 'Me' : '',
                                    type: LabelType.bodySmall,
                                  ),
                                ),
                                SizedBox(
                                  height: 16,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return strangerContactList;
  }

  List<Widget> getTopicList() {
    List<Widget> topicList = [];
    if (_topic.length > 0) {
      topicList.add(Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 16),
        child: Label(
          '(${_topic.length}) ${NMobileLocalizations.of(context).group_chat}',
          type: LabelType.h3,
          height: 1,
        ),
      ));
    }

    for (var item in _topic) {
      String name = item.topicName;
      if (item.type == TopicType.private) {
        name = item.topicName + '.' + item.owner.substring(0, 8);
      }

      topicList.add(InkWell(
        onTap: () async {
          TopicSchema topic = await TopicSchema.getTopic(item.topic);
          Navigator.of(context).pushNamed(ChatGroupPage.routeName, arguments: ChatSchema(type: ChatType.Channel, topic: topic));
        },
        child: Container(
          height: 72,
          padding: const EdgeInsets.only(),
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.only(right: 16),
                  alignment: Alignment.center,
                  child: item.avatarWidget(
                    size: 48,
                    fontColor: DefaultTheme.primaryColor,
                    backgroundColor: DefaultTheme.primaryColor.withAlpha(25),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: DefaultTheme.backgroundColor2)),
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          height: 44,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  item.type == TopicType.private
                                      ? loadAssetIconsImage(
                                          'lock',
                                          width: 18,
                                          color: DefaultTheme.primaryColor,
                                        )
                                      : Container(),
                                  Label(
                                    name,
                                    type: LabelType.h3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Label(
                                item.topic,
                                height: 1,
                                type: LabelType.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return topicList;
  }

  searchAction(String val) {
    if (val.length == 0) {
      setState(() {
        _friends = _allFriends;
        _strangerContacts = _allStrangerContacts;
        _topic = _allTopic;
      });
    } else {
      setState(() {
        _strangerContacts = _allStrangerContacts.where((ContactSchema e) => e.name.toLowerCase().contains(val.toLowerCase())).toList();
        _friends = _allFriends.where((ContactSchema e) => e.name.contains(val)).toList();
        _topic = _allTopic.where((TopicSchema e) => e.topic.contains(val)).toList();
      });
    }
  }
}
