import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
const WETH9 = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

const DAI_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"
const USDC_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"

function log(text, value){
  console.log(`${text}: `)
  console.log(` ${value}`)
}

describe("Lock", function () {

  let aaveWrapper;
  let dai, usdc, weth, accounts;
  

  beforeEach("#deploy", async () => {
    accounts = await ethers.getSigners()
    const provider = new ethers.providers.JsonRpcProvider("https://eth-mainnet.g.alchemy.com/v2/UOdRxTyyeJu4-FcOki2B-pfG0RnekNMV")


    dai = await ethers.getContractAt("IERC20", DAI)
    usdc = await ethers.getContractAt("IERC20", USDC)

    // Unlock DAI and USDC whales
    const impersonatedSigner = await ethers.getImpersonatedSigner(DAI_WHALE);
    log("impersonateAccount",impersonateAccount)

  //   await network.provider.request({
  //     method: "hardhat_impersonateAccount",
  //     params: [DAI_WHALE],
  //   })
  //   await network.provider.request({
  //     method: "hardhat_impersonateAccount",
  //     params: [USDC_WHALE],
  //   })

  //   const daiWhale = await ethers.getSigner(DAI_WHALE)
  //   const usdcWhale = await ethers.getSigner(USDC_WHALE)

  //   // Send DAI and USDC to accounts[0]
  //   expect(await dai.balanceOf(daiWhale.address)).to.gte(daiAmount)
  //   expect(await usdc.balanceOf(usdcWhale.address)).to.gte(usdcAmount)

  //   await dai.connect(daiWhale).transfer(accounts[0].address, daiAmount)
  //   await usdc.connect(usdcWhale).transfer(accounts[0].address, usdcAmount)

  //   let AaveWrapper = await ethers.getContractFactory("AaveWrapper");
  //   aaveWrapper = await AaveWrapper.deploy();
  //   log("AaveWrapper",aaveWrapper.address)
  // })

  // describe("Deployment", function () {
  //   it("Should set the right unlockTime", async function () {
  //     log("",0)
  //   });

    
  });
});
