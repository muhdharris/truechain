// scripts/deploy-tracking.js
const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("🚀 Starting Tracking contract deployment...");

  // Get signers
  const [deployer] = await hre.ethers.getSigners();
  console.log("👤 Deploying with account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "ETH");

  // Get the contract factory
  const Tracking = await hre.ethers.getContractFactory("Tracking");
  
  // Deploy the contract
  console.log("📦 Deploying Tracking contract...");
  const tracking = await Tracking.deploy();
  
  // Wait for deployment to finish
  await tracking.waitForDeployment();
  
  const contractAddress = await tracking.getAddress();
  console.log("✅ Tracking contract deployed to:", contractAddress);

  // Get network information
  const network = hre.network.name;
  const chainId = (await hre.ethers.provider.getNetwork()).chainId;
  
  console.log("🌐 Network:", network);
  console.log("🔗 Chain ID:", chainId.toString());

  // Update .env file with new contract address
  const envPath = path.join(__dirname, '..', '.env');
  let envContent = '';
  
  if (fs.existsSync(envPath)) {
    envContent = fs.readFileSync(envPath, 'utf8');
  }

  // Update the product contract address for localhost
  const envKey = `LOCALHOST_PRODUCT_CONTRACT_ADDRESS`;
  const envLine = `${envKey}=${contractAddress}`;
  
  if (envContent.includes(envKey)) {
    // Replace existing line
    envContent = envContent.replace(
      new RegExp(`${envKey}=.*`), 
      envLine
    );
  } else {
    // Add new line
    envContent += `\n${envLine}`;
  }
  
  fs.writeFileSync(envPath, envContent);
  console.log(`✅ Updated .env with ${envKey}=${contractAddress}`);

  // Test the deployed contract
  console.log("\n🧪 Testing deployed contract...");
  
  try {
    // Test basic contract functions
    const totalProducts = await tracking.getProductCount();
    console.log("📊 Initial product count:", totalProducts.toString());
    
    const analyticsData = await tracking.getAnalyticsData();
    console.log("📈 Initial analytics data:", {
      totalProducts: analyticsData[0].toString(),
      totalVerifications: analyticsData[1].toString(),
      totalEvents: analyticsData[2].toString(),
      activeProducts: analyticsData[3].toString()
    });
    
    console.log("✅ Contract test successful!");
    
    // Register a test product
    console.log("\n🧪 Registering test product...");
    const tx = await tracking.registerProduct(
      "MYA001",
      "Sustainable Palm Oil Batch 1",
      "Palm Oil",
      "SKU-PALM-0020",
      hre.ethers.parseEther("0.1"), // 0.1 ETH
      1000,
      "Johor, Malaysia"
    );
    
    await tx.wait();
    console.log("✅ Test product MYA001 registered!");
    
    // Verify the test product
    console.log("🔍 Verifying test product...");
    const verifyTx = await tracking.verifyProduct(
      "MYA001",
      "Kuala Lumpur, Malaysia",
      250
    );
    
    await verifyTx.wait();
    console.log("✅ Test product MYA001 verified!");
    
    // Register another test product
    const tx2 = await tracking.registerProduct(
      "MYA002",
      "Sustainable Palm Oil Batch 2",
      "Palm Oil",
      "SKU-PALM-0021",
      hre.ethers.parseEther("0.12"),
      800,
      "Penang, Malaysia"
    );
    
    await tx2.wait();
    console.log("✅ Test product MYA002 registered!");
    
    // Check updated analytics
    const updatedAnalytics = await tracking.getAnalyticsData();
    console.log("📈 Updated analytics:", {
      totalProducts: updatedAnalytics[0].toString(),
      totalVerifications: updatedAnalytics[1].toString(),
      totalEvents: updatedAnalytics[2].toString(),
      activeProducts: updatedAnalytics[3].toString()
    });
    
    // Get recent products
    const recentProducts = await tracking.getRecentProducts(5);
    console.log("🆕 Recent products:", recentProducts);
    
  } catch (error) {
    console.log("❌ Contract test failed:", error.message);
  }

  // Create deployment info
  const deploymentInfo = {
    contractAddress: contractAddress,
    network: network,
    chainId: chainId.toString(),
    deploymentTime: new Date().toISOString(),
    deployer: deployer.address,
    contractName: "Tracking",
    version: "Enhanced for Analytics",
    testProductsRegistered: ["MYA001", "MYA002"],
    features: [
      "Product Registration",
      "Location Tracking",
      "Ownership Transfer", 
      "Verification Events",
      "Analytics Support",
      "Real-time Data"
    ]
  };

  // Save deployment info
  const deploymentsDir = path.join(__dirname, '..', 'deployments');
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  const deploymentFile = path.join(deploymentsDir, `tracking-${network}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  console.log("📄 Deployment info saved to:", deploymentFile);

  console.log("\n🎉 Deployment completed successfully!");
  console.log("=".repeat(60));
  console.log("📋 Summary:");
  console.log(`🔗 Contract Address: ${contractAddress}`);
  console.log(`🌐 Network: ${network}`);
  console.log(`🆔 Chain ID: ${chainId.toString()}`);
  console.log(`📊 Test Products: MYA001, MYA002 registered`);
  console.log(`🔍 Verifications: 1 verification recorded`);
  console.log("\n📋 Next steps:");
  console.log("1. Restart your Hardhat node if needed");
  console.log("2. Update your Flutter app's .env file (already updated)");
  console.log("3. Restart your Flutter app to load the new configuration");
  console.log("4. Test the blockchain analytics screen");
  console.log("5. Register more products to see real analytics data");
  
  console.log("\n🔧 Smart Contract Functions Available:");
  console.log("• registerProduct() - Register new products");
  console.log("• verifyProduct() - Verify product authenticity");
  console.log("• updateProductLocation() - Track product movement");
  console.log("• getAnalyticsData() - Get real-time analytics");
  console.log("• getRecentProducts() - Get latest registered products");
}

// Handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });