// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract presale is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter; 
    //Mapping to store the Phase details.
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 totalTokens;
        uint256 tokenPrice;
        uint256 tokenSold;
    }
    //Mapping to store the Investor details.
    struct Investor {
        uint256 balance;
        uint256 unlockedTokens;
        uint256 tokenClaimed;
        uint256 lockTime;
        uint256 refferal;
        bool invested;
        bool refferalUsed;
    }
    
    uint256 public tgeTimestamp; //Token Generation Event Time Stamp.
    
    IERC20 public token;
    
    address public tokenOwner;
    
    mapping(uint256 => address[]) public idWiseInvestorList; // Event iD to investor list
   
    Counters.Counter public presaleEventid; //Event iD.
    
    Counters.Counter public referralCode; //Refferal Code.
    
    mapping(uint256 => Phase) public idToPhaseMapping; // Event iD no. to Event Struct.
    
    mapping(uint256 => mapping(address => Investor)) public investorMapping; //iD=>Investor address =>Investor struct
    
    mapping(uint256 => address) public referralCodeToReferralAddress; //Referal Code => address.
    mapping(address => uint256) public referralAddressToReferralCode; //Address => Code.
    
    mapping(address => uint256) public cumulativeInvestment; // to be used for finding category. Total investments over all the Presale.
    
    uint256 public decimalFactor; // this variable is to handle fractional token price. Temporary variable


    event PreSaleCreated(uint _totalToken,uint256 _tokenPrice, uint256 _startTime, uint256 _endTime, uint256 _id);
    event TokensLocked(uint256 _id, address _investor, uint256 _amount, bool _referral, uint _referralCode,address referralOwner);
    event TokenWithdrawn(uint256 _id, uint256 _claimAmount,address _investor);

    constructor(address _token, uint256 _tgeTimestamp) {
        token = IERC20(_token);
        tgeTimestamp = _tgeTimestamp;
        referralCode = Counters.Counter(1000);
        decimalFactor=100;
        tokenOwner=msg.sender;
    }

    // Creates the Presale Events.
    function createPreSale(uint256 totalToken, uint256 tokenPrice, uint256 startTime, uint256 endTime) external onlyOwner returns (bool) {
        
        require(startTime >= block.timestamp, "ERR-1");
        require(startTime < endTime, "ERR-2");
        
        presaleEventid.increment();
        idToPhaseMapping[presaleEventid.current()].startTime = startTime;
        idToPhaseMapping[presaleEventid.current()].endTime = endTime;
        idToPhaseMapping[presaleEventid.current()].totalTokens = totalToken;
        idToPhaseMapping[presaleEventid.current()].tokenPrice = tokenPrice;
        idToPhaseMapping[presaleEventid.current()].tokenSold = 0;

        emit PreSaleCreated(idToPhaseMapping[presaleEventid.current()].totalTokens, idToPhaseMapping[presaleEventid.current()].tokenPrice, idToPhaseMapping[presaleEventid.current()].startTime,idToPhaseMapping[presaleEventid.current()].endTime, presaleEventid.current());
        
        return true;
    }

    //Allows User to buy the tokens by giving USDT and locks their token till the TGE.
    function lock(uint256 eventid, uint256 usdtamount, uint256 sponsorReferralCode) external nonReentrant {
        
        // uint256 tokenAmount = _amount*decimalFactor*10**18/ iDToPhaseMapping[_iD].tokenPrice; // N/D > 1
        uint256 tokenAmount = usdtamount*decimalFactor/ idToPhaseMapping[eventid].tokenPrice;  
        
        require(tokenAmount <= (idToPhaseMapping[eventid].totalTokens-idToPhaseMapping[eventid].tokenSold), "ERR-3");
        require(block.timestamp >= idToPhaseMapping[eventid].startTime, "ERR-4");
        require(block.timestamp < idToPhaseMapping[eventid].endTime, "ERR-5");
        
        idWiseInvestorList[eventid].push(msg.sender);                   //Updates the investors for this Event.
        idToPhaseMapping[eventid].tokenSold+=tokenAmount;               //Updates the token sold in this Event.
        investorMapping[eventid][msg.sender].balance += tokenAmount;    //Updares the User balance in this Event.
        investorMapping[eventid][msg.sender].invested = true;           //Updates the Invested for User.
        investorMapping[eventid][msg.sender].lockTime = tgeTimestamp;   //Updates Lock Time.
        cumulativeInvestment[msg.sender] += tokenAmount;                 //Updates the Cumulative investment time.

        if (sponsorReferralCode != 0 && referralCodeToReferralAddress[sponsorReferralCode] != address(0)) {     //Checks if referral appiled.
            investorMapping[eventid][msg.sender].refferalUsed = true;                   
            investorMapping[eventid][msg.sender].refferal = sponsorReferralCode;
            idToPhaseMapping[eventid].tokenSold+=tokenAmount / 20;          //provides extra tokens if refferal used.
        
        }
        else {
            investorMapping[eventid][msg.sender].refferalUsed = false;
        }

        emit TokensLocked(eventid,msg.sender, tokenAmount, investorMapping[eventid][msg.sender].refferalUsed, sponsorReferralCode, referralCodeToReferralAddress[sponsorReferralCode]);

        bool vestingSuccess=token.transferFrom(tokenOwner, address(this), tokenAmount);
        require(vestingSuccess, "ERR-13");
        
         if (investorMapping[eventid][msg.sender].refferalUsed) {      // If referral used we transfer the 20% extra to referral user.
            bool referalSuccess=token.transferFrom(tokenOwner, referralCodeToReferralAddress[sponsorReferralCode], tokenAmount / 20);
            require(referalSuccess, "ERR-12");
         }


    }


    function withdraw(uint256 eventid, uint256 claimAmount) external nonReentrant {
    
    require(investorMapping[eventid][msg.sender].invested, "ERR-6");
    require(block.timestamp > investorMapping[eventid][msg.sender].lockTime, "ERR-7");

    unlockedTokens( eventid, msg.sender);
    require(claimAmount<=(investorMapping[eventid][msg.sender].unlockedTokens - investorMapping[eventid][msg.sender].tokenClaimed),"ERR-8");

    investorMapping[eventid][msg.sender].tokenClaimed+=claimAmount;

    emit TokenWithdrawn( eventid, claimAmount, msg.sender);

    bool withdrawSuccess=token.transfer(msg.sender,claimAmount);
    require(withdrawSuccess,"ERR-14");

    }


    function unlockedTokens(uint eventid, address investor) public {
    
    if (block.timestamp > tgeTimestamp && block.timestamp <= tgeTimestamp + 180) {
    investorMapping[eventid][investor].unlockedTokens = investorMapping[eventid][investor].balance / 4;
    }
    if (block.timestamp > tgeTimestamp + 180 && block.timestamp <= tgeTimestamp + 360) {
        investorMapping[eventid][investor].unlockedTokens = investorMapping[eventid][investor].balance / 2;
    }
    if (block.timestamp > tgeTimestamp + 360 && block.timestamp <= tgeTimestamp + 540) {
        investorMapping[eventid][investor].unlockedTokens = (investorMapping[eventid][investor].balance * 3) / 4;
    }
    if (block.timestamp > tgeTimestamp + 540) {
        investorMapping[eventid][investor].unlockedTokens = investorMapping[eventid][investor].balance;
    }
    }


    function generateReferal(address sponsor) public onlyOwner { // How and when it is to be generated after locking by investor is to be finalised. 
    
    require(referralAddressToReferralCode[sponsor] == 0, "ERR-9");
    
    referralCodeToReferralAddress[referralCode.current()] = sponsor;
    referralAddressToReferralCode[sponsor] = referralCode.current();
    referralCode.increment();
    }


    function findCategory(uint256 totalPreSalePhases, address investor) external view onlyOwner returns (uint category) {
    
    uint256 totalInvestment = cumulativeInvestment[investor];
    
    require(totalInvestment >= 100, "ERR-10");
    require(block.timestamp >= idToPhaseMapping[totalPreSalePhases].endTime, "ERR-11");
    
    if (totalInvestment >= 100 && totalInvestment <= 500) {
        category = 1;
    } else if (totalInvestment > 500 && totalInvestment <= 1000) {
        category = 2;
    } else if (totalInvestment > 1000 && totalInvestment <= 5000) {
        category = 3;
    } else if (totalInvestment > 5000 && totalInvestment <= 10000) {
        category = 4;
    } else if (totalInvestment > 10000) {
        category = 5;
    }
    
    return category;
    }
    

    function getTime() external view returns (uint256) {
    return block.timestamp;
    }

}

/* 

- 7 pre sale events

- Investors can lock their investment in the vesting contract. 

- Currently for the purpose of testing, we have pegged to a manual entry of USDT that 
investor is transferring to buy tokens

- Later we will provide a functionality on the dapp to buy tokens using USDT/ ethers

- Based on the amount of unlocked tokens as per the vesting schedule at any given
point of time, users can withdraw their tokens.

- Investors can also use a referral code of other investor and that investor gets 5% tokens 
as referral reward.

- At the end of all the pre sale events, we will categorise the investors into different 
categories based on their amount of investment. The benefits for each category will be 
decided later.

*/


/*

ERROR Codes

ERR-1	InvaliD date entered
ERR-2	End time should be more than start time
ERR-3	Insufficient tokens try a lower value
ERR-4	Time of presale has not yet arrived
ERR-5	Time of presale has passed
ERR-6	You are not an investor
ERR-7	Tokens have not been unlocked
ERR-8	Claimed tokens not unlocked yet
ERR-9	Referral code already generated
ERR-10	Insufficient investment
ERR-11	Pre Sale phases are not over yet
ERR-12  Referral reward token transfer failed
ERR-13  Token vesting failed
ERR-14  Token withdraw failed

*/



