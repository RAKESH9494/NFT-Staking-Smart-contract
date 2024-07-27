// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTStaking is UUPSUpgradeable, OwnableUpgradeable,IERC721Receiver {

    // State variables
    IERC721 public NFTcontract; 
    IERC20 public RewardToken; 
    uint256 public RewardPerBlock; 
    uint256 public UnbondingPeriod;
    uint256 public RewardClaimDelay; 
    bool public IsPaused; 

    // User stake Info
    struct Stake {
        uint256 tokenId;
        uint256 stakedAtBlock;
        uint256 unstakedAtBlock;
    }

    mapping(address => Stake[]) public stakes; 
    mapping(address => uint256) public Rewards; 
    mapping(address => uint256) public LastClaimed; 

    // Events
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event RewardClaimed(address indexed user, uint256 amount);
    event StakingPaused();
    event StakingUnpaused();
    event RewardPerBlockUpdated(uint256 newRewardPerBlock);

    // Initializing the states 
    function initialize(
        address _NFTcontract,
        address _RewardToken,
        uint256 _RewardPerBlock,
        uint256 _UnbondingPeriod,
        uint256 _RewardClaimDelay
    ) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        NFTcontract = IERC721(_NFTcontract);
        RewardToken = IERC20(_RewardToken);
        RewardPerBlock = _RewardPerBlock;
        UnbondingPeriod = _UnbondingPeriod;
        RewardClaimDelay = _RewardClaimDelay;
    }

    // Checks the stake is paused or not
    modifier checkPausedStatus() {
        require(!IsPaused, "Staking is paused");
        _;
    }

    // For contract upgrade
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Staking one or multiple tokens
    function stake(uint256[] calldata _TokenIds) public checkPausedStatus {
        for (uint256 i = 0; i < _TokenIds.length; i++) {
            NFTcontract.safeTransferFrom(msg.sender, address(this), _TokenIds[i]);
            stakes[msg.sender].push(Stake(_TokenIds[i], block.timestamp, 0));
            emit Staked(msg.sender, _TokenIds[i]);
        }
    }

    // Unstaking tokens 
    function unstake(uint256[] calldata _TokenIds) public checkPausedStatus {
        for (uint256 i = 0; i < _TokenIds.length; i++) {
            unstakeToken(msg.sender, _TokenIds[i]);
        }
    }

    // Access through each user's token and update the states
    function unstakeToken(address _user, uint256 _TokenId) internal {
        Stake[] storage userStakes = stakes[_user]; 
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].tokenId == _TokenId && userStakes[i].unstakedAtBlock == 0) {
                userStakes[i].unstakedAtBlock = block.timestamp; 
                emit Unstaked(_user, _TokenId);
                return;
            }
        }
        revert("Already Unstaked or not staked");
    }

    // Withdrawing the NFTs from contract
    function withdrawNFT(uint256 _TokenId) public{
        Stake[] storage userStakes = stakes[msg.sender]; 
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].tokenId == _TokenId && block.timestamp >= userStakes[i].unstakedAtBlock + UnbondingPeriod) {
                NFTcontract.safeTransferFrom(address(this), msg.sender, _TokenId);
                _removeStake(msg.sender, i); 
                return;
            }
        }
        revert("Unbonding period not over or token not unstaked");
    }

    // Internal function to remove stakes
    function _removeStake(address _user, uint256 _index) internal {
        Stake[] storage userStakes = stakes[_user]; 
        userStakes[_index] = userStakes[userStakes.length - 1]; 
        userStakes.pop();
    }

    // Claiming rewards after delay period
    function claimRewards() public{
        require(block.timestamp >= LastClaimed[msg.sender] + RewardClaimDelay, "Only after claim delay");
        uint256 pendingRewards = calculateRewards(msg.sender); 
        Rewards[msg.sender] = 0; 
        LastClaimed[msg.sender] = block.timestamp;
        RewardToken.transfer(msg.sender, pendingRewards);
        emit RewardClaimed(msg.sender, pendingRewards);
    }

    // Calculating rewards for a user
    function calculateRewards(address _user) public view returns (uint256) {
        Stake[] storage userStakes = stakes[_user]; 
        uint256 totalRewards = Rewards[_user]; 

        for (uint256 i = 0; i < userStakes.length; i++) {
            uint256 stakedperiod = userStakes[i].unstakedAtBlock == 0 ? block.timestamp : userStakes[i].unstakedAtBlock;
            totalRewards += (stakedperiod - userStakes[i].stakedAtBlock) * RewardPerBlock;
        }
        return totalRewards;
    }

    // Pausing the staking
    function pauseStaking() public onlyOwner {
        IsPaused = true;
        emit StakingPaused();
    }

    // Unpausing the staking
    function unpauseStaking() public onlyOwner {
        IsPaused = false; 
        emit StakingUnpaused();
    }

    // Updating the reward per block
    function updateRewardPerBlock(uint256 _RewardPerBlock) public onlyOwner {
        RewardPerBlock = _RewardPerBlock;
        emit RewardPerBlockUpdated(_RewardPerBlock);
    }

    //Loging stakes

    function getStakes(address _user) public view returns(Stake[] memory){
        return stakes[_user];
    }

    // Implementing the IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
