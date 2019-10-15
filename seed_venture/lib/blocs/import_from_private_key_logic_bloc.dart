final ImportPrivateKeyLogicBloc importPrivateKeyLogicBloc = ImportPrivateKeyLogicBloc();

class ImportPrivateKeyLogicBloc   {
  String _currentPrivateKey;

  void setCurrentPrivateKey(String privateKey) {
    this._currentPrivateKey = privateKey;
  }

  String getCurrentPrivateKey() {
    return _currentPrivateKey;
  }

  // validatePrivateKey()

  void dispose() {}
}
