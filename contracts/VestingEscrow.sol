// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title VestingEscrow
 * @author BootNode
 * @dev Sets a vesting schedule on the token for a recipient. After the cliff date, tokens vest linearly.
 * Holds functionality to interact with the safety module.
 * The recipient receives the voting power of the locked tokens to use them in governance.
 * The owner holds the power of stopping the vesting, reclaiming the tokens amount not vested.
 */
contract VestingEscrow is OwnableUpgradeable {
  address public token;
  address public recipient;
  uint256 public vestingAmount;
  uint256 public vestingBegin;
  uint256 public vestingCliff;
  uint256 public vestingEnd;

  uint256 public lastUpdate;

  event Claimed(uint256 amount, address claimer, address recipient);
  event Removed(uint256 amount);

  /**
   * @dev Initializes the owner and vest parameters
   * @param token_ The address of the tokens
   * @param recipient_ The address of the recipient that will be receiving the tokens
   * @param vestingAmount_ Amount of tokens being vested for `recipient`
   * @param vestingBegin_ Epoch time when tokens begin to vest
   * @param vestingCliff_ Duration after which the first portion vests
   * @param vestingEnd_ Epoch Time until all the amount should be vested
   * @return Bool indicating the correct initialization
   */
  function initialize(
    address token_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingCliff_,
    uint256 vestingEnd_
  ) external initializer returns (bool) {
    require(vestingCliff_ >= vestingBegin_, "cliff is too early");
    require(vestingEnd_ >= vestingCliff_, "end is too early");
    require(vestingEnd_ > vestingBegin_, "end should be bigger than start");

    __Ownable_init_unchained();

    token = token_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingCliff = vestingCliff_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin;

    return true;
  }

  /**
   * @dev Claim the vested tokens for the recipient. Anyone can call this method.
   * If there are tokens staked in the safety module, the staked token representation will have priority to be
   * transferred first.
   * Unclaimed SafetyModule rewards will remain assigned to this contract after executing this function.
   */
  function claim() external {
    require(block.timestamp >= vestingCliff, "not time yet");

    uint256 amount;

    if (block.timestamp >= vestingEnd) {
      amount = _getTokenBalance();
    } else {
      amount = _getClaimAmount();

      lastUpdate = block.timestamp;
    }

    _transferToken(recipient, amount);
    emit Claimed(amount, msg.sender, recipient);
  }

  /**
   * @dev Cancels the vesting and withdraws the amount not vested. Only the owner can call this method.
   * Unclaimed SafetyModule rewards will remain assigned to this contract after executing this function.
   */
  function cancelVesting() external onlyOwner {
    uint256 vested = _getClaimAmount();

    // update end date so the recipient can claim the remaining token balance
    // instead of calculating the amount
    vestingEnd = block.timestamp;

    uint256 balance = _getTokenBalance();
    uint256 amountToRemove = balance - vested;

    _transferToken(owner(), amountToRemove);
    emit Removed(amountToRemove);
  }

  /**
   * @dev Gets the amount available for claim
   *
   * @return the amount of vested tokens
   */
  function getClaimable() external view returns (uint256) {
    if (block.timestamp < vestingCliff) {
      return 0;
    }

    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = _getTokenBalance();
    } else {
      amount = _getClaimAmount();
    }

    return amount;
  }

  /**
   * @dev Transfers `amount` of `asset` to `to`
   *
   * @param to Address that will receive the assets
   * @param amount Amount of assets to transfer
   */
  function _transferToken(address to, uint256 amount) internal returns (bool) {
    return IERC20(token).transfer(to, amount);
  }

  /**
   * @dev Returns the `asset` balance of the escrow contract
   *
   * @return the balance amount
   */
  function _getTokenBalance() internal view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  /**
   * @dev Calculates the amount available for claim
   *
   * @return the amount of vested tokens
   */
  function _getClaimAmount() internal view returns (uint256) {
    return (vestingAmount * (block.timestamp - lastUpdate)) / (vestingEnd - vestingBegin);
  }
}
