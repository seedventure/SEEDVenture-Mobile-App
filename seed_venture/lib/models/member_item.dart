class MemberItem {
  final String memberAddress;
  final String fundingPanelAddress;
  final String ipfsUrl;
  final String hash;
  final String name;
  final String description;
  final String url;
  final String imgBase64;
  final List documents;

  MemberItem(
      {this.memberAddress,
      this.fundingPanelAddress,
      this.ipfsUrl,
      this.hash,
      this.name,
      this.description,
      this.url,
      this.imgBase64,
      this.documents});
}
