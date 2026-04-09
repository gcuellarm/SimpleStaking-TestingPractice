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
