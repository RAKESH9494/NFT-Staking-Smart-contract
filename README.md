# Instructions on how to deploy, test, and interact with the contract.

### **1. Set Up Hardhat Project**

1. **Create a New Project Directory:**
   ```bash
   mkdir NFt-Staking
   cd NFt-Staking
   ```

2. **Initialize a Hardhat Project:**
   ```bash
   npm install --save-dev hardhat
   npx hardhat
   ```
   Choose the "Create a basic sample project" option when prompted.

3. **Install Dependencies:**
   ```bash
   npm install @openzeppelin/contracts-upgradeable @openzeppelin/contracts @nomiclabs/hardhat-ethers ethers @openzeppelin/hardhat-upgrades
   ```

### **2. Configure Hardhat**

Edit `hardhat.config.js` to include the testnet setting:

```javascript

require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "",
  networks: {
    hardhat: {},
    testnet: {
      url: API_URL, //API key should get from the providers like Alchemy, infura etc.
      accounts: [`0x${PRIVATE_KEY}`] // Private key of the owner's address
    }
  },
}


```

### **3. Create Deployment Script**

Create a file `scripts/deploy.js`:

```javascript
const hre = require("hardhat");

async function main() {
    const NFTContractAddress = "0x..."; // ERC721 contract address
    const TokenAddress = "0x..."; // ERC20 token address(reward purpose)
    const RewardPerBlock = 10 ; //
    const UnbondingPeriod = 10 * 24 * 60 * 60; // 10 days  
    const RewardClaimDelay = 5 * 24 * 60 * 60; // 5 days


    // Deploy the contract with upgradeable proxy
    const NFTStaking = await hre.ethers.getContractFactory("NFTStaking");
    const nftStaking = await upgrades.deployProxy(NFTStaking, [NFTContractAddress,TokenAddress,RewardPerBlock,UnbondingPeriod,RewardClaimDelay], { initializer: 'initialize' });

    console.log("NFTStaking deployed to:", nftStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

```

### **4. Deploy the Contract**

To deploy to test, run:

```bash
npx hardhat run scripts/deploy.js --network testnet
```

### **5. Testing the Contract**

1. **Write Tests:**

   Create a test file in the `test` directory, e.g., `test/test.js`:

   ```javascript
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

   ```

2. **Run Tests:**

   ```bash
   npx hardhat test
   ```

### **6. Interact with the Contract**

To interact with the deployed contract, we can use a script or a tool like Hardhat Console:

1. **Create Interaction Script:**

   Create a file `scripts/interact.js`:

   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       const [deployer] = await ethers.getSigners();
       const nftStakingAddress = "0x..."; // deployed NFTStaking address
       const NFTStaking = await ethers.getContractFactory("NFTStaking");
       const nftStaking = await NFTStaking.attach(nftStakingAddress);

       // Loging rewards
       const reward = await nftStaking.calculateRewards(user_address);
       console.log("Pending Rewards:", ethers.utils.formatUnits(reward, 18));

       //Staking nfts

        const NFT = await ethers.getContractFactory("ERC721Mock");
        const nft = await NFT.attach(nftAddress);

        // Mint an NFT for the user 
        await nft.mint(user.address, 1);
        await nft.connect(user).approve(nftStaking.address, 1);

        // Stake the NFT
        await nftStaking.connect(user).stake([1]);

        console.log("NFT Staked");

        // Get the stakes of the user
        const stakes = await nftStaking.getStakes(user.address);
        console.log("Stakes:", stakes);


   }

   main()
       .then(() => process.exit(0))
       .catch((error) => {
           console.error(error);
           process.exit(1);
       });
   ```

2. **Run Interaction Script:**

   ```bash
   npx hardhat run scripts/interact.js --network testnet
   ```

### **Summary**

1. **Deploy**: Use `npx hardhat run scripts/deploy.js --network rinkeby`.
2. **Test**: Write tests in the `test` directory and run them with `npx hardhat test`.
3. **Interact**: Write interaction scripts in the `scripts` directory and run them with `npx hardhat run scripts/interact.js --network rinkeby`.

These steps should cover the basics of deploying, testing, and interacting with your `NFTStaking` contract. If you have any specific questions or run into issues, feel free to ask!
