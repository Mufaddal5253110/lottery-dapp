import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';

class LotteriesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final contractLink = Get.find<ContractLinking>();
  setup() async {
    // contractLink.isLoading.value = true;
    await contractLink.getAbi();
    await contractLink.getCredentials();
    await contractLink.getDeployedContractLotteryGenerator();
    // contractLink.isLoading.value = false;
  }

  @override
  Future<void> onInit() async {
    await setup();
    super.onInit();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    contractLink.listenLotteryCreatedEvent().listen((event) async {
      print("Calling listenLotteryCreatedEvent");
      print(event);
      await contractLink.getLotteriesList();
    });
  }
}
