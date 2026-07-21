import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:next_on/core/theme/app_colors.dart';
import '../../shared/widgets/global_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              heightBx(),
              Row(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widthBx(w: 15),
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipOval(
                      child: assetImg("assets/images/mum_jokmok.jpeg"),
                    ),
                  ),
                  widthBx(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heightBx(h: 6),
                        customText("ໝ່ຳ ຈົກມົກ", fontWeight: FontWeight.w600, fontSize: 18),
                        customText("ນັກພັດທະນາແອັບມືຖື", color: AppColors.subTitle,),
                      ],
                    ),
                  ),
                  widthBx(),

                  Padding(
                    padding: const EdgeInsets.only(top: 10, right: 15),
                    child: assetImg("assets/icon/bell.png", width: 30, height: 30),
                  )
                ]
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(15, 15, 15, 60),
                  children: [

                    /// monitoring
                    Container(
                      // height: 200,
                      alignment: Alignment(0, 0),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              customText("ການຕິດຕາມ",color: Colors.white),

                              assetImg("assets/icon/scan.png", width: 25, height: 25),



                            ],
                          ),

                          heightBx(h: 15),
                          customText(
                            DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          heightBx(h: 20),
                          Row(
                            children: [
                              monitoringItem(
                                "12",
                                "ຂາດວຽກ",
                              ),
                              _lineH(),

                              monitoringItem(
                                "0",
                                "ມາຊ້າ",
                              ),
                              _lineH(),
                              monitoringItem(
                                "35",
                                "ລ່ວງເວລາ",
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),
                    heightBx(h: 20),

                    /// responsive grid menus here
                    SizedBox(
                      height: 300,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 4,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          final menuNames = [
                            "ເຂົ້າ/ອອກວຽກ",
                            "ການເຄື່ອນໄຫວ",
                            "ເອກະສານ",
                            "ລາຍງານ",
                            "ພາກສ່ວນ",
                            "ຕັ້ງຄ່າ",
                            "ແຈ້ງເຕືອນ",
                            "ໂປຣໄຟລ໌",
                          ];
                          final icons = [
                            Icons.history,
                            Icons.directions_run,
                            Icons.description,
                            Icons.assessment,
                            Icons.people,
                            Icons.settings,
                            Icons.notifications,
                            Icons.person,
                          ];
                          return menuItem(menuNames[index], icon: icons[index]);
                        },
                      ),
                    )
                  ]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// Widgets =================================================================
  Widget monitoringItem(String title, String subtitle){
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          customText(
            title,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          // heightBx(h: 6),
          customText(
            subtitle,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _lineH(){
    return Container(
      height: 40,
      decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border))
      ),
    );
  }

  Widget menuItem(String menuName, {IconData? icon}){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Icon(icon ?? Icons.check, size: 24, color: AppColors.primary),
        ),
        SizedBox(height: 4),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              menuName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

}