import 'package:flutter/material.dart';

import '../../app/theme/interbank_theme.dart';

class InterbankLogo extends StatelessWidget {
  const InterbankLogo({super.key, this.compact = false, this.inverse = false});

  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 40,
          height: compact ? 28 : 40,
          decoration: BoxDecoration(
            color: InterbankTheme.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_balance,
            color: Colors.white,
            size: compact ? 18 : 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Interbank UC',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: inverse ? Colors.white : InterbankTheme.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
