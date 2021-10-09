// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//calling the openzeppelin's ownable function instead of writing our own Onlyowner modifier
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    uint256 public fee;
    uint256 public randomness;
    address payable public recentWinner;
    bytes32 public keyhash;
    AggregatorV3Interface internal ethUSDPriceFeed;

    // Below enum defines a state of the contract ; as declared below : OPEN:0;CLOSE:1; CALCULATING_WINNER:2

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // Declaring variable of type LOTTERY_STATE
    LOTTERY_STATE public lottery_state;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // Initializing Lottery state
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // Required to be the lottery state to be open during contract execution / call
        require(lottery_state == LOTTERY_STATE.OPEN);
        //required to enter min of $ 50 - required minimium to enter the lottery
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // Since ETH/USD price has 8 decimals
        // Solidity do not understand decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; // Cost to enter in wei (smallest sub - denomination of ETH)
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        // Only admin can modify the state of the LOTTERY_STATE

        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start the lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {
        //     uint256(
        //         keccak256(
        //             abi.encodePacked(
        //                 nonce, // Can be predictable - aka , transaction #
        //                 msg.sender, // can be predictable
        //                 block.difficulty, // block.difficulty can be manipulated by the miner
        //                 block.timestamp // can be predictable
        //             )
        //         )
        //     ) % players.length;
        // }
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyhash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "you aren't there yet"
        );
        require(_randomness > 0, "randomness not found");
        uint256 indexofWinner = _randomness % players.length;
        recentWinner = players[indexofWinner];

        recentWinner.transfer(address(this).balance);
        // reset the player array
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
