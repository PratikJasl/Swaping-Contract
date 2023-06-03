//SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SingleSwap
{
    // interface for the ISwapRouter function contract.
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
    // ERC20 Contract address of all the tokens that will be exchanged.
    // These are hardcoded here for simplicity.
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;  // Inbuilt into Uniswap
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Inbuilt into Uniswap

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;
    
    // It takes the fixed amount of tokenX and trades it for the maximum amount of Token Y.
    // Before calling this function the User must approve this contract to take TokenX from this account.
    function swapExactInputSingle(uint256 amountIn) external returns(uint amountOut)
    {
        //TransferHelper has safe transfer function to transfer token from ERC20 to this contract. 
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);

        //Approval function to approve the swapRouter contract to spend the Tokens in this contract's balance.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = 
            ISwapRouter.ExactInputSingleParams ({
                tokenIn: WETH9,                 //The contract address of the inbound token.
                tokenOut: DAI,                  //The contract address of the outbound token.
                fee: poolFee,                   //The swap fee for swapping in the pool.
                recipient: msg.sender,          //The destination address of the outbound token.
                deadline: block.timestamp,      //the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices
                amountIn: amountIn,           //Amount of TokenIn.      
                amountOutMinimum: 0,            //Minimum amount of Tokens to be giving in exchange. TokensOut
                sqrtPriceLimitX96: 0            //Used to set the limit for the price the swap will push the pool to. [Clarify?]
            });

        // The call to `exactInputSingle` executes the swap.
        // Amount Out is the amount of DAI received for the WETh9 we send.
        amountOut = swapRouter.exactInputSingle(params);
    }

    //This function takes the fixed amount of Output tokens we want and then calculates how much input token will be required for it.
    //We have to provide an extra amount of input tokens, and the remainder will br  returned back to the user.
    function swapExactOutputSingle(uint amountOut, uint amountInMax) external returns(uint amountIn)
    {
        //Transfers Max amount of Input token to the contract balance.
        //User must approve the transaction first.
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountInMax);

        //Approves the swapRouter function to spend the input tokens in contract balance.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountInMax);

        ISwapRouter.ExactOutputSingleParams memory params = 
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: WETH9,                     //The contract address of the inbound token.
                tokenOut: DAI,                      //The contract address of the outbound token.
                fee: poolFee,                       //The swap fee for swapping in the pool.
                recipient: msg.sender,              //The destination address of the outbound token.
                deadline: block.timestamp,          //the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices
                amountOut: amountOut,               //Tokens we wil be receiving.      
                amountInMaximum: amountInMax,       //Max tokensIn we are ready to give for the exchange.
                sqrtPriceLimitX96: 0
            });
    
        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);


        // All the input Tokens may not have been used hence the remaining WETH is transferred back to User.
        if(amountIn < amountInMax)
        {
            TransferHelper.safeApprove(WETH9, address(swapRouter),0);

            TransferHelper.safeTransfer(WETH9, msg.sender, amountInMax - amountIn);
        }
    }
}



