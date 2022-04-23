// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract testAirDrop is Ownable{ 

    //TODO: Update airdropped balance of tUSDC 
    //mapping(address => uint256) public airdroppedBal;
    struct btonsLocked {  
        uint256 timeInit;  
        uint256 amounts;  
        }
    struct airdropForTheWeek {  
        address investerWallet;  
        uint256 entitledAmt;  
        }
        
    mapping(address => btonsLocked) public btonHoldings;
    mapping(address => uint256) public airdroppedHistory;
    mapping(uint256 => airdropForTheWeek) public toDistribute;

    IERC20 public USDC;
    IERC20 public Bton;

    constructor() {
        USDC = IERC20(0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B);
        //Bton = IERC20(_btonAddr);
        }

   
    function updateBtonHoldings(uint256 _amt) external {
        btonHoldings[msg.sender].timeInit = block.timestamp;
        btonHoldings[msg.sender].amounts = _amt;
    }

    function calcAirdropRate(uint256 totalBtons) public pure returns(uint256) { //TODO: Make this internal and this has to be called in withdraw to update.
       /* uint256 deltaTimeFromInit;
        uint256 epochs;
        uint256 airdropAmt;
        deltaTimeFromInit = block.timestamp - airdroppedBal[msg.sender].timeInit;
        epochs = deltaTimeFromInit / 180; //test
        airdropAmt = epochs *1;
        airdroppedBal[msg.sender].amounts = airdropAmt;
    */  
    uint256 totalUSDC = 1000;
 
    return (totalUSDC/totalBtons);
    
    }
    function withdrawAirDrop() public onlyOwner{ //withdraw everything
        require (btonHoldings[msg.sender].amounts >0, "You dont have anything");
        uint256 i;
        for (i = 0; i < 10; i++) { //TODO: Update forloop 
        
        //TODO: Transfer USDC from this to the account and update history
        //TODO: have to calculate entitledAmt
        //usdc.transfer(toDistribute[i].investerWallet, toDistribute[i].entitledAmt);
       
        //airdroppedHistory[toDistribute[i].investerWallet] += toDistribute[i].entitledAmt;
        //toDistribute[i].entitledAmt =0;
        }

    }



}
