class MemberItem {
  final String memberAddress;
  final String fundingPanelAddress;
  String ipfsUrl;
  String hash;
  String name;
  String description;
  String url;
  String imgBase64;
  List documents;
  String seedsUnlocked;

  MemberItem(
      {this.memberAddress,
      this.fundingPanelAddress,
      this.ipfsUrl,
      this.hash,
      this.name,
      this.description,
      this.url,
      this.imgBase64,
      this.documents,
      this.seedsUnlocked});
}
