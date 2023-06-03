//SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract MultihopSwap
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

    //MultiHop swaps: If the pools for two tokens are not available then uniswap first swaps the TokenIn for USDC
    //and then buys the tokenout using the USDC and returns it to the user.

    function swapExactInputMultihop(uint256 amountIn) external returns (uint256 amountOut)
     {
        //TransferHelper has safe transfer function to transfer token from ERC20 to this contract. 
        //User must allow this contract to TransferFrom his balance.
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);

        // Approve the router to spend the WETH.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(WETH9, poolFee, USDC, uint24(100), DAI),  //Swap WETH9 --> USDC --> DAI
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap using the SWAP Router of Uniswap V3.
        amountOut = swapRouter.exactInput(params);
     }
     
    function swapExactOutputMultihop(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountInMaximum);
        
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountInMaximum);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case USDC is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is DAI so that swap happens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(DAI, uint24(100), USDC, poolFee, WETH9),  //SWAP DAI --> USDC -->WETH9
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(WETH9, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(WETH9, address(this), msg.sender, amountInMaximum - amountIn);
        }
    } 
}