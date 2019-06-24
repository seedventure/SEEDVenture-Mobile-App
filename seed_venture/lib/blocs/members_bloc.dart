import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/member_item.dart';

final MembersBloc membersBloc = MembersBloc();

class MembersBloc {
  String _fundingPanelAddress;

  String getFundingPanelAddress(){
    return _fundingPanelAddress;
  }


  BehaviorSubject<List<MemberItem>> _getMembers =
  BehaviorSubject<List<MemberItem>>();

  Stream<List<MemberItem>> get outMembers => _getMembers.stream;
  Sink<List<MemberItem>> get _inMembers => _getMembers.sink;

  void getMembers(String fpAddress){
    this._fundingPanelAddress = fpAddress;
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_details'));
      List<MemberItem> members = List();

      for (int i = 0; i < maps.length; i++) {
        if (maps[i]['funding_panel_address'] == fpAddress) {
          List membersMaps = maps[i]['members'];
          for (int j = 0; j < membersMaps.length; j++) {
            members.add(MemberItem(
                membersMaps[j]['member_address'],
                membersMaps[j]['ipfsUrl'],
                membersMaps[j]['hash'],
                membersMaps[j]['name'],
                membersMaps[j]['description'],
                membersMaps[j]['url'],
                membersMaps[j]['imgBase64']));
          }

          break;
        }
      }

      _inMembers.add(members);
    });
  }



  void closeSubjects() {
    //_getMembers.close();
  }


}
