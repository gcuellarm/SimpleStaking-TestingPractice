# 🧪 SimpleStaking — Solidity Testing with Foundry

A simplified ETH staking contract designed to practice **smart contract testing** using Foundry.

This project focuses on:

- Reward accrual over time
- State consistency after multiple interactions
- Proper handling of user balances and rewards
- Unit testing best practices

---

## 📖 Overview

`SimpleStaking` allows users to:

- Stake ETH
- Earn rewards over time
- Withdraw their stake
- Claim accumulated rewards

The contract implements a simplified version of real-world DeFi reward distribution logic using a **reward per token model**.

---

## ⚙️ Contract Features

- Per-user staking balances
- Global `totalStaked`
- Time-based reward accrual (`block.timestamp`)
- Reward tracking via:
  - `rewardPerTokenStored`
  - `userRewardPerTokenPaid`
  - `rewards`
- Claimable rewards in ETH
- Partial withdrawals supported

---

## 🧠 Core Concepts

This contract introduces important DeFi mechanics:

### 🔹 Reward Accrual

Rewards increase over time based on:
reward ∝ stake × time

### 🔹 Lazy Reward Calculation

Rewards are not continuously updated. Instead, they are calculated:

- On user interaction (`stake`, `withdraw`, `claim`)
- Using `rewardPerToken()` and `earned()`

### 🔹 State Update Pattern

All critical functions use:


updateReward(user) → modify balances


This ensures rewards are correctly accounted before state changes.

---

## 🧪 Test Coverage

The project includes a full suite of **unit tests** written using Foundry.

---

### ✅ Stake Tests

- Stake increases user balance
- Stake increases `totalStaked`
- Contract balance reflects deposits
- Reverts when staking `0`

---

### ✅ Withdraw Tests

- Withdraw reduces user balance
- Withdraw reduces `totalStaked`
- ETH is transferred back to the user
- Reverts when:
  - Amount is zero
  - Amount exceeds balance

---

### ✅ Reward Tests

- Rewards accumulate over time
- Rewards remain zero without stake

---

### ✅ Multi-User Tests

- Rewards are distributed proportionally based on stake
- Users entering later do not receive past rewards
- Rewards continue correctly after multiple users interact

---

### ✅ Claim Tests

- Claim transfers rewards to the user
- Claim resets accumulated rewards

---

### ✅ Advanced Tests (Important)

#### 🔹 Withdraw Does Not Lose Rewards

Ensures that:

> Accumulated rewards are preserved after partial withdrawal.

This validates correct use of:
updateReward(user)
before modifying balances.

---

#### 🔹 Multiple Actions Keep State Consistent

Simulates a sequence of actions:

- Stake → time passes → withdraw → time passes

Ensures:

- Rewards continue accumulating correctly
- Internal balances remain consistent
- `totalStaked` is accurate
- Contract balance matches expected value

---

## 🔀 Fuzz Testing

In addition to unit tests, this project includes a comprehensive suite of **fuzz tests** to validate contract behavior under a wide range of inputs.

Fuzz testing allows us to automatically test the contract against **randomized values**, ensuring robustness and uncovering edge cases that fixed inputs might miss.

---

### 🧠 What is Fuzz Testing?

Fuzz testing (or property-based testing) verifies that certain **invariants and properties always hold true**, regardless of the specific input values.

Instead of testing:

```text
stake(10 ether)

we test:

stake(any valid amount)
```
This approach is critical in smart contract development, where unexpected inputs can lead to vulnerabilities.

---

## 🧪 Fuzz Test Coverage

The fuzz tests focus on validating core properties of the staking system.

---

### ✅ Stake Fuzz Tests

**Property:**

> For any valid stake amount, the contract state updates correctly.

**Validations:**

- User balance increases correctly  
- `totalStaked` reflects the new deposit  
- Contract balance increases accordingly  
- User external balance decreases by the staked amount  

---

### ✅ Withdraw Fuzz Tests

**Property:**

> For any valid deposit and withdraw amount, withdrawals behave correctly.

**Constraints:**

- `withdrawAmount > 0`  
- `withdrawAmount <= depositAmount`  

**Validations:**

- User internal balance decreases correctly  
- `totalStaked` updates accordingly  
- Contract balance decreases  
- ETH is correctly returned to the user  

---

### ✅ Reward Accrual Fuzz Tests

**Property:**

> Rewards must increase over time for any valid stake and time duration.

**Constraints:**

- `amount > 0`  
- `timeJump > 0`  

**Validations:**

- Rewards after time progression are greater than zero  
- Stake and total supply remain consistent  

---

### ✅ Reward Preservation Fuzz Tests

**Property:**

> Accumulated rewards must not be lost after a partial withdrawal.

**Constraints:**

- `withdrawAmount < depositAmount` (strictly partial withdrawal)  
- `timeJump > 0`  

**Validations:**

- Rewards before and after withdrawal are equal  
- Rewards remain positive  
- User balance is updated correctly  

This ensures correct usage of:

```text
updateReward(user)
```
before modifying balances.

---
### ✅ Claim Reward Fuzz Tests

**Property:**

- Claiming rewards transfers the correct amount and resets accumulated rewards.

**Constraints:**

- Valid stake amount
- Reasonable time progression (bounded to avoid unrealistic reward growth)

**Validations:**

- User receives the exact accumulated reward
- Reward balance is reset to zero after claim

## ⚙️ Input Constraints

To ensure meaningful fuzzing, inputs are bounded using:

- vm.assume(...) for filtering invalid cases
- Controlled ranges for:
  - stake amounts
  - withdraw amounts
  - time progression

This prevents:

- invalid states (e.g. withdrawing more than deposited)
- unrealistic scenarios (e.g. extremely large time jumps)

---

## 🔒 Invariant Testing

Invariant tests verify that critical properties of the contract always hold true, regardless of the sequence of actions performed.

Unlike unit and fuzz tests, which validate specific scenarios, invariant tests ensure the system remains **consistent under arbitrary interactions**.

---

## 🏗️ Test Architecture

The invariant testing suite is composed of two main components:

---

### 1. Handler Contract (`SimpleStakingHandler`)

The handler acts as an intermediary that:

- Executes randomized actions on the contract
- Simulates multiple users interacting with the system
- Tracks historical values required for invariant validation

#### 👥 Users

- Three simulated users:
  - `alice`
  - `bob`
  - `charlie`
- Each user is funded with **1,000 ETH**

#### ⚙️ Available Actions

- `stake(userSeed, amount)`
  - Stakes a bounded random amount (`1 wei → 100 ETH`)
  - Selects user based on `userSeed`

- `withdraw(userSeed, amount)`
  - Withdraws a bounded amount up to the user’s balance

- `claimReward(userSeed)`
  - Claims accumulated rewards for a random user

- `warpTime(timeJump)`
  - Advances blockchain time (`1 second → 7 days`)

#### 📊 State Tracking

To validate monotonic properties, the handler keeps track of historical maximum values:

- `maxRewardPerTokenStoredSeen`
- `maxLastUpdateTimeSeen`

These values are updated after every interaction that may affect reward logic:
stake / withdraw / claimReward

This enables detection of **unexpected decreases** in critical state variables.

---

### 2. Invariant Tests (`SimpleStakingInvariantTest`)

The following invariants are enforced:

---

### 📌 invariant_TotalStakedEqualsSumOfTrackedBalances

**Definition:**

The global `totalStaked` must always equal the sum of all tracked user balances.

**Why it matters:**

- Ensures internal accounting is correct
- Prevents inconsistencies that could lead to fund loss or exploits

---

### 📌 invariant_UserBalanceNeverExceedsTotalStaked

**Definition:**

No individual user balance can exceed the total staked amount.

**Why it matters:**

- Prevents impossible states
- Guarantees logical consistency of balances

---

### 📌 invariant_GetVaultBalanceMatchesRealBalance

**Definition:**

The contract’s `getVaultBalance()` must match the actual ETH balance.

**Why it matters:**

- Ensures getters reflect real on-chain state
- Prevents misleading or manipulable outputs

---

### 📌 invariant_RewardPerTokenStoredNeverDecreases

**Definition:**

`rewardPerTokenStored` must be monotonic (never decrease).

**Why it matters:**

- This variable drives reward calculations
- A decrease would indicate a critical bug in reward distribution logic

**Implementation detail:**

