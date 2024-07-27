Here's a detailed documentation explaining the function logic for the `NFTStaking` smart contract:

---

## `NFTStaking` Contract Documentation

### Overview

The `NFTStaking` contract allows users to stake ERC721 tokens and earn rewards in the form of ERC20 tokens. It includes functionalities for staking, unstaking, claiming rewards, and managing the staking process.

### State Variables

- `IERC721 public NFTcontract`: The ERC721 contract for the NFTs being staked.
- `IERC20 public RewardToken`: The ERC20 token used as a reward.
- `uint256 public RewardPerBlock`: The amount of reward tokens distributed per block.
- `uint256 public UnbondingPeriod`: The time period required before an unstaked NFT can be withdrawn.
- `uint256 public RewardClaimDelay`: The delay period before rewards can be claimed again.
- `bool public IsPaused`: Indicates whether the staking functionality is paused.

### Structs

- `struct Stake`: Represents an individual stake of an NFT by a user.
  - `uint256 tokenId`: The ID of the staked NFT.
  - `uint256 stakedAtBlock`: The timestamp when the NFT was staked.
  - `uint256 unstakedAtBlock`: The timestamp when the NFT was unstaked (0 if still staked).

### Mappings

- `mapping(address => Stake[]) public stakes`: Maps user addresses to their list of stakes.
- `mapping(address => uint256) public Rewards`: Maps user addresses to their accumulated rewards.
- `mapping(address => uint256) public LastClaimed`: Maps user addresses to the last time rewards were claimed.

### Events

- `event Staked(address indexed user, uint256 tokenId)`: Emitted when an NFT is staked.
- `event Unstaked(address indexed user, uint256 tokenId)`: Emitted when an NFT is unstaked.
- `event RewardClaimed(address indexed user, uint256 amount)`: Emitted when rewards are claimed.
- `event StakingPaused()`: Emitted when staking is paused.
- `event StakingUnpaused()`: Emitted when staking is unpaused.
- `event RewardPerBlockUpdated(uint256 newRewardPerBlock)`: Emitted when the reward per block is updated.

### Functions

#### `initialize`

```solidity
function initialize(
    address _NFTcontract,
    address _RewardToken,
    uint256 _RewardPerBlock,
    uint256 _UnbondingPeriod,
    uint256 _RewardClaimDelay
) external initializer
```

- **Purpose**: Initializes the contract with addresses for the NFT and reward token contracts, reward per block, unbonding period, and reward claim delay.
- **Access**: External, only callable once during contract deployment.

#### `checkPausedStatus`

```solidity
modifier checkPausedStatus()
```

- **Purpose**: Modifier to ensure that functions are not executed when staking is paused.
- **Usage**: Applied to functions that should not operate when staking is paused.

#### `_authorizeUpgrade`

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```

- **Purpose**: Allows the contract owner to authorize upgrades.
- **Access**: Internal, only callable by the contract owner.

#### `stake`

```solidity
function stake(uint256[] calldata _TokenIds) public checkPausedStatus
```

- **Purpose**: Allows users to stake one or more NFTs by providing their token IDs.
- **Access**: Public, requires staking to be active.
- **Logic**: Transfers NFTs from the user to the contract and records the stake details.

#### `unstake`

```solidity
function unstake(uint256[] calldata _TokenIds) public checkPausedStatus
```

- **Purpose**: Allows users to unstake one or more NFTs.
- **Access**: Public, requires staking to be active.
- **Logic**: Calls `unstakeToken` for each provided token ID.

#### `unstakeToken`

```solidity
function unstakeToken(address _user, uint256 _TokenId) internal
```

- **Purpose**: Internal function to handle the logic for unstaking a specific token.
- **Logic**: Marks the token as unstaked and emits an `Unstaked` event.

#### `withdrawNFT`

```solidity
function withdrawNFT(uint256 _TokenId) public
```

- **Purpose**: Allows users to withdraw NFTs after the unbonding period has elapsed.
- **Access**: Public.
- **Logic**: Transfers the NFT back to the user and removes the stake record.

#### `_removeStake`

```solidity
function _removeStake(address _user, uint256 _index) internal
```

- **Purpose**: Internal function to remove a stake from the list of a user's stakes.
- **Logic**: Replaces the removed stake with the last stake in the array and pops the last element.

#### `claimRewards`

```solidity
function claimRewards() public
```

- **Purpose**: Allows users to claim their accumulated rewards after the reward claim delay period.
- **Access**: Public.
- **Logic**: Calculates pending rewards, updates the last claimed timestamp, and transfers the rewards to the user.

#### `calculateRewards`

```solidity
function calculateRewards(address _user) public view returns (uint256)
```

- **Purpose**: Calculates the total rewards accrued by a user based on their stakes.
- **Access**: Public, view function.
- **Logic**: Computes the rewards for each stake based on the elapsed time and reward per block.

#### `pauseStaking`

```solidity
function pauseStaking() public onlyOwner
```

- **Purpose**: Pauses the staking functionality.
- **Access**: Public, only callable by the contract owner.
- **Logic**: Sets `IsPaused` to true and emits a `StakingPaused` event.

#### `unpauseStaking`

```solidity
function unpauseStaking() public onlyOwner
```

- **Purpose**: Unpauses the staking functionality.
- **Access**: Public, only callable by the contract owner.
- **Logic**: Sets `IsPaused` to false and emits a `StakingUnpaused` event.

#### `updateRewardPerBlock`

```solidity
function updateRewardPerBlock(uint256 _RewardPerBlock) public onlyOwner
```

- **Purpose**: Updates the reward amount per block.
- **Access**: Public, only callable by the contract owner.
- **Logic**: Sets a new reward per block value and emits a `RewardPerBlockUpdated` event.

#### `getStakes`

```solidity
function getStakes(address _user) public view returns (Stake[] memory)
```

- **Purpose**: Returns the list of stakes for a specific user.
- **Access**: Public, view function.

#### `onERC721Received`

```solidity
function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4)
```

- **Purpose**: Implements the `IERC721Receiver` interface to handle incoming ERC721 token transfers.
- **Logic**: Returns the selector for the `onERC721Received` function to accept the token.

---

This documentation should provide a comprehensive understanding of the `NFTStaking` contract and its functionalities. If you need further details or clarifications, feel free to ask!