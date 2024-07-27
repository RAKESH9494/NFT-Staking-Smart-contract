const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("NFTStaking", function () {
    let NFTStaking, staking, NFT, RewardToken, nft, rewardToken;
    let owner, user1, user2;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        
        // Deploying ERC721 contract for NFTs 
        NFT = await ethers.getContractFactory("ERC721Mock");
        nft = await NFT.deploy("TestNFT", "TNFT");
        
        // Deploying ERC20 contract for RewardToken
        RewardToken = await ethers.getContractFactory("ERC20Mock");
        rewardToken = await RewardToken.deploy("TestRewardToken", "TRT");
       
        // Deploy NFTStaking contract
        NFTStaking = await ethers.getContractFactory("NFTStaking");
        staking = await upgrades.deployProxy(NFTStaking, [await nft.getAddress(), await rewardToken.getAddress(), 1, 100, 10], { initializer: 'initialize' });

        // Mint some NFTs and reward tokens
        await nft.mint(user1, 1);
        await nft.mint(user1, 2);
        await rewardToken.transfer(await staking.getAddress(), 10000);
    });

    it("should allow a user to stake NFTs", async function () {
        await nft.connect(user1).setApprovalForAll(await staking.getAddress(), true);
        await staking.connect(user1).stake([1, 2]);
        const userStakes = await staking.getStakes(user1);
        expect(userStakes.length).to.equal(2);
        expect(userStakes[0].tokenId).to.equal(1);
        expect(userStakes[1].tokenId).to.equal(2);
    });

    it("should allow a user to unstake NFTs", async function () {
        await nft.connect(user1).setApprovalForAll(await staking.getAddress(), true);
        await staking.connect(user1).stake([1, 2]);

        await staking.connect(user1).unstake([1]);
        const userStakes = await staking.getStakes(user1);
        expect(userStakes[0].unstakedAtBlock).to.not.equal(0);
    });

    it("should allow a user to withdraw NFTs after the unbonding period", async function () {
        await nft.connect(user1).setApprovalForAll(await staking.getAddress(), true);
        await staking.connect(user1).stake([1]);
        await staking.connect(user1).unstake([1]);

        await ethers.provider.send("evm_increaseTime", [100*15]);
        await ethers.provider.send("evm_mine");

        await staking.connect(user1).withdrawNFT(1);
        expect(await nft.ownerOf(1)).to.equal(user1);
    });

    it("should allow a user to claim rewards after the claim delay", async function () {
        await nft.connect(user1).setApprovalForAll(await staking.getAddress(), true);
        await staking.connect(user1).stake([1]);

        // Simulate waiting period
        await ethers.provider.send("evm_increaseTime", [11]);
        await ethers.provider.send("evm_mine");

        await staking.connect(user1).claimRewards();

        const rewardBalance = await rewardToken.balanceOf(user1.address);
        expect(rewardBalance).to.be.gt(0);
    });

    it("should handle pausing and unpausing staking", async function () {
        await staking.pauseStaking();
        await expect(staking.connect(user1).stake([1])).to.be.revertedWith("Staking is paused");

        await staking.unpauseStaking();
        await nft.connect(user1).setApprovalForAll(await staking.getAddress(), true);
        await staking.connect(user1).stake([1]);

        const userStakes = await staking.getStakes(user1.address);
        expect(userStakes.length).to.equal(1);
    });

    it("should update the reward per time", async function () {
        await staking.updateRewardPerBlock(2);
        expect(await staking.RewardPerBlock()).to.equal(2);
    });

});
