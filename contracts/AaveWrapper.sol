// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "hardhat/console.sol";

/// @title AaveWrapper
/// @author Rishabh
/// @notice You can use this contract for making secure deposit, borrow, repay and withdrawl
/// @dev All function calls are currently implemented without side effects
contract AaveWrapper {
    ///1 is for stable interest mode and 2 is for variable mode
    uint256 private interest_mode;

    ///Mutex variable for preveting re-entrancy
    uint256 private unlocked = 1;

    address owner;

    ///ERROR to mark unexpected Ether payments send to Streaming contract
    error UnexpectedETH(address sender, uint256 amount);

    address LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address PRICE_ORACLE = 0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;

    address DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

    constructor(uint256 _interest_mode) {
        interest_mode = _interest_mode;
        owner = msg.sender;
    }

    /// @notice Checks whether caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    /// @notice Checks whether caller is re-entering the contract
    modifier checkReentracy() {
        require(unlocked == 1, "SC is locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /// @notice Change the interest rate mode
    /// @param _interest_mode new mode
    function changeInterestMode(uint256 _interest_mode) external onlyOwner {
        interest_mode = _interest_mode;
    }

    /// @notice Get the price of token in ETH terms. output is in wei
    /// @param asset address of token
    function getAssetPriceInEth(address asset)
        public
        view
        returns (uint256 price)
    {
        price = IPriceOracleGetter(PRICE_ORACLE).getAssetPrice(asset);
    }

    /// @notice Deposit collateral Token and Borrow debt token
    /// @param collateralToken address of collaternal token
    /// @param collateralAmount Amount of collaternal token
    /// @param debtToken address of debt token
    /// @param debtAmount amount of debt token
    function depositAndBorrow(
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    ) external checkReentracy {
        //check that collateral amount in SC is greater than equal to collateralAmount provided
        require(
            IERC20(collateralToken).balanceOf(address(this)) >=
                collateralAmount,
            "depositAndBorrow: Non-sufficient collateral"
        );

        displayUserInformation(address(this), "Before ");

        //provide permission to LENDING_POOL to access collateral Token
        IERC20(collateralToken).approve(LENDING_POOL, collateralAmount);

        console.log("Approve done...");

        //Making a deposit
        ILendingPool(LENDING_POOL).deposit(
            collateralToken,
            collateralAmount,
            address(this),
            0
        );

        (, , uint256 availableBorrowsETH, ) = displayUserInformation(
            address(this),
            "After Deposit "
        );

        require(
            availableBorrowsETH >=
                (debtAmount * getAssetPriceInEth(debtToken)) / 1 ether,
            "depositAndBorrow: Debt Token Limit crossed"
        );

        console.log("Deposit complete...");

        //Making a borrow
        ILendingPool(LENDING_POOL).borrow(
            debtToken,
            debtAmount,
            interest_mode,
            0,
            address(this)
        );

        console.log("Borrow complete...");

        displayUserInformation(address(this), "After Borrow ");

        _safeTransfer(debtToken, msg.sender, debtAmount);
    }

    /// @notice Repay debt Token and withdraw collaternal token
    /// @param collateralToken address of collaternal token
    /// @param collateralAmount Amount of collaternal token
    /// @param debtToken address of debt token
    /// @param debtAmount amount of debt token
    function paybackAndWithdraw(
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    ) external checkReentracy {
        require(
            IERC20(debtToken).balanceOf(address(this)) >= debtAmount,
            "paybackAndWithdraw: Debt Token not sent"
        );

        (, uint256 currentStableDebt, , , , , , , ) = IProtocolDataProvider(
            DATA_PROVIDER
        ).getUserReserveData(debtToken, address(this));

        console.log("currentStableDebt: ",currentStableDebt);
        console.log("debtAmount: ",debtAmount);


        require(
            currentStableDebt <= debtAmount,
            "paybackAndWithdraw: Debt Amount sent should be grater than currentStableDebt"
        );

        IERC20(debtToken).approve(LENDING_POOL, debtAmount);

        uint256 currDebtTokenAmount = IERC20(debtToken).balanceOf(
            address(this)
        );

        displayUserInformation(address(this), "Before repay ");

        //repay
        ILendingPool(LENDING_POOL).repay(
            debtToken,
            debtAmount,
            interest_mode,
            address(this)
        );

        uint256 finalDebtTokenAmount = IERC20(debtToken).balanceOf(
            address(this)
        );

        (uint256 totalCollateralETH, , , ) = displayUserInformation(
            address(this),
            "After repay "
        );

        require(
            totalCollateralETH >=
                (getAssetPriceInEth(collateralToken) * collateralAmount) /
                    1 ether,
            "paybackAndWithdraw: Collateteral asked back cannot be greater than totalCollateral deposited"
        );

        console.log(
            "price of collateral token in wei",
            getAssetPriceInEth(collateralToken)
        );

        //withdraw
        ILendingPool(LENDING_POOL).withdraw(
            collateralToken,
            collateralAmount,
            address(this)
        );

        displayUserInformation(address(this), "After withdraw ");

        _safeTransfer(
            collateralToken,
            msg.sender,
            IWETH(collateralToken).balanceOf(address(this))
        );

        _safeTransfer(
            debtToken,
            msg.sender,
            debtAmount - (currDebtTokenAmount - finalDebtTokenAmount)
        );
    }

    /// @notice Console log the user state and returns imp state var
    /// @param user address
    /// @param state helper for logging
    function displayUserInformation(address user, string memory state)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            ,

        ) = ILendingPool(LENDING_POOL).getUserAccountData(user);
        console.log("");
        console.log(state, " totalCollateralETH", totalCollateralETH);
        console.log(state, " totalDebtETH", totalDebtETH);
        console.log(state, " availableBorrowsETH", availableBorrowsETH);
        console.log(
            state,
            " currentLiquidationThreshold",
            currentLiquidationThreshold
        );
        console.log("");
        return (
            totalCollateralETH,
            totalDebtETH,
            availableBorrowsETH,
            currentLiquidationThreshold
        );
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

    /**
     * @notice reciever funciton to handle unexpected ether payments
     */
    receive() external payable {
        revert UnexpectedETH(msg.sender, msg.value);
    }
}
