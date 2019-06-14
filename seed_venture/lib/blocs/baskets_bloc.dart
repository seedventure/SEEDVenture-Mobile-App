import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/funding_panel_details.dart';

final BasketsBloc basketsBloc = BasketsBloc();

class BasketsBloc {
  PublishSubject<List<FundingPanelDetails>> _getFundingPanelsDetails =
      PublishSubject <List<FundingPanelDetails>>();

  Stream<List<FundingPanelDetails>> get outFundingPanelsDetails =>
      _getFundingPanelsDetails.stream;
  Sink<List<FundingPanelDetails>> get _inFundingPanelsDetails =>
      _getFundingPanelsDetails.sink;

  BasketsBloc() {
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_details'));
      List<FundingPanelDetails> fundingPanelsDetails = List();

      for(int i = 0; i < maps.length; i++){
        fundingPanelsDetails.add(FundingPanelDetails(maps[i]['name'], maps[i]['description'], maps[i]['url'], maps[i]['imgBase64']));
      }

      _inFundingPanelsDetails.add(fundingPanelsDetails);

    });
  }

  void closeSubjects() {
    _getFundingPanelsDetails.close();
  }
}
