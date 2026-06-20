// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Roll and Roll';

  @override
  String get commoncancel => 'Cancel';

  @override
  String get commonsave => 'Save';

  @override
  String get commonadd => 'Add';

  @override
  String get commonclose => 'Close';

  @override
  String get commondelete => 'Delete';

  @override
  String get commonedit => 'Edit';

  @override
  String get commonremove => 'Remove';

  @override
  String get commonconfirm => 'Confirm';

  @override
  String get commonback => 'Back';

  @override
  String get commonretry => 'Retry';

  @override
  String get commonselectAll => 'Select All';

  @override
  String get commonclearAll => 'Clear';

  @override
  String get commonnoData => 'None';

  @override
  String get commonsearch => 'Search';

  @override
  String get commonsend => 'Send';

  @override
  String get commoncopy => 'Copy';

  @override
  String get commondecrease => 'Decrease';

  @override
  String get commonincrease => 'Increase';

  @override
  String get hometitle => 'Choose how to start';

  @override
  String get homeplayerName => 'Your player name';

  @override
  String get homeplayerNameHint => 'e.g. Alex';

  @override
  String get homecreateRoom => 'Create Room';

  @override
  String get homejoinRoom => 'Join Room';

  @override
  String get homeliveMode => 'Live Mode';

  @override
  String get homecreateSave => 'Create Save';

  @override
  String get homemodifySave => 'Modify Save';

  @override
  String get homewebWarning =>
      'Web does not support creating rooms. You can join a room created on desktop, or use Live Mode directly.';

  @override
  String get settingstitle => 'Settings';

  @override
  String get settingslanguage => 'Language 语言';

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
  String get roomCreatetitle => 'Create Room';

  @override
  String get roomCreatecloudTitle => 'Create Cloud Room';

  @override
  String get roomCreatelocalTitle => 'Open Local Port';

  @override
  String get roomCreatecloudDesc =>
      'Create a room via Cloudflare global network, no port forwarding needed';

  @override
  String get roomCreateportLabel => 'Port';

  @override
  String get roomCreateopenPort => 'Open Port';

  @override
  String get roomCreateclosePort => 'Close Port';

  @override
  String get roomCreatecreateRoom => 'Create Room';

  @override
  String get roomCreatecloseRoom => 'Close Room';

  @override
  String get roomCreatestatus => 'Status';

  @override
  String get roomCreateaddress => 'Room Address';

  @override
  String get roomCreateroomIdCopied => 'Room ID copied!';

  @override
  String get roomCreaterefreshMembers => 'Refresh member list';

  @override
  String get roomCreateselectIdentity => 'Select Identity';

  @override
  String get roomCreateselectArchive => 'Select Archive';

  @override
  String get roomCreatecreateArchive => 'Create Archive';

  @override
  String get roomCreateeditArchive => 'Edit Archive';

  @override
  String get roomCreateselectArchiveFile => 'Select archive file';

  @override
  String get roomCreatepleaseSelectArchive =>
      'Please select an archive file first';

  @override
  String get roomCreateopenArchiveFailed => 'Failed to open archive';

  @override
  String get roomCreateenterPort => 'Please enter a port number';

  @override
  String get roomCreateportRange => 'Port must be an integer between 1~65535';

  @override
  String get roomCreatedesktopOnly => 'Please run on desktop';

  @override
  String get roomCreateroomId => 'Room ID';

  @override
  String get roomCreatetellTeammates => 'Share this with your team';

  @override
  String get roomCreateportOpened => 'Port opened';

  @override
  String get roomCreatelocalAddress => 'Local address';

  @override
  String get roomCreatecreateFailed => 'Failed to create room';

  @override
  String get roomCreateopenPortFailed => 'Failed to open port';

  @override
  String get roomCreatenotCreated => 'Room not created yet';

  @override
  String get roomCreatewaitCreate => 'Waiting to create room';

  @override
  String get roomCreateroomClosed => 'Room closed';

  @override
  String get roomCreateportClosed => 'Port closed';

  @override
  String get roomCreatewaitOpenPort => 'Waiting to open port';

  @override
  String get roomCreatemembers => 'Room Members';

  @override
  String get roomCreateready => 'Ready';

  @override
  String get roomCreatenotReady => 'Not Ready';

  @override
  String get roomCreatereadyUp => 'Ready Up';

  @override
  String get roomCreatecancelReady => 'Cancel Ready';

  @override
  String get roomCreatewaitAllReady => 'Waiting for all members to be ready';

  @override
  String get roomCreateadventureInProgress => 'Adventure in progress';

  @override
  String get roomCreatestartAdventure => 'Start Adventure';

  @override
  String get roomCreateconfirmKick => 'Confirm Kick';

  @override
  String roomCreateconfirmKickContent(Object name) {
    return 'Are you sure you want to kick $name?';
  }

  @override
  String get roomCreatekick => 'Kick';

  @override
  String get roomCreateRolePlayer => 'Player';

  @override
  String get roomCreateRoleHost => 'Host';

  @override
  String get roomJointitle => 'Join Room';

  @override
  String get roomJoinbyRoomId => 'Enter Room ID';

  @override
  String get roomJoinbyIp => 'Join via IP and Port';

  @override
  String get roomJoinaskHost => 'Ask the host for the room ID';

  @override
  String get roomJoinroomIdLabel => 'Room ID';

  @override
  String get roomJoinipLabel => 'Room IP';

  @override
  String get roomJoinroomIdHint => 'e.g. ABC123';

  @override
  String get roomJoinipHint => 'e.g. 127.0.0.1';

  @override
  String get roomJoinportLabel => 'Room Port';

  @override
  String get roomJoinconnecting => 'Connecting...';

  @override
  String get roomJoinjoinRoom => 'Join Room';

  @override
  String get roomJoinenterRoomId => 'Please enter a room ID';

  @override
  String get roomJoinenterIp => 'Please enter an IP';

  @override
  String get roomJoinenterPort => 'Please enter a valid port';

  @override
  String get roomJoinwaitingConfirm => 'Waiting for host confirmation...';

  @override
  String get roomJoinjoined => 'Joined';

  @override
  String get roomJoinjoinFailed => 'Failed to join';

  @override
  String get roomJoinreconnecting => 'Reconnecting...';

  @override
  String get roomJoinreconnected => 'Reconnected';

  @override
  String get roomJoinreconnectFailed => 'Reconnect failed';

  @override
  String get roomJoinconnected => 'Connected to room';

  @override
  String get roomJoinleaveRoom => 'Leave Room';

  @override
  String get roomJoinyourName => 'Your Name';

  @override
  String get roomJoinyourRole => 'Your Role';

  @override
  String get roomJoinswitchRole => 'Switch Role';

  @override
  String get roomJoinhostSave => 'Host Save';

  @override
  String get roomJoinadventureStarted => 'Adventure started';

  @override
  String get roomJoinroomMembers => 'Room Members';

  @override
  String get roomJoinnameInUse =>
      'Name is already in use, please change and retry';

  @override
  String get roomJoinkicked => 'You have been kicked from the room';

  @override
  String get adventuretitle => 'Adventure';

  @override
  String get adventurereturnToRoom => 'Return to Room';

  @override
  String get adventuresaveProgress => 'Save Progress';

  @override
  String get adventuresaveAs => 'Save As';

  @override
  String get adventureexitAdventure => 'Exit Adventure';

  @override
  String get adventureexitConfirm =>
      'Exiting will kick all players. Are you sure?';

  @override
  String get adventureexit => 'Exit';

  @override
  String get adventuresaveAndExit => 'Save Progress & Exit';

  @override
  String get adventurechat => 'Chat';

  @override
  String get adventureenterAdventure => 'Enter Adventure';

  @override
  String get adventureplayerList => 'Character List';

  @override
  String get adventurerightClickDeploy => 'Right-click to deploy';

  @override
  String get adventurenoCharacters => 'No characters';

  @override
  String get adventurenoEquipment => 'No equipment';

  @override
  String get adventurenoItems => 'No items';

  @override
  String get adventurenoSkills => 'No skills';

  @override
  String get adventureequipment => 'Equipment';

  @override
  String get adventureitems => 'Items';

  @override
  String get adventureskills => 'Skills';

  @override
  String get adventureaddEquipment => 'Add Equipment';

  @override
  String get adventureaddItem => 'Add Item';

  @override
  String get adventuresearchEquipment => 'Search equipment name/slot/effect...';

  @override
  String get adventuresearchItems => 'Search item name/type/effect...';

  @override
  String get adventurenoMatchEquipment => 'No matching equipment';

  @override
  String get adventurenoMatchItems => 'No matching items';

  @override
  String get adventureclosePanel => 'Close Panel';

  @override
  String get adventuretotalValue => 'Total Value';

  @override
  String get adventuredeploy => 'Deploy';

  @override
  String get adventuredeployHint => 'Tap map to place';

  @override
  String get adventuretakeDown => 'Remove';

  @override
  String get adventureeditHp => 'Edit HP';

  @override
  String get adventurecurrentHp => 'Current HP';

  @override
  String get adventuremaxHp => 'Max HP';

  @override
  String get adventurenotes => 'Notes';

  @override
  String get adventurenewNote => 'New Note';

  @override
  String get adventurenoteHint =>
      'Record status changes, buffs, debuffs, etc...';

  @override
  String get adventurehostMode => 'Host Mode';

  @override
  String get adventurecharacterManagement => 'Character Management';

  @override
  String get adventureaddCharacter => 'Add Character';

  @override
  String get adventureremoveCharacter => 'Remove Character';

  @override
  String get adventuresaveSuccess => 'Progress saved';

  @override
  String get adventuresaveFailed => 'Save failed';

  @override
  String get adventureconfirmSave => 'Confirm Save';

  @override
  String get adventureconfirmSaveContent =>
      'This will overwrite the existing save. Continue?';

  @override
  String get adventuresavedAs => 'Saved as';

  @override
  String get adventuresaved => 'Saved';

  @override
  String get adventureexpressionInvalid => 'Invalid expression';

  @override
  String adventurespeakingCount(Object count) {
    return '$count speaking';
  }

  @override
  String get adventureunmute => 'Unmute Mic';

  @override
  String get adventuremute => 'Mute Mic';

  @override
  String get adventureselectMic => 'Select Microphone';

  @override
  String get adventurejoinVoice => 'Join Voice Channel';

  @override
  String get adventureleaveVoice => 'Leave Voice Channel';

  @override
  String get adventureequipped => 'equipped';

  @override
  String get adventureobtained => 'obtained';

  @override
  String get adventurenoteAdded => 'note added';

  @override
  String get adventurenoteDeleted => 'note deleted';

  @override
  String get adventuredeployed => 'deployed';

  @override
  String get adventuretakenDown => 'removed';

  @override
  String get adventuregridOn => 'Show Grid';

  @override
  String get adventuregridOff => 'Hide Grid';

  @override
  String get adventurecoordsOn => 'Show Coordinates';

  @override
  String get adventurecoordsOff => 'Hide Coordinates';

  @override
  String get adventurerollDice => 'Roll';

  @override
  String get adventureexpandDice => 'Expand Dice';

  @override
  String get adventurecollapseDice => 'Collapse Dice';

  @override
  String get adventurechatHint => 'Type a message...';

  @override
  String get mapeditTitle => 'Edit Map';

  @override
  String get mapselectMap => 'Select Map';

  @override
  String get mapnoMaps => 'No maps in this archive';

  @override
  String get maporCreateEdit => 'Or create / edit map';

  @override
  String get mapcreateEditMap => 'Create / Edit Map (Open Archive Editor)';

  @override
  String get mapfromArchive => 'Select a map from archive';

  @override
  String get maploadMapFailed => 'Map load failed';

  @override
  String get maparrangePositions => 'Arrange Character Positions';

  @override
  String mappositionsPlaced(Object count) {
    return '$count positions placed';
  }

  @override
  String mapplaceCharacterOnMap(Object name) {
    return 'Tap the map to place \"$name\"';
  }

  @override
  String mapcharacterCount(Object count) {
    return 'Characters ($count) — select a character then tap the map';
  }

  @override
  String mapnoImage(Object name) {
    return 'Map \"$name\" has no image';
  }

  @override
  String get mapsize => 'Size';

  @override
  String get mapnoDescription => 'No description';

  @override
  String get mapaddMap => 'Add Map';

  @override
  String get mapmapName => 'Map Name';

  @override
  String get mapdescription => 'Description';

  @override
  String get mapuploadImage => 'Upload Map Image *';

  @override
  String get mapwidthMeters => 'Width (meters)';

  @override
  String get maplengthMeters => 'Length (meters)';

  @override
  String get mapmeterUnit => 'm';

  @override
  String get mappleaseUploadImage => 'Please upload a map image first';

  @override
  String get mapdefaultName => 'Untitled Map';

  @override
  String get mapmapList => 'Map List';

  @override
  String mapmapsCount(Object count) {
    return '$count map(s) added';
  }

  @override
  String get mapnoMapsAdded => 'No maps yet, tap the button above to add';

  @override
  String get charselectCharacter => 'Select Character';

  @override
  String get charfromArchive => 'Select a character from archive';

  @override
  String get charnoCharacters => 'No characters in this archive';

  @override
  String get charorCreate => 'Or create a new character';

  @override
  String get charcreateInArchive => 'Create Character in Current Archive';

  @override
  String get charcreateNew => 'Create New Character (Full Editor)';

  @override
  String get charhello => 'Hello';

  @override
  String get charwaitingHost => 'Waiting for host to enter adventure';

  @override
  String get charhostSettingUp => 'Host is setting up the map...';

  @override
  String get charwaitingAdventure => 'Waiting for host to start...';

  @override
  String get charready => 'Ready';

  @override
  String charaddedToArchive(Object name) {
    return 'Character \"$name\" added to archive';
  }

  @override
  String charupdatedInArchive(Object name) {
    return 'Character \"$name\" updated';
  }

  @override
  String get charaddFailed => 'Add failed';

  @override
  String get charupdateFailed => 'Update failed';

  @override
  String get chareditCharacter => 'Edit Character';

  @override
  String get charnewCharacter => 'New Character to Archive';

  @override
  String get charpleaseEnterName => 'Please enter a character name first';

  @override
  String get charselectPortrait => 'Select Character Portrait';

  @override
  String get charcharacterInfo => 'Character Info';

  @override
  String get charcharacterName => 'Character Name';

  @override
  String get charselectAvatar => 'Select Avatar';

  @override
  String get charspeed => 'Speed';

  @override
  String get charmetersPerRound => 'm/round';

  @override
  String get charclass => 'Class';

  @override
  String get charaddClass => 'Add Class';

  @override
  String get charprimaryClass => 'Primary Class';

  @override
  String get charsubClass => 'Sub Class';

  @override
  String get charremoveClass => 'Remove Class';

  @override
  String get charrace => 'Race';

  @override
  String get charcustomRace => 'Custom Race Name';

  @override
  String get charlevel => 'Level';

  @override
  String get charhp => 'HP';

  @override
  String get charcurrent => 'Current';

  @override
  String get charmax => 'Max';

  @override
  String charskillsCount(Object count) {
    return 'Skills ($count)';
  }

  @override
  String get charaddSkillFromTemplate => 'Add Skill from Template';

  @override
  String get charbackpack => 'Backpack';

  @override
  String get charweight => 'Weight';

  @override
  String get charequipmentSlots => 'Equipment Slots';

  @override
  String get charpleaseAddSlots =>
      'Please add equipment slots in the Rules page';

  @override
  String get charitemsTab => 'Items';

  @override
  String get charselectItem => 'Select Item';

  @override
  String get charpleaseAddItemTemplates =>
      'Please add item templates in the Rules page first';

  @override
  String get charstats => 'Attribute Distribution';

  @override
  String get charaddStat => 'Add Stat';

  @override
  String get charaddCustomStat => 'Add Custom Stat';

  @override
  String get charstatName => 'Stat Name';

  @override
  String get charstatInitialValue => 'Initial Value (0~20)';

  @override
  String get charstatHint => 'e.g. Luck, Agility';

  @override
  String get charsaveModify => 'Save Changes';

  @override
  String get charaddToArchive => 'Add to Current Archive';

  @override
  String charselectEquipmentSlot(Object slot) {
    return 'Select $slot';
  }

  @override
  String get charequip => 'Equip';

  @override
  String get charinventory => 'Inventory';

  @override
  String get charpersonality => 'Personality';

  @override
  String get charhostNotes => 'Host Notes';

  @override
  String get charnotArchived => 'Not selected';

  @override
  String get chardefaultName => 'Unnamed Adventurer';

  @override
  String get chardefaultClass => 'Fighter';

  @override
  String get chardefaultRace => 'Human';

  @override
  String get chardefaultEquipment => 'Unnamed Equipment';

  @override
  String get chardefaultItem => 'Unnamed Item';

  @override
  String get statstrength => 'Strength';

  @override
  String get statdexterity => 'Dexterity';

  @override
  String get statconstitution => 'Constitution';

  @override
  String get statintelligence => 'Intelligence';

  @override
  String get statwisdom => 'Wisdom';

  @override
  String get statcharisma => 'Charisma';

  @override
  String get racehuman => 'Human';

  @override
  String get raceelf => 'Elf';

  @override
  String get racedwarf => 'Dwarf';

  @override
  String get racehalfling => 'Halfling';

  @override
  String get racedragonborn => 'Dragonborn';

  @override
  String get raceorc => 'Orc';

  @override
  String get damagefire => 'Fire';

  @override
  String get damagecold => 'Cold';

  @override
  String get damagelightning => 'Lightning';

  @override
  String get damagepoison => 'Poison';

  @override
  String get damagenecrotic => 'Necrotic';

  @override
  String get damageradiant => 'Radiant';

  @override
  String get damageforce => 'Force';

  @override
  String get damagepsychic => 'Psychic';

  @override
  String get damagenecrosis => 'Necrosis';

  @override
  String get damagepiercing => 'Piercing';

  @override
  String get damageslashing => 'Slashing';

  @override
  String get damagebludgeoning => 'Bludgeoning';

  @override
  String get equiphelmet => 'Helmet';

  @override
  String get equipbody => 'Body Armor';

  @override
  String get equiphands => 'Gauntlets';

  @override
  String get equiplegs => 'Leggings';

  @override
  String get equipaccessory => 'Accessory';

  @override
  String get savecreateTitle => 'Create Save';

  @override
  String get savemodifyTitle => 'Modify Save';

  @override
  String get savecharacters => 'Characters';

  @override
  String get savemaps => 'Maps';

  @override
  String get saverules => 'Rules';

  @override
  String get saveswitchCharacter => 'Switch Character';

  @override
  String get saveaddCharacter => 'Add Character';

  @override
  String get saveselectArchive => 'Select Archive';

  @override
  String get saveselectArchiveFile => 'Select Archive File';

  @override
  String get saveselectModifyFile => 'Select archive to modify (.zip)';

  @override
  String get savezipOnly => 'Please select a .zip archive file';

  @override
  String get savereadFailed => 'Failed to read archive';

  @override
  String get savesaving => 'Saving...';

  @override
  String get savesaveFile => 'Save Archive';

  @override
  String get savesaveModify => 'Save Changes';

  @override
  String get savesaveAs => 'Save As';

  @override
  String get savesaveAsDialog => 'Save Archive File (ZIP)';

  @override
  String get savesaveAsRule => 'Save Rulebook As';

  @override
  String savesaved(Object charCount, Object mapCount) {
    return 'Archive saved (Characters:$charCount Maps:$mapCount)';
  }

  @override
  String get savesaveFailed => 'Save failed';

  @override
  String get saveupdated => 'Archive updated';

  @override
  String get savesaveAsSuccess => 'Saved as';

  @override
  String get savesaveAsFailed => 'Save as failed';

  @override
  String get saveimportRule => 'Import Rulebook';

  @override
  String get saveruleImported => 'Rulebook imported';

  @override
  String get saveruleExported => 'Rulebook exported';

  @override
  String get saveimportFailed => 'Import failed';

  @override
  String get savebackpackFull => 'Backpack is full';

  @override
  String get saveconfirmOverwrite => 'Confirm Save';

  @override
  String get saveconfirmOverwriteContent =>
      'This will overwrite the existing archive. Continue?';

  @override
  String get savenoArchive => 'Not selected';

  @override
  String get rulesbackpackSettings => 'Backpack Settings';

  @override
  String get rulesbackpackSlotMax => 'Backpack Slot Limit';

  @override
  String rulesbackpackSlotDescription(Object max) {
    return 'Each character can carry up to $max items';
  }

  @override
  String get rulesweightMaxExpression => 'Max Weight Expression';

  @override
  String get rulesweightMaxHint => 'STR*15';

  @override
  String get rulesweightMaxDefault => 'Leave empty for default: STR × 15';

  @override
  String get rulesweightCurrentExpression => 'Current Weight Expression';

  @override
  String get rulesweightCurrentHint => 'Leave empty to sum item weights';

  @override
  String get rulesweightCurrentDefault =>
      'Leave empty for default: sum of all item weight fields';

  @override
  String rulesitemTemplates(Object count) {
    return 'Item Templates ($count)';
  }

  @override
  String get rulesitemTemplatesDesc =>
      'Customize item properties; characters can select from these to add to backpack';

  @override
  String get rulesaddItemTemplate => 'Add Item Template';

  @override
  String get rulesequipmentSlotEdit => 'Equipment Slot Editor';

  @override
  String get rulesequipmentSlotDesc =>
      'Define equipment slot names (e.g. Helmet, Body Armor, Gauntlets, Leggings, Accessory)';

  @override
  String get rulesaddEquipmentSlot => 'Add Equipment Slot';

  @override
  String get rulesdeleteSlot => 'Delete Slot';

  @override
  String rulesequipmentTemplates(Object count) {
    return 'Equipment Templates ($count)';
  }

  @override
  String get rulesequipmentTemplatesDesc =>
      'Customize equipment properties; characters can select from these to equip';

  @override
  String get rulesaddEquipmentTemplate => 'Add Equipment Template';

  @override
  String rulesskillTemplates(Object count) {
    return 'Skill Templates ($count)';
  }

  @override
  String get rulesskillTemplatesDesc =>
      'Customize skill templates; characters can select from these to add to their skill list';

  @override
  String get rulesaddSkillTemplate => 'Add Skill Template';

  @override
  String rulesdamageTypes(Object count) {
    return 'Damage Types ($count)';
  }

  @override
  String get rulesdamageTypesDesc =>
      'Define damage types for the game; skill templates can reference these';

  @override
  String get rulesaddDamageType => 'Add Damage Type';

  @override
  String get rulesturnSettings => 'Turn Settings';

  @override
  String get rulesturnNotSet => 'No turn parameters set';

  @override
  String rulesturnSet(Object count) {
    return '$count item(s) set';
  }

  @override
  String get rulesaddTurnSetting => 'Add Turn Setting';

  @override
  String get rulesphaseSettings => 'Phase Settings';

  @override
  String rulesphasesSet(Object count) {
    return '$count phase(s) set';
  }

  @override
  String get rulesaddPhase => 'Add Phase';

  @override
  String get rulesdeletePhase => 'Delete Phase';

  @override
  String get rulesitemName => 'Item Name';

  @override
  String get rulesitemType => 'Item Type';

  @override
  String get rulesitemTypeHint => 'Weapon / Armor / Potion / Misc';

  @override
  String get rulesitemEffect => 'Item Effect';

  @override
  String get rulesitemEffectHint => 'e.g. Restore 2d6+4 HP';

  @override
  String get rulesvalue => 'Value';

  @override
  String get rulesweight => 'Weight';

  @override
  String get rulesselectItemImage => 'Select Item Image';

  @override
  String get rulesselectImage => 'Select Image';

  @override
  String get rulesimageSelected => 'Image Selected';

  @override
  String get rulesequipmentName => 'Equipment Name';

  @override
  String get rulesequipmentSlot => 'Equipment Slot';

  @override
  String get rulesequipmentType => 'Equipment Type';

  @override
  String get rulesequipmentTypeHint => 'Armor / Weapon / Accessory';

  @override
  String get rulesequipmentEffect => 'Equipment Effect';

  @override
  String get rulesequipmentEffectHint => 'e.g. +2 AC';

  @override
  String get rulesselectEquipmentImage => 'Select Equipment Image';

  @override
  String get rulesskillName => 'Skill Name';

  @override
  String get rulesskillDamage => 'Skill Damage';

  @override
  String get rulesdamageExpression => 'Expression';

  @override
  String get rulesdamageType => 'Damage Type';

  @override
  String get rulesnone => 'None';

  @override
  String get rulesskillIcon => 'Select Skill Icon';

  @override
  String get rulesuploadIcon => 'Upload Icon';

  @override
  String get rulesiconSelected => 'Icon Selected';

  @override
  String get rulesdamageTypeName => 'Damage Type Name';

  @override
  String get rulesdamageTypeHint => 'e.g. Fire, Cold, Lightning';

  @override
  String get ruleseditItemTemplate => 'Edit Item Template';

  @override
  String get rulesaddItemTemplateTitle => 'Add Item Template';

  @override
  String get ruleseditEquipmentTemplate => 'Edit Equipment Template';

  @override
  String get rulesaddEquipmentTemplateTitle => 'Add Equipment Template';

  @override
  String get ruleseditSkillTemplate => 'Edit Skill Template';

  @override
  String get rulesaddSkillTemplateTitle => 'Add Skill Template';

  @override
  String get rulesaddEquipmentSlotTitle => 'Add Equipment Slot';

  @override
  String get rulesequipmentSlotName => 'Equipment Slot Name';

  @override
  String get rulesequipmentSlotHint => 'e.g. Helmet, Gauntlets, Body Armor';

  @override
  String get rulesaddDamageTypeTitle => 'Add Damage Type';

  @override
  String get livetitle => 'Live Mode';

  @override
  String get livedesktopOnly => 'Live Mode is desktop only';

  @override
  String get liveselectArchive => 'Select Archive';

  @override
  String get liveselectArchiveStart => 'Select an archive to start streaming';

  @override
  String get liveselectMap => 'Select a Map';

  @override
  String get liveselectCharacters => 'Live Mode · Select Characters';

  @override
  String get livenoCharacters => 'No characters in this archive';

  @override
  String livestartLive(Object count) {
    return 'Start Stream ($count character(s) selected)';
  }

  @override
  String get liveswitchMap => 'Switch Map';

  @override
  String get livereopenPlayer => 'Reopen Player Window';

  @override
  String get livebackToSelection => 'Back to Selection';

  @override
  String get livediceLog => 'Dice Log';

  @override
  String get livenoDiceLog => 'No dice rolls yet';

  @override
  String get livechatPlaceholder => 'Type a message...';

  @override
  String get liveloadFailed => 'Load failed';

  @override
  String get livenoEquipmentTemplates => 'No equipment templates in rulebook';

  @override
  String get livenoItemTemplates => 'No item templates in rulebook';

  @override
  String get liveplayerWindow => 'Player View';

  @override
  String get liveloadError =>
      'Archive path is empty, please ask the host to reopen the window';

  @override
  String get liveloadSaveFailed => 'Failed to load archive';

  @override
  String get livenoChars => 'No character data';

  @override
  String get livenoMap => 'No map data';

  @override
  String get voicenoMicPermission => 'No microphone permission';

  @override
  String get errorzipMissing => 'savejson is missing from the ZIP archive';

  @override
  String get errorillegalChar => 'Expression contains illegal characters';

  @override
  String get errorparenMismatch => 'Mismatched parentheses';

  @override
  String get errorinvalidDice => 'Invalid dice';

  @override
  String get errorincompleteExpression => 'Incomplete expression';

  @override
  String get errordivideByZero => 'Division by zero';

  @override
  String get errorunknownOperator => 'Unknown operator';

  @override
  String get errorwebNoHost =>
      'Cannot host on Web. Please run the desktop version.';

  @override
  String get errorwebCreateRoom =>
      'Web does not support creating rooms. Please use the desktop version.';

  @override
  String errorcannotConnect(Object uri) {
    return 'Cannot connect to $uri';
  }

  @override
  String errorconnectionTimeout(Object uri) {
    return 'Connection to $uri timed out';
  }

  @override
  String get errorkicked => 'You have been kicked by the host';

  @override
  String errornameTaken(Object name) {
    return 'Name \"$name\" is already in use, please change and retry';
  }
}
