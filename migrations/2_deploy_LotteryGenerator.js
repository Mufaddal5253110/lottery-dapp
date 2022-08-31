const LotteryGenerator = artifacts.require("LotteryGenerator");

module.exports = function (deployer) {
  deployer.deploy(LotteryGenerator);
};
