// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

contract SimpleStakingFuzzTest is Test {
    SimpleStaking public staking;

    address alice;
    address bob;

    function setUp() public {
        staking = new SimpleStaking();

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.deal(alice, 1_000 ether);
        vm.deal(bob, 1_000 ether);
    }

    // =========================================================
    // STAKE FUZZ TESTS
    // =========================================================

    function testFuzz_Stake_IncreasesBalance(uint256 amount) public {
        // Arrange
        vm.assume(amount > 0 && amount < 1_000 ether);

        // Act
        vm.prank(alice);
        staking.stake{value: amount}();

        // Assert
        assertEq(address(staking).balance, amount);
        assertEq(staking.balances(alice), amount);
        assertEq(alice.balance, 1_000 ether - amount);
        assertEq(staking.totalStaked(), amount);
    }

    // =========================================================
    // WITHDRAW FUZZ TESTS
    // =========================================================

    function testFuzz_Withdraw_Works(uint256 depositAmount, uint256 withdrawAmount) public {
        // Arrange
        vm.assume(depositAmount > 0 && depositAmount < 1_000 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        // Act
        vm.startPrank(alice);
        staking.stake{value: depositAmount}();

        staking.withdraw(withdrawAmount);
        vm.stopPrank();

        // Assert
        assertEq(address(staking).balance, depositAmount - withdrawAmount);
        assertEq(staking.balances(alice), depositAmount - withdrawAmount);
        assertEq(staking.totalStaked(), depositAmount - withdrawAmount);
        assertEq(alice.balance, 1_000 ether - depositAmount + withdrawAmount);
    }

    // =========================================================
    // REWARD FUZZ TESTS
    // =========================================================

    function testFuzz_Rewards_AccumulateOverTime(uint256 amount, uint256 timeJump) public {
        // Arrange
        vm.assume(amount > 0 && amount < 1_000 ether);
        vm.assume(timeJump > 0 && timeJump < 100 hours);

        // Act
        vm.prank(alice);
        staking.stake{value: amount}();
        vm.warp(block.timestamp + timeJump);
        uint256 rewardAfterTimeJump = staking.earned(alice);

        // Assert
        assertEq(staking.balances(alice), amount);
        assertEq(staking.totalStaked(), amount);
        assertGt(rewardAfterTimeJump, 0);
    }

    // =========================================================
    // REWARD PRESERVATION FUZZ TESTS
    // =========================================================

    function testFuzz_Withdraw_DoesNotLoseRewards(uint256 depositAmount, uint256 withdrawAmount, uint256 timeJump)
        public
    {
        // Arrange
        vm.assume(depositAmount > 0 && depositAmount < 1_000 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount < depositAmount);
        vm.assume(timeJump > 0 && timeJump < 100 hours);

        // Act
        vm.startPrank(alice);
        staking.stake{value: depositAmount}();

        vm.warp(block.timestamp + timeJump);
        uint256 rewardAfterTimeJump = staking.earned(alice);

        staking.withdraw(withdrawAmount);
        vm.stopPrank();
        uint256 rewardAfterWithdraw = staking.earned(alice);

        // Assert
        assertEq(rewardAfterWithdraw, rewardAfterTimeJump);
        assertGt(rewardAfterWithdraw, 0);
        assertGt(rewardAfterTimeJump, 0);
        assertEq(staking.balances(alice), depositAmount - withdrawAmount);
    }

    // =========================================================
    // CLAIM FUZZ TESTS
    // =========================================================

    function testFuzz_ClaimReward_Works(uint256 amount, uint256 timeJump) public {
        // Arrange
        vm.assume(amount > 0 && amount < 1_000 ether);
        vm.assume(timeJump > 0 && timeJump <= 1 days);

        vm.deal(address(staking), 10_000 ether);

        // Act
        vm.prank(alice);
        staking.stake{value: amount}();

        vm.warp(block.timestamp + timeJump);

        uint256 aliceBalanceBeforeClaim = alice.balance;
        uint256 rewardBeforeClaim = staking.earned(alice);

        vm.prank(alice);
        staking.claimReward();

        uint256 rewardAfterClaim = staking.earned(alice);

        // Assert
        assertGt(rewardBeforeClaim, 0);
        assertEq(alice.balance, aliceBalanceBeforeClaim + rewardBeforeClaim);
        assertEq(rewardAfterClaim, 0);
    }
}
