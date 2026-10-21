// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IVortexParametricInsurance {
    function buyInsurancePolicy(uint256 poolId) external payable;
    function triggerOraclePayout(uint256 poolId, address policyHolder) external;
}
