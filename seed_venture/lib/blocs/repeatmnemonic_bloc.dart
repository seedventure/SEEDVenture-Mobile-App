import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';


class RepeatMnemonicBloc implements BlocBase {
  PublishSubject subject = PublishSubject();


  void checkMnemonic(String rightMnemonic, String typedMnemonic){
    if(rightMnemonic == typedMnemonic){
      subject.add(true);
    } else {
      subject.add(false);
    }
  }

  void dispose() {
    subject.close();
  }
}
