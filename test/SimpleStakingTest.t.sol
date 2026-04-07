// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

contract SimpleStakingTest is Test {
    SimpleStaking public staking;

    address alice;
    address bob;

    function setUp() public {
        staking = new SimpleStaking();

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    // =========================================================
    // STAKE TESTS
    // =========================================================

    function test_Stake_IncreasesBalance() public {
        // Act
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        // Assert
        assertEq(staking.balances(alice), 10 ether);
        assertEq(staking.totalStaked(), 10 ether);
        assertEq(address(staking).balance, 10 ether);
    }

    function test_Stake_RevertsIfZero() public {
        // Act + Assert
        vm.prank(alice);
        vm.expectRevert(SimpleStaking.ZeroAmount.selector);
        staking.stake{value: 0 ether}();
    }

    // =========================================================
    // WITHDRAW TESTS
    // =========================================================

    function test_Withdraw_Works() public {
        // Arrange

        // Act
        vm.startPrank(alice);
        staking.stake{value: 10 ether}();

        staking.withdraw(5 ether);
        vm.stopPrank();

        // Assert
        assertEq(staking.balances(alice), 5 ether);
        assertEq(alice.balance, 95 ether);
        assertEq(staking.totalStaked(), 5 ether);
        assertEq(address(staking).balance, 5 ether);
    }

    function test_Withdraw_RevertsIfInsufficientBalance() public {
        // Arrange
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        // Act + Assert
        vm.prank(alice);
        vm.expectRevert(SimpleStaking.InsufficientBalance.selector);
        staking.withdraw(15 ether);
    }

    function test_Withdraw_RevertsIfZero() public {
        // Act
        vm.startPrank(alice);
        staking.stake{value: 10 ether}();

        vm.expectRevert(SimpleStaking.ZeroAmount.selector);
        staking.withdraw(0);
        vm.stopPrank();
    }

    // =========================================================
    // REWARD TESTS 
    // =========================================================

    function test_Rewards_AccumulateOverTime() public {
        // Act
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        uint256 initialReward = staking.earned(alice);
        vm.warp(block.timestamp + 1 hours);
        uint256 finalReward = staking.earned(alice);
        
        // Assert
        assertGt(finalReward, initialReward);
    }

    function test_Rewards_AreZeroIfNoStake() public {
        // Act
        vm.prank(alice);
        uint256 reward = staking.earned(alice);

        // Assert
        assertEq(reward, 0);
    }

    // =========================================================
    // MULTI-USER TESTS
    // =========================================================

    function test_Rewards_DistributedProportionally() public {
        vm.prank(alice);
        staking.stake{value: 10 ether}();
        uint256 initialAliceReward = staking.earned(alice);

        vm.prank(bob);
        staking.stake{value: 5 ether}();
        uint256 initialBobReward = staking.earned(bob);

        vm.warp(block.timestamp + 1 weeks);

        uint256 finalAliceReward = staking.earned(alice);
        uint256 finalBobReward = staking.earned(bob);

        // Assert
        assertGt(finalAliceReward, initialAliceReward);
        assertGt(finalBobReward, initialBobReward);
        assertGt(finalAliceReward, finalBobReward); // Alice staked more, so she should earn more rewards
        assertEq(initialAliceReward, 0);
        assertEq(initialBobReward, 0);
        assertEq(initialAliceReward, initialBobReward);
    }

    function test_UserEnteringLater_DoesNotGetPastRewards() public {
        // Arrange

        // Alice stakes first
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        // One week passes where only Alice is staking
        vm.warp(block.timestamp + 1 weeks);

        uint256 aliceRewardBeforeBobEnters = staking.earned(alice);

        // Bob joins later
        vm.prank(bob);
        staking.stake{value: 10 ether}();

        // At the moment of entry, Bob should not receive past rewards
        uint256 bobRewardAtEntry = staking.earned(bob);

        // Act
        // Another week passes with both users staking
        vm.warp(block.timestamp + 1 weeks);

        uint256 aliceRewardAfterMoreTime = staking.earned(alice);
        uint256 bobRewardAfterMoreTime = staking.earned(bob);

        // Assert
        // Alice accumulated rewards during the first week
        assertGt(aliceRewardBeforeBobEnters, 0);

        // Bob does not receive rewards from before he entered
        assertEq(bobRewardAtEntry, 0);

        // After staking for one week, Bob should start earning rewards
        assertGt(bobRewardAfterMoreTime, 0);

        // Alice continues accumulating rewards over time
        assertGt(aliceRewardAfterMoreTime, aliceRewardBeforeBobEnters);
    }

    // =========================================================
    // CLAIM TESTS
    // =========================================================

    function test_ClaimReward_Works() public {
        // Arrange
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        uint256 aliceBalanceBeforeClaim = alice.balance;

        vm.warp(block.timestamp + 1 hours);

        uint256 rewardBeforeClaim = staking.earned(alice);

        // Act
        vm.prank(alice);
        staking.claimReward();

        // Assert
        assertGt(rewardBeforeClaim, 0);
        assertEq(alice.balance, aliceBalanceBeforeClaim + rewardBeforeClaim);
    }

    function test_ClaimReward_ResetsReward() public {
        // Arrange
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        vm.warp(block.timestamp + 1 hours);

        uint256 rewardBeforeClaim = staking.earned(alice);

        // Act
        vm.prank(alice);
        staking.claimReward();
        uint256 rewardAfterClaim = staking.earned(alice);

        // Assert
        assertGt(rewardBeforeClaim, 0);
        assertEq(rewardAfterClaim, 0);
    }

    // =========================================================
    // EXTRA (HIGHLY RECOMMENDED)
    // =========================================================

    function test_Withdraw_DoesNotLoseRewards() public {
        // Arrange
        vm.prank(alice);
        staking.stake{value: 10 ether}();
        vm.warp(block.timestamp + 1 hours);

        uint256 rewardBeforeWithdraw = staking.earned(alice);

        // Act
        vm.prank(alice);
        staking.withdraw(8 ether);
        uint256 aliceRewardsAfterPartialWithdraw = staking.earned(alice);

        // Assert
        assertGt(rewardBeforeWithdraw, 0);
        assertEq(aliceRewardsAfterPartialWithdraw, rewardBeforeWithdraw);
    }

    function test_MultipleActions_KeepStateConsistent() public {
        // Arrange
        vm.prank(alice);
        staking.stake{value: 10 ether}();

        vm.warp(block.timestamp + 1 hours);
        uint256 rewardAfterFirstHour = staking.earned(alice);

        // Act
        vm.prank(alice);
        staking.withdraw(5 ether);

        vm.warp(block.timestamp + 1 hours);
        uint256 rewardAfterSecondHour = staking.earned(alice);

        // Assert
        assertEq(alice.balance, 95 ether);

        // Rewards already existed after the first hour
        assertGt(rewardAfterFirstHour, 0);

        // After partial withdrawal and more time passing,
        // rewards should continue increasing
        assertGt(rewardAfterSecondHour, rewardAfterFirstHour);

        // Internal stake should be reduced correctly
        assertEq(staking.balances(alice), 5 ether);

        // Total staked in the system should reflect the change
        assertEq(staking.totalStaked(), 5 ether);

        // Contract balance must remain consistent
        assertEq(address(staking).balance, 5 ether);
    }
}