import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/core/theme/app_colors.dart';
import 'package:next_on/core/theme/app_text_styles.dart';
import 'package:next_on/shared/widgets/global_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController ctrEmail = TextEditingController();
  TextEditingController ctrPassword = TextEditingController();
  bool rememberMe = false;
  bool passObscureText = true;
  bool isChecked = false;

  // Error states
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 50, 20, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Column(
                children: [
                  heightBx(h: 50),
                  assetImg("assets/images/polygon.png", width: 80, height: 80, fit: BoxFit.contain),
                  heightBx(h: 20),
                  customText("NEXTON", fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 40),
                  heightBx(h: 40),

                  customText(
                      "ເຂົ້າສູ່ລະບົບ",
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      fontSize: 20,
                      alight: TextAlign.center
                  ),
                  // heightBx(h: 15),
                  // customText(
                  //   "NEXTON ຍິນດີຕ້ອນຮັບ",
                  //   fontSize: 18,
                  //   alight: TextAlign.center,
                  //   color: AppColors.textTertiary,
                  // ),

                  heightBx(h: 40),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customText(
                              "ອີເມວ",
                            ),
                            heightBx(h: 6),
                            TextField(
                              decoration: inputDecoration("Example@gmail.com"),
                            ),
                            heightBx(h: 20),

                            passwordField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Widgets =================================================================
  Widget body(){
    return Container();
  }

  Widget passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            customText("ລະຫັດຜ່ານ"),
            customText("ລືມລະຫັດຜ່ານ ?", color: Colors.blueAccent, fontWeight: FontWeight.w500),
          ],
        ),
        heightBx(h: 6),
        Stack(
          children: [
            TextField(
              controller: ctrPassword,
              obscureText: passObscureText,
              obscuringCharacter: '*',
              inputFormatters: [],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              onChanged: (value) {
                // _clearPasswordError();
              },
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                // isDense: true,
                hintText: 'ປ້ອນລະຫັດຜ່ານ',
                hintStyle: AppTextStyles.hintStyle,
                // contentPadding: const EdgeInsets.fromLTRB(15, 15, 50, 15),
                counterText: '',
                // Hides the character counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xffE5E5E5), width: 1),
                  borderRadius: BorderRadius.circular(12),
                  //  when the TextFormField in unfocused
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _passwordError != null
                        ? AppColors.error
                        : AppColors.border,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  //  when the TextFormField in unfocused
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.secondaryVariant),
                  //  when the TextFormField in focused
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    passObscureText = !passObscureText;
                  });
                },
                child: Image.asset(
                  passObscureText
                      ? "assets/images/view.png"
                      : "assets/images/hide.png",
                  height: 20,
                  width: 20,
                ),
              ),
            ),
          ],
        ),
        // errorText(_passwordError),
        heightBx(h: 30),

        // Checkbox(
        //   value: isChecked,
        //   onChanged: (bool? value) {
        //     setState(() {
        //       isChecked = value!;
        //     });
        //   },
        // ),

        GestureDetector(
          onTap: (){
            setState(() {
              isChecked = !isChecked;
            });
          },
          child: checkBx(),
        ),
        heightBx(),
        heightBx(),
        button((){
          /// go to home page
          context.go('/');
        },
          "ເຂົ້າສູ່ລະບົບ",
        ),


      ],
    );
  }

  /// Remember me
  Widget checkBx(){
    return Row(
      children: [
        AnimatedContainer(
          height: 25,
          width: 25,
          duration: Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary),
          ),
          child: Icon(Icons.check,size: 15, color: Colors.white,),
        ),
        widthBx(w: 10),
        customText("ຈື່ອີເມວຂ້ອຍໄວ້"),
      ],
    );
  }


}
