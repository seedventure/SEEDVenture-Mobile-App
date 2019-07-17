import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/member_item.dart';

final MembersBloc membersBloc = MembersBloc();

class MembersBloc {
  BehaviorSubject<List<MemberItem>> _getMembers =
      BehaviorSubject<List<MemberItem>>();

  Stream<List<MemberItem>> get outMembers => _getMembers.stream;
  Sink<List<MemberItem>> get _inMembers => _getMembers.sink;

  BehaviorSubject<MemberItem> _singleMemberData = BehaviorSubject<MemberItem>();

  Stream<MemberItem> get outSingleMemberData => _singleMemberData.stream;
  Sink<MemberItem> get _inSingleMemberData => _singleMemberData.sink;

  void getSingleMemberData(String fundingPanelAddress, String memberAddress) {
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_data'));
      MemberItem startup;

      for (int i = 0; i < maps.length; i++) {
        if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
            fundingPanelAddress.toLowerCase()) {
          List members = maps[i]['members'];

          for (int j = 0; j < members.length; j++) {
            if (members[j]['member_address'].toString().toLowerCase() ==
                memberAddress.toLowerCase()) {
              startup = MemberItem(
                  memberAddress: members[j]['members_address'],
                  fundingPanelAddress: fundingPanelAddress,
                  ipfsUrl: members[j]['ipfsUrl'],
                  hash: members[j]['hash'],
                  name: members[j]['name'],
                  description: members[j]['description'],
                  imgBase64: members[j]['imgBase64'],
                  url: members[j]['url'],
                  documents: maps[j]['documents']);

              break;
            }
          }

          break;
        }
      }

      _inSingleMemberData.add(startup);
    });
  }

  void getMembers(String fpAddress) {
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_data'));
      List<MemberItem> members = List();

      for (int i = 0; i < maps.length; i++) {
        if (maps[i]['funding_panel_address'] == fpAddress) {
          List membersMaps = maps[i]['members'];
          for (int j = 0; j < membersMaps.length; j++) {
            members.add(MemberItem(
                memberAddress: membersMaps[j]['member_address'],
                fundingPanelAddress: fpAddress,
                description: membersMaps[j]['description'],
                hash: membersMaps[j]['hash'],
                name: membersMaps[j]['name'],
                imgBase64: membersMaps[j]['imgBase64'],
                url: membersMaps[j]['url'],
                ipfsUrl: membersMaps[j]['ipfsUrl'],
                documents: membersMaps[j]['documents']));
          }

          break;
        }
      }

      _inMembers.add(members);
    });
  }

  void dispose() {
    _getMembers.close();
    _singleMemberData.close();
  }
}
