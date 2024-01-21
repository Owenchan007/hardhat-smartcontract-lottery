// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol"; // 1. 通过消耗获取账号
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// 1. Enter the lottery (paying some amount)
// 2. Pick a random winner (verifiably random)
// 3. Winner to be selected every X minutes -> completly automate
error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();

contract Raffle is VRFConsumerBaseV2 {
    /* State Variables */
    uint256 private immutable i_entranceFee; // 设置入场费，它是一个storage，耗费gas多，设置成private保证在写其他合约时无法更改该变量
    address payable[] private s_players; // payable是可接受支付的关键字，函数或是变量写了该关键字就意味着可以接受ETH代币
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    address private s_rencentWinner;

    /* Events */
    // 事件(Events)是区块链Log(日志)的一部分，我们触发(Emit)的事件都会被Log记载，相比Storage更加节省Gas
    // indexed是Events的优先级，最多可声明3个，以非编码的形式存储在Log中，其余的非indexed将被编码后存入Log，需要解码才能查看
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // 在VRFConsumerBaseV2中也有构造函数，合约继承了另一个合约，也要实现其内部的构造函数，因此需要传入一个协调员（发送LINK代币的地址）
    //！！！！！在VRFCoordinatorV2Interface中定义请求要求，例如要几个随机数，用哪一个gasLane，你的请求ID（要匹配该合约地址）
    //！！！！！在VRFConsumerBaseV2中调用fulfillRandomWords函数会返回所请求的随机数
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        // 这里是
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); // 实例化Sepolia上的接口，把地址传进去就可以使用链上合约的函数了
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        // 如果用户没有发送足够的ETH，我们返回错误，错误函数定义在合约外面
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        s_players.push(payable(msg.sender)); // 这里显示转换payable是因为我们在上面定义的s_players是一个payable数组，两者要保持一致，要不然没办法push进去，格式不同
        emit RaffleEnter(msg.sender); // 触发事件，把sender信息上传到Log中
    }

    function requestRandomWinner() external {
        // 1. 请求随机数
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gasLane(gas通道)
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
        // 2.
    }

    // 从ChainLink获取填充随机数，Override是重载实现其VRFConsumerBaseV2的内部虚拟函数
    function fulfillRandomWords(
        uint256 /* requestId */, // 链上合约会返回一个请求ID一个随机数组（看之前NUM_WORDS写了请求几个）
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; // 取余
        address payable recentWinner = s_players[indexOfWinner];
        s_rencentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // 这里的call会返回好几个值，我们只要第一个是否成功的bool

        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner); // 触发事项，把这一次获胜的人存到log中去
    }

    // -------------------view function---------------------
    // view函数是只读的，不更改区块链上的状态，如果写了改状态的代码编译时会出错
    // 获取最低准入金额
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_rencentWinner;
    }

    // function pickRandomWinner() returns () {}
}
