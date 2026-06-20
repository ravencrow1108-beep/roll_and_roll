import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'Roll and Roll'**
  String get appTitle;

  /// No description provided for @commoncancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commoncancel;

  /// No description provided for @commonsave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonsave;

  /// No description provided for @commonadd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonadd;

  /// No description provided for @commonclose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonclose;

  /// No description provided for @commondelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commondelete;

  /// No description provided for @commonedit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonedit;

  /// No description provided for @commonremove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get commonremove;

  /// No description provided for @commonconfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonconfirm;

  /// No description provided for @commonback.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonback;

  /// No description provided for @commonretry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonretry;

  /// No description provided for @commonselectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get commonselectAll;

  /// No description provided for @commonclearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get commonclearAll;

  /// No description provided for @commonnoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get commonnoData;

  /// No description provided for @commonsearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get commonsearch;

  /// No description provided for @commonsend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get commonsend;

  /// No description provided for @commoncopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commoncopy;

  /// No description provided for @commondecrease.
  ///
  /// In zh, this message translates to:
  /// **'减少'**
  String get commondecrease;

  /// No description provided for @commonincrease.
  ///
  /// In zh, this message translates to:
  /// **'增加'**
  String get commonincrease;

  /// No description provided for @hometitle.
  ///
  /// In zh, this message translates to:
  /// **'选择你想要开始的方式'**
  String get hometitle;

  /// No description provided for @homeplayerName.
  ///
  /// In zh, this message translates to:
  /// **'你的玩家名称'**
  String get homeplayerName;

  /// No description provided for @homeplayerNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：阿宇'**
  String get homeplayerNameHint;

  /// No description provided for @homecreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'新建房间'**
  String get homecreateRoom;

  /// No description provided for @homejoinRoom.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get homejoinRoom;

  /// No description provided for @homeliveMode.
  ///
  /// In zh, this message translates to:
  /// **'直播模式'**
  String get homeliveMode;

  /// No description provided for @homecreateSave.
  ///
  /// In zh, this message translates to:
  /// **'创建存档'**
  String get homecreateSave;

  /// No description provided for @homemodifySave.
  ///
  /// In zh, this message translates to:
  /// **'修改存档'**
  String get homemodifySave;

  /// No description provided for @homewebWarning.
  ///
  /// In zh, this message translates to:
  /// **'Web 端不支持创建房间。你可以加入桌面端创建的房间，或直接使用直播模式。'**
  String get homewebWarning;

  /// No description provided for @settingstitle.
  ///
  /// In zh, this message translates to:
  /// **'软件设置'**
  String get settingstitle;

  /// No description provided for @settingslanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言 Language'**
  String get settingslanguage;

  /// No description provided for @settingslangChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get settingslangChinese;

  /// No description provided for @settingslangEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settingslangEnglish;

  /// No description provided for @settingsRestartHintZh.
  ///
  /// In zh, this message translates to:
  /// **'切换语言后重启应用生效'**
  String get settingsRestartHintZh;

  /// No description provided for @settingsRestartHintEn.
  ///
  /// In zh, this message translates to:
  /// **'Restart the app after switching language'**
  String get settingsRestartHintEn;

  /// No description provided for @roomCreatetitle.
  ///
  /// In zh, this message translates to:
  /// **'新建房间'**
  String get roomCreatetitle;

  /// No description provided for @roomCreatecloudTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建云端房间'**
  String get roomCreatecloudTitle;

  /// No description provided for @roomCreatelocalTitle.
  ///
  /// In zh, this message translates to:
  /// **'开放本机端口'**
  String get roomCreatelocalTitle;

  /// No description provided for @roomCreatecloudDesc.
  ///
  /// In zh, this message translates to:
  /// **'通过 Cloudflare 全球网络创建房间，无需开放端口'**
  String get roomCreatecloudDesc;

  /// No description provided for @roomCreateportLabel.
  ///
  /// In zh, this message translates to:
  /// **'端口号'**
  String get roomCreateportLabel;

  /// No description provided for @roomCreateopenPort.
  ///
  /// In zh, this message translates to:
  /// **'开放端口'**
  String get roomCreateopenPort;

  /// No description provided for @roomCreateclosePort.
  ///
  /// In zh, this message translates to:
  /// **'关闭端口'**
  String get roomCreateclosePort;

  /// No description provided for @roomCreatecreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'创建房间'**
  String get roomCreatecreateRoom;

  /// No description provided for @roomCreatecloseRoom.
  ///
  /// In zh, this message translates to:
  /// **'关闭房间'**
  String get roomCreatecloseRoom;

  /// No description provided for @roomCreatestatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get roomCreatestatus;

  /// No description provided for @roomCreateaddress.
  ///
  /// In zh, this message translates to:
  /// **'房间地址'**
  String get roomCreateaddress;

  /// No description provided for @roomCreateroomIdCopied.
  ///
  /// In zh, this message translates to:
  /// **'房间号已复制！'**
  String get roomCreateroomIdCopied;

  /// No description provided for @roomCreaterefreshMembers.
  ///
  /// In zh, this message translates to:
  /// **'刷新成员列表'**
  String get roomCreaterefreshMembers;

  /// No description provided for @roomCreateselectIdentity.
  ///
  /// In zh, this message translates to:
  /// **'选择身份'**
  String get roomCreateselectIdentity;

  /// No description provided for @roomCreateselectArchive.
  ///
  /// In zh, this message translates to:
  /// **'选择存档'**
  String get roomCreateselectArchive;

  /// No description provided for @roomCreatecreateArchive.
  ///
  /// In zh, this message translates to:
  /// **'创建存档'**
  String get roomCreatecreateArchive;

  /// No description provided for @roomCreateeditArchive.
  ///
  /// In zh, this message translates to:
  /// **'编辑存档'**
  String get roomCreateeditArchive;

  /// No description provided for @roomCreateselectArchiveFile.
  ///
  /// In zh, this message translates to:
  /// **'选择存档文件'**
  String get roomCreateselectArchiveFile;

  /// No description provided for @roomCreatepleaseSelectArchive.
  ///
  /// In zh, this message translates to:
  /// **'请先选择存档文件'**
  String get roomCreatepleaseSelectArchive;

  /// No description provided for @roomCreateopenArchiveFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开存档失败'**
  String get roomCreateopenArchiveFailed;

  /// No description provided for @roomCreateenterPort.
  ///
  /// In zh, this message translates to:
  /// **'请输入端口号'**
  String get roomCreateenterPort;

  /// No description provided for @roomCreateportRange.
  ///
  /// In zh, this message translates to:
  /// **'端口号必须是 1~65535 之间的整数'**
  String get roomCreateportRange;

  /// No description provided for @roomCreatedesktopOnly.
  ///
  /// In zh, this message translates to:
  /// **'请在桌面端运行'**
  String get roomCreatedesktopOnly;

  /// No description provided for @roomCreateroomId.
  ///
  /// In zh, this message translates to:
  /// **'房间号'**
  String get roomCreateroomId;

  /// No description provided for @roomCreatetellTeammates.
  ///
  /// In zh, this message translates to:
  /// **'告诉队友这个'**
  String get roomCreatetellTeammates;

  /// No description provided for @roomCreateportOpened.
  ///
  /// In zh, this message translates to:
  /// **'已开放端口'**
  String get roomCreateportOpened;

  /// No description provided for @roomCreatelocalAddress.
  ///
  /// In zh, this message translates to:
  /// **'本机地址'**
  String get roomCreatelocalAddress;

  /// No description provided for @roomCreatecreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败'**
  String get roomCreatecreateFailed;

  /// No description provided for @roomCreateopenPortFailed.
  ///
  /// In zh, this message translates to:
  /// **'开放端口失败'**
  String get roomCreateopenPortFailed;

  /// No description provided for @roomCreatenotCreated.
  ///
  /// In zh, this message translates to:
  /// **'尚未创建房间'**
  String get roomCreatenotCreated;

  /// No description provided for @roomCreatewaitCreate.
  ///
  /// In zh, this message translates to:
  /// **'等待创建房间'**
  String get roomCreatewaitCreate;

  /// No description provided for @roomCreateroomClosed.
  ///
  /// In zh, this message translates to:
  /// **'房间已关闭'**
  String get roomCreateroomClosed;

  /// No description provided for @roomCreateportClosed.
  ///
  /// In zh, this message translates to:
  /// **'已关闭端口'**
  String get roomCreateportClosed;

  /// No description provided for @roomCreatewaitOpenPort.
  ///
  /// In zh, this message translates to:
  /// **'等待开放端口'**
  String get roomCreatewaitOpenPort;

  /// No description provided for @roomCreatemembers.
  ///
  /// In zh, this message translates to:
  /// **'房间成员'**
  String get roomCreatemembers;

  /// No description provided for @roomCreateready.
  ///
  /// In zh, this message translates to:
  /// **'已准备'**
  String get roomCreateready;

  /// No description provided for @roomCreatenotReady.
  ///
  /// In zh, this message translates to:
  /// **'未准备'**
  String get roomCreatenotReady;

  /// No description provided for @roomCreatereadyUp.
  ///
  /// In zh, this message translates to:
  /// **'准备就绪'**
  String get roomCreatereadyUp;

  /// No description provided for @roomCreatecancelReady.
  ///
  /// In zh, this message translates to:
  /// **'取消准备'**
  String get roomCreatecancelReady;

  /// No description provided for @roomCreatewaitAllReady.
  ///
  /// In zh, this message translates to:
  /// **'等待所有成员准备就绪'**
  String get roomCreatewaitAllReady;

  /// No description provided for @roomCreateadventureInProgress.
  ///
  /// In zh, this message translates to:
  /// **'冒险进行中'**
  String get roomCreateadventureInProgress;

  /// No description provided for @roomCreatestartAdventure.
  ///
  /// In zh, this message translates to:
  /// **'开始冒险'**
  String get roomCreatestartAdventure;

  /// No description provided for @roomCreateconfirmKick.
  ///
  /// In zh, this message translates to:
  /// **'确认踢出'**
  String get roomCreateconfirmKick;

  /// No description provided for @roomCreateconfirmKickContent.
  ///
  /// In zh, this message translates to:
  /// **'确定要将 {name} 踢出房间吗？'**
  String roomCreateconfirmKickContent(Object name);

  /// No description provided for @roomCreatekick.
  ///
  /// In zh, this message translates to:
  /// **'踢出'**
  String get roomCreatekick;

  /// No description provided for @roomCreateRolePlayer.
  ///
  /// In zh, this message translates to:
  /// **'玩家'**
  String get roomCreateRolePlayer;

  /// No description provided for @roomCreateRoleHost.
  ///
  /// In zh, this message translates to:
  /// **'主持'**
  String get roomCreateRoleHost;

  /// No description provided for @roomJointitle.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get roomJointitle;

  /// No description provided for @roomJoinbyRoomId.
  ///
  /// In zh, this message translates to:
  /// **'输入房间号'**
  String get roomJoinbyRoomId;

  /// No description provided for @roomJoinbyIp.
  ///
  /// In zh, this message translates to:
  /// **'通过 IP 和端口加入房间'**
  String get roomJoinbyIp;

  /// No description provided for @roomJoinaskHost.
  ///
  /// In zh, this message translates to:
  /// **'让房主把房间号发给你'**
  String get roomJoinaskHost;

  /// No description provided for @roomJoinroomIdLabel.
  ///
  /// In zh, this message translates to:
  /// **'房间号'**
  String get roomJoinroomIdLabel;

  /// No description provided for @roomJoinipLabel.
  ///
  /// In zh, this message translates to:
  /// **'房间 IP'**
  String get roomJoinipLabel;

  /// No description provided for @roomJoinroomIdHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: ABC123'**
  String get roomJoinroomIdHint;

  /// No description provided for @roomJoinipHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: 127.0.0.1'**
  String get roomJoinipHint;

  /// No description provided for @roomJoinportLabel.
  ///
  /// In zh, this message translates to:
  /// **'房间端口'**
  String get roomJoinportLabel;

  /// No description provided for @roomJoinconnecting.
  ///
  /// In zh, this message translates to:
  /// **'连接中...'**
  String get roomJoinconnecting;

  /// No description provided for @roomJoinjoinRoom.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get roomJoinjoinRoom;

  /// No description provided for @roomJoinenterRoomId.
  ///
  /// In zh, this message translates to:
  /// **'请输入房间号'**
  String get roomJoinenterRoomId;

  /// No description provided for @roomJoinenterIp.
  ///
  /// In zh, this message translates to:
  /// **'请输入 IP'**
  String get roomJoinenterIp;

  /// No description provided for @roomJoinenterPort.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效端口号'**
  String get roomJoinenterPort;

  /// No description provided for @roomJoinwaitingConfirm.
  ///
  /// In zh, this message translates to:
  /// **'等待房主确认...'**
  String get roomJoinwaitingConfirm;

  /// No description provided for @roomJoinjoined.
  ///
  /// In zh, this message translates to:
  /// **'已加入房间'**
  String get roomJoinjoined;

  /// No description provided for @roomJoinjoinFailed.
  ///
  /// In zh, this message translates to:
  /// **'加入失败'**
  String get roomJoinjoinFailed;

  /// No description provided for @roomJoinreconnecting.
  ///
  /// In zh, this message translates to:
  /// **'重连中...'**
  String get roomJoinreconnecting;

  /// No description provided for @roomJoinreconnected.
  ///
  /// In zh, this message translates to:
  /// **'已重连'**
  String get roomJoinreconnected;

  /// No description provided for @roomJoinreconnectFailed.
  ///
  /// In zh, this message translates to:
  /// **'重连失败'**
  String get roomJoinreconnectFailed;

  /// No description provided for @roomJoinconnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接到房间'**
  String get roomJoinconnected;

  /// No description provided for @roomJoinleaveRoom.
  ///
  /// In zh, this message translates to:
  /// **'离开房间'**
  String get roomJoinleaveRoom;

  /// No description provided for @roomJoinyourName.
  ///
  /// In zh, this message translates to:
  /// **'你的名称'**
  String get roomJoinyourName;

  /// No description provided for @roomJoinyourRole.
  ///
  /// In zh, this message translates to:
  /// **'你的身份'**
  String get roomJoinyourRole;

  /// No description provided for @roomJoinswitchRole.
  ///
  /// In zh, this message translates to:
  /// **'切换身份'**
  String get roomJoinswitchRole;

  /// No description provided for @roomJoinhostSave.
  ///
  /// In zh, this message translates to:
  /// **'房主备档'**
  String get roomJoinhostSave;

  /// No description provided for @roomJoinadventureStarted.
  ///
  /// In zh, this message translates to:
  /// **'冒险已开始'**
  String get roomJoinadventureStarted;

  /// No description provided for @roomJoinroomMembers.
  ///
  /// In zh, this message translates to:
  /// **'房间成员'**
  String get roomJoinroomMembers;

  /// No description provided for @roomJoinnameInUse.
  ///
  /// In zh, this message translates to:
  /// **'名称已被使用，请更换名称后重试'**
  String get roomJoinnameInUse;

  /// No description provided for @roomJoinkicked.
  ///
  /// In zh, this message translates to:
  /// **'你已被踢出房间'**
  String get roomJoinkicked;

  /// No description provided for @adventuretitle.
  ///
  /// In zh, this message translates to:
  /// **'冒险中'**
  String get adventuretitle;

  /// No description provided for @adventurereturnToRoom.
  ///
  /// In zh, this message translates to:
  /// **'返回房间'**
  String get adventurereturnToRoom;

  /// No description provided for @adventuresaveProgress.
  ///
  /// In zh, this message translates to:
  /// **'保存进度'**
  String get adventuresaveProgress;

  /// No description provided for @adventuresaveAs.
  ///
  /// In zh, this message translates to:
  /// **'另存为'**
  String get adventuresaveAs;

  /// No description provided for @adventureexitAdventure.
  ///
  /// In zh, this message translates to:
  /// **'退出冒险'**
  String get adventureexitAdventure;

  /// No description provided for @adventureexitConfirm.
  ///
  /// In zh, this message translates to:
  /// **'退出冒险将踢出所有玩家，确定要退出吗？'**
  String get adventureexitConfirm;

  /// No description provided for @adventureexit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get adventureexit;

  /// No description provided for @adventuresaveAndExit.
  ///
  /// In zh, this message translates to:
  /// **'保存进度并退出'**
  String get adventuresaveAndExit;

  /// No description provided for @adventurechat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get adventurechat;

  /// No description provided for @adventureenterAdventure.
  ///
  /// In zh, this message translates to:
  /// **'进入冒险'**
  String get adventureenterAdventure;

  /// No description provided for @adventureplayerList.
  ///
  /// In zh, this message translates to:
  /// **'角色列表'**
  String get adventureplayerList;

  /// No description provided for @adventurerightClickDeploy.
  ///
  /// In zh, this message translates to:
  /// **'右键头像上场'**
  String get adventurerightClickDeploy;

  /// No description provided for @adventurenoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色'**
  String get adventurenoCharacters;

  /// No description provided for @adventurenoEquipment.
  ///
  /// In zh, this message translates to:
  /// **'暂无装备'**
  String get adventurenoEquipment;

  /// No description provided for @adventurenoItems.
  ///
  /// In zh, this message translates to:
  /// **'暂无物品'**
  String get adventurenoItems;

  /// No description provided for @adventurenoSkills.
  ///
  /// In zh, this message translates to:
  /// **'暂无技能'**
  String get adventurenoSkills;

  /// No description provided for @adventureequipment.
  ///
  /// In zh, this message translates to:
  /// **'装备'**
  String get adventureequipment;

  /// No description provided for @adventureitems.
  ///
  /// In zh, this message translates to:
  /// **'物品'**
  String get adventureitems;

  /// No description provided for @adventureskills.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get adventureskills;

  /// No description provided for @adventureaddEquipment.
  ///
  /// In zh, this message translates to:
  /// **'添加装备'**
  String get adventureaddEquipment;

  /// No description provided for @adventureaddItem.
  ///
  /// In zh, this message translates to:
  /// **'添加物品'**
  String get adventureaddItem;

  /// No description provided for @adventuresearchEquipment.
  ///
  /// In zh, this message translates to:
  /// **'搜索装备名称/位置/效果…'**
  String get adventuresearchEquipment;

  /// No description provided for @adventuresearchItems.
  ///
  /// In zh, this message translates to:
  /// **'搜索物品名称/类型/效果…'**
  String get adventuresearchItems;

  /// No description provided for @adventurenoMatchEquipment.
  ///
  /// In zh, this message translates to:
  /// **'无匹配装备模板'**
  String get adventurenoMatchEquipment;

  /// No description provided for @adventurenoMatchItems.
  ///
  /// In zh, this message translates to:
  /// **'无匹配物品模板'**
  String get adventurenoMatchItems;

  /// No description provided for @adventureclosePanel.
  ///
  /// In zh, this message translates to:
  /// **'关闭面板'**
  String get adventureclosePanel;

  /// No description provided for @adventuretotalValue.
  ///
  /// In zh, this message translates to:
  /// **'总价值'**
  String get adventuretotalValue;

  /// No description provided for @adventuredeploy.
  ///
  /// In zh, this message translates to:
  /// **'上场'**
  String get adventuredeploy;

  /// No description provided for @adventuredeployHint.
  ///
  /// In zh, this message translates to:
  /// **'点击地图放置'**
  String get adventuredeployHint;

  /// No description provided for @adventuretakeDown.
  ///
  /// In zh, this message translates to:
  /// **'下场'**
  String get adventuretakeDown;

  /// No description provided for @adventureeditHp.
  ///
  /// In zh, this message translates to:
  /// **'编辑血量'**
  String get adventureeditHp;

  /// No description provided for @adventurecurrentHp.
  ///
  /// In zh, this message translates to:
  /// **'当前 HP'**
  String get adventurecurrentHp;

  /// No description provided for @adventuremaxHp.
  ///
  /// In zh, this message translates to:
  /// **'最大 HP'**
  String get adventuremaxHp;

  /// No description provided for @adventurenotes.
  ///
  /// In zh, this message translates to:
  /// **'注释'**
  String get adventurenotes;

  /// No description provided for @adventurenewNote.
  ///
  /// In zh, this message translates to:
  /// **'新注释'**
  String get adventurenewNote;

  /// No description provided for @adventurenoteHint.
  ///
  /// In zh, this message translates to:
  /// **'记录角色的状态变化、Buff、Debuff 等…'**
  String get adventurenoteHint;

  /// No description provided for @adventurehostMode.
  ///
  /// In zh, this message translates to:
  /// **'主持模式'**
  String get adventurehostMode;

  /// No description provided for @adventurecharacterManagement.
  ///
  /// In zh, this message translates to:
  /// **'角色管理'**
  String get adventurecharacterManagement;

  /// No description provided for @adventureaddCharacter.
  ///
  /// In zh, this message translates to:
  /// **'添加角色'**
  String get adventureaddCharacter;

  /// No description provided for @adventureremoveCharacter.
  ///
  /// In zh, this message translates to:
  /// **'移除角色'**
  String get adventureremoveCharacter;

  /// No description provided for @adventuresaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'进度已保存'**
  String get adventuresaveSuccess;

  /// No description provided for @adventuresaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get adventuresaveFailed;

  /// No description provided for @adventureconfirmSave.
  ///
  /// In zh, this message translates to:
  /// **'确认保存'**
  String get adventureconfirmSave;

  /// No description provided for @adventureconfirmSaveContent.
  ///
  /// In zh, this message translates to:
  /// **'当前操作会覆盖旧的存档，是否继续？'**
  String get adventureconfirmSaveContent;

  /// No description provided for @adventuresavedAs.
  ///
  /// In zh, this message translates to:
  /// **'已另存为'**
  String get adventuresavedAs;

  /// No description provided for @adventuresaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get adventuresaved;

  /// No description provided for @adventureexpressionInvalid.
  ///
  /// In zh, this message translates to:
  /// **'表达式无效'**
  String get adventureexpressionInvalid;

  /// No description provided for @adventurespeakingCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 人'**
  String adventurespeakingCount(Object count);

  /// No description provided for @adventureunmute.
  ///
  /// In zh, this message translates to:
  /// **'打开麦克风'**
  String get adventureunmute;

  /// No description provided for @adventuremute.
  ///
  /// In zh, this message translates to:
  /// **'关闭麦克风'**
  String get adventuremute;

  /// No description provided for @adventureselectMic.
  ///
  /// In zh, this message translates to:
  /// **'选择麦克风'**
  String get adventureselectMic;

  /// No description provided for @adventurejoinVoice.
  ///
  /// In zh, this message translates to:
  /// **'加入语音频道'**
  String get adventurejoinVoice;

  /// No description provided for @adventureleaveVoice.
  ///
  /// In zh, this message translates to:
  /// **'退出语音频道'**
  String get adventureleaveVoice;

  /// No description provided for @adventureequipped.
  ///
  /// In zh, this message translates to:
  /// **'装备了'**
  String get adventureequipped;

  /// No description provided for @adventureobtained.
  ///
  /// In zh, this message translates to:
  /// **'获得了'**
  String get adventureobtained;

  /// No description provided for @adventurenoteAdded.
  ///
  /// In zh, this message translates to:
  /// **'新增注释'**
  String get adventurenoteAdded;

  /// No description provided for @adventurenoteDeleted.
  ///
  /// In zh, this message translates to:
  /// **'注释已删除'**
  String get adventurenoteDeleted;

  /// No description provided for @adventuredeployed.
  ///
  /// In zh, this message translates to:
  /// **'已上场'**
  String get adventuredeployed;

  /// No description provided for @adventuretakenDown.
  ///
  /// In zh, this message translates to:
  /// **'已下场'**
  String get adventuretakenDown;

  /// No description provided for @adventuregridOn.
  ///
  /// In zh, this message translates to:
  /// **'显示网格'**
  String get adventuregridOn;

  /// No description provided for @adventuregridOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭网格'**
  String get adventuregridOff;

  /// No description provided for @adventurecoordsOn.
  ///
  /// In zh, this message translates to:
  /// **'显示坐标'**
  String get adventurecoordsOn;

  /// No description provided for @adventurecoordsOff.
  ///
  /// In zh, this message translates to:
  /// **'隐藏坐标'**
  String get adventurecoordsOff;

  /// No description provided for @adventurerollDice.
  ///
  /// In zh, this message translates to:
  /// **'投掷'**
  String get adventurerollDice;

  /// No description provided for @adventureexpandDice.
  ///
  /// In zh, this message translates to:
  /// **'展开骰子'**
  String get adventureexpandDice;

  /// No description provided for @adventurecollapseDice.
  ///
  /// In zh, this message translates to:
  /// **'收起骰子'**
  String get adventurecollapseDice;

  /// No description provided for @adventurechatHint.
  ///
  /// In zh, this message translates to:
  /// **'输入消息…'**
  String get adventurechatHint;

  /// No description provided for @mapeditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑地图'**
  String get mapeditTitle;

  /// No description provided for @mapselectMap.
  ///
  /// In zh, this message translates to:
  /// **'选择地图'**
  String get mapselectMap;

  /// No description provided for @mapnoMaps.
  ///
  /// In zh, this message translates to:
  /// **'该存档中没有地图'**
  String get mapnoMaps;

  /// No description provided for @maporCreateEdit.
  ///
  /// In zh, this message translates to:
  /// **'或创建 / 编辑地图'**
  String get maporCreateEdit;

  /// No description provided for @mapcreateEditMap.
  ///
  /// In zh, this message translates to:
  /// **'创建 / 编辑地图 (打开创建存档)'**
  String get mapcreateEditMap;

  /// No description provided for @mapfromArchive.
  ///
  /// In zh, this message translates to:
  /// **'从存档中选择地图'**
  String get mapfromArchive;

  /// No description provided for @maploadMapFailed.
  ///
  /// In zh, this message translates to:
  /// **'地图加载失败'**
  String get maploadMapFailed;

  /// No description provided for @maparrangePositions.
  ///
  /// In zh, this message translates to:
  /// **'布置角色位置'**
  String get maparrangePositions;

  /// No description provided for @mappositionsPlaced.
  ///
  /// In zh, this message translates to:
  /// **'已布置 {count} 个角色'**
  String mappositionsPlaced(Object count);

  /// No description provided for @mapplaceCharacterOnMap.
  ///
  /// In zh, this message translates to:
  /// **'点击地图放置「{name}」的位置'**
  String mapplaceCharacterOnMap(Object name);

  /// No description provided for @mapcharacterCount.
  ///
  /// In zh, this message translates to:
  /// **'角色 ({count}) — 选择角色后点击地图放置'**
  String mapcharacterCount(Object count);

  /// No description provided for @mapnoImage.
  ///
  /// In zh, this message translates to:
  /// **'地图 \"{name}\" 暂无图片'**
  String mapnoImage(Object name);

  /// No description provided for @mapsize.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get mapsize;

  /// No description provided for @mapnoDescription.
  ///
  /// In zh, this message translates to:
  /// **'无描述'**
  String get mapnoDescription;

  /// No description provided for @mapaddMap.
  ///
  /// In zh, this message translates to:
  /// **'添加地图'**
  String get mapaddMap;

  /// No description provided for @mapmapName.
  ///
  /// In zh, this message translates to:
  /// **'地图名称'**
  String get mapmapName;

  /// No description provided for @mapdescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get mapdescription;

  /// No description provided for @mapuploadImage.
  ///
  /// In zh, this message translates to:
  /// **'上传地图图片 *'**
  String get mapuploadImage;

  /// No description provided for @mapwidthMeters.
  ///
  /// In zh, this message translates to:
  /// **'宽度（米）'**
  String get mapwidthMeters;

  /// No description provided for @maplengthMeters.
  ///
  /// In zh, this message translates to:
  /// **'长度（米）'**
  String get maplengthMeters;

  /// No description provided for @mapmeterUnit.
  ///
  /// In zh, this message translates to:
  /// **'米'**
  String get mapmeterUnit;

  /// No description provided for @mappleaseUploadImage.
  ///
  /// In zh, this message translates to:
  /// **'请先上传地图图片'**
  String get mappleaseUploadImage;

  /// No description provided for @mapdefaultName.
  ///
  /// In zh, this message translates to:
  /// **'无名地图'**
  String get mapdefaultName;

  /// No description provided for @mapmapList.
  ///
  /// In zh, this message translates to:
  /// **'地图列表'**
  String get mapmapList;

  /// No description provided for @mapmapsCount.
  ///
  /// In zh, this message translates to:
  /// **'已添加 {count} 张地图'**
  String mapmapsCount(Object count);

  /// No description provided for @mapnoMapsAdded.
  ///
  /// In zh, this message translates to:
  /// **'暂无地图，点击上方按钮添加'**
  String get mapnoMapsAdded;

  /// No description provided for @charselectCharacter.
  ///
  /// In zh, this message translates to:
  /// **'选择角色'**
  String get charselectCharacter;

  /// No description provided for @charfromArchive.
  ///
  /// In zh, this message translates to:
  /// **'从存档中选择角色'**
  String get charfromArchive;

  /// No description provided for @charnoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'该存档中没有角色'**
  String get charnoCharacters;

  /// No description provided for @charorCreate.
  ///
  /// In zh, this message translates to:
  /// **'或新建角色到当前存档'**
  String get charorCreate;

  /// No description provided for @charcreateInArchive.
  ///
  /// In zh, this message translates to:
  /// **'在当前存档新建角色'**
  String get charcreateInArchive;

  /// No description provided for @charcreateNew.
  ///
  /// In zh, this message translates to:
  /// **'创建新角色 (完整创建)'**
  String get charcreateNew;

  /// No description provided for @charhello.
  ///
  /// In zh, this message translates to:
  /// **'你好'**
  String get charhello;

  /// No description provided for @charwaitingHost.
  ///
  /// In zh, this message translates to:
  /// **'等待主持进入冒险'**
  String get charwaitingHost;

  /// No description provided for @charhostSettingUp.
  ///
  /// In zh, this message translates to:
  /// **'主持正在布置地图…'**
  String get charhostSettingUp;

  /// No description provided for @charwaitingAdventure.
  ///
  /// In zh, this message translates to:
  /// **'等待主持开始…'**
  String get charwaitingAdventure;

  /// No description provided for @charready.
  ///
  /// In zh, this message translates to:
  /// **'准备'**
  String get charready;

  /// No description provided for @charaddedToArchive.
  ///
  /// In zh, this message translates to:
  /// **'角色「{name}」已添加到存档'**
  String charaddedToArchive(Object name);

  /// No description provided for @charupdatedInArchive.
  ///
  /// In zh, this message translates to:
  /// **'角色「{name}」已更新'**
  String charupdatedInArchive(Object name);

  /// No description provided for @charaddFailed.
  ///
  /// In zh, this message translates to:
  /// **'添加失败'**
  String get charaddFailed;

  /// No description provided for @charupdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败'**
  String get charupdateFailed;

  /// No description provided for @chareditCharacter.
  ///
  /// In zh, this message translates to:
  /// **'编辑角色'**
  String get chareditCharacter;

  /// No description provided for @charnewCharacter.
  ///
  /// In zh, this message translates to:
  /// **'新建角色到当前存档'**
  String get charnewCharacter;

  /// No description provided for @charpleaseEnterName.
  ///
  /// In zh, this message translates to:
  /// **'请先输入角色名称'**
  String get charpleaseEnterName;

  /// No description provided for @charselectPortrait.
  ///
  /// In zh, this message translates to:
  /// **'选择角色头像'**
  String get charselectPortrait;

  /// No description provided for @charcharacterInfo.
  ///
  /// In zh, this message translates to:
  /// **'角色信息'**
  String get charcharacterInfo;

  /// No description provided for @charcharacterName.
  ///
  /// In zh, this message translates to:
  /// **'角色名称'**
  String get charcharacterName;

  /// No description provided for @charselectAvatar.
  ///
  /// In zh, this message translates to:
  /// **'选择头像'**
  String get charselectAvatar;

  /// No description provided for @charspeed.
  ///
  /// In zh, this message translates to:
  /// **'速度'**
  String get charspeed;

  /// No description provided for @charmetersPerRound.
  ///
  /// In zh, this message translates to:
  /// **'米/回合'**
  String get charmetersPerRound;

  /// No description provided for @charclass.
  ///
  /// In zh, this message translates to:
  /// **'职业'**
  String get charclass;

  /// No description provided for @charaddClass.
  ///
  /// In zh, this message translates to:
  /// **'添加职业'**
  String get charaddClass;

  /// No description provided for @charprimaryClass.
  ///
  /// In zh, this message translates to:
  /// **'主职业'**
  String get charprimaryClass;

  /// No description provided for @charsubClass.
  ///
  /// In zh, this message translates to:
  /// **'副职业'**
  String get charsubClass;

  /// No description provided for @charremoveClass.
  ///
  /// In zh, this message translates to:
  /// **'移除职业'**
  String get charremoveClass;

  /// No description provided for @charrace.
  ///
  /// In zh, this message translates to:
  /// **'种族'**
  String get charrace;

  /// No description provided for @charcustomRace.
  ///
  /// In zh, this message translates to:
  /// **'自定义种族名称'**
  String get charcustomRace;

  /// No description provided for @charlevel.
  ///
  /// In zh, this message translates to:
  /// **'等级'**
  String get charlevel;

  /// No description provided for @charhp.
  ///
  /// In zh, this message translates to:
  /// **'血量'**
  String get charhp;

  /// No description provided for @charcurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get charcurrent;

  /// No description provided for @charmax.
  ///
  /// In zh, this message translates to:
  /// **'上限'**
  String get charmax;

  /// No description provided for @charskillsCount.
  ///
  /// In zh, this message translates to:
  /// **'技能 ({count})'**
  String charskillsCount(Object count);

  /// No description provided for @charaddSkillFromTemplate.
  ///
  /// In zh, this message translates to:
  /// **'从模板添加技能'**
  String get charaddSkillFromTemplate;

  /// No description provided for @charbackpack.
  ///
  /// In zh, this message translates to:
  /// **'背包'**
  String get charbackpack;

  /// No description provided for @charweight.
  ///
  /// In zh, this message translates to:
  /// **'负重'**
  String get charweight;

  /// No description provided for @charequipmentSlots.
  ///
  /// In zh, this message translates to:
  /// **'装备栏'**
  String get charequipmentSlots;

  /// No description provided for @charpleaseAddSlots.
  ///
  /// In zh, this message translates to:
  /// **'请在规则页面添加装备栏'**
  String get charpleaseAddSlots;

  /// No description provided for @charitemsTab.
  ///
  /// In zh, this message translates to:
  /// **'物品栏'**
  String get charitemsTab;

  /// No description provided for @charselectItem.
  ///
  /// In zh, this message translates to:
  /// **'选择物品'**
  String get charselectItem;

  /// No description provided for @charpleaseAddItemTemplates.
  ///
  /// In zh, this message translates to:
  /// **'请先在规则页面添加物品模板'**
  String get charpleaseAddItemTemplates;

  /// No description provided for @charstats.
  ///
  /// In zh, this message translates to:
  /// **'属性分配'**
  String get charstats;

  /// No description provided for @charaddStat.
  ///
  /// In zh, this message translates to:
  /// **'添加属性'**
  String get charaddStat;

  /// No description provided for @charaddCustomStat.
  ///
  /// In zh, this message translates to:
  /// **'添加自定义属性'**
  String get charaddCustomStat;

  /// No description provided for @charstatName.
  ///
  /// In zh, this message translates to:
  /// **'属性名称'**
  String get charstatName;

  /// No description provided for @charstatInitialValue.
  ///
  /// In zh, this message translates to:
  /// **'初始值 (0~20)'**
  String get charstatInitialValue;

  /// No description provided for @charstatHint.
  ///
  /// In zh, this message translates to:
  /// **'如: 幸运、灵巧'**
  String get charstatHint;

  /// No description provided for @charsaveModify.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get charsaveModify;

  /// No description provided for @charaddToArchive.
  ///
  /// In zh, this message translates to:
  /// **'添加到当前存档'**
  String get charaddToArchive;

  /// No description provided for @charselectEquipmentSlot.
  ///
  /// In zh, this message translates to:
  /// **'选择 {slot}'**
  String charselectEquipmentSlot(Object slot);

  /// No description provided for @charequip.
  ///
  /// In zh, this message translates to:
  /// **'装备'**
  String get charequip;

  /// No description provided for @charinventory.
  ///
  /// In zh, this message translates to:
  /// **'背包'**
  String get charinventory;

  /// No description provided for @charpersonality.
  ///
  /// In zh, this message translates to:
  /// **'性格'**
  String get charpersonality;

  /// No description provided for @charhostNotes.
  ///
  /// In zh, this message translates to:
  /// **'主持注释'**
  String get charhostNotes;

  /// No description provided for @charnotArchived.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get charnotArchived;

  /// No description provided for @chardefaultName.
  ///
  /// In zh, this message translates to:
  /// **'无名冒险者'**
  String get chardefaultName;

  /// No description provided for @chardefaultClass.
  ///
  /// In zh, this message translates to:
  /// **'战士'**
  String get chardefaultClass;

  /// No description provided for @chardefaultRace.
  ///
  /// In zh, this message translates to:
  /// **'人类'**
  String get chardefaultRace;

  /// No description provided for @chardefaultEquipment.
  ///
  /// In zh, this message translates to:
  /// **'无名装备'**
  String get chardefaultEquipment;

  /// No description provided for @chardefaultItem.
  ///
  /// In zh, this message translates to:
  /// **'无名物品'**
  String get chardefaultItem;

  /// No description provided for @statstrength.
  ///
  /// In zh, this message translates to:
  /// **'力量'**
  String get statstrength;

  /// No description provided for @statdexterity.
  ///
  /// In zh, this message translates to:
  /// **'敏捷'**
  String get statdexterity;

  /// No description provided for @statconstitution.
  ///
  /// In zh, this message translates to:
  /// **'体质'**
  String get statconstitution;

  /// No description provided for @statintelligence.
  ///
  /// In zh, this message translates to:
  /// **'智力'**
  String get statintelligence;

  /// No description provided for @statwisdom.
  ///
  /// In zh, this message translates to:
  /// **'感知'**
  String get statwisdom;

  /// No description provided for @statcharisma.
  ///
  /// In zh, this message translates to:
  /// **'魅力'**
  String get statcharisma;

  /// No description provided for @racehuman.
  ///
  /// In zh, this message translates to:
  /// **'人类'**
  String get racehuman;

  /// No description provided for @raceelf.
  ///
  /// In zh, this message translates to:
  /// **'精灵'**
  String get raceelf;

  /// No description provided for @racedwarf.
  ///
  /// In zh, this message translates to:
  /// **'矮人'**
  String get racedwarf;

  /// No description provided for @racehalfling.
  ///
  /// In zh, this message translates to:
  /// **'半身人'**
  String get racehalfling;

  /// No description provided for @racedragonborn.
  ///
  /// In zh, this message translates to:
  /// **'龙裔'**
  String get racedragonborn;

  /// No description provided for @raceorc.
  ///
  /// In zh, this message translates to:
  /// **'兽人'**
  String get raceorc;

  /// No description provided for @damagefire.
  ///
  /// In zh, this message translates to:
  /// **'火焰'**
  String get damagefire;

  /// No description provided for @damagecold.
  ///
  /// In zh, this message translates to:
  /// **'寒冷'**
  String get damagecold;

  /// No description provided for @damagelightning.
  ///
  /// In zh, this message translates to:
  /// **'雷电'**
  String get damagelightning;

  /// No description provided for @damagepoison.
  ///
  /// In zh, this message translates to:
  /// **'毒素'**
  String get damagepoison;

  /// No description provided for @damagenecrotic.
  ///
  /// In zh, this message translates to:
  /// **'暗蚀'**
  String get damagenecrotic;

  /// No description provided for @damageradiant.
  ///
  /// In zh, this message translates to:
  /// **'光耀'**
  String get damageradiant;

  /// No description provided for @damageforce.
  ///
  /// In zh, this message translates to:
  /// **'力场'**
  String get damageforce;

  /// No description provided for @damagepsychic.
  ///
  /// In zh, this message translates to:
  /// **'精神'**
  String get damagepsychic;

  /// No description provided for @damagenecrosis.
  ///
  /// In zh, this message translates to:
  /// **'坏死'**
  String get damagenecrosis;

  /// No description provided for @damagepiercing.
  ///
  /// In zh, this message translates to:
  /// **'穿刺'**
  String get damagepiercing;

  /// No description provided for @damageslashing.
  ///
  /// In zh, this message translates to:
  /// **'挥砍'**
  String get damageslashing;

  /// No description provided for @damagebludgeoning.
  ///
  /// In zh, this message translates to:
  /// **'钝击'**
  String get damagebludgeoning;

  /// No description provided for @equiphelmet.
  ///
  /// In zh, this message translates to:
  /// **'头盔'**
  String get equiphelmet;

  /// No description provided for @equipbody.
  ///
  /// In zh, this message translates to:
  /// **'身甲'**
  String get equipbody;

  /// No description provided for @equiphands.
  ///
  /// In zh, this message translates to:
  /// **'手甲'**
  String get equiphands;

  /// No description provided for @equiplegs.
  ///
  /// In zh, this message translates to:
  /// **'腿甲'**
  String get equiplegs;

  /// No description provided for @equipaccessory.
  ///
  /// In zh, this message translates to:
  /// **'饰品'**
  String get equipaccessory;

  /// No description provided for @savecreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建存档'**
  String get savecreateTitle;

  /// No description provided for @savemodifyTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改存档'**
  String get savemodifyTitle;

  /// No description provided for @savecharacters.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get savecharacters;

  /// No description provided for @savemaps.
  ///
  /// In zh, this message translates to:
  /// **'地图'**
  String get savemaps;

  /// No description provided for @saverules.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get saverules;

  /// No description provided for @saveswitchCharacter.
  ///
  /// In zh, this message translates to:
  /// **'切换角色'**
  String get saveswitchCharacter;

  /// No description provided for @saveaddCharacter.
  ///
  /// In zh, this message translates to:
  /// **'添加角色'**
  String get saveaddCharacter;

  /// No description provided for @saveselectArchive.
  ///
  /// In zh, this message translates to:
  /// **'选择存档'**
  String get saveselectArchive;

  /// No description provided for @saveselectArchiveFile.
  ///
  /// In zh, this message translates to:
  /// **'选择存档文件'**
  String get saveselectArchiveFile;

  /// No description provided for @saveselectModifyFile.
  ///
  /// In zh, this message translates to:
  /// **'选择要修改的存档文件 (.zip)'**
  String get saveselectModifyFile;

  /// No description provided for @savezipOnly.
  ///
  /// In zh, this message translates to:
  /// **'请选择 .zip 格式的存档文件'**
  String get savezipOnly;

  /// No description provided for @savereadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取存档失败'**
  String get savereadFailed;

  /// No description provided for @savesaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中...'**
  String get savesaving;

  /// No description provided for @savesaveFile.
  ///
  /// In zh, this message translates to:
  /// **'保存存档'**
  String get savesaveFile;

  /// No description provided for @savesaveModify.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get savesaveModify;

  /// No description provided for @savesaveAs.
  ///
  /// In zh, this message translates to:
  /// **'另存为'**
  String get savesaveAs;

  /// No description provided for @savesaveAsDialog.
  ///
  /// In zh, this message translates to:
  /// **'保存存档文件 (ZIP)'**
  String get savesaveAsDialog;

  /// No description provided for @savesaveAsRule.
  ///
  /// In zh, this message translates to:
  /// **'另存为规则书'**
  String get savesaveAsRule;

  /// No description provided for @savesaved.
  ///
  /// In zh, this message translates to:
  /// **'存档已保存 (角色:{charCount} 地图:{mapCount})'**
  String savesaved(Object charCount, Object mapCount);

  /// No description provided for @savesaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get savesaveFailed;

  /// No description provided for @saveupdated.
  ///
  /// In zh, this message translates to:
  /// **'存档已更新'**
  String get saveupdated;

  /// No description provided for @savesaveAsSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已另存为'**
  String get savesaveAsSuccess;

  /// No description provided for @savesaveAsFailed.
  ///
  /// In zh, this message translates to:
  /// **'另存失败'**
  String get savesaveAsFailed;

  /// No description provided for @saveimportRule.
  ///
  /// In zh, this message translates to:
  /// **'导入规则书'**
  String get saveimportRule;

  /// No description provided for @saveruleImported.
  ///
  /// In zh, this message translates to:
  /// **'规则书已导入'**
  String get saveruleImported;

  /// No description provided for @saveruleExported.
  ///
  /// In zh, this message translates to:
  /// **'规则书已导出'**
  String get saveruleExported;

  /// No description provided for @saveimportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get saveimportFailed;

  /// No description provided for @savebackpackFull.
  ///
  /// In zh, this message translates to:
  /// **'背包已满'**
  String get savebackpackFull;

  /// No description provided for @saveconfirmOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'确认保存'**
  String get saveconfirmOverwrite;

  /// No description provided for @saveconfirmOverwriteContent.
  ///
  /// In zh, this message translates to:
  /// **'当前操作会覆盖旧的存档，是否继续？'**
  String get saveconfirmOverwriteContent;

  /// No description provided for @savenoArchive.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get savenoArchive;

  /// No description provided for @rulesbackpackSettings.
  ///
  /// In zh, this message translates to:
  /// **'背包设置'**
  String get rulesbackpackSettings;

  /// No description provided for @rulesbackpackSlotMax.
  ///
  /// In zh, this message translates to:
  /// **'物品栏格子上限'**
  String get rulesbackpackSlotMax;

  /// No description provided for @rulesbackpackSlotDescription.
  ///
  /// In zh, this message translates to:
  /// **'每个角色的背包最多存放 {max} 件物品'**
  String rulesbackpackSlotDescription(Object max);

  /// No description provided for @rulesweightMaxExpression.
  ///
  /// In zh, this message translates to:
  /// **'负重上限表达式'**
  String get rulesweightMaxExpression;

  /// No description provided for @rulesweightMaxHint.
  ///
  /// In zh, this message translates to:
  /// **'力量*15'**
  String get rulesweightMaxHint;

  /// No description provided for @rulesweightMaxDefault.
  ///
  /// In zh, this message translates to:
  /// **'留空则默认：力量 × 15'**
  String get rulesweightMaxDefault;

  /// No description provided for @rulesweightCurrentExpression.
  ///
  /// In zh, this message translates to:
  /// **'当前负重表达式'**
  String get rulesweightCurrentExpression;

  /// No description provided for @rulesweightCurrentHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则累加物品重量'**
  String get rulesweightCurrentHint;

  /// No description provided for @rulesweightCurrentDefault.
  ///
  /// In zh, this message translates to:
  /// **'留空则默认：所有物品 weight 字段之和'**
  String get rulesweightCurrentDefault;

  /// No description provided for @rulesitemTemplates.
  ///
  /// In zh, this message translates to:
  /// **'物品模板 ({count})'**
  String rulesitemTemplates(Object count);

  /// No description provided for @rulesitemTemplatesDesc.
  ///
  /// In zh, this message translates to:
  /// **'自定义物品属性，角色页面从中选择添加到背包'**
  String get rulesitemTemplatesDesc;

  /// No description provided for @rulesaddItemTemplate.
  ///
  /// In zh, this message translates to:
  /// **'添加物品模板'**
  String get rulesaddItemTemplate;

  /// No description provided for @rulesequipmentSlotEdit.
  ///
  /// In zh, this message translates to:
  /// **'装备栏编辑'**
  String get rulesequipmentSlotEdit;

  /// No description provided for @rulesequipmentSlotDesc.
  ///
  /// In zh, this message translates to:
  /// **'定义装备栏位置名称（如 头盔、身甲、手甲、腿甲、饰品）'**
  String get rulesequipmentSlotDesc;

  /// No description provided for @rulesaddEquipmentSlot.
  ///
  /// In zh, this message translates to:
  /// **'添加装备栏'**
  String get rulesaddEquipmentSlot;

  /// No description provided for @rulesdeleteSlot.
  ///
  /// In zh, this message translates to:
  /// **'删除装备栏'**
  String get rulesdeleteSlot;

  /// No description provided for @rulesequipmentTemplates.
  ///
  /// In zh, this message translates to:
  /// **'装备模板 ({count})'**
  String rulesequipmentTemplates(Object count);

  /// No description provided for @rulesequipmentTemplatesDesc.
  ///
  /// In zh, this message translates to:
  /// **'自定义装备属性，角色页面从中选择装备到装备栏'**
  String get rulesequipmentTemplatesDesc;

  /// No description provided for @rulesaddEquipmentTemplate.
  ///
  /// In zh, this message translates to:
  /// **'添加装备模板'**
  String get rulesaddEquipmentTemplate;

  /// No description provided for @rulesskillTemplates.
  ///
  /// In zh, this message translates to:
  /// **'技能模板 ({count})'**
  String rulesskillTemplates(Object count);

  /// No description provided for @rulesskillTemplatesDesc.
  ///
  /// In zh, this message translates to:
  /// **'自定义技能模板，角色页面可从中选择添加到角色技能列表'**
  String get rulesskillTemplatesDesc;

  /// No description provided for @rulesaddSkillTemplate.
  ///
  /// In zh, this message translates to:
  /// **'添加技能模板'**
  String get rulesaddSkillTemplate;

  /// No description provided for @rulesdamageTypes.
  ///
  /// In zh, this message translates to:
  /// **'伤害类型 ({count})'**
  String rulesdamageTypes(Object count);

  /// No description provided for @rulesdamageTypesDesc.
  ///
  /// In zh, this message translates to:
  /// **'定义游戏中的伤害类型，技能模板可从中选择'**
  String get rulesdamageTypesDesc;

  /// No description provided for @rulesaddDamageType.
  ///
  /// In zh, this message translates to:
  /// **'添加伤害类型'**
  String get rulesaddDamageType;

  /// No description provided for @rulesturnSettings.
  ///
  /// In zh, this message translates to:
  /// **'回合设置'**
  String get rulesturnSettings;

  /// No description provided for @rulesturnNotSet.
  ///
  /// In zh, this message translates to:
  /// **'暂未设置回合参数'**
  String get rulesturnNotSet;

  /// No description provided for @rulesturnSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置 {count} 项'**
  String rulesturnSet(Object count);

  /// No description provided for @rulesaddTurnSetting.
  ///
  /// In zh, this message translates to:
  /// **'添加回合设置'**
  String get rulesaddTurnSetting;

  /// No description provided for @rulesphaseSettings.
  ///
  /// In zh, this message translates to:
  /// **'环节设置'**
  String get rulesphaseSettings;

  /// No description provided for @rulesphasesSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置 {count} 个环节'**
  String rulesphasesSet(Object count);

  /// No description provided for @rulesaddPhase.
  ///
  /// In zh, this message translates to:
  /// **'添加环节'**
  String get rulesaddPhase;

  /// No description provided for @rulesdeletePhase.
  ///
  /// In zh, this message translates to:
  /// **'删除环节'**
  String get rulesdeletePhase;

  /// No description provided for @rulesitemName.
  ///
  /// In zh, this message translates to:
  /// **'物品名称'**
  String get rulesitemName;

  /// No description provided for @rulesitemType.
  ///
  /// In zh, this message translates to:
  /// **'物品类型'**
  String get rulesitemType;

  /// No description provided for @rulesitemTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'武器 / 防具 / 药水 / 杂物'**
  String get rulesitemTypeHint;

  /// No description provided for @rulesitemEffect.
  ///
  /// In zh, this message translates to:
  /// **'物品效果'**
  String get rulesitemEffect;

  /// No description provided for @rulesitemEffectHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: 回复2d6+4生命值'**
  String get rulesitemEffectHint;

  /// No description provided for @rulesvalue.
  ///
  /// In zh, this message translates to:
  /// **'价值'**
  String get rulesvalue;

  /// No description provided for @rulesweight.
  ///
  /// In zh, this message translates to:
  /// **'负重'**
  String get rulesweight;

  /// No description provided for @rulesselectItemImage.
  ///
  /// In zh, this message translates to:
  /// **'选择物品图片'**
  String get rulesselectItemImage;

  /// No description provided for @rulesselectImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get rulesselectImage;

  /// No description provided for @rulesimageSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择图片'**
  String get rulesimageSelected;

  /// No description provided for @rulesequipmentName.
  ///
  /// In zh, this message translates to:
  /// **'装备名称'**
  String get rulesequipmentName;

  /// No description provided for @rulesequipmentSlot.
  ///
  /// In zh, this message translates to:
  /// **'装备位置'**
  String get rulesequipmentSlot;

  /// No description provided for @rulesequipmentType.
  ///
  /// In zh, this message translates to:
  /// **'装备类型'**
  String get rulesequipmentType;

  /// No description provided for @rulesequipmentTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'防具 / 武器 / 饰品'**
  String get rulesequipmentTypeHint;

  /// No description provided for @rulesequipmentEffect.
  ///
  /// In zh, this message translates to:
  /// **'装备效果'**
  String get rulesequipmentEffect;

  /// No description provided for @rulesequipmentEffectHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: +2护甲'**
  String get rulesequipmentEffectHint;

  /// No description provided for @rulesselectEquipmentImage.
  ///
  /// In zh, this message translates to:
  /// **'选择装备图片'**
  String get rulesselectEquipmentImage;

  /// No description provided for @rulesskillName.
  ///
  /// In zh, this message translates to:
  /// **'技能名称'**
  String get rulesskillName;

  /// No description provided for @rulesskillDamage.
  ///
  /// In zh, this message translates to:
  /// **'技能伤害'**
  String get rulesskillDamage;

  /// No description provided for @rulesdamageExpression.
  ///
  /// In zh, this message translates to:
  /// **'表达式'**
  String get rulesdamageExpression;

  /// No description provided for @rulesdamageType.
  ///
  /// In zh, this message translates to:
  /// **'伤害类型'**
  String get rulesdamageType;

  /// No description provided for @rulesnone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get rulesnone;

  /// No description provided for @rulesskillIcon.
  ///
  /// In zh, this message translates to:
  /// **'选择技能图标'**
  String get rulesskillIcon;

  /// No description provided for @rulesuploadIcon.
  ///
  /// In zh, this message translates to:
  /// **'上传图标'**
  String get rulesuploadIcon;

  /// No description provided for @rulesiconSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择图标'**
  String get rulesiconSelected;

  /// No description provided for @rulesdamageTypeName.
  ///
  /// In zh, this message translates to:
  /// **'伤害类型名称'**
  String get rulesdamageTypeName;

  /// No description provided for @rulesdamageTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: 火焰、寒冷、雷电'**
  String get rulesdamageTypeHint;

  /// No description provided for @ruleseditItemTemplate.
  ///
  /// In zh, this message translates to:
  /// **'编辑物品模板'**
  String get ruleseditItemTemplate;

  /// No description provided for @rulesaddItemTemplateTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加物品模板'**
  String get rulesaddItemTemplateTitle;

  /// No description provided for @ruleseditEquipmentTemplate.
  ///
  /// In zh, this message translates to:
  /// **'编辑装备模板'**
  String get ruleseditEquipmentTemplate;

  /// No description provided for @rulesaddEquipmentTemplateTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加装备模板'**
  String get rulesaddEquipmentTemplateTitle;

  /// No description provided for @ruleseditSkillTemplate.
  ///
  /// In zh, this message translates to:
  /// **'编辑技能模板'**
  String get ruleseditSkillTemplate;

  /// No description provided for @rulesaddSkillTemplateTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加技能模板'**
  String get rulesaddSkillTemplateTitle;

  /// No description provided for @rulesaddEquipmentSlotTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加装备栏'**
  String get rulesaddEquipmentSlotTitle;

  /// No description provided for @rulesequipmentSlotName.
  ///
  /// In zh, this message translates to:
  /// **'装备栏名称'**
  String get rulesequipmentSlotName;

  /// No description provided for @rulesequipmentSlotHint.
  ///
  /// In zh, this message translates to:
  /// **'例如: 头盔、手甲、身甲'**
  String get rulesequipmentSlotHint;

  /// No description provided for @rulesaddDamageTypeTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加伤害类型'**
  String get rulesaddDamageTypeTitle;

  /// No description provided for @livetitle.
  ///
  /// In zh, this message translates to:
  /// **'直播模式'**
  String get livetitle;

  /// No description provided for @livedesktopOnly.
  ///
  /// In zh, this message translates to:
  /// **'直播模式仅支持桌面端'**
  String get livedesktopOnly;

  /// No description provided for @liveselectArchive.
  ///
  /// In zh, this message translates to:
  /// **'选择存档'**
  String get liveselectArchive;

  /// No description provided for @liveselectArchiveStart.
  ///
  /// In zh, this message translates to:
  /// **'选择存档开始直播'**
  String get liveselectArchiveStart;

  /// No description provided for @liveselectMap.
  ///
  /// In zh, this message translates to:
  /// **'选择一个地图'**
  String get liveselectMap;

  /// No description provided for @liveselectCharacters.
  ///
  /// In zh, this message translates to:
  /// **'直播模式 · 选择角色'**
  String get liveselectCharacters;

  /// No description provided for @livenoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'该存档中没有角色'**
  String get livenoCharacters;

  /// No description provided for @livestartLive.
  ///
  /// In zh, this message translates to:
  /// **'开始直播 (已选{count}个角色)'**
  String livestartLive(Object count);

  /// No description provided for @liveswitchMap.
  ///
  /// In zh, this message translates to:
  /// **'切换地图'**
  String get liveswitchMap;

  /// No description provided for @livereopenPlayer.
  ///
  /// In zh, this message translates to:
  /// **'重新打开玩家窗口'**
  String get livereopenPlayer;

  /// No description provided for @livebackToSelection.
  ///
  /// In zh, this message translates to:
  /// **'回到选角'**
  String get livebackToSelection;

  /// No description provided for @livediceLog.
  ///
  /// In zh, this message translates to:
  /// **'投掷记录'**
  String get livediceLog;

  /// No description provided for @livenoDiceLog.
  ///
  /// In zh, this message translates to:
  /// **'暂无投掷记录'**
  String get livenoDiceLog;

  /// No description provided for @livechatPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入消息…'**
  String get livechatPlaceholder;

  /// No description provided for @liveloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get liveloadFailed;

  /// No description provided for @livenoEquipmentTemplates.
  ///
  /// In zh, this message translates to:
  /// **'规则书中没有装备模板'**
  String get livenoEquipmentTemplates;

  /// No description provided for @livenoItemTemplates.
  ///
  /// In zh, this message translates to:
  /// **'规则书中没有物品模板'**
  String get livenoItemTemplates;

  /// No description provided for @liveplayerWindow.
  ///
  /// In zh, this message translates to:
  /// **'玩家视角'**
  String get liveplayerWindow;

  /// No description provided for @liveloadError.
  ///
  /// In zh, this message translates to:
  /// **'存档路径为空，请联系主持重新打开窗口'**
  String get liveloadError;

  /// No description provided for @liveloadSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载存档失败'**
  String get liveloadSaveFailed;

  /// No description provided for @livenoChars.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色数据'**
  String get livenoChars;

  /// No description provided for @livenoMap.
  ///
  /// In zh, this message translates to:
  /// **'暂无地图数据'**
  String get livenoMap;

  /// No description provided for @voicenoMicPermission.
  ///
  /// In zh, this message translates to:
  /// **'没有麦克风权限'**
  String get voicenoMicPermission;

  /// No description provided for @errorzipMissing.
  ///
  /// In zh, this message translates to:
  /// **'ZIP 存档中缺少 save.json'**
  String get errorzipMissing;

  /// No description provided for @errorillegalChar.
  ///
  /// In zh, this message translates to:
  /// **'表达式包含非法字符'**
  String get errorillegalChar;

  /// No description provided for @errorparenMismatch.
  ///
  /// In zh, this message translates to:
  /// **'括号不匹配'**
  String get errorparenMismatch;

  /// No description provided for @errorinvalidDice.
  ///
  /// In zh, this message translates to:
  /// **'无效骰子'**
  String get errorinvalidDice;

  /// No description provided for @errorincompleteExpression.
  ///
  /// In zh, this message translates to:
  /// **'表达式不完整'**
  String get errorincompleteExpression;

  /// No description provided for @errordivideByZero.
  ///
  /// In zh, this message translates to:
  /// **'除以零'**
  String get errordivideByZero;

  /// No description provided for @errorunknownOperator.
  ///
  /// In zh, this message translates to:
  /// **'未知运算符'**
  String get errorunknownOperator;

  /// No description provided for @errorwebNoHost.
  ///
  /// In zh, this message translates to:
  /// **'当前 Web 端暂不支持创建房间，请在桌面端运行。'**
  String get errorwebNoHost;

  /// No description provided for @errorwebCreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'Web 端不支持创建房间，请使用桌面端创建。'**
  String get errorwebCreateRoom;

  /// No description provided for @errorcannotConnect.
  ///
  /// In zh, this message translates to:
  /// **'无法连接到 {uri}'**
  String errorcannotConnect(Object uri);

  /// No description provided for @errorconnectionTimeout.
  ///
  /// In zh, this message translates to:
  /// **'连接 {uri} 超时'**
  String errorconnectionTimeout(Object uri);

  /// No description provided for @errorkicked.
  ///
  /// In zh, this message translates to:
  /// **'你已被房主踢出房间'**
  String get errorkicked;

  /// No description provided for @errornameTaken.
  ///
  /// In zh, this message translates to:
  /// **'名称 \"{name}\" 已被使用，请更换名称后重试'**
  String errornameTaken(Object name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
