// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenSwap {
    IERC20 public tSC;
    
    uint256 public trader_tsc_balance;
    IERC20 public mockUSDC;
    uint public amountUSDC;

    constructor(
        address _tSC,
        //address _trader,

        address _mockUSDC
        //uint _amountusdc
    ) {
        tSC = IERC20(_tSC);
//        trader = _trader;
       trader_tsc_balance = tSC.balanceOf(msg.sender);
        mockUSDC = IERC20(_mockUSDC);
        //amountUSDC = _amountusdc;
    }
    //Selling scepter to Wand function
    function sellTsc(uint256 amountSellTSC) public {
        //require(msg.sender == trader , "Not authorized");
        uint256 trader_tsc_balance = tSC.balanceOf(msg.sender);
        require(trader_tsc_balance > amountSellTSC, "You dont have that amount!");

       /* require(
            mockUSDC.allowance(owner2, address(this)) >= amount2,
            "Token 2 allowance too low"
        );*/
            //WAND to transfer USDC to seller
        mockUSDC.transfer(msg.sender, amountSellTSC + 1);
            //Transfer the sold tsc to WAND
        //_safeTransferFrom(tSC, msg.sender, address(this), amountSellTSC);
        //_safeTransferFrom(token2, owner2, owner1, amount2);
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}