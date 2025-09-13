const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying ProductTracking contract...");

  const ProductTracking = await hre.ethers.getContractFactory("ProductTracking");
  const productTracking = await ProductTracking.deploy();
  
  await productTracking.waitForDeployment();
  const contractAddress = await productTracking.getAddress();
  
  console.log("✅ ProductTracking deployed to:", contractAddress);
  console.log("📝 Update your .env file with:");
  console.log(`LOCALHOST_PRODUCT_CONTRACT_ADDRESS=${contractAddress}`);
  
  // Test deployment
  const productCount = await productTracking.getProductCount();
  console.log("✅ Contract working, product count:", productCount.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });