// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IVestingEscrow } from "./interfaces/IVestingEscrow.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title VestingEscrowFactory
 * @author BootNode
 * @dev Deploy VestingEscrow proxy contracts to distribute ERC20 tokens and acts as a beacon contract to determine
 * their implementation contract.
 */
contract VestingEscrowFactory {
  using Clones for address;

  /**
   * @dev Struct used to group escrow related data used in `deployVestingEscrow` function
   *
   * `recipient` The address of the recipient that will be receiving the tokens
   * `admin` The address of the admin that will have special execution permissions in the escrow contract.
   * `vestingAmount` Amount of tokens being vested for `recipient`
   * `vestingBegin` Epoch time when tokens begin to vest
   * `vestingCliff` Duration after which the first portion vests
   * `vestingEnd` Epoch Time until all the amount should be vested
   */
  struct EscrowParams {
    address recipient;
    address admin;
    address token;
    uint256 vestingAmount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  struct Escrow {
    address deployer;
    address token;
    address recipient;
    address admin;
    address escrow;
    uint256 amount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  address public implementation;
  Escrow[] public escrows;

  event VestingEscrowCreated(
    address indexed deployer,
    address indexed token,
    address indexed recipient,
    address admin,
    address escrow,
    uint256 amount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  );

  /**
   * @dev Stores the implementation target for the proxies.
   *
   * @param implementation_ The address of the target implementation
   */
  constructor(address implementation_) {
    implementation = implementation_;
  }

  /**
   * @dev Deploys a proxy, initialize the vesting data and fund the escrow contract.
   * Caller should previously give allowance of the token.
   *
   * @param escrowData Escrow related data
   * @return The address of the deployed contract
   */
  function deployVestingEscrow(EscrowParams memory escrowData) external returns (address) {
    // Create the escrow contract
    address vestingEscrow = implementation.clone();

    // Initialize the contract with the vesting data
    require(
      IVestingEscrow(vestingEscrow).initialize(
        escrowData.token,
        escrowData.recipient,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      ),
      "initialization failed"
    );

    // Transfer the ownership to the admin
    IVestingEscrow(vestingEscrow).transferOwnership(escrowData.admin);

    // Transfer funds from the caller to the escrow contract
    IERC20(escrowData.token).transferFrom(msg.sender, vestingEscrow, escrowData.vestingAmount);

    escrows.push(
      Escrow(
        msg.sender,
        escrowData.token,
        escrowData.recipient,
        escrowData.admin,
        vestingEscrow,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      )
    );

    emit VestingEscrowCreated(
      msg.sender,
      escrowData.token,
      escrowData.recipient,
      escrowData.admin,
      vestingEscrow,
      escrowData.vestingAmount,
      escrowData.vestingBegin,
      escrowData.vestingCliff,
      escrowData.vestingEnd
    );

    return vestingEscrow;
  }

  function getEscrows() external view returns (Escrow[] memory) {
    Escrow[] memory list = new Escrow[](escrows.length);

    for (uint256 i = 0; i < escrows.length; i++) {
      list[i] = escrows[i];
    }

    return list;
  }

  function getEscrowsByRecipient(address recipient) external view returns (Escrow[] memory) {
    Escrow[] memory list = new Escrow[](escrows.length);

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].recipient == recipient) {
        list[i] = escrows[i];
      }
    }

    return list;
  }

  function getEscrowsByDeployer(address deployer) external view returns (Escrow[] memory) {
    Escrow[] memory list = new Escrow[](escrows.length);

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].deployer == deployer) {
        list[i] = escrows[i];
      }
    }

    return list;
  }

  function getEscrowsByAdmin(address admin) external view returns (Escrow[] memory) {
    Escrow[] memory list = new Escrow[](escrows.length);

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].admin == admin) {
        list[i] = escrows[i];
      }
    }

    return list;
  }
}
