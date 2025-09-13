// scripts/deploy-tracking.js
const hre = require("hardhat");

async function main() {
  console.log("Starting TrackingWithTransparency contract deployment...");

  // Get the contract factory for your actual contract
  const TrackingWithTransparency = await hre.ethers.getContractFactory("TrackingWithTransparency");
  
  // Deploy the contract
  console.log("Deploying TrackingWithTransparency contract...");
  const tracking = await TrackingWithTransparency.deploy();
  
  // Wait for deployment to finish
  await tracking.waitForDeployment();
  
  const contractAddress = await tracking.getAddress();
  console.log("✅ TrackingWithTransparency contract deployed to:", contractAddress);

  // Test the deployed contract
  try {
    const contractInfo = await tracking.getContractInfo();
    console.log("Contract Version:", contractInfo.version);
    console.log("Contract Features:", contractInfo.features);
    
    const metrics = await tracking.getGlobalTransparencyMetrics();
    console.log("Initial Shipments:", metrics._totalShipments.toString());
  } catch (error) {
    console.log("Contract test failed:", error.message);
  }

  console.log("\nUpdate your .env file:");
  console.log(`CONTRACT_ADDRESS=${contractAddress}`);
  console.log(`LOCALHOST_CONTRACT_ADDRESS=${contractAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });