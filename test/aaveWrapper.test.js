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

  })

  it("unlock account", async () => {
    const AaveWrapper = await ethers.getContractFactory("AaveWrapper");
    aaveWrapper = await AaveWrapper.deploy()

    const collateralToken = WETH9
    const collateralAmount = 1n * 10n ** 18n
    const debtToken = DAI
    const debtAmount =  100n * 10n ** 18n;
    await weth.deposit({ value: collateralAmount })
    let weth_balance = await weth.balanceOf(accounts[0].address);
    console.log(`WETH amount before deposit: ${ethers.utils.formatEther(weth_balance)}`);
    
    await weth.connect(accounts[0]).transfer(aaveWrapper.address, collateralAmount)

    // let lp = await ethers.getContractAt("ILendingPool", LENDING_POOL);
    // let txn = await lp.connect(accounts[0]).deposit(WETH9, collateralAmount, accounts[0].address, 0);
    // console.log(txn)
    // let rc = await txn.wait()
    // console.log(rc)
    console.log(`Balance of DAI Before: ${await dai.balanceOf(accounts[0].address)}`)

    await aaveWrapper.connect(accounts[0]).depositAndBorrow(collateralToken, collateralAmount, debtToken, debtAmount, {gasLimit: 1e6});
    
    console.log(`Balance of DAI After: ${await dai.balanceOf(accounts[0].address)}`)

    await dai.transfer(aaveWrapper.address, debtAmount);

    await aaveWrapper.connect(accounts[0]).paybackAndWithdraw(collateralToken, collateralAmount, debtToken, debtAmount);

  })
})