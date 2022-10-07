// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "hardhat/console.sol";

contract AaveWrapper {


    address LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function depositAndBorrow(address collateralToken, uint256 collateralAmount, address debtToken, uint256 debtAmount) external {
        
        (uint totalCollateralETH, uint totalDebtETH, uint availableBorrowsETH, uint currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("Before totalCollateralETH", totalCollateralETH);
        console.log("Before totalDebtETH", totalDebtETH);
        console.log("Before availableBorrowsETH", availableBorrowsETH);
        console.log("Before currentLiquidationThreshold", currentLiquidationThreshold);

        if(collateralToken == WETH){
            IWETH(collateralToken).approve(LENDING_POOL, collateralAmount);
        }else{
            IERC20(collateralToken).approve(LENDING_POOL, collateralAmount);
        }

    
        console.log("approve done");
        
        ILendingPool(LENDING_POOL).deposit(collateralToken, collateralAmount, address(this), 0);

        ( totalCollateralETH,  totalDebtETH,  availableBorrowsETH,  currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("After Deposit totalCollateralETH", totalCollateralETH);
        console.log("After Deposit totalDebtETH", totalDebtETH);
        console.log("After Deposit availableBorrowsETH", availableBorrowsETH);
        console.log("After Deposit currentLiquidationThreshold", currentLiquidationThreshold);

        console.log("Deposit complete...");

        ILendingPool(LENDING_POOL).borrow(debtToken, debtAmount, 1, 0, address(this));
        console.log("Borrow complete...");

        ( totalCollateralETH,  totalDebtETH,  availableBorrowsETH,  currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("After Borrow totalCollateralETH", totalCollateralETH);
        console.log("After Borrow totalDebtETH", totalDebtETH);
        console.log("After Borrow availableBorrowsETH", availableBorrowsETH);
        console.log("After Borrow currentLiquidationThreshold", currentLiquidationThreshold);

        if(debtToken == WETH){
            IWETH(debtToken).transfer(msg.sender, debtAmount);
        }else{
            IERC20(debtToken).transfer(msg.sender, debtAmount);
        }

    }
    
    function paybackAndWithdraw(address collateralToken, uint256 collateralAmount, address debtToken, uint256 debtAmount)  external {

        if(collateralToken == WETH){
            IWETH(debtToken).approve(LENDING_POOL, debtAmount);
        }else{
            IERC20(debtToken).approve(LENDING_POOL, debtAmount);
        }
        (uint totalCollateralETH, uint totalDebtETH, uint availableBorrowsETH, uint currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log(" Before repay totalCollateralETH", totalCollateralETH);
        console.log(" Before repay  totalDebtETH", totalDebtETH);
        console.log(" Before repay  availableBorrowsETH", availableBorrowsETH);
        console.log(" Before repay  currentLiquidationThreshold", currentLiquidationThreshold);

        ILendingPool(LENDING_POOL).repay(debtToken, debtAmount, 1, address(this));

        ( totalCollateralETH,  totalDebtETH,  availableBorrowsETH,  currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("After repay totalCollateralETH", totalCollateralETH);
        console.log("After repay totalDebtETH", totalDebtETH);
        console.log("After repay availableBorrowsETH", availableBorrowsETH);
        console.log("After repay currentLiquidationThreshold", currentLiquidationThreshold);

        
        ILendingPool(LENDING_POOL).withdraw(collateralToken, collateralAmount, address(this));

        ( totalCollateralETH,  totalDebtETH,  availableBorrowsETH,  currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("After withdraw totalCollateralETH", totalCollateralETH);
        console.log("After withdraw totalDebtETH", totalDebtETH);
        console.log("After withdraw availableBorrowsETH", availableBorrowsETH);
        console.log("After withdraw currentLiquidationThreshold", currentLiquidationThreshold);

        console.log("IWETH(collateralToken).balanceOf(address(this))", IWETH(collateralToken).balanceOf(address(this)));
        console.log("collateralAmount", collateralAmount);
        

        if(collateralToken == WETH){
            IWETH(collateralToken).transfer(msg.sender, IWETH(collateralToken).balanceOf(address(this)));
        }else{
            IERC20(collateralToken).transfer(msg.sender, IWETH(collateralToken).balanceOf(address(this)));
        }

    }
}