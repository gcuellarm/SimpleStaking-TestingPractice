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

## 🛠️ Tech Stack

- Solidity `^0.8.20`
- Foundry (`forge`)
- forge-std testing library

---

## ▶️ Running Tests

Run all tests:

```bash
forge test -vv

Run only staking tests:

forge test --match-contract SimpleStakingTest -vv
