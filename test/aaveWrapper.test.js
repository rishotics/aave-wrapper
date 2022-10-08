const { expect } = require("chai")
const { ethers, network } = require("hardhat")

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
// DAI_WHALE must be an account, not contract
const DAI_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"

const WETH9 = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const LENDING_POOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";



describe("AaveWrapper", () => {
  let accounts
  let dai
  let weth
  let whale
  let aaveWrapper
  let collateralToken = WETH9
  let collateralAmount = 1n * 10n ** 18n
  let debtToken = DAI
  let debtAmount =  100n * 10n ** 18n;
  let AaveWrapper;

  before(async () => {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE],
    })

    whale = await ethers.getSigner(DAI_WHALE)
    dai = await ethers.getContractAt("IERC20", DAI)

    accounts = await ethers.getSigners();

    const amount = 100n * 10n ** 18n

    console.log("DAI balance of whale", await dai.balanceOf(DAI_WHALE))
    expect(await dai.balanceOf(DAI_WHALE)).to.gte(amount)

    await dai.connect(whale).transfer(accounts[0].address, amount)

    console.log(
      "DAI balance of account",
      await dai.balanceOf(accounts[0].address)
    )

    weth = await ethers.getContractAt("IWETH", WETH9)

    AaveWrapper = await ethers.getContractFactory("AaveWrapper");
  
  })

    describe("#reverts", function () {

      it("should fail when collateral not trasffered", async function () {
        
        AaveWrapper = await ethers.getContractFactory("AaveWrapper");
        aaveWrapper = await AaveWrapper.deploy(1)

        await weth.deposit({ value: 10n * 10n ** 18n  })
        let weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);

        await expect(
          aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, debtAmount)
        ).to.be.revertedWith("depositAndBorrow: Non-sufficient collateral");
      });

      it("should fail when debt amount is grater than allowed limit of borrow", async function () {
        AaveWrapper = await ethers.getContractFactory("AaveWrapper");
        aaveWrapper = await AaveWrapper.deploy(1)

        await weth.deposit({ value: 10n * 10n ** 18n  })
        let weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);


        await weth.connect(accounts[0]).transfer(aaveWrapper.address, collateralAmount);
        let temp_debtAmount = 10000n * 10n ** 18n;
        await expect(
          aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, temp_debtAmount)
        ).to.be.revertedWith("depositAndBorrow: Debt Token Limit crossed");
      });

      it("should fail when debt token is not sent for repay", async function () {
        AaveWrapper = await ethers.getContractFactory("AaveWrapper");
        aaveWrapper = await AaveWrapper.deploy(1)

        await weth.deposit({ value: 10n * 10n ** 18n  })
        let weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);


        await weth.connect(accounts[0]).transfer(aaveWrapper.address, collateralAmount);
        await aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, debtAmount, {gasLimit: 1e6});
        await expect(
          aaveWrapper.connect(accounts[0]).paybackAndWithdraw(collateralToken, collateralAmount, debtToken, debtAmount)
        ).to.be.revertedWith("paybackAndWithdraw: Debt Token not sent");
      });

      it("should fail when debt token is not sent for repay", async function () {
        AaveWrapper = await ethers.getContractFactory("AaveWrapper");
        aaveWrapper = await AaveWrapper.deploy(1)

        await weth.deposit({ value: 10n * 10n ** 18n  })
        let weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);


        await weth.connect(accounts[0]).transfer(aaveWrapper.address, collateralAmount);
        await aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, debtAmount, {gasLimit: 1e6});
        
        temp_debtAmount = 1n * 10n ** 18n
    
        await dai.transfer(aaveWrapper.address, temp_debtAmount);
        await expect(
          aaveWrapper.connect(accounts[0]).paybackAndWithdraw(collateralToken, collateralAmount, debtToken, temp_debtAmount)
        ).to.be.revertedWith("paybackAndWithdraw: Debt Amount sent should be grater than currentStableDebt");
      });
    });


    describe("#success", function () {

      it("should pass", async function () {
        AaveWrapper = await ethers.getContractFactory("AaveWrapper");
        aaveWrapper = await AaveWrapper.deploy(1)

        await weth.deposit({ value: 10n * 10n ** 18n  })
        let weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);

        await weth.connect(accounts[0]).transfer(aaveWrapper.address, collateralAmount)
        
        console.log(`Balance of DAI Before depositAndBorrow: ${await dai.balanceOf(accounts[0].address)}`)
        console.log(`Price of DAI in ETH is: ${(await aaveWrapper.getAssetPriceInEth(DAI))}`)
    
        await aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, debtAmount, {gasLimit: 1e6});
        
        console.log(`Balance of DAI After depositAndBorrow: ${await dai.balanceOf(accounts[0].address)}`)
    
        debtAmount = 150n * 10n ** 18n
    
        await dai.transfer(aaveWrapper.address, debtAmount);
    
        console.log(`Transferred dai for repaying, current balance of owner of dai: ${await dai.balanceOf(accounts[0].address)}`)
    
        await aaveWrapper.connect(accounts[0]).paybackAndWithdraw(collateralToken, collateralAmount, debtToken, debtAmount);
        
        weth_balance = await weth.balanceOf(accounts[0].address);
        console.log(`WETH amount after repaying: ${ethers.utils.formatEther(weth_balance)}`);
        console.log(`Balance of DAI After depositAndBorrow: ${await dai.balanceOf(accounts[0].address)}`)
      })

      
    });

  
})

function wei2eth(value){
    return ethers.utils.parseEther(value.toString())
}


// 825000000000000000
// 752,750,000,000,000
// 100000000000000000000
// 100,000,009,706,036,561,775
// 1,000,000,009,108,899,672