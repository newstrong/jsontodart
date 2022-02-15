import 'package:flutter/material.dart';
import 'package:json_to_dart/style/color.dart';

class Drag2Icon extends StatelessWidget {
  const Drag2Icon({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10.0),
      width: double.infinity,
      alignment: Alignment.center,
      height: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 14,
            height: 2,
            decoration: ShapeDecoration(
              color: ColorPlate.gray.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Container(height: 4),
          Container(
            width: 14,
            height: 2,
            decoration: ShapeDecoration(
              color: ColorPlate.gray.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
