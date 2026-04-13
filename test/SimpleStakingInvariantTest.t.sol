// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

contract SimpleStakingHandler is Test {
    SimpleStaking public staking;

    address public alice;
    address public bob;
    address public charlie;

    uint256 public maxRewardPerTokenStoredSeen;
    uint256 public maxLastUpdateTimeSeen;

    address[] public users;

    constructor(SimpleStaking _staking) {
        staking = _staking;

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        users.push(alice);
        users.push(bob);
        users.push(charlie);

        vm.deal(alice, 1_000 ether);
        vm.deal(bob, 1_000 ether);
        vm.deal(charlie, 1_000 ether);
    }

    function stake(uint256 userSeed, uint256 amount) external {
        address user = users[userSeed % users.length];

        amount = bound(amount, 1 wei, 100 ether);

        // Si el usuario no tiene suficiente ETH, no hacemos nada
        if (user.balance < amount) {
            return;
        }

        vm.prank(user);
        try staking.stake{value: amount}() {
            // ok
        } catch {
            // ignore
        }

        _trackRewardPerTokenStored();
        _trackLastUpdateTime();
    }

    function withdraw(uint256 userSeed, uint256 amount) external {
        address user = users[userSeed % users.length];

        uint256 userBalance = staking.balances(user);

        if (userBalance == 0) {
            return;
        }

        amount = bound(amount, 1 wei, userBalance);

        vm.prank(user);
        try staking.withdraw(amount) {
            // ok
        } catch {
            // ignore
        }
        
        _trackRewardPerTokenStored();
        _trackLastUpdateTime();
    }

    function claimReward(uint256 userSeed) external {
        address user = users[userSeed % users.length];

        vm.prank(user);
        try staking.claimReward() {
            // ok
        } catch {
            // ignore
        }
        
        _trackRewardPerTokenStored();
        _trackLastUpdateTime();
    }

    function warpTime(uint256 timeJump) external {
        timeJump = bound(timeJump, 1, 7 days);
        vm.warp(block.timestamp + timeJump);
    }

    function usersLength() external view returns (uint256) {
        return users.length;
    }

    function getUser(uint256 index) external view returns (address) {
        return users[index];
    }

    function _trackRewardPerTokenStored() internal {
        uint256 current = staking.rewardPerTokenStored();
        if (current > maxRewardPerTokenStoredSeen) {
            maxRewardPerTokenStoredSeen = current;
        }
    }

    function _trackLastUpdateTime() internal {
        uint256 current = staking.lastUpdateTime();
        if (current > maxLastUpdateTimeSeen) {
            maxLastUpdateTimeSeen = current;
        }
    }
}

contract SimpleStakingInvariantTest is StdInvariant, Test {
    SimpleStaking public staking;
    SimpleStakingHandler public handler;

    function setUp() public {
        staking = new SimpleStaking();
        handler = new SimpleStakingHandler(staking);

        targetContract(address(handler));
    }

    function invariant_TotalStakedEqualsSumOfTrackedBalances() public view {
        uint256 totalTrackedBalances;

        for (uint256 i = 0; i < handler.usersLength(); i++) {
            address user = handler.getUser(i);
            totalTrackedBalances += staking.balances(user);
        }

        assertEq(staking.totalStaked(), totalTrackedBalances);
    }

    function invariant_UserBalanceNeverExceedsTotalStaked() public view {
        for (uint256 i = 0; i < handler.usersLength(); i++) {
            address user = handler.getUser(i);
            assertLe(staking.balances(user), staking.totalStaked());
        }
    }

    function invariant_GetVaultBalanceMatchesRealBalance() public view {
        assertEq(staking.getVaultBalance(), address(staking).balance);
    }

    function invariant_RewardPerTokenStoredNeverDecreases() public view {
        assertEq(staking.rewardPerTokenStored(), handler.maxRewardPerTokenStoredSeen());
    }

    function invariant_LastUpdateTimeNeverDecreases() public view {
        assertEq(staking.lastUpdateTime(), handler.maxLastUpdateTimeSeen());
    }
}
