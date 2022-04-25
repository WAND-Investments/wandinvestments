// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./w-IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract testSticks is ReentrancyGuard, Ownable{

    uint constant DECIMALS = 10**18; 
    uint256 constant secondsInADay = 60*60*24;

    //addresses of Treasuries TODO: to hardcode
    address public scepterTreasuryAddr = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public batonTreasuryAddr = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public riskTreasuryAddr ;
    address public devWalletAddr = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

    mapping(address => bool) public whiteListAddresses;
    mapping(uint256 => uint256) public taxForLocks;

    //view treasuries balances
    uint256 public sptrTreasuryBal;
    uint256 public btonTreasuryBal;

    //Time Factors
    uint256 public timeLaunched = 0;
    uint256 public daysInCalculation;

    uint256 maxWithdrawTax = 90;
    uint256 daysTax;
    //fortest
    //uint256 private ft5daybought = 100000;
    //uint256 private ft5daysold = 90000;
    //uint256 private double5daytokens = 600000;

    address public testwallet = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

    //Scepter public scepterToken;
    //address public usdcToken= 0x291153a24E642A16e876aB68B4516f1a8EdadDD3;
    
    //IERC20 public tSC; //SPTR, //WAND //BTON
    IERC20 public SPTR;
    IERC20 public WAND;
    IERC20 public BTON;

    IERC20 public tokenStable;

    //tokens bought/sold daily tracker mappings
    mapping(uint256 => uint256) public tokensBoughtXDays;
    mapping(uint256 => uint256) public tokensSoldXDays;
    mapping(uint256 => uint256) public circulatingSupplyXDays;
    
    struct stableTokensParams {  
        address contractAddress;  
        uint256 tokenDecimals;  
        }

    mapping (string => stableTokensParams) public stableERC20Info;

    struct lockedamounts {  
        uint256 timeUnlocked;  
        uint256 amounts;  
        }
    mapping(address => lockedamounts) public withheldWithdrawals;   
    //Scepter private sptr;
    //Baton private btn;
    //Wand private wand;

    /**
    Events
    **/
    event sceptersBought(address indexed _from, uint256 _amount);
    event sceptersSold(address indexed _from, uint256 _amount);

    constructor() {   
        //INIT Contracts, Treasuries and ERC20 Tokens
        SPTR = IERC20(0x99CF4c4CAE3bA61754Abd22A8de7e8c7ba3C196d);
        WAND = IERC20(0xd7B63981A38ACEB507354DF5b51945bacbe28414);
        BTON = IERC20(0x0A0AebE2ABF81bd34d5dA7E242C0994B51fF5c1f);
        //tSC = IERC20(scepterAddr);
        //init USDC
        stableERC20Info["USDC"].contractAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
        stableERC20Info["USDC"].tokenDecimals = 6;
        //init DAI
        stableERC20Info["DAI"].contractAddress = 0x2A4a8Ab6A0Bc0d377098F8688F77003833BC1C9d;
        stableERC20Info["DAI"].tokenDecimals = 18;
        //init FRAX
        stableERC20Info["FRAX"].contractAddress = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;
        stableERC20Info["FRAX"].tokenDecimals = 18;
            
        //fix percentage
        
        for (daysTax = 0; daysTax < 10; daysTax++)
        {
            taxForLocks[daysTax] = maxWithdrawTax - (daysTax*10) ;
        }
        
        //TODO take in WandAirdrop contract
        //airdrop = WandAirdrop(airdropAddr);

        }
        
    // START of MATHS FUNCTIONS
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "uint overflow from multiplication");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "uint underflow from subtraction");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "uint overflow from multiplication");
        return c;
    }
    
    function decMul18(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = mul(x, y);
        decProd = add(prod_xy, DECIMALS / 2) / DECIMALS;
    }

    function decDiv18(uint x, uint y) internal pure returns (uint decQuotient) {
        uint prod_xTEN18 = mul(x, DECIMALS);
        decQuotient = add(prod_xTEN18, y / 2) / y;
    }

    //END OF MATHS FUNCTIONS

    //Front End User Functions
    function cashOutScepter(uint256 amountSPTRtoSell, uint256 daysChosenLocked, string memory _stableChosen) public {
        //require(msg.sender == trader , "Not authorized");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSell, "You dont have that amount!");

       /* require(
            mockUSDC.allowance(owner2, address(this)) >= amount2,"Token 2 allowance too low");
            */
        //uint256 sptrAmt = amountSCPtoSell * DECIMALS;
        //burn wand and sptr
        WAND.burn(address(this),amountSPTRtoSell);
        SPTR.burn(msg.sender,amountSPTRtoSell);
        
        //Keeping track of tokens sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSPTRtoSell;
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSell;

        //Calculatin USD amount to user and to dev.
        uint256 usdAmt; 
        usdAmt = decMul18(this.getSellPrice() , amountSPTRtoSell);
        //TODO: 
        if (daysChosenLocked ==0) //payout immediate.
        {
            usdAmt = decMul18(usdAmt,decDiv18(10,100)); //10% payout
            uint256 usdAmtTrf = usdAmt/(10**(18-stableERC20Info[_stableChosen].tokenDecimals)); //Converted to decimals
            tokenStable.transfer(msg.sender, usdAmtTrf); 
            tokenStable.transfer(devWalletAddr, decMul18(usdAmtTrf,decDiv18(5,100)));
        }
        else { //locked TODO: Check decimals
        withheldWithdrawals[msg.sender].amounts = decMul18(usdAmt,decDiv18(taxForLocks[daysChosenLocked],100));
        withheldWithdrawals[msg.sender].timeUnlocked = block.timestamp + (daysChosenLocked * secondsInADay);
        }
        
    }

    function cashOutBaton(uint256 amountBTONtoSell, string memory _stableChosen) public payable{
        //require(msg.sender == trader , "Not authorized");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(BTON.balanceOf(msg.sender) >= amountBTONtoSell, "You dont have that amount!");

       /* require(
            mockUSDC.allowance(owner2, address(this)) >= amount2,"Token 2 allowance too low");
            */

        //WAND to transfer USDC to seller
        //uint256 btonAmt = amountBTONtoSell * DECIMALS;
        uint256 usdAmt; 
        usdAmt = decMul18(this.getSellPrice() , amountBTONtoSell) / (10**(18-stableERC20Info[_stableChosen].tokenDecimals));
        
        BTON.burn(address(this),amountBTONtoSell);

        
    }

    function transformScepterToBaton(uint256 amountSCPtoSwap) public payable{
        //require(msg.sender == trader , "Not authorized");
        require(SPTR.balanceOf(msg.sender) > amountSCPtoSwap, "You dont have that amount!");

        uint256 sptrAmt = amountSCPtoSwap * DECIMALS;

        WAND.burn(address(this),sptrAmt);
        SPTR.burn(msg.sender,sptrAmt);
        BTON.mint(msg.sender,sptrAmt);

        //Keeping track of SPTRS sold per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensSoldXDays[dInArray] += amountSCPtoSwap;
        circulatingSupplyXDays[dInArray] -= amountSCPtoSwap;

        //TODO: Update Airdrop contract
        //airdrop.updateBtonHoldings(amountSCPtoSwap);
    }   
    
    function buyScepter(uint256 amountSPTRtoBuy, string memory _stableChosen) public nonReentrant{
        //require(msg.sender == trader , "Not authorized");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        require(amountSPTRtoBuy <= 250000 * DECIMALS , "Per transaction limit");
       // require(tokenStable.balanceOf(msg.sender) > amountSCPtoBuy, "You dont have that amount!");
        //calculate amount of stables to pay
        //uint256 sptrAmt = amountSCPtoBuy * DECIMALS;
        uint256 usdAmtToPay;
        usdAmtToPay = decMul18(amountSPTRtoBuy, this.getBuyPrice()) / (10**(18-stableERC20Info[_stableChosen].tokenDecimals));

        //Transfer USDC to WI from trader
        _safeTransferFrom(tokenStable, msg.sender, scepterTreasuryAddr, decMul18(usdAmtToPay,decDiv18(95,100)));
        _safeTransferFrom(tokenStable, msg.sender, devWalletAddr, decMul18(usdAmtToPay,decDiv18(5,100)));

      
        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(address(this), amountSPTRtoBuy); 

        //Keeping track of tokens bought per day
        uint256 dInArray =(block.timestamp- timeLaunched)/86400; 
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;
        
        emit sceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function claimLockedUSDC(address _claimant, string memory _stableChosen) public {
        require (block.timestamp >= withheldWithdrawals[_claimant].timeUnlocked, "Not unlocked");
        tokenStable = IERC20(stableERC20Info[_stableChosen].contractAddress);
        //function to claim the USDC locked after cashing out scepter
        uint256 claimAmts;
        claimAmts = withheldWithdrawals[_claimant].amounts;
        _safeTransferFrom(tokenStable, address(this), msg.sender, claimAmts);

    }

    //Front End Display

    function getCircSupplyXDays() external view returns (uint256){
		uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        uint256 CircSupplyXDays = 0;
        uint256 numdays = daysInCalculation/86400;
        uint256 d;
        
        if (daySinceLaunched ==0) {
            return circulatingSupplyXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            CircSupplyXDays += circulatingSupplyXDays[d];
            }
            return CircSupplyXDays;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {
            CircSupplyXDays += circulatingSupplyXDays[d];
            }
            return CircSupplyXDays;
        }

    }

    function getGrowthFactor() external view returns (uint256){
        //FORMULA: 2* (number of tokens bought over the last X days / total number of tokens existing X days ago) and capped at 1.2
        uint256 _gF;
       // uint256 xDaysCircSupply;
        //uint256 numdays = daysInCalculation/86400;
        //uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;
        //uint256 d;
      // xDaysCircSupply = getCircSupplyXDays(); 

       _gF = 2 * (decDiv18(this.getTokensBoughtXDays(), this.getCircSupplyXDays()));
       if (_gF > 300000000000000000)
       {
           _gF = 300000000000000000;
       }
       return _gF ;
    }

    function getSellFactor() external view returns (uint256){
        //FORMULA:  2 * (number of tokens sold over the last X days / total number of tokens existing X days ago) and capped at 0.3.
        uint256 _sF; 
 
       _sF = 2 * (decDiv18(this.getTokensSoldXDays(), this.getCircSupplyXDays()));
       if (_sF > 300000000000000000)
       {
           _sF = 300000000000000000;
       }
       return _sF ;
    }

    function getSPTRBackingPrice() external view returns (uint256){
        //FORMULA: Scepter Treasury in USDC divide by Total Supply of Scepters

       return decDiv18(sptrTreasuryBal * DECIMALS,SPTR.totalSupply());
    }

    function getBTONBackingPrice() external view returns (uint256){
        //FORMULA: Baton Treasury in USDC divide by Total Supply of Baton

       return decDiv18(btonTreasuryBal * DECIMALS, BTON.totalSupply());
    }

    function getBTONRedeemingPrice() external view returns (uint256){
        //FORMULA: 30% of Baton backing price, capped at half of scepter backing price
        if (decMul18(this.getBTONBackingPrice(), div(30,100)) > decDiv18(this.getSPTRBackingPrice(), 2))
        {
            return decDiv18(this.getSPTRBackingPrice(), 2);
        }
        else
        {
            return decMul18(this.getBTONBackingPrice(), div(30,100));
        }
       
    }

    function getBuyPrice() external view returns (uint256){
         //FORMULA: Backing Price * (1.2 + Growth factor)
         //Price Protocol use to sell to investors
        return decMul18(this.getSPTRBackingPrice() , (1200000000000000000 + this.getGrowthFactor()));

    }

    function getSellPrice() external view returns (uint256){
        //FORMULA: Backing price * (0.9 - Sell factor) 
        //Price Protocol use to buy back from investors
        return decMul18(this.getSPTRBackingPrice() , (900000000000000000 - this.getSellFactor()));
    }

    //Admin Functions

    function updateSPTRTreasuryBal(uint256 _totalAmt) public { //TODO: lockdown
        //tokenStable = IERC20(stableERC20Info["USDC"].contractAddress);
        sptrTreasuryBal = _totalAmt;  
    } 
    function updateBTONTreasuryBal(uint256 _totalAmt) public { //TODO: lockdown
        //tokenStable = IERC20(stableERC20Info["USDC"].contractAddress);
        btonTreasuryBal = _totalAmt;  
    }     

    function Launch() public onlyOwner{
         require (timeLaunched ==0, "Already Launched");
        timeLaunched = block.timestamp;
        daysInCalculation = 5 days;

        //airdrop SPTRS to seeds
        SPTR.mint(0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 9411764706 * 10**12); //seed 1
        SPTR.mint(0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 4470588235 * 10**13); //seed 2
        SPTR.mint(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678, 4705882353 * 10**13); //seed 3

        WAND.mint(address(this), (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13));
        
        tokensBoughtXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);
        circulatingSupplyXDays[0] = (9411764706 * 10**12) + (4470588235 * 10**13) + (4705882353 * 10**13);
        //TODO: Get the value of treasury bal for launch
        sptrTreasuryBal = 86000;

    }

    function setDaysUsedInFactors(uint256 numDays) public onlyOwner{  
        daysInCalculation = numDays * 86400;     
    }

    function testUpdatetimeLockedplus(uint256 amt) public  {
        //require(amt > withheldWithdrawals[msg.sender].amounts, "You dont have that much to withdraw!");
        /*     lockedamounts memory currentEntry;
        currentEntry.timeUnlocked = timeUnlocked;
        currentEntry.amounts = amt;
        */
    
        withheldWithdrawals[msg.sender].timeUnlocked = block.timestamp + 864000;
        withheldWithdrawals[msg.sender].amounts += amt;
    
    }
    
    function testUpdatetimeLockedminus(uint256 amt) public  {
        require(amt < withheldWithdrawals[msg.sender].amounts, "You dont have that much to withdraw!");
        /*     lockedamounts memory currentEntry;
        currentEntry.timeUnlocked = timeUnlocked;
        currentEntry.amounts = amt;
        */
        withheldWithdrawals[msg.sender].amounts -= amt;
        if (withheldWithdrawals[msg.sender].amounts ==0 ){
            delete(withheldWithdrawals[msg.sender]);
        }
    }


    function getTokensBoughtXDays() external view returns (uint256){
        uint256 boughtCount =0;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;

        if (daySinceLaunched == 0) {
            return tokensBoughtXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            boughtCount += tokensBoughtXDays[d];
            }
            return boughtCount;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {  //for loop example
                boughtCount += tokensBoughtXDays[d];
                }
            return boughtCount;
        }
               
    }
    function getTokensSoldXDays() external view returns (uint256){
        uint256 soldCount =0;
        uint256 d;
        uint256 numdays = daysInCalculation/86400;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / 86400;

        if (daySinceLaunched == 0) {
            return tokensSoldXDays[0];
        }
        else if (daySinceLaunched < numdays)
        {
            for (d = 0; d < daySinceLaunched; d++) {
            soldCount += tokensSoldXDays[d];
            }
            return soldCount;
        }
        else{
            for (d = daySinceLaunched - numdays; d < daySinceLaunched; d++) {  //for loop example
                soldCount += tokensSoldXDays[d];
                }
            return soldCount;
        }

    }

    function addWhitelistee(address _addr) public onlyOwner {  
       whiteListAddresses[_addr] = true;
    }

    function addStable(string memory _ticker, address _addr, uint256 _dec) public onlyOwner {
    
        stableERC20Info[_ticker].contractAddress = _addr;
        stableERC20Info[_ticker].tokenDecimals = _dec;

    }
    
    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

} //Closing for Main Contract

/**
*
Abstract Functions
*

interface Scepter {
   
    
}
interface Wand {
    function mint(address addrTo, uint256 amount) external  ;
    //function scepterTotalSupply() public view virtual returns (uint256);
    function transferFrom(address addrTo, uint256 amount) external ;
    function burn (address addrFrom, uint256 amount) external  ;
}

interface Baton {
  
    function mint(address addrTo, uint256 amount) external  ;
}**/