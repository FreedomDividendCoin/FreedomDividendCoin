pragma solidity 0.8.24;

contract UBI_RPG {
    address private WFDCContract = 0x63D6e1E46d3b72D2BB30D3A8D2C811cCb180Ab60;

    WrappedFreedomDividendCoin private WFDCToken;

    address private owner;
    
    uint private transferMinimum = 5000000000000000;//0.005
    
    uint private minimumWFDC = 100000;//1000
    
    uint private earnLimit = 4;
    
    uint private maxEarnLimit = 4;
    
    uint private minEarnLimit = 1;
    
    struct PlayerInfo {
        uint gameState;
        uint lastEarnWFDCTimestamp;
        uint earnWFDCCount;
    }

    mapping(address => PlayerInfo) private Player;

    event GameEvent(
        address Address,
        uint eventType,
        bool isSpend,
        uint amount
    );
    
    struct earnInfo {
    	uint earnType;
    	uint earnAmount;
    }
    
    earnInfo[] private AllEarnInfo;

    constructor() {
        WFDCToken = WrappedFreedomDividendCoin(WFDCContract);
        owner = msg.sender;
    }
    
    function spend(uint gameState) external payable returns(uint) {
    	require(msg.value >= transferMinimum, "Transfers needs to be higher than minimum");
    	
    	PlayerInfo memory onePlayer;
    	onePlayer.gameState = gameState;
		onePlayer.lastEarnWFDCTimestamp = Player[msg.sender].lastEarnWFDCTimestamp;
		onePlayer.earnWFDCCount = Player[msg.sender].earnWFDCCount;
    	Player[msg.sender] = onePlayer;
    	
    	emit GameEvent(msg.sender, gameState, true, msg.value);
    	
    	return gameState;
    }
    
    function spendWFDC(uint amount, uint gameState) external returns(uint) {
        require(amount >= minimumWFDC, "WFDC amount less than minimum");
        require(amount <= WFDCToken.balanceOf(msg.sender), "Player not enough tokens");
    	
        WFDCToken.transferFrom(msg.sender,address(this), amount);
        
    	PlayerInfo memory onePlayer;
    	onePlayer.gameState = gameState;
    	onePlayer.lastEarnWFDCTimestamp = Player[msg.sender].lastEarnWFDCTimestamp;
		onePlayer.earnWFDCCount = Player[msg.sender].earnWFDCCount;
    	Player[msg.sender] = onePlayer;
        
        emit GameEvent(msg.sender, gameState, true, amount);
            
        return gameState;
    }
    
    function earnWFDC(uint eType) external returns(uint) {
        for (uint count = 0; count < AllEarnInfo.length; count++) {
            if (eType == AllEarnInfo[count].earnType) {
            	PlayerInfo memory onePlayer;
            	if ((block.timestamp - Player[msg.sender].lastEarnWFDCTimestamp) >= 1 days) {
            	    onePlayer.gameState = Player[msg.sender].gameState;
					onePlayer.lastEarnWFDCTimestamp = block.timestamp;
					onePlayer.earnWFDCCount = 1;
            	} else {
                    onePlayer.gameState = Player[msg.sender].gameState;
                    onePlayer.lastEarnWFDCTimestamp = block.timestamp;
                    onePlayer.earnWFDCCount = Player[msg.sender].earnWFDCCount + 1;
				}
	    	
                if (onePlayer.earnWFDCCount <= earnLimit) {
                    Player[msg.sender] = onePlayer;
                    WFDCToken.transfer(msg.sender, AllEarnInfo[count].earnAmount);
                    emit GameEvent(msg.sender, eType, false, AllEarnInfo[count].earnAmount);
                }
            }
        }
    	
    	return eType;
    }

    function getVersion() external pure returns(string memory) {
        return "v1.1";
    }

    function withdrawWFDC(uint amount) external returns (bool) {
        require(msg.sender == owner, "Only owner");
        WFDCToken.transfer(msg.sender, amount);
        return true;
    }
    
    function withdrawBNB(uint value) external returns (bool) {
    	require(msg.sender == owner, "Only owner");
    	(bool success,) = owner.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    	return true;
    }
    
    function setTransferMinimum(uint amount) external returns(bool) {
        require(msg.sender == owner, "Only owner");
        transferMinimum = amount;
        return true;
    }
    
    function getTransferMinimum() external view returns(uint) {
        return transferMinimum;
    }
    
    function setMinimumWFDC(uint amount) external returns(bool) {
        require(msg.sender == owner, "Only owner");
        minimumWFDC = amount;
        return true;
    }
    
    function getMinimumWFDC() external view returns(uint) {
        return minimumWFDC;
    }
    
    function setEarnInfo(uint eType, uint eAmount) external returns(bool) {
    	require(msg.sender == owner, "Only owner");
    	earnInfo memory eInfo;
    	eInfo.earnType = eType;
    	eInfo.earnAmount = eAmount;
    	AllEarnInfo.push(eInfo);
    	return true;
    }
    
    function deleteEarnInfo(uint id) external returns(bool) {
    	require(msg.sender == owner, "Only owner");
        AllEarnInfo[id] = AllEarnInfo[AllEarnInfo.length - 1];
        AllEarnInfo.pop();
        return true;
    }
    
    function getAllEarnInfoType(uint id) external view returns(uint) {
    	return AllEarnInfo[id].earnType;
    }
    
    function getAllEarnInfoAmount(uint id) external view returns(uint) {
    	return AllEarnInfo[id].earnAmount;
    }
    
    function getAllEarnInfoLength() external view returns(uint) {
    	return AllEarnInfo.length;
    }
    
    function getAmountByEarnType(uint eType) external view returns(uint) {
    	uint returnAmount = 0;
    	for (uint count = 0; count < AllEarnInfo.length; count++) {
            if (eType == AllEarnInfo[count].earnType) {
            	returnAmount = AllEarnInfo[count].earnAmount;
            }
    	}
    	return returnAmount;
    }
    
    function getPlayerGameState(address Address) external view returns(uint) {
        return Player[Address].gameState;
    }
    
    function getPlayerLastEarnWFDCTimestamp(address Address) external view returns(uint) {
        return Player[Address].lastEarnWFDCTimestamp;
    }
    
    function getPlayerEarnWFDCCount(address Address) external view returns(uint) {
        return Player[Address].earnWFDCCount;
    }
    
    function getEarnLimit() external view returns(uint) {
    	return earnLimit;
    }
    
    function setEarnLimit(uint amount) external returns(bool) {
    	require(msg.sender == owner, "Only owner");
    	if (amount <= maxEarnLimit && amount >= minEarnLimit) {
    	    earnLimit = amount;
    	}
    	return true;
    }
    
    function getBlockTimestamp() external view returns(uint) {
    	return block.timestamp;
    }

}

interface WrappedFreedomDividendCoin {
    function balanceOf(address owner) external returns(uint);
    function transfer(address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external returns (uint);
}
