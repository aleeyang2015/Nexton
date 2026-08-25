import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

Widget popBack() {
  return Container(
    height: 50,
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.only(top: 10),
    child: Icon(Icons.arrow_back_ios, size: 24, color: Color(0xff1C1B1F)),
  );
}

Widget underLineTxt(
  String txt, {
  double fontSize = 16,
  Color color = Colors.black,
  FontWeight fontWeight = FontWeight.w400,
}) {
  return Text(
    txt,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: TextDecoration.underline,
      decorationColor: color,
    ),
  );
}

/// vertical space
Widget heightBx({double h = 10}) {
  return SizedBox(height: h);
}

/// horizontal space
Widget widthBx({double w = 10}) {
  return SizedBox(width: w);
}

/// divider line
Widget divider = Divider(color: Colors.grey.withValues(alpha: 4));

/// custom line
Widget generalLine({Color color = AppColors.gray400, double width = 1}) =>
    Container(
      alignment: Alignment(0, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color, width: width),
        ),
      ),
    );

/// show img widget
Widget assetImg(
  String img, {
  double width = 60,
  double height = 60,
  BoxFit fit = BoxFit.cover,
  Color? color,
}) {
  return Image.asset(
    img,
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
  );
}

/// text label
Widget customText(
  String txt, {
  double fontSize = 16,
  Color color = Colors.black,
  FontWeight fontWeight = FontWeight.w400,
  int maxLine = 1,
  TextAlign alight = TextAlign.start,
}) {
  return Text(
    txt,
    style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
    maxLines: maxLine,
    overflow: TextOverflow.ellipsis,
    textAlign: alight,
  );
}

InputDecoration inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    fillColor: Colors.white,
    filled: true,
    hintStyle: AppTextStyles.hintStyle,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.secondaryVariant),
    ),
  );
}

/// Primary action button. Pass [enabled] `false` to grey it out and block
/// taps — used while a form is submitting or incomplete.
Widget button(
  Function() func,
  String label, {
  double height = 56,
  bool enabled = true,
}) {
  return SizedBox(
    width: double.infinity,
    height: height,
    child: ElevatedButton(
      onPressed: enabled ? func : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.gray400,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: customText(
        label,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontSize: 18,
      ),
    ),
  );
}
