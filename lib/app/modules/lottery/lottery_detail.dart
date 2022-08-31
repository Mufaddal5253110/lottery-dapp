import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';
import 'package:lottery_advance/utils/constants.dart';
import 'package:lottery_advance/utils/font_styles.dart';
import 'package:lottery_advance/utils/input_decorations.dart';
import 'package:lottery_advance/utils/remove_scroll_glow.dart';
import 'package:lottery_advance/utils/theme.dart';

class LotteryDetail extends StatefulWidget {
  final String lotteryAddress;
  const LotteryDetail({Key? key, required this.lotteryAddress})
      : super(key: key);

  @override
  State<LotteryDetail> createState() => _LotteryDetailState();
}

class _LotteryDetailState extends State<LotteryDetail> {
  final contractLink = Get.find<ContractLinking>();
  final lotteryMaxEntryController = TextEditingController();
  final lotteryETHRequiredController = TextEditingController();
  bool _isLoading = true;
  // String weiToethereum = "";

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await contractLink.getDeployedContractLottery(widget.lotteryAddress);
    Future.delayed(
      Duration.zero,
      () => setState(() {
        _isLoading = false;
      }),
    );

    contractLink.listenPalyerParticipate().listen((event) async {
      await contractLink.reloadContractOnParticipate();
    });

