// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

interface IPriceOracleGetter {
    function getAssetPrice(address _asset) external view returns (uint256);
}