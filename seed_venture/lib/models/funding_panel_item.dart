
class FundingPanelItem {
  final String tokenAddress;
  final String fundingPanelAddress;
  final String adminToolsAddress;
  final String lastDEXPrice;
  final List<Map> fundingPanelUpdates;

  FundingPanelItem(this.tokenAddress, this.fundingPanelAddress, this.adminToolsAddress, this.lastDEXPrice, this.fundingPanelUpdates);
}