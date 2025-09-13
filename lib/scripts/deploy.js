// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  console.log("Starting TrackingWithTransparency contract deployment...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Get the contract factory - use the exact name from your .sol file
  const TrackingWithTransparency = await hre.ethers.getContractFactory("TrackingWithTransparency");
  
  console.log("Deploying TrackingWithTransparency contract...");
  
  // Deploy the contract
  const trackingContract = await TrackingWithTransparency.deploy();
  
  // Wait for deployment to be mined
  await tracking.deployed();
  
  console.log("✅ TrackingWithTransparency deployed to:", tracking.address);
  console.log("Transaction hash:", tracking.deployTransaction.hash);
  console.log("Block number:", tracking.deployTransaction.blockNumber);
  
  // Get contract info to verify deployment
  try {
    const contractInfo = await tracking.getContractInfo();
    console.log("📋 Contract Info:");
    console.log("  Version:", contractInfo.version);
    console.log("  Features:", contractInfo.features);
    console.log("  Description:", contractInfo.description);
  } catch (e) {
    console.log("Could not get contract info:", e.message);
  }
  
  // Test basic functionality
  try {
    const metrics = await tracking.getGlobalTransparencyMetrics();
    console.log("📊 Initial Metrics:");
    console.log("  Total Shipments:", metrics._totalShipments.toString());
    console.log("  Verified Shipments:", metrics._totalVerifiedShipments.toString());
    console.log("  Completed Shipments:", metrics._totalCompletedShipments.toString());
    console.log("  Transparency Rate:", metrics._transparencyRate.toString() + "%");
  } catch (e) {
    console.log("Could not get metrics:", e.message);
  }
  
  console.log("\n🔧 Configuration:");
  console.log("  Contract Address:", tracking.address);
  console.log("  Network:", await ethers.provider.getNetwork());
  console.log("  Gas Used:", tracking.deployTransaction.gasUsed?.toString());
  
  console.log("\n📝 Update your .env file:");
  console.log(`CONTRACT_ADDRESS=${tracking.address}`);
  console.log(`LOCALHOST_CONTRACT_ADDRESS=${tracking.address}`);
}

main()
  .then(() => {
    console.log("\n✅ Deployment completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });