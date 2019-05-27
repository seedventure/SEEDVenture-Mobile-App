import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';

class GridPageBloc implements BlocBase {
  PublishSubject subject = PublishSubject();


  void dispose() {
    subject.close();
  }
}