- The handler tracks the maximum observed value
- The invariant ensures the contract value always matches this maximum

---

### 📌 invariant_LastUpdateTimeNeverDecreases

**Definition:**

`lastUpdateTime` must never decrease.

**Why it matters:**

- Reward calculations depend on time progression
- A decrease would break temporal consistency

**Implementation detail:**

- The handler tracks the maximum observed timestamp
- The invariant ensures the contract state never goes backwards in time

---
## ⚠️ Findings & Limitations
### 1. Rewards Are Paid From the Same Pool as Staked Funds

#### Description

In this implementation, staking rewards are paid directly from the contract's ETH balance:

```solidity
(bool success, ) = payable(msg.sender).call{value: reward}("");
```
This means that both:
 - *staked funds*
 - *rewards*
are sourced from the same pool.

---

### Impact
As users claim rewards over time, the contract balance decreases while `totalStkaed` remains unchanged.
This can lead to a state where:
```solidity
contract balance < totalStaked
```
Which breaks the assumption that the contract fully backs all staked funds.

---
### Root Cause
The contract does not distinguish between:
 - staking capital
 - reward funding
There is no separate mechanism to supply rewards.

---
### Why this Matters
In production DeFi protocol , this design would be unsafe because:
 - users could drain funds needed to back other stakers
 - the system becomes economically unsustainable
 - withdrawals may eventually fail

---

### Recommended Improvements
A production-ready design should:
 - introduce a dedicated reward pool (e.g. `fundRewards()` function), or
 - use a separate reward token instead of ETH, or
 - implement a sustainable reward emission model

---

## Education Note
This limitation is intentional in this project to keep the implementation simple and focus on testing and core staking mechanics.

---
## 🔎 Findings
## Severity
**Severity:** High (in production scenario)

## Exploit scenario
An attacker could: 
 1. Stake a large amount
 2. Wait for rewards to accumulate
 3. Claim rewards repeatedly
 4. Drain contract balance affecting other users

## Reward System Depends on Continuous User Interaction

#### Description

The reward calculation mechanism relies on user-triggered interactions (`stake`, `withdraw`, `claimReward`) to update the global state:

```solidity
rewardPerTokenStored = rewardPerToken();
lastUpdateTime = block.timestamp;
```
No automatic update occurs over time unless a user interacts with the contract.

### Impact
If no users interact with the contract for a long period:
 - rewards are not reflected in rewardPerTokenStored
 - the system appears "stale" until the next interaction
 - the first user to interact after inactivity triggers a large update

### Root Cause
The contract follows a lazy update model, where reward calculations are deferred until user interaction.

### Why This Matters
While this pattern is common in DeFi for gas efficiency, it introduces:
 - delayed state updates
 - dependence on user activity for correctness
 - potential uneven gas costs (first caller after long inactivity pays more gas)

### Recommended Improvements
Possible improvements include:
 - introducing periodic updates via automation (e.g. keepers)
 - limiting maximum time delta in reward calculations
 - documenting this behavior clearly for integrators

## Potential Precision Loss Due to Integer Division
Reward calculations rely on integer arithmetic:
```solidity
((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked;
```
Since Solidity does not support floating-point numbers, division truncates decimals.

### Impact
Over time, this can lead to:
 - small rounding errors
 - slight discrepancies in reward distribution
 - unallocated "dust" remaining in the contract

### Root Cause
Integer division in Solidity always rounds down, causing precision loss in fractional calculations.

### Why This Matters
In long-running systems or high-volume protocols:
 - rounding errors can accumulate
 - total distributed rewards may be slightly lower than expected
 - some value may remain locked in the contract

### Recommended Improvements
Common mitigation strategies:
 - using higher precision (e.g. 1e18 scaling, already applied here)
 - tracking and redistributing leftover dust
 - using more advanced accounting models if precision is critical

### Educational Note
This limitation is inherent to Solidity and appears in nearly all DeFi protocols. The key is to understand and manage its impact rather than eliminate it entirely.

---

## 🛠️ Tech Stack

- Solidity `^0.8.20`
- Foundry (`forge`)
- forge-std testing library

---

## ▶️ Running Tests

Run all tests:

```bash
forge test -vv
```

Run only staking tests:
```bash
forge test --match-contract SimpleStakingTest -vv
```
