// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Roll and Roll';

  @override
  String get commoncancel => '取消';

  @override
  String get commonsave => '保存';

  @override
  String get commonadd => '添加';

  @override
  String get commonclose => '关闭';

  @override
  String get commondelete => '删除';

  @override
  String get commonedit => '编辑';

  @override
  String get commonremove => '移除';

  @override
  String get commonconfirm => '确定';

  @override
  String get commonback => '返回';

  @override
  String get commonretry => '重试';

  @override
  String get commonselectAll => '全选';

  @override
  String get commonclearAll => '清空';

  @override
  String get commonnoData => '暂无';

  @override
  String get commonsearch => '搜索';

  @override
  String get commonsend => '发送';

  @override
  String get commoncopy => '复制';

  @override
  String get commondecrease => '减少';

  @override
  String get commonincrease => '增加';

  @override
  String get hometitle => '选择你想要开始的方式';

  @override
  String get homeplayerName => '你的玩家名称';

  @override
  String get homeplayerNameHint => '例如：阿宇';

  @override
  String get homecreateRoom => '新建房间';

  @override
  String get homejoinRoom => '加入房间';

  @override
  String get homeliveMode => '直播模式';

  @override
  String get homecreateSave => '创建存档';

  @override
  String get homemodifySave => '修改存档';

  @override
  String get homewebWarning => 'Web 端不支持创建房间。你可以加入桌面端创建的房间，或直接使用直播模式。';

  @override
  String get settingstitle => '软件设置';

  @override
  String get settingslanguage => '语言 Language';

  @override
  String get settingslangChinese => '中文';

  @override
  String get settingslangEnglish => 'English';

  @override
  String get settingsRestartHintZh => '切换语言后重启应用生效';

  @override
  String get settingsRestartHintEn =>
      'Restart the app after switching language';

  @override
  String get roomCreatetitle => '新建房间';

  @override
  String get roomCreatecloudTitle => '创建云端房间';

  @override
  String get roomCreatelocalTitle => '开放本机端口';

  @override
  String get roomCreatecloudDesc => '通过 Cloudflare 全球网络创建房间，无需开放端口';

  @override
  String get roomCreateportLabel => '端口号';

  @override
  String get roomCreateopenPort => '开放端口';

  @override
  String get roomCreateclosePort => '关闭端口';

  @override
  String get roomCreatecreateRoom => '创建房间';

  @override
  String get roomCreatecloseRoom => '关闭房间';

  @override
  String get roomCreatestatus => '状态';

  @override
  String get roomCreateaddress => '房间地址';

  @override
  String get roomCreateroomIdCopied => '房间号已复制！';

  @override
  String get roomCreaterefreshMembers => '刷新成员列表';

  @override
  String get roomCreateselectIdentity => '选择身份';

  @override
  String get roomCreateselectArchive => '选择存档';

  @override
  String get roomCreatecreateArchive => '创建存档';

  @override
  String get roomCreateeditArchive => '编辑存档';

  @override
  String get roomCreateselectArchiveFile => '选择存档文件';

  @override
  String get roomCreatepleaseSelectArchive => '请先选择存档文件';

  @override
  String get roomCreateopenArchiveFailed => '打开存档失败';

  @override
  String get roomCreateenterPort => '请输入端口号';

  @override
  String get roomCreateportRange => '端口号必须是 1~65535 之间的整数';

  @override
  String get roomCreatedesktopOnly => '请在桌面端运行';

  @override
  String get roomCreateroomId => '房间号';

  @override
  String get roomCreatetellTeammates => '告诉队友这个';

  @override
  String get roomCreateportOpened => '已开放端口';

  @override
  String get roomCreatelocalAddress => '本机地址';

  @override
  String get roomCreatecreateFailed => '创建房间失败';

  @override
  String get roomCreateopenPortFailed => '开放端口失败';

  @override
  String get roomCreatenotCreated => '尚未创建房间';

  @override
  String get roomCreatewaitCreate => '等待创建房间';

  @override
  String get roomCreateroomClosed => '房间已关闭';

  @override
  String get roomCreateportClosed => '已关闭端口';

  @override
  String get roomCreatewaitOpenPort => '等待开放端口';

  @override
  String get roomCreatemembers => '房间成员';

  @override
  String get roomCreateready => '已准备';

  @override
  String get roomCreatenotReady => '未准备';

  @override
  String get roomCreatereadyUp => '准备就绪';

  @override
  String get roomCreatecancelReady => '取消准备';

  @override
  String get roomCreatewaitAllReady => '等待所有成员准备就绪';

  @override
  String get roomCreateadventureInProgress => '冒险进行中';

  @override
  String get roomCreatestartAdventure => '开始冒险';

  @override
  String get roomCreateconfirmKick => '确认踢出';

  @override
  String roomCreateconfirmKickContent(Object name) {
    return '确定要将 $name 踢出房间吗？';
  }

  @override
  String get roomCreatekick => '踢出';

  @override
  String get roomCreateRolePlayer => '玩家';

  @override
  String get roomCreateRoleHost => '主持';

  @override
  String get roomJointitle => '加入房间';

  @override
  String get roomJoinbyRoomId => '输入房间号';

  @override
  String get roomJoinbyIp => '通过 IP 和端口加入房间';

  @override
  String get roomJoinaskHost => '让房主把房间号发给你';

  @override
  String get roomJoinroomIdLabel => '房间号';

  @override
  String get roomJoinipLabel => '房间 IP';

  @override
  String get roomJoinroomIdHint => '例如: ABC123';

  @override
  String get roomJoinipHint => '例如: 127.0.0.1';

  @override
  String get roomJoinportLabel => '房间端口';

  @override
  String get roomJoinconnecting => '连接中...';

  @override
  String get roomJoinjoinRoom => '加入房间';

  @override
  String get roomJoinenterRoomId => '请输入房间号';

  @override
  String get roomJoinenterIp => '请输入 IP';

  @override
  String get roomJoinenterPort => '请输入有效端口号';

  @override
  String get roomJoinwaitingConfirm => '等待房主确认...';

  @override
  String get roomJoinjoined => '已加入房间';

  @override
  String get roomJoinjoinFailed => '加入失败';

  @override
  String get roomJoinreconnecting => '重连中...';

  @override
  String get roomJoinreconnected => '已重连';

  @override
  String get roomJoinreconnectFailed => '重连失败';

  @override
  String get roomJoinconnected => '已连接到房间';

  @override
  String get roomJoinleaveRoom => '离开房间';

  @override
  String get roomJoinyourName => '你的名称';

  @override
  String get roomJoinyourRole => '你的身份';

  @override
  String get roomJoinswitchRole => '切换身份';

  @override
  String get roomJoinhostSave => '房主备档';

  @override
  String get roomJoinadventureStarted => '冒险已开始';

  @override
  String get roomJoinroomMembers => '房间成员';

  @override
  String get roomJoinnameInUse => '名称已被使用，请更换名称后重试';

  @override
  String get roomJoinkicked => '你已被踢出房间';

  @override
  String get adventuretitle => '冒险中';

  @override
  String get adventurereturnToRoom => '返回房间';

  @override
  String get adventuresaveProgress => '保存进度';

  @override
  String get adventuresaveAs => '另存为';

  @override
  String get adventureexitAdventure => '退出冒险';

  @override
  String get adventureexitConfirm => '退出冒险将踢出所有玩家，确定要退出吗？';

  @override
  String get adventureexit => '退出';

  @override
  String get adventuresaveAndExit => '保存进度并退出';

  @override
  String get adventurechat => '聊天';

  @override
  String get adventureenterAdventure => '进入冒险';

  @override
  String get adventureplayerList => '角色列表';

  @override
  String get adventurerightClickDeploy => '右键头像上场';

  @override
  String get adventurenoCharacters => '暂无角色';

  @override
  String get adventurenoEquipment => '暂无装备';

  @override
  String get adventurenoItems => '暂无物品';

  @override
  String get adventurenoSkills => '暂无技能';

  @override
  String get adventureequipment => '装备';

  @override
  String get adventureitems => '物品';

  @override
  String get adventureskills => '技能';

  @override
  String get adventureaddEquipment => '添加装备';

  @override
  String get adventureaddItem => '添加物品';

  @override
  String get adventuresearchEquipment => '搜索装备名称/位置/效果…';

  @override
  String get adventuresearchItems => '搜索物品名称/类型/效果…';

  @override
  String get adventurenoMatchEquipment => '无匹配装备模板';

  @override
  String get adventurenoMatchItems => '无匹配物品模板';

  @override
  String get adventureclosePanel => '关闭面板';

  @override
  String get adventuretotalValue => '总价值';

  @override
  String get adventuredeploy => '上场';

  @override
  String get adventuredeployHint => '点击地图放置';

  @override
  String get adventuretakeDown => '下场';

  @override
  String get adventureeditHp => '编辑血量';

  @override
  String get adventurecurrentHp => '当前 HP';

  @override
  String get adventuremaxHp => '最大 HP';

  @override
  String get adventurenotes => '注释';

  @override
  String get adventurenewNote => '新注释';

  @override
  String get adventurenoteHint => '记录角色的状态变化、Buff、Debuff 等…';

  @override
  String get adventurehostMode => '主持模式';

  @override
  String get adventurecharacterManagement => '角色管理';

  @override
  String get adventureaddCharacter => '添加角色';

  @override
  String get adventureremoveCharacter => '移除角色';

  @override
  String get adventuresaveSuccess => '进度已保存';

  @override
  String get adventuresaveFailed => '保存失败';

  @override
  String get adventureconfirmSave => '确认保存';

  @override
  String get adventureconfirmSaveContent => '当前操作会覆盖旧的存档，是否继续？';

  @override
  String get adventuresavedAs => '已另存为';

  @override
  String get adventuresaved => '已保存';

  @override
  String get adventureexpressionInvalid => '表达式无效';

  @override
  String adventurespeakingCount(Object count) {
    return '$count 人';
  }

  @override
  String get adventureunmute => '打开麦克风';

  @override
  String get adventuremute => '关闭麦克风';

  @override
  String get adventureselectMic => '选择麦克风';

  @override
  String get adventurejoinVoice => '加入语音频道';

  @override
  String get adventureleaveVoice => '退出语音频道';

  @override
  String get adventureequipped => '装备了';

  @override
  String get adventureobtained => '获得了';

  @override
  String get adventurenoteAdded => '新增注释';

  @override
  String get adventurenoteDeleted => '注释已删除';

  @override
  String get adventuredeployed => '已上场';

  @override
  String get adventuretakenDown => '已下场';

  @override
  String get adventuregridOn => '显示网格';

  @override
  String get adventuregridOff => '关闭网格';

  @override
  String get adventurecoordsOn => '显示坐标';

  @override
  String get adventurecoordsOff => '隐藏坐标';

  @override
  String get adventurerollDice => '投掷';

  @override
  String get adventureexpandDice => '展开骰子';

  @override
  String get adventurecollapseDice => '收起骰子';

  @override
  String get adventurechatHint => '输入消息…';

  @override
  String get mapeditTitle => '编辑地图';

  @override
  String get mapselectMap => '选择地图';

  @override
  String get mapnoMaps => '该存档中没有地图';

  @override
  String get maporCreateEdit => '或创建 / 编辑地图';

  @override
  String get mapcreateEditMap => '创建 / 编辑地图 (打开创建存档)';

  @override
  String get mapfromArchive => '从存档中选择地图';

  @override
  String get maploadMapFailed => '地图加载失败';

  @override
  String get maparrangePositions => '布置角色位置';

  @override
  String mappositionsPlaced(Object count) {
    return '已布置 $count 个角色';
  }

  @override
  String mapplaceCharacterOnMap(Object name) {
    return '点击地图放置「$name」的位置';
  }

  @override
  String mapcharacterCount(Object count) {
    return '角色 ($count) — 选择角色后点击地图放置';
  }

  @override
  String mapnoImage(Object name) {
    return '地图 \"$name\" 暂无图片';
  }

  @override
  String get mapsize => '尺寸';

  @override
  String get mapnoDescription => '无描述';

  @override
  String get mapaddMap => '添加地图';

  @override
  String get mapmapName => '地图名称';

  @override
  String get mapdescription => '描述';

  @override
  String get mapuploadImage => '上传地图图片 *';

  @override
  String get mapwidthMeters => '宽度（米）';

  @override
  String get maplengthMeters => '长度（米）';

  @override
  String get mapmeterUnit => '米';

  @override
  String get mappleaseUploadImage => '请先上传地图图片';

  @override
  String get mapdefaultName => '无名地图';

  @override
  String get mapmapList => '地图列表';

  @override
  String mapmapsCount(Object count) {
    return '已添加 $count 张地图';
  }

  @override
  String get mapnoMapsAdded => '暂无地图，点击上方按钮添加';

  @override
  String get charselectCharacter => '选择角色';

  @override
  String get charfromArchive => '从存档中选择角色';

  @override
  String get charnoCharacters => '该存档中没有角色';

  @override
  String get charorCreate => '或新建角色到当前存档';

  @override
  String get charcreateInArchive => '在当前存档新建角色';

  @override
  String get charcreateNew => '创建新角色 (完整创建)';

  @override
  String get charhello => '你好';

  @override
  String get charwaitingHost => '等待主持进入冒险';

  @override
  String get charhostSettingUp => '主持正在布置地图…';

  @override
  String get charwaitingAdventure => '等待主持开始…';

  @override
  String get charready => '准备';

  @override
  String charaddedToArchive(Object name) {
    return '角色「$name」已添加到存档';
  }

  @override
  String charupdatedInArchive(Object name) {
    return '角色「$name」已更新';
  }

  @override
  String get charaddFailed => '添加失败';

  @override
  String get charupdateFailed => '更新失败';

  @override
  String get chareditCharacter => '编辑角色';

  @override
  String get charnewCharacter => '新建角色到当前存档';

  @override
  String get charpleaseEnterName => '请先输入角色名称';

  @override
  String get charselectPortrait => '选择角色头像';

  @override
  String get charcharacterInfo => '角色信息';

  @override
  String get charcharacterName => '角色名称';

  @override
  String get charselectAvatar => '选择头像';

  @override
  String get charspeed => '速度';

  @override
  String get charmetersPerRound => '米/回合';

  @override
  String get charclass => '职业';

  @override
  String get charaddClass => '添加职业';

  @override
  String get charprimaryClass => '主职业';

  @override
  String get charsubClass => '副职业';

  @override
  String get charremoveClass => '移除职业';

  @override
  String get charrace => '种族';

  @override
  String get charcustomRace => '自定义种族名称';

  @override
  String get charlevel => '等级';

  @override
  String get charhp => '血量';

  @override
  String get charcurrent => '当前';

  @override
  String get charmax => '上限';

  @override
  String charskillsCount(Object count) {
    return '技能 ($count)';
  }

  @override
  String get charaddSkillFromTemplate => '从模板添加技能';

  @override
  String get charbackpack => '背包';

  @override
  String get charweight => '负重';

  @override
  String get charequipmentSlots => '装备栏';

  @override
  String get charpleaseAddSlots => '请在规则页面添加装备栏';

  @override
  String get charitemsTab => '物品栏';

  @override
  String get charselectItem => '选择物品';

  @override
  String get charpleaseAddItemTemplates => '请先在规则页面添加物品模板';

  @override
  String get charstats => '属性分配';

  @override
  String get charaddStat => '添加属性';

  @override
  String get charaddCustomStat => '添加自定义属性';

  @override
  String get charstatName => '属性名称';

  @override
  String get charstatInitialValue => '初始值 (0~20)';

  @override
  String get charstatHint => '如: 幸运、灵巧';

  @override
  String get charsaveModify => '保存修改';

  @override
  String get charaddToArchive => '添加到当前存档';

  @override
  String charselectEquipmentSlot(Object slot) {
    return '选择 $slot';
  }

  @override
  String get charequip => '装备';

  @override
  String get charinventory => '背包';

  @override
  String get charpersonality => '性格';

  @override
  String get charhostNotes => '主持注释';

  @override
  String get charnotArchived => '未选择';

  @override
  String get chardefaultName => '无名冒险者';

  @override
  String get chardefaultClass => '战士';

  @override
  String get chardefaultRace => '人类';

  @override
  String get chardefaultEquipment => '无名装备';

  @override
  String get chardefaultItem => '无名物品';

  @override
  String get statstrength => '力量';

  @override
  String get statdexterity => '敏捷';

  @override
  String get statconstitution => '体质';

  @override
  String get statintelligence => '智力';

  @override
  String get statwisdom => '感知';

  @override
  String get statcharisma => '魅力';

  @override
  String get racehuman => '人类';

  @override
  String get raceelf => '精灵';

  @override
  String get racedwarf => '矮人';

  @override
  String get racehalfling => '半身人';

  @override
  String get racedragonborn => '龙裔';

  @override
  String get raceorc => '兽人';

  @override
  String get damagefire => '火焰';

  @override
  String get damagecold => '寒冷';

  @override
  String get damagelightning => '雷电';

  @override
  String get damagepoison => '毒素';

  @override
  String get damagenecrotic => '暗蚀';

  @override
  String get damageradiant => '光耀';

  @override
  String get damageforce => '力场';

  @override
  String get damagepsychic => '精神';

  @override
  String get damagenecrosis => '坏死';

  @override
  String get damagepiercing => '穿刺';

  @override
  String get damageslashing => '挥砍';

  @override
  String get damagebludgeoning => '钝击';

  @override
  String get equiphelmet => '头盔';

  @override
  String get equipbody => '身甲';

  @override
  String get equiphands => '手甲';

  @override
  String get equiplegs => '腿甲';

  @override
  String get equipaccessory => '饰品';

  @override
  String get savecreateTitle => '创建存档';

  @override
  String get savemodifyTitle => '修改存档';

  @override
  String get savecharacters => '角色';

  @override
  String get savemaps => '地图';

  @override
  String get saverules => '规则';

  @override
  String get saveswitchCharacter => '切换角色';

  @override
  String get saveaddCharacter => '添加角色';

  @override
  String get saveselectArchive => '选择存档';

  @override
  String get saveselectArchiveFile => '选择存档文件';

  @override
  String get saveselectModifyFile => '选择要修改的存档文件 (.zip)';

  @override
  String get savezipOnly => '请选择 .zip 格式的存档文件';

  @override
  String get savereadFailed => '读取存档失败';

  @override
  String get savesaving => '保存中...';

  @override
  String get savesaveFile => '保存存档';

  @override
  String get savesaveModify => '保存修改';

  @override
  String get savesaveAs => '另存为';

  @override
  String get savesaveAsDialog => '保存存档文件 (ZIP)';

  @override
  String get savesaveAsRule => '另存为规则书';

  @override
  String savesaved(Object charCount, Object mapCount) {
    return '存档已保存 (角色:$charCount 地图:$mapCount)';
  }

  @override
  String get savesaveFailed => '保存失败';

  @override
  String get saveupdated => '存档已更新';

  @override
  String get savesaveAsSuccess => '已另存为';

  @override
  String get savesaveAsFailed => '另存失败';

  @override
  String get saveimportRule => '导入规则书';

  @override
  String get saveruleImported => '规则书已导入';

  @override
  String get saveruleExported => '规则书已导出';

  @override
  String get saveimportFailed => '导入失败';

  @override
  String get savebackpackFull => '背包已满';

  @override
  String get saveconfirmOverwrite => '确认保存';

  @override
  String get saveconfirmOverwriteContent => '当前操作会覆盖旧的存档，是否继续？';

  @override
  String get savenoArchive => '未选择';

  @override
  String get rulesbackpackSettings => '背包设置';

  @override
  String get rulesbackpackSlotMax => '物品栏格子上限';

  @override
  String rulesbackpackSlotDescription(Object max) {
    return '每个角色的背包最多存放 $max 件物品';
  }

  @override
  String get rulesweightMaxExpression => '负重上限表达式';

  @override
  String get rulesweightMaxHint => '力量*15';

  @override
  String get rulesweightMaxDefault => '留空则默认：力量 × 15';

  @override
  String get rulesweightCurrentExpression => '当前负重表达式';

  @override
  String get rulesweightCurrentHint => '留空则累加物品重量';

  @override
  String get rulesweightCurrentDefault => '留空则默认：所有物品 weight 字段之和';

  @override
  String rulesitemTemplates(Object count) {
    return '物品模板 ($count)';
  }

  @override
  String get rulesitemTemplatesDesc => '自定义物品属性，角色页面从中选择添加到背包';

  @override
  String get rulesaddItemTemplate => '添加物品模板';

  @override
  String get rulesequipmentSlotEdit => '装备栏编辑';

  @override
  String get rulesequipmentSlotDesc => '定义装备栏位置名称（如 头盔、身甲、手甲、腿甲、饰品）';

  @override
  String get rulesaddEquipmentSlot => '添加装备栏';

  @override
  String get rulesdeleteSlot => '删除装备栏';

  @override
  String rulesequipmentTemplates(Object count) {
    return '装备模板 ($count)';
  }

  @override
  String get rulesequipmentTemplatesDesc => '自定义装备属性，角色页面从中选择装备到装备栏';

  @override
  String get rulesaddEquipmentTemplate => '添加装备模板';

  @override
  String rulesskillTemplates(Object count) {
    return '技能模板 ($count)';
  }

  @override
  String get rulesskillTemplatesDesc => '自定义技能模板，角色页面可从中选择添加到角色技能列表';

  @override
  String get rulesaddSkillTemplate => '添加技能模板';

  @override
  String rulesdamageTypes(Object count) {
    return '伤害类型 ($count)';
  }

  @override
  String get rulesdamageTypesDesc => '定义游戏中的伤害类型，技能模板可从中选择';

  @override
  String get rulesaddDamageType => '添加伤害类型';

  @override
  String get rulesturnSettings => '回合设置';

  @override
  String get rulesturnNotSet => '暂未设置回合参数';

  @override
  String rulesturnSet(Object count) {
    return '已设置 $count 项';
  }

  @override
  String get rulesaddTurnSetting => '添加回合设置';

  @override
  String get rulesphaseSettings => '环节设置';

  @override
  String rulesphasesSet(Object count) {
    return '已设置 $count 个环节';
  }

  @override
  String get rulesaddPhase => '添加环节';

  @override
  String get rulesdeletePhase => '删除环节';

  @override
  String get rulesitemName => '物品名称';

  @override
  String get rulesitemType => '物品类型';

  @override
  String get rulesitemTypeHint => '武器 / 防具 / 药水 / 杂物';

  @override
  String get rulesitemEffect => '物品效果';

  @override
  String get rulesitemEffectHint => '例如: 回复2d6+4生命值';

  @override
  String get rulesvalue => '价值';

  @override
  String get rulesweight => '负重';

  @override
  String get rulesselectItemImage => '选择物品图片';

  @override
  String get rulesselectImage => '选择图片';

  @override
  String get rulesimageSelected => '已选择图片';

  @override
  String get rulesequipmentName => '装备名称';

  @override
  String get rulesequipmentSlot => '装备位置';

  @override
  String get rulesequipmentType => '装备类型';

  @override
  String get rulesequipmentTypeHint => '防具 / 武器 / 饰品';

  @override
  String get rulesequipmentEffect => '装备效果';

  @override
  String get rulesequipmentEffectHint => '例如: +2护甲';

  @override
  String get rulesselectEquipmentImage => '选择装备图片';

  @override
  String get rulesskillName => '技能名称';

  @override
  String get rulesskillDamage => '技能伤害';

  @override
  String get rulesdamageExpression => '表达式';

  @override
  String get rulesdamageType => '伤害类型';

  @override
  String get rulesnone => '无';

  @override
  String get rulesskillIcon => '选择技能图标';

  @override
  String get rulesuploadIcon => '上传图标';

  @override
  String get rulesiconSelected => '已选择图标';

  @override
  String get rulesdamageTypeName => '伤害类型名称';

  @override
  String get rulesdamageTypeHint => '例如: 火焰、寒冷、雷电';

  @override
  String get ruleseditItemTemplate => '编辑物品模板';

  @override
  String get rulesaddItemTemplateTitle => '添加物品模板';

  @override
  String get ruleseditEquipmentTemplate => '编辑装备模板';

  @override
  String get rulesaddEquipmentTemplateTitle => '添加装备模板';

  @override
  String get ruleseditSkillTemplate => '编辑技能模板';

  @override
  String get rulesaddSkillTemplateTitle => '添加技能模板';

  @override
  String get rulesaddEquipmentSlotTitle => '添加装备栏';

  @override
  String get rulesequipmentSlotName => '装备栏名称';

  @override
  String get rulesequipmentSlotHint => '例如: 头盔、手甲、身甲';

  @override
  String get rulesaddDamageTypeTitle => '添加伤害类型';

  @override
  String get livetitle => '直播模式';

  @override
  String get livedesktopOnly => '直播模式仅支持桌面端';

  @override
  String get liveselectArchive => '选择存档';

  @override
  String get liveselectArchiveStart => '选择存档开始直播';

  @override
  String get liveselectMap => '选择一个地图';

  @override
  String get liveselectCharacters => '直播模式 · 选择角色';

  @override
  String get livenoCharacters => '该存档中没有角色';

  @override
  String livestartLive(Object count) {
    return '开始直播 (已选$count个角色)';
  }

  @override
  String get liveswitchMap => '切换地图';

  @override
  String get livereopenPlayer => '重新打开玩家窗口';

  @override
  String get livebackToSelection => '回到选角';

  @override
  String get livediceLog => '投掷记录';

  @override
  String get livenoDiceLog => '暂无投掷记录';

  @override
  String get livechatPlaceholder => '输入消息…';

  @override
  String get liveloadFailed => '加载失败';

  @override
  String get livenoEquipmentTemplates => '规则书中没有装备模板';

  @override
  String get livenoItemTemplates => '规则书中没有物品模板';

  @override
  String get liveplayerWindow => '玩家视角';

  @override
  String get liveloadError => '存档路径为空，请联系主持重新打开窗口';

  @override
  String get liveloadSaveFailed => '加载存档失败';

  @override
  String get livenoChars => '暂无角色数据';

  @override
  String get livenoMap => '暂无地图数据';

  @override
  String get voicenoMicPermission => '没有麦克风权限';

  @override
  String get errorzipMissing => 'ZIP 存档中缺少 save.json';

  @override
  String get errorillegalChar => '表达式包含非法字符';

  @override
  String get errorparenMismatch => '括号不匹配';

  @override
  String get errorinvalidDice => '无效骰子';

  @override
  String get errorincompleteExpression => '表达式不完整';

  @override
  String get errordivideByZero => '除以零';

  @override
  String get errorunknownOperator => '未知运算符';

  @override
  String get errorwebNoHost => '当前 Web 端暂不支持创建房间，请在桌面端运行。';

  @override
  String get errorwebCreateRoom => 'Web 端不支持创建房间，请使用桌面端创建。';

  @override
  String errorcannotConnect(Object uri) {
    return '无法连接到 $uri';
  }

  @override
  String errorconnectionTimeout(Object uri) {
    return '连接 $uri 超时';
  }

  @override
  String get errorkicked => '你已被房主踢出房间';

  @override
  String errornameTaken(Object name) {
    return '名称 \"$name\" 已被使用，请更换名称后重试';
  }
}
