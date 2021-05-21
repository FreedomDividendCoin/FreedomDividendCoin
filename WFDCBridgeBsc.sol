pragma solidity 0.8.0;

contract WFDCBridgeBsc {
    
    address private owner;
    
    struct admin {
        bool isAdmin;
        uint limit;
        uint approvedLimit;
    }
    
    mapping (address => admin) private admins;
    
    mapping (address => uint) private balances;
    
    address private WFDCContract = 0x63D6e1E46d3b72D2BB30D3A8D2C811cCb180Ab60;
    
    WrappedFreedomDividendCoin private WFDCToken;
    
    uint private transferFeeMinimum = 113000000000000000;
    
    uint private feeModifier = 0;//100 = 1%
    
    string private version = "v1";
    
    event TransferBridge(
        address from,
        address to,
        uint amount
    );
    
    event Balance(
        address Address,
        uint amount,
        bool isBalanceAdd
    );
    
    constructor() {
        owner = msg.sender;
        WFDCToken = WrappedFreedomDividendCoin(WFDCContract);
    }
    
    function bridgeBurn(uint amount, address adminAddress) external payable {
        require(admins[adminAddress].isAdmin == true, 'only admin');
        require(msg.value >= transferFeeMinimum, "Transfer Fee needs to be higher than minimum");
        
        WFDCToken.burn(msg.sender,amount);
        
        TransferHelper.safeTransferETH(
          adminAddress, msg.value
        );
        
        if (feeModifier > 0) {
            uint fee = amount / feeModifier;
            require(fee > 0, "Fee needs to be higher than the minimum");
            TransferHelper.safeTransfer(
              WFDCContract, adminAddress, fee
            );
            amount -= fee;
        }
        
        require((admins[adminAddress].limit >= amount), 'not enough admin limit');
        admins[adminAddress].limit -= amount;
        admins[adminAddress].approvedLimit += amount;
        
        balanceAdd(msg.sender, amount);
        
        emit TransferBridge(
          msg.sender,
          adminAddress,
          amount
        );
    }
    
    function mint(uint amount, address to) external {
        require(admins[msg.sender].isAdmin == true, 'only admin');
        
        WFDCToken.mint(to,amount);
        
        emit TransferBridge(
          msg.sender,
          to,
          amount
        );
    }
    
    function balanceOf(address Address) external view returns (uint) {
        return balances[Address];
    }
    
    function balanceAdd(address Address, uint value) internal {
        require(Address != address(0));
        balances[Address] = balances[Address] + value;
        emit Balance(
          Address,
          value,
          true
        );
    }
    
    function balanceSubtract(address Address, uint value) internal {
        require(Address != address(0));
        require(balances[Address] - value >= 0, 'Not enough balance to subtract');
        balances[Address] = balances[Address] - value;
        emit Balance(
          Address,
          value,
          false
        );
    }
    
    function adminSubtractBalance(address Address, uint value) external {
        require(admins[msg.sender].isAdmin == true, 'only admin');
        admins[msg.sender].approvedLimit -= value;
        balanceSubtract(Address, value);
        emit TransferBridge(
          msg.sender,
          Address,
          value
        );
    }
    
    function updateAdmin(address adminAddress, bool state, uint limit) external {
        require(msg.sender == owner, 'only owner');
        admins[adminAddress].isAdmin = state;
        admins[adminAddress].limit = limit;
    }
    
    function getAdmin(address Address) external view returns(bool,uint,uint) {
        return (admins[Address].isAdmin,admins[Address].limit,admins[Address].approvedLimit);
    }
    
    function getOwner() external view returns(address) {
        return owner;
    }
    
    function setTransferFeeMinimum(uint amount) external {
        require(msg.sender == owner, 'only owner');
        transferFeeMinimum = amount;
    }
    
    function getTransferFeeMinimum() external view returns(uint) {
        return transferFeeMinimum;
    }
    
    function setFeeModifier(uint amount) external {
        require(msg.sender == owner, 'only owner');
        feeModifier = amount;
    }
    
    function getFeeModifier() external view returns(uint) {
        return feeModifier;
    }
    
    function getVersion() external view returns(string memory) {
        return version;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface WrappedFreedomDividendCoin {
    function updateAdmin(address admin, bool isAdmin) external;
    function mint(address to, uint amount) external;
    function burn(address ownerAddress, uint amount) external;
    function getAdmin(address admin) external view returns(bool);
    function getOwner() external view returns(address);
}
