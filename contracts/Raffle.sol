// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 1. Enter the lottery (paying some amount)
// 2. Pick a random winner (verifiably random)
// 3. Winner to be selected every X minutes -> completly automate
error Raffle__NotEnoughEthEntered();

contract Raffle {
    /* State Variables */
    uint256 private immutable i_entranceFee; // 设置入场费，它是一个storage，耗费gas多，设置成private保证在写其他合约时无法更改该变量
    address payable[] private s_players; // payable是可接受支付的关键字，函数或是变量写了该关键字就意味着可以接受ETH代币

    /* Events */
    // 事件(Events)是区块链Log(日志)的一部分，我们触发(Emit)的事件都会被Log记载，相比Storage更加节省Gas
    // indexed是Events的优先级，最多可声明3个，以非编码的形式存储在Log中，其余的非indexed将被编码后存入Log，需要解码才能查看
    event RaffleEnter(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // 如果用户没有发送足够的ETH，我们返回错误，错误函数定义在合约外面
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        s_players.push(payable(msg.sender)); // 这里显示转换payable是因为我们在上面定义的s_players是一个payable数组，两者要保持一致，要不然没办法push进去，格式不同
    }

    // view函数是只读的，不更改区块链上的状态，如果写了改状态的代码编译时会出错
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    // function pickRandomWinner() returns () {}
}
