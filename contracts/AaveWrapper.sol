// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "hardhat/console.sol";

contract AaveWrapper {


    address LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address PRICE_ORACLE = 0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;
    address DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

    function getAssetPriceInEth(address asset)public view returns(uint price){
        price = IPriceOracleGetter(PRICE_ORACLE).getAssetPrice(asset);
    }


    function depositAndBorrow(address collateralToken, uint256 collateralAmount, address debtToken, uint256 debtAmount) external {
        
        require(IERC20(collateralToken).balanceOf(address(this)) >= collateralAmount, "Non-sufficient collateral");
        
        displayUserInformation(address(this), "Before ");

        IERC20(collateralToken).approve(LENDING_POOL, collateralAmount);

        console.log("Approve done...");
        
        //deposit
        ILendingPool(LENDING_POOL).deposit(collateralToken, collateralAmount, address(this), 0);

        (,,uint availableBorrowsETH,) = displayUserInformation(address(this), "After Deposit ");

        require(availableBorrowsETH >= (debtAmount * getAssetPriceInEth(debtToken))/1 ether, "Debt Token Limit crossed");

        console.log("Deposit complete...");

        //borrow
        ILendingPool(LENDING_POOL).borrow(debtToken, debtAmount, 1, 0, address(this));
        
        console.log("Borrow complete...");

        displayUserInformation(address(this), "After Borrow ");

        _safeTransfer(debtToken, msg.sender, debtAmount);

    }
    
    function paybackAndWithdraw(address collateralToken, uint256 collateralAmount, address debtToken, uint256 debtAmount)  external {

        require(IERC20(debtToken).balanceOf(address(this)) >= debtAmount, "Debt Token not sent");

        (
            uint currentATokenBalance,
            uint currentStableDebt,
            uint currentVariableDebt,
            uint principalStableDebt,
            uint scaledVariableDebt,
            uint stableBorrowRate,
            ,
            ,
        ) = IProtocolDataProvider(DATA_PROVIDER).getUserReserveData(
            debtToken,
            address(this)
        );

        require(currentStableDebt <= debtAmount, "paybackAndWithdraw: Debt Amount sent should be grater than currentStableDebt");

        console.log("currentStableDebt: ", currentStableDebt);

        IERC20(debtToken).approve(LENDING_POOL, debtAmount);

        uint currDebtTokenAmount = IERC20(debtToken).balanceOf(address(this));
        
        displayUserInformation(address(this), "Before repay ");

        //repay
        ILendingPool(LENDING_POOL).repay(debtToken, debtAmount, 1, address(this));

        uint finalDebtTokenAmount = IERC20(debtToken).balanceOf(address(this));

        displayUserInformation(address(this), "After repay ");

        //withdraw
        ILendingPool(LENDING_POOL).withdraw(collateralToken, collateralAmount, address(this));

        displayUserInformation(address(this), "After withdraw ");

        _safeTransfer(collateralToken, msg.sender, IWETH(collateralToken).balanceOf(address(this)));

        _safeTransfer(debtToken, msg.sender, debtAmount -  (currDebtTokenAmount-finalDebtTokenAmount));

    }

    function displayUserInformation(address user, string memory state)public view returns(uint, uint, uint, uint){ 
        (uint totalCollateralETH, uint totalDebtETH, uint availableBorrowsETH, uint currentLiquidationThreshold, ,) = ILendingPool(LENDING_POOL).getUserAccountData(user);
        console.log("");
        console.log(state, " totalCollateralETH", totalCollateralETH);
        console.log(state, " totalDebtETH", totalDebtETH);
        console.log(state, " availableBorrowsETH", availableBorrowsETH);
        console.log(state, " currentLiquidationThreshold", currentLiquidationThreshold);
        console.log("");
        return (totalCollateralETH, totalDebtETH, availableBorrowsETH,currentLiquidationThreshold);
    }


    /**
     * @notice private funciton to safetly transfer token 
     * @param to address to
     * @param value amount
     */
    function _safeTransfer(
        address _token,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "_safeTransfer: transfer failed"
        );
    }


}