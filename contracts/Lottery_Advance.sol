// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LotteryGenerator {
    address[] public lotteries;
    struct lottery{
        uint index;
        address manager;
    }
    mapping(address => lottery) lotteryStructs;

    function createLottery(string memory name) public {
        require(bytes(name).length > 0);
        Lottery newLottery = new Lottery(name, msg.sender);
        lotteries.push(address(newLottery));
        lotteryStructs[address(newLottery)].index = lotteries.length- 1;
        lotteryStructs[address(newLottery)].manager = msg.sender;

        // event
        emit LotteryCreated(address(newLottery));
    }

    function getLotteries() public view returns(address[] memory) {
        return lotteries;
    }

    function deleteLottery(address lotteryAddress) public {
        require(msg.sender == lotteryStructs[lotteryAddress].manager);
        uint indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];
        lotteries[indexToDelete] = lastAddress;
        delete lotteries[indexToDelete];
        // lotteries.length--;
    }

    // Events
    event LotteryCreated(
        address lotteryAddress
    );
}

contract Lottery {
    // name of the lottery
    string public lotteryName;
    // Creator of the lottery contract
    address public manager;

    // variables for players
    struct Player {
        string name;
        uint entryCount;
        uint index;
        address adrs;
    }
    address[] public addressIndexes;
    mapping(address => Player) players;
    address payable[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isLotteryLive;
    uint public maxEntriesForPlayer;
    uint public ethToParticipate;

    // constructor
    constructor(string memory name, address creator){
        manager = creator;
        lotteryName = name;
    }

    // Let users participate by sending eth directly to contract address
    receive() external payable {
        // player name will be unknown
        participate("Unknown");
    }

    function participate(string memory playerName) public payable {
        require(bytes(playerName).length > 0);
        require(isLotteryLive);
        require(msg.value == ethToParticipate * 1 ether);
        require(players[msg.sender].entryCount < maxEntriesForPlayer);

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            players[msg.sender].adrs = msg.sender;
            addressIndexes.push(msg.sender);
            players[msg.sender].index = addressIndexes.length- 1;
        } else {
            players[msg.sender].entryCount += 1;
        }

        lotteryBag.push(payable(msg.sender));
    
        // event
        emit PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
    }

    function activateLottery(uint maxEntries, uint ethRequired) public restricted {
        isLotteryLive = true;
        maxEntriesForPlayer = maxEntries == 0 ? 1: maxEntries;
        ethToParticipate = ethRequired == 0 ? 1: ethRequired;
    }

    function declareWinner() public restricted{
        require(lotteryBag.length > 0);

        uint index = generateRandomNumber() % lotteryBag.length;
        
        lotteryBag[index].transfer(address(this).balance);
         
        winner.name = players[lotteryBag[index]].name;
        winner.entryCount = players[lotteryBag[index]].entryCount;
        winner.adrs = lotteryBag[index];
        // empty the lottery bag and indexAddresses
        lotteryBag = new address payable[](0);
        addressIndexes = new address[](0);

        // Mark the lottery inactive
        isLotteryLive = false;
    
        // event
        emit WinnerDeclared(winner.name, winner.entryCount);
    }

    function getPlayers() public view returns(address[] memory) {
        return addressIndexes;
    }

    function getLotterySoldCount() public view returns(uint) {
        return lotteryBag.length;
    }

    function getPlayer(address playerAddress) public view returns (string memory, uint) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint) {
        return address(this).balance;
    }

    function getCurrentWinner() public view returns (string memory, uint,address) {
        return (winner.name,winner.entryCount,winner.adrs);
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns(uint) {
        // return uint(keccak256(block.difficulty, now, block.timestamp.length));
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,lotteryBag.length)));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Events
    event WinnerDeclared( string name, uint entryCount );
    event PlayerParticipated( string name, uint entryCount );
}