import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:lottery_advance/app/models/user.dart';
import 'package:lottery_advance/app/modules/home/views/svg_wrapper.dart';
import 'package:lottery_advance/app/services/wallet_service.dart';
import 'package:lottery_advance/utils/constants.dart';
// import 'package:lottery_advance/utils/secret.dart';
import 'package:multiavatar/multiavatar.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends GetxController
    with GetSingleTickerProviderStateMixin {
/*
      For Emulator
        final String _rpcUrl = "http://10.0.2.2:7545";
        final String _wsUrl = "ws://10.0.2.2:7545/";

      For Browser
        final String _rpcUrl = "http://127.0.0.1:7545";
        final String _wsUrl = "ws://127.0.0.1:7545/";

      For mobile both pc and mobile running on same internet
        final String _rpcUrl = "http://192.168.40.193:7545";
        final String _wsUrl = "ws://192.168.40.193:7545/";
      
      For Infura Ropsten
        final String _rpcUrl = "https://ropsten.infura.io/v3/$INFURA_API_KEY";
        final String _wsUrl = "wss://ropsten.infura.io/ws/v3/$INFURA_API_KEY";

      For Alchemy goerli
        final String _rpcUrl = "https://eth-goerli.g.alchemy.com/v2/$Alchemy_Goerli_KEY";
        final String _wsUrl = "wss://eth-goerli.g.alchemy.com/v2/$Alchemy_Goerli_KEY";s
*/
  final String _rpcUrl = "http://192.168.40.193:7545";
  final String _wsUrl = "ws://192.168.40.193:7545/";

  late Web3Client _web3client;

  late String _abiCode;
  late String _abiCode2;

  late EthereumAddress _contractAddressLottery;
  late EthereumAddress _contractAddressLotteryGenerator;

  late Credentials _credentials;
  late DeployedContract _deployedContractLottery;
  late DeployedContract _deployedContractLotteryGenerator;
  late ContractFunction getLotteries, createLottery, deleteLottery;
  late ContractFunction lotteryName,
      manager,
      participate,
      activateLottery,
      declareWinner,
      getPlayers,
      getPlayer,
      getWinningPrice,
      getCurrentWinner,
      isLotteryLive,
      maxEntriesForPlayer,
      ethToParticipate,
      getLotterySoldCount;

  late ContractEvent LotteryCreated, WinnerDeclared, PlayerParticipated;

  final managerAddress = ''.obs;
  final lotryname = ''.obs;
  final lottries = [].obs;
  final userAddress = ''.obs;
  final privateKey = ''.obs;
  final contractBalance = ''.obs;
  final userBalance = ''.obs;
  final lastWinner = ''.obs;
  final name = ''.obs;
  final message = ''.obs;
  final lotteryETH = 0.0.obs;
  final check = true.obs;
  final isLoading = false.obs;
  final isLoadingParticipate = false.obs;
  final isLoadingActivateLottery = false.obs;
  final isLoadingDeclareWinner = false.obs;
  final isLoadingLotteryDetail = false.obs;
  final lotteryLive = false.obs;
  final lotteryLimit = 0.obs;
  final lotterySold = 0.obs;
  final lotteryBuyCount = 0.obs;
  final players = [].obs;
  final users = <User>[].obs;
  late WalletService walletService;
  String? svgCode;
  DrawableRoot? svgRoot;
  final keyController = TextEditingController();
  final nameController = TextEditingController();
  late AnimationController animationController;

  setup() async {
    _web3client = Web3Client(
      _rpcUrl,
      Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(_wsUrl).cast<String>();
      },
    );
    // await getAbi();
    // await getCredentials();
    // await getDeployedContractLotteryGenerator();
    await loadUsers();
    await generateSvg();
    // await getPlayers();
    // await getLotteryBalance();
    // await getLastWinner();

    nameController.addListener(() {
      name.value = nameController.text;
    });
    keyController.addListener(() {
      privateKey.value = keyController.text;
    });
  }

  Future<void> getAbi() async {
    // isLoading.value =true;
    // Reading the contract abi
    String abiStringFile =
        await rootBundle.loadString("src/artifacts/Lottery.json");
    String abiStringFile2 =
        await rootBundle.loadString("src/artifacts/LotteryGenerator.json");
    var jsonAbi = jsonDecode(abiStringFile);
    var jsonAbi2 = jsonDecode(abiStringFile2);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _abiCode2 = jsonEncode(jsonAbi2["abi"]);

    if (kDebugMode) {
      print("ABI Lottery: ${_abiCode}");
      print("ABI LotterGenerator: ${_abiCode2}");
    }

    // _contractAddressLottery =
    //     EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    _contractAddressLotteryGenerator =
        EthereumAddress.fromHex(jsonAbi2["networks"]["5777"]["address"]);
    if (kDebugMode) {
      // print("Contract Address Lottery : ${_contractAddressLottery}");
      print(
          "Contract Address LotteryGenerator : ${_contractAddressLotteryGenerator}");
    }
    // isLoading.value =false;
  }

  Future<void> getCredentials() async {
    // isLoading.value =true;
    _credentials = EthPrivateKey.fromHex(privateKey.value);
    if (kDebugMode) {
      print("Credentials: ${await _credentials.extractAddress()}");
    }
    // isLoading.value =false;
  }

  Future<void> getDeployedContractLotteryGenerator() async {
    // isLoading.value =true;
    // Telling Web3dart where our contract is declared.
    _deployedContractLotteryGenerator = DeployedContract(
        ContractAbi.fromJson(_abiCode2, "LotteryGenerator"),
        _contractAddressLotteryGenerator);
    // Extracting the functions, declared in contract.
    //---------LotteryGenerator--------
    getLotteries = _deployedContractLotteryGenerator.function('getLotteries');
    createLottery = _deployedContractLotteryGenerator.function('createLottery');
    deleteLottery = _deployedContractLotteryGenerator.function('deleteLottery');
    LotteryCreated = _deployedContractLotteryGenerator.event('LotteryCreated');
    await getLotteriesList();
    // isLoading.value =true;
  }

  Future<void> getDeployedContractLottery(String lotteryAddress) async {
    // isLoadingLotteryDetail.value = true;
    _contractAddressLottery = EthereumAddress.fromHex(lotteryAddress);
    // Telling Web3dart where our contract is declared.
    _deployedContractLottery = DeployedContract(
        ContractAbi.fromJson(_abiCode, "Lottery"), _contractAddressLottery);

    // Extracting the functions, declared in contract.
    // --------Lottery---------
    lotteryName = _deployedContractLottery.function('lotteryName');
    getLotterySoldCount =
        _deployedContractLottery.function('getLotterySoldCount');
    manager = _deployedContractLottery.function('manager');
    participate = _deployedContractLottery.function('participate');
    activateLottery = _deployedContractLottery.function('activateLottery');
    declareWinner = _deployedContractLottery.function('declareWinner');
    getPlayers = _deployedContractLottery.function('getPlayers');
    getPlayer = _deployedContractLottery.function('getPlayer');
    getCurrentWinner = _deployedContractLottery.function('getCurrentWinner');
    isLotteryLive = _deployedContractLottery.function('isLotteryLive');
    maxEntriesForPlayer =
        _deployedContractLottery.function('maxEntriesForPlayer');
    ethToParticipate = _deployedContractLottery.function('ethToParticipate');
    WinnerDeclared = _deployedContractLottery.event('WinnerDeclared');
    PlayerParticipated = _deployedContractLottery.event('PlayerParticipated');

    await getManager();
    await getLotteryName();
    await getLotteryBalance();
    await getPlayersList();
    await lotteryLiveFunc();
    await lotteryLimitFunc();
    await lotteryETHFunc();
    await lotteryBuyCountFunc();
    await lotterySoldFunc();
    // isLoadingLotteryDetail.value = false;
  }

  Future<void> lotteryLiveFunc() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: isLotteryLive,
      params: [],
    );
    lotteryLive.value = res.first;
    // isLoading.value = false;
  }

  Future<void> lotterySoldFunc() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: getLotterySoldCount,
      params: [],
    );
    lotterySold.value = (res.first).toInt();
    // isLoading.value = false;
  }

  Future<void> lotteryLimitFunc() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: maxEntriesForPlayer,
      params: [],
    );
    lotteryLimit.value = (res.first).toInt();
    // isLoading.value = false;
  }

  Future<void> lotteryETHFunc() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: ethToParticipate,
      params: [],
    );
    lotteryETH.value = (res.first).toDouble();
    // isLoading.value = false;
  }

  Future<void> lotteryBuyCountFunc() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: getPlayer,
      params: [EthereumAddress.fromHex(userAddress.value)],
    );
    lotteryBuyCount.value = res[1].toInt();
    // isLoading.value = false;
  }

  Future<void> createLotteryFunc(String name) async {
    print("Entered createLotteryFunc");
    isLoading.value = true;
    await _web3client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _deployedContractLotteryGenerator,
        function: createLottery,
        parameters: [name],
      ),
      chainId: 3,
      // fetchChainIdFromNetworkId: true,
    );
    isLoading.value = false;
    print("Exited createLotteryFunc");
  }

  Stream<FilterEvent> listenLotteryCreatedEvent() {
    FilterOptions options = FilterOptions(
      address: _contractAddressLotteryGenerator,
      fromBlock: const BlockNum.genesis(),
      toBlock: const BlockNum.current(),
      topics: [
        [
          bytesToHex(LotteryCreated.signature,
              padToEvenLength: true, include0x: true)
        ],
      ],
    );
    final event = _web3client.events(options);
    return event;
  }

  Stream<FilterEvent> listenPalyerParticipate() {
    FilterOptions options = FilterOptions(
      address: _contractAddressLottery,
      fromBlock: const BlockNum.genesis(),
      toBlock: const BlockNum.current(),
      topics: [
        [
          bytesToHex(PlayerParticipated.signature,
              padToEvenLength: true, include0x: true)
        ],
      ],
    );
    final event = _web3client.events(options);
    return event;
  }

  Stream<FilterEvent> listenWinnerDeclared() {
    FilterOptions options = FilterOptions(
      address: _contractAddressLottery,
      fromBlock: const BlockNum.genesis(),
      toBlock: const BlockNum.current(),
      topics: [
        [
          bytesToHex(WinnerDeclared.signature,
              padToEvenLength: true, include0x: true)
        ],
      ],
    );
    final event = _web3client.events(options);
    return event;
  }

  Future<void> deleteLotteryFunc(String address) async {
    isLoading.value = true;
    await _web3client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _deployedContractLotteryGenerator,
        function: deleteLottery,
        parameters: [
          EthereumAddress.fromHex(address),
        ],
      ),
      chainId: 3,
      // fetchChainIdFromNetworkId: true,
    );
    // lottries.value =
    //     (res.first as List<dynamic>).map((e) => e.toString()).toList();
    await getLotteriesList();
    isLoading.value = false;
  }

  Future<void> activateLotteryFunc(int maxEntry, int ethRequired) async {
    isLoadingActivateLottery.value = true;
    await _web3client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _deployedContractLottery,
        function: activateLottery,
        parameters: [
          BigInt.from(maxEntry),
          BigInt.from(ethRequired),
        ],
      ),
      chainId: 3,
      // fetchChainIdFromNetworkId: true,
    );
    await reloadContractOnActivate();
    isLoadingActivateLottery.value = false;
  }

  Future<void> getLotteriesList() async {
    isLoading.value = true;
    try {
      final res = await _web3client.call(
        contract: _deployedContractLotteryGenerator,
        function: getLotteries,
        params: [],
      );
      if (res.first != null) {
        lottries.value =
            (res.first as List<dynamic>).map((e) => e.toString()).toList();
        if (kDebugMode) {
          print("Lotteries : $lottries");
        }
      }
    } catch (error, trace) {
      if (kDebugMode) {
        print("Error on getLotteriesList: $error");
        print("Trace on getLotteriesList: $trace");
      }
    }

    // update();
    isLoading.value = false;
  }

  Future<void> getManager() async {
    // isLoading.value = true;
    final res = await _web3client.call(
      contract: _deployedContractLottery,
      function: manager,
      params: [],
    );
    managerAddress.value = (EthereumAddress.fromHex("${res.first}")).toString();
    // isLoading.value = false;
  }

  Future<void> getLotteryName() async {
    // isLoading.value = true;
    final res = await _web3client.call(
        contract: _deployedContractLottery, function: lotteryName, params: []);
    lotryname.value = '${res.first}';
    // isLoading.value = false;
  }

  Future<void> getLastWinner() async {
    // isLoading.value = true;
    final res = await _web3client.call(
        contract: _deployedContractLottery,
        function: getCurrentWinner,
        params: []);
    lastWinner.value = '${res[2]}';
    // isLoading.value = false;
  }

  Future<void> getLotteryBalance() async {
    // isLoading.value = true;
    final balance =
        await _web3client.getBalance(_deployedContractLottery.address);
    contractBalance.value = '${balance.getValueInUnit(EtherUnit.ether)} ETH';

    // isLoading.value = false;
  }

  Future<void> getPlayersList() async {
    // isLoading.value = true;
    final currentPlayers = await _web3client.call(
        contract: _deployedContractLottery, function: getPlayers, params: []);
    if (currentPlayers.isNotEmpty) {
      players.value = (currentPlayers[0] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    // isLoading.value = false;
  }

  // Future<void> getPlayerFunc(String address) async {
  //   isLoading.value = true;
  //   final res = await _web3client.call(
  //     contract: _deployedContractLottery,
  //     function: getPlayer,
  //     params: [address],
  //   );

  //   isLoading.value = false;
  // }

  Future<void> initWallet() async {
    if (keyController.text.length == 64 || privateKey.value.length == 64) {
      // if (privateKey!.length == 64) {
      // isLoading.value = true;
      walletService = WalletService(privateKey.value);
      final address = await walletService.credentials?.extractAddress();
      userAddress.value = '$address';
      final balance = await _web3client.getBalance(address!);
      userBalance.value = '${balance.getValueInUnit(EtherUnit.ether)} ETH';
      // isLoading.value = false;
    } else {
      Get.rawSnackbar(message: 'Enter a valid Key');
    }
  }

  Future<void> saveAccount() async {
    isLoading.value = true;
    final user = User(
      address: userAddress.value,
      avatar: svgCode!,
      privateKey: privateKey.value,
      name: nameController.text,
    );
    final existingUser = users.firstWhere((u) => u.address == userAddress,
        orElse: () => User(address: '', avatar: '', privateKey: '', name: ''));
    if (existingUser.address == '') {
      users.add(user);
      Get.rawSnackbar(message: 'Account Added');
    } else {
      int i = users.indexOf(existingUser);
      users[i] = User(
        address: existingUser.address,
        avatar: svgCode!,
        privateKey: existingUser.privateKey,
        name: nameController.text,
      );
      Get.rawSnackbar(message: 'Account Updated');
    }

    await box.write('users', users.map((u) => u.toJson()).toList());
    isLoading.value = false;
  }

  void removeAccount(User u) {
    users.remove(u);
    box.write('users', users.map((u) => u.toJson()).toList());
  }

  Future<void> participateInLottery() async {
    final amountInWei = pow(10, 18) * lotteryETH.value;
    // final amountInWei = lotteryETH.value;

    isLoadingParticipate.value = true;
    try {
      message.value = 'Processing transaction, please wait...';
      await _web3client.sendTransaction(
        walletService.credentials!,
        Transaction.callContract(
          contract: _deployedContractLottery,
          from: EthereumAddress.fromHex(userAddress.value),
          function: participate,
          parameters: [name.value],
          value: EtherAmount.inWei(BigInt.from(amountInWei)),
        ),
        chainId: 3,
        // fetchChainIdFromNetworkId: true,
      );
      message.value = "You've been entered, updating values may take sometime";
      await Future.delayed(const Duration(seconds: 5));
      await reloadContractOnParticipate();
    } catch (e) {
      message.value = 'An error occurred: $e';
      Get.rawSnackbar(message: 'Error: $e');
    }
    isLoadingParticipate.value = false;
    await Future.delayed(const Duration(seconds: 5), () {
      message.value = '';
    });
  }

  Future<void> pickWinner() async {
    isLoadingDeclareWinner.value = true;
    message.value = 'Picking winner, please wait!';
    try {
      await _web3client.sendTransaction(
        walletService.credentials!,
        Transaction.callContract(
          contract: _deployedContractLottery,
          from: EthereumAddress.fromHex(userAddress.value),
          function: declareWinner,
          parameters: [],
        ),
        chainId: 3,
        // fetchChainIdFromNetworkId: true,
      );
      await reloadContractOnDecalreWinner();
      message.value = 'Winner: ${lastWinner} ';
    } catch (e) {
      message.value = 'An error occurred: $e';
      Get.rawSnackbar(message: 'Error: $e');
    }
    isLoadingDeclareWinner.value = false;
    await Future.delayed(const Duration(seconds: 10), () => message.value = '');
  }

  void selectAccount(User u) {
    privateKey.value = u.privateKey;
    nameController.text = u.name;
    name.value = u.name;
    keyController.text = u.privateKey;
    svgCode = u.avatar;
    update();
    generateSvg();
    initWallet();
  }

  Future<void> reloadContract() async {
    await initWallet();
    await getLotteriesList();
  }

  Future<void> reloadContractOnActivate() async {
    await initWallet();
    await lotteryLimitFunc();
    await lotteryETHFunc();

    lotteryLive.value = true;
  }

  Future<void> reloadContractOnParticipate() async {
    await getLotteryBalance();
    await getPlayersList();
    await lotteryBuyCountFunc();
    await initWallet();
    await lotterySoldFunc();
  }

  Future<void> reloadContractOnDecalreWinner() async {
    await initWallet();
    await getLastWinner();
    contractBalance.value = '0.0 ETH';
    lotteryETH.value = 0.0;
    lotteryLive.value = false;
    lotteryLimit.value = 0;
    lotteryBuyCount.value = 0;
    lotterySold.value = 0;
    players.value = [];
  }

  Future<void> loadUsers() async {
    final localUsers = box.read('users');
    if (localUsers != null && localUsers.isNotEmpty) {
      users.assignAll(
        List<User>.from(
          localUsers.map(
            (u) => User(
              address: u['address'],
              name: u['name'],
              avatar: u['avatar'],
              privateKey: u['privateKey'],
            ),
          ),
        ),
      );
      selectAccount(users.first);
    }
  }

  Future<void> generateSvg({bool force = false}) async {
    isLoading.value = true;
    if (svgCode == null || force) {
      svgCode = multiavatar(DateTime.now().millisecondsSinceEpoch.toString());
    }
    svgRoot = await SvgWrapper(svgCode!).generateLogo();
    update();
    isLoading.value = false;
  }

  @override
  Future<void> onInit() async {
    await setup();
    super.onInit();
  }

  @override
  void onReady() {
    animationController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this);
    animationController.repeat();
    super.onReady();
  }
}
