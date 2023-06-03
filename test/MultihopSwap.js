/* const { expect } = require("chai");
const { ethers } = require("hardhat");

const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const DAI_DECIMALS = 18; 
const SwapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564"; 

const WETH9 = [
  // Read-Only Functions
  "function balanceOf(address owner) view returns (uint256)",
  // Authenticated Functions
  "function transfer(address to, uint amount) returns (bool)",
  "function deposit() public payable",
  "function approve(address spender, uint256 amount) returns (bool)",
];

describe("BeforeEach", function () 
{   
    let account;
    let Multihopswap;
    let deploy;
    let Weth;
    let Dai;
    let Usdc;

    before(async function(){

        account = await ethers.getSigners(1);
        Multihopswap = await ethers.getContractFactory("MultihopSwap");
        deploy = await Multihopswap.deploy();

        Weth = await ethers.getContractAt("IWETH",WETH_ADDRESS);
        Dai = await ethers.getContractAt("IERC20",DAI_ADDRESS);
        Usdc = await ethers.getContractAt("IERC20",USDC_ADDRESS);   
    });

    describe("MultiHopSwap", function()
    {
    it("Multiswap Swap Input", async function () {
    
    const amountIn = 10n**18n;

    await Weth.deposit({value: amountIn});
    await Weth.approve(deploy.address, amountIn);

    await deploy.swapExactInputMultihop(amountIn);
    let DAI_Balance = await Dai.balanceOf(account[0].address);
    console.log("DAI Balance is:", DAI_Balance);
    });
  
    it("Multiswap Swap Output", async function() {
    const DaiamountOut = 100n*10n**18n;
    const WethMaximumIn = 10n**18n;

    await Weth.deposit({value: WethMaximumIn});
    await Weth.approve(deploy.address, WethMaximumIn);

    await deploy.swapExactOutputMultihop(DaiamountOut, WethMaximumIn);
    console.log(account[0].address);
    console.log("Dai Balance is:", await Dai.balanceOf(account[0].address));
    });
    });
});
 */