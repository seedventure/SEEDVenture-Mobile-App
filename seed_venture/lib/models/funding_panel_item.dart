import 'package:seed_venture/models/member_item.dart';

class FundingPanelItem {

  // data for configuration file
  final String tokenAddress;
  final String fundingPanelAddress;
  final String adminToolsAddress;
  final List<Map> fundingPanelUpdates;

  // data for SharedPreferences (visualization)
  final String name;
  final String description;
  final String url;
  final String imgBase64;
  bool favorite;

  // shared
  final String latestDexQuotation;
  final double seedWhitelistThreshold;
  final List<MemberItem> members;
  final List tags;
  final List documents;
  final bool whitelisted;

  void setFavorite(bool favorite){
    this.favorite = favorite;
  }



  FundingPanelItem({this.tokenAddress, this.fundingPanelAddress, this.adminToolsAddress, this.fundingPanelUpdates,
      this.name, this.description, this.url, this.imgBase64, this.favorite, this.latestDexQuotation, this.members, this.tags, this.documents, this.seedWhitelistThreshold, this.whitelisted});
}