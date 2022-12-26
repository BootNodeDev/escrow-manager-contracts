// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IVestingEscrow {
  function initialize(
    address token,
    address recipient,
    uint256 vestingAmount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  ) external returns (bool);

  function transferOwnership(address newOwner) external;
}
