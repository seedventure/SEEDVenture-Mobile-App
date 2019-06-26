import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/members_bloc.dart';

class BasketTokenBalance extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BasketTokenBalanceState();
}

class _BasketTokenBalanceState extends State<BasketTokenBalance> {
  @override
  void initState() {
    membersBloc.getSpecificBasketBalance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Basket Token Balance'),
        ),
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              String tokenSymbol = snapshot.data[0];
              String tokenBalance = snapshot.data[1];
              return SingleChildScrollView(
                child: Container(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text('Balance: $tokenBalance $tokenSymbol'),
                          ],
                        )
                      ],
                    )),
              );
            } else {
              return Center(
                  child:
                      Text('Balances are being loaded from the blockchain...'));
            }
          },
          stream: membersBloc.outBasketBalanceAndSymbol,
        ));
  }
}
