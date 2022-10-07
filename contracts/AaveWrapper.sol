// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "hardhat/console.sol";

contract AaveWrapper {


    address LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    function depositAndBorrow(address collateralToken, uint256 collateralAmount, address debtToken, uint256 debtAmount) external {
        
        (uint totalCollateralETH, uint totalDebtETH, uint availableBorrowsETH, uint currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        console.log("Before totalCollateralETH", totalCollateralETH);
        console.log("Before totalDebtETH", totalDebtETH);
        console.log("Before availableBorrowsETH", availableBorrowsETH);
        console.log("Before currentLiquidationThreshold", currentLiquidationThreshold);


        IWETH(collateralToken).approve(LENDING_POOL, collateralAmount);
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

    }
 
}