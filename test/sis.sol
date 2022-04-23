// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";


//start of contract
contract personalSafuuTrader is Ownable
{
    AggregatorV3Interface internal priceFeed;
    //address private owner;
    uint256  public BnbToSafuu; 
    IERC20 public Safuu;
    IERC20 public USDC;
    //uint256 public nativeInContract = address(this).balance;

constructor () {
  BnbToSafuu = 100000;
  Safuu = IERC20(0xE5bA47fD94CB645ba4119222e34fB33F59C7CD90);
  USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
 // safuu = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138); //for test
   priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
  }


    function buySafuu(uint256 amttobuy) public payable
    {
        require(amttobuy >= BnbToSafuu, "Minimum trade amount 1 bnb");
        uint256 payableAmt; //18decimals
        payableAmt = (amttobuy/BnbToSafuu) *(10**18);
        (bool success, ) = owner().call{value: payableAmt}("");
        require(success, "Transfer failed!");

        //transfer the safuu to user
        Safuu.transfer(msg.sender, amttobuy);
       
    }
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    function sellSafuu(uint256 amttosell) public 
    {
        require(amttosell == BnbToSafuu, "Must be 1 bnb worth");
    _safeTransferFrom(Safuu, msg.sender, address(this), amttosell);
    //transfer BNB to user
    uint256 usdc; //18decimals
    //payableBNB = (amttosell/BnbToSafuu) *(10**18);
    //(bool success, ) = msg.sender.call{value: payableBNB}("");
      //  require(success, "Transfer failed!");
     usdc = uint256(getLatestPrice()) *(10**10);
    USDC.transfer(msg.sender, usdc);
    }


    function setFactor(uint256 _newfactor) public onlyOwner {
        
        BnbToSafuu = _newfactor;
    }
    function withdrawToOwner()
    public 
    { 
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
        Safuu.transfer(owner(), Safuu.balanceOf(address(this)));
        USDC.transfer(owner(), USDC.balanceOf(address(this)));
    }
    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}