    // lotteryETHRequiredController.addListener(() {
    //   setState(() {
    //     weiToethereum =
    //         (int.parse(lotteryETHRequiredController.text) * pow(10, -18))
    //             .toString();
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      height: Get.height * 0.88,
      child: ScrollConfiguration(
        behavior: RemoveScrollGlow(),
        child: _isLoading == true
            ? const Center(child: CircularProgressIndicator())
            : Obx(
                () => ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: Get.width * 0.4,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Get.theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                        ).marginOnly(top: 5),
                      ],
                    ),
                    Obx(
                      () => SizedBox(
                        width: Get.width * 0.8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: Get.back,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            (contractLink.managerAddress.value ==
                                        contractLink.userAddress.value &&
                                    contractLink.lotteryLive.value == false)
                                ? PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text(
                                          "Delete Lottery",
                                          style: bodySemiLight,
                                        ),
                                        onTap: () async {
                                          Get.back();
                                          await contractLink.deleteLotteryFunc(
                                              widget.lotteryAddress);
                                        },
                                      )
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        contractLink.lotryname.value,
                        style: headingStyleSemiBold,
                      ),
                    ),
                    const Center(
                      child: Text(
                        "by",
                        style: bodySemiLightSmall,
                      ),
                    ).marginSymmetric(vertical: 5),
                    Center(
                      child: Text(
                        contractLink.managerAddress.value,
                        style: bodySemiBoldSmall,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              FontAwesomeIcons.award,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              contractLink.contractBalance.value,
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.groups,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              '${contractLink.players.length}',
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              contractLink.lotteryLive.value
                                  ? FontAwesomeIcons.toggleOn
                                  : FontAwesomeIcons.toggleOff,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              contractLink.lotteryLive.value
                                  ? "Active"
                                  : "Inactive",
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                      ],
                    ).marginSymmetric(vertical: 20),
                    ListTile(
                      leading: const Icon(
                        FontAwesomeIcons.gift,
                        color: primaryColor,
                      ),
                      title: const Text(
                        'Last Winner',
                        style: bodySemiBold,
                      ),
                      subtitle: Obx(
                        () => Text(
                          '${contractLink.lastWinner.value.isEmpty ? defaultHex : contractLink.lastWinner.value} ',
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        FontAwesomeIcons.ticketAlt,
                        color: primaryColor,
                      ),
                      title: Text(
                        'Tickets Buy ( Max : ${contractLink.lotteryLimit.value} )',
                        style: bodySemiBold,
                      ),
                      subtitle: Obx(
                        () => Text(
                          '${contractLink.lotteryBuyCount.value}',
                        ),
                      ),
                    ),
                    if (contractLink.managerAddress.value ==
                        contractLink.userAddress.value)
                      ListTile(
                        leading: const Icon(
                          FontAwesomeIcons.clipboardCheck,
                          color: primaryColor,
                        ),
                        title: const Text(
                          'Tickets Sold',
                          style: bodySemiBold,
                        ),
                        subtitle: Obx(
                          () => Text(
                            '${contractLink.lotterySold.value}',
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () => contractLink.isLoadingParticipate.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        contractLink.animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : contractLink.lotteryLive.value
                                  ? contractLink.lotteryBuyCount.value == 0
                                      ? MaterialButton(
                                          onPressed:
                                              contractLink.participateInLottery,
                                          color: primaryColor,
                                          textColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32)),
                                          child: Text(
                                            '${contractLink.lotteryETH} ETH \n Participate',
                                            style: bodySemiBold,
                                            textAlign: TextAlign.center,
                                          ).paddingAll(12),
                                        ).paddingSymmetric(
                                          vertical: 4, horizontal: 16)
                                      : (contractLink.players.value.contains(
                                                  contractLink
                                                      .userAddress.value) &&
                                              contractLink
                                                      .lotteryBuyCount.value <
                                                  contractLink
                                                      .lotteryLimit.value)
                                          ? MaterialButton(
                                              onPressed: contractLink
                                                  .participateInLottery,
                                              color: primaryColor,
                                              textColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          32)),
                                              child: Text(
                                                '${contractLink.lotteryETH} ETH \n Buy more',
                                                style: bodySemiBold,
                                                textAlign: TextAlign.center,
                                              ).paddingAll(12),
                                            ).paddingSymmetric(
                                              vertical: 4, horizontal: 16)
                                          : Text(
                                              "All tickets sold",
                                              style: bodySemiBold.copyWith(
                                                  color: Colors.red),
                                            )
                                  : const SizedBox.shrink(),
                        ),
                        Obx(
                          () => contractLink.isLoadingDeclareWinner.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        contractLink.animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : (contractLink.userAddress.value ==
                                          contractLink.managerAddress.value &&
                                      contractLink.lotteryLive.value)
                                  ? MaterialButton(
                                      onPressed: contractLink.pickWinner,
                                      color: secondaryColor,
                                      textColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32)),
                                      child: const Text(
                                        'Pick Winner',
                                        style: bodySemiBold,
                                      ).paddingAll(12),
                                    ).paddingSymmetric(
                                      vertical: 16, horizontal: 16)
                                  : Container(),
                        ),
                        Obx(
                          () => contractLink.isLoadingActivateLottery.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        contractLink.animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : (contractLink.lotteryLive.value == false &&
                                      contractLink.managerAddress.value ==
                                          contractLink.userAddress.value)
                                  ? MaterialButton(
                                      onPressed: () {
                                        activateLotteryDialog();
                                      },
                                      color: primaryColor,
                                      textColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32)),
                                      child: const Text(
                                        'Activate Lottery',
                                        style: bodySemiBold,
                                        textAlign: TextAlign.center,
                                      ).paddingAll(12),
                                    ).paddingSymmetric(
                                      vertical: 4, horizontal: 16)
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Obx(
                        () => Text(
                          "${contractLink.message.value}",
                          textAlign: TextAlign.center,
                          style: bodySemiBold.copyWith(
                              color: contractLink.message.contains('error')
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void activateLotteryDialog() {
    Get.back();
    Get.defaultDialog(
        title: "Activate Lottery",
        titleStyle: bodySemiBold,
        content: Container(
          constraints: BoxConstraints(maxWidth: Get.width * 0.8),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: lotteryMaxEntryController,
                decoration: borderedInputDecoration(
                  fillColor: primaryColor,
                  hint: 'Ex: 10',
                  icon: const Icon(
                    Icons.groups,
                    color: primaryColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: lotteryMaxEntryController.clear,
                    icon: const Icon(
                      Icons.clear,
                      color: primaryColor,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ).marginOnly(bottom: 10),
              TextField(
                controller: lotteryETHRequiredController,
                decoration: borderedInputDecoration(
                  fillColor: primaryColor,
                  hint: 'Ex: 1',
                  icon: const Icon(
                    FontAwesomeIcons.ethereum,
                    color: primaryColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: lotteryETHRequiredController.clear,
                    icon: const Icon(
                      Icons.clear,
                      color: primaryColor,
                    ),
                  ),
                ),
                // onChanged: (msg) {
                //   setState(() {
                //     weiToethereum = (int.parse(msg) * pow(10, -18)).toString();
                //   });
                // },
                keyboardType: TextInputType.number,
              ),
              // Text(
              //   "Value in Ethereum : ${weiToethereum}",
              //   style: bodySemiBoldSmall,
              // ).marginOnly(top: 5),
            ],
          ),
        ),
        actions: [
          Obx(
            () => contractLink.isLoadingActivateLottery.value
                ? const Center(child: CircularProgressIndicator())
                : MaterialButton(
                    onPressed: () async {
                      await contractLink.activateLotteryFunc(
                        int.parse(lotteryMaxEntryController.text.trim()),
                        int.parse(lotteryETHRequiredController.text.trim()),
                      );
                      lotteryMaxEntryController.clear();
                      lotteryETHRequiredController.clear();
                      Get.back();
                    },
                    splashColor: splashColor,
                    child: Text(
                      'Activate',
                      style: bodySemiBoldSmall.copyWith(color: primaryColor),
                    ),
                  ).paddingSymmetric(vertical: 2),
          ),
        ]);
  }
}
