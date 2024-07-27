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
