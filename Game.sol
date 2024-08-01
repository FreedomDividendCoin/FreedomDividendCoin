pragma solidity 0.8.24;

contract Game {
    uint private start = 0;

    address private WFDCContract = 0x63D6e1E46d3b72D2BB30D3A8D2C811cCb180Ab60;

    WrappedFreedomDividendCoin private WFDCToken;

    uint private max = 10000000;

    address private owner;

    event Result(
        address Address,
        bool win,
        uint amount
    );

    constructor() {
        WFDCToken = WrappedFreedomDividendCoin(WFDCContract);
        owner = msg.sender;
    }

    function game(uint amount) external returns(uint) {
        require(amount <= max, "Token amount higher than max");
        require(amount <= WFDCToken.balanceOf(msg.sender), "Player not enough tokens");
        require(amount <= WFDCToken.balanceOf(address(this)), "Game not enough tokens");
        require(amount <= WFDCToken.allowance(msg.sender,address(this)), "Game not high enough allowance");
        uint rand = getRandom(100);
        if (rand > 50) {
            //win
            WFDCToken.transfer(msg.sender, amount);
            emit Result(msg.sender, true, amount);
        } else {
            //lose
            WFDCToken.transferFrom(msg.sender,address(this), amount);
            emit Result(msg.sender, false, amount);
        }
        return rand;
    }

    function getRandom(uint modulus) internal returns(uint) {
        start++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,start))) % modulus;
    }

    function getVersion() external view returns(string memory) {
        return "v1";
    }

    function withdraw(uint amount) external {
        require(msg.sender == owner, 'only owner');
        WFDCToken.transfer(msg.sender, amount);
    }

}

interface WrappedFreedomDividendCoin {
    function balanceOf(address owner) external returns(uint);
    function transfer(address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external returns (uint);
}
