const hre = require("hardhat");

async function main() {
  console.log("🚀 Simple deployment test...");
  
  try {
    const Tracking = await hre.ethers.getContractFactory("Tracking");
    console.log("✅ Contract factory created");
    
    const tracking = await Tracking.deploy();
    console.log("✅ Deploy transaction sent");
    
    await tracking.waitForDeployment();
    console.log("✅ Deployment confirmed");
    
    const address = await tracking.getAddress();
    console.log("📍 Contract address:", address);
    
  } catch (error) {
    console.error("❌ Deployment error:", error.message);
  }
}

main();