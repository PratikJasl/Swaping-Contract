const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe("Before Each", function()
{
    let Owner;
    let account;
    let deploy;
    let presale;
    const Token = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    
    before(async function(){
        [Owner,account] = await ethers.getSigners();
        presale = await ethers.getContractFactory("presale");
        deploy = await presale.deploy(Token,100);
    });

    describe("CreatePresaleFunction",function()
    {
        it("Should Create a Presale with the given parameters",async function()
        {
            const totalTokens = 10n**18n;
            const tokenPrice = 1n**18n;
            const startTime = 1785500292;
            const endTime = startTime+1000;
    
            await deploy.connect(Owner).createPreSale(totalTokens,tokenPrice,startTime,endTime);
            let EventID = await deploy.presaleEventid();
            //Test case for Event ID.
            expect(EventID).to.equal(1);
            console.log("EventID is :", EventID.toNumber());
            
            //Test case for Mapping.
            const phase = await deploy.idToPhaseMapping(1);
            expect(phase.totalTokens).to.equal(totalTokens);
            expect(phase.tokenPrice).to.equal(tokenPrice);
            expect(phase.startTime).to.equal(startTime);
            expect(phase.endTime).to.equal(endTime);
            expect(phase.tokenSold).to.equal(0);
        });

        it("Only the User should be able to Create Pre Sale", async function()
        {
            const totalTokens = 10n**18n;
            const tokenPrice = 1n**18n;
            const startTime = 1785500292;
            const endTime = startTime+1000;

            await expect(deploy.connect(account).createPreSale(totalTokens,tokenPrice, startTime,endTime))
            .to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Presale should emit an event when event is created",async function()
        {
            const totalTokens = 10n**18n;
            const tokenPrice = 1n**18n;
            const startTime = 1785500292;
            const endTime = startTime+1000;
            // create a Presale by calling the presale function.
            const Tx = await deploy.createPreSale(totalTokens,tokenPrice,startTime,endTime);
            //When a transaction is mined it created a transaction receipt. which contains all the information.
            //Get the Tx Receipt.
            const receipt = await Tx.wait();
            const event = receipt.events.find((event) => event.event == "PreSaleCreated");

            expect(event).to.not.be.undefined;
        });
        
    });

});