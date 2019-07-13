final ImportPrivateKeyLogicBloc importPrivateKeyLogicBloc = ImportPrivateKeyLogicBloc();

// Test private key import

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
