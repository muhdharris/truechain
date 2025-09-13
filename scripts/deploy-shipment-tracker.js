// scripts/deploy-shipment-tracker.js
const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying ShipmentTracker contract...");

  // Get the contract factory
  const ShipmentTracker = await ethers.getContractFactory("ShipmentTracker");
  
  // Deploy the contract
  const shipmentTracker = await ShipmentTracker.deploy();
  
  // Wait for deployment
  await shipmentTracker.deployed();
  
  console.log("✅ ShipmentTracker deployed to:", shipmentTracker.address);
  
  // Test the contract by creating a sample shipment
  console.log("\n🧪 Testing contract functionality...");
  
  const [owner] = await ethers.getSigners();
  console.log("👤 Using account:", owner.address);
  
  // Create a test shipment
  const tx = await shipmentTracker.createShipment(
    "TRC-TEST-001",
    "MYA001",
    "Premium Palm Oil",
    "Malaysia Oil Palm Plantation",
    "Singapore Distribution Center",
    ethers.utils.parseUnits("10", 0), // 10 metric tons
    owner.address // recipient
  );
  
  const receipt = await tx.wait();
  console.log("📦 Test shipment created. Transaction hash:", receipt.transactionHash);
  
  // Listen for events
  console.log("\n🎧 Setting up event listeners for MetaMask notifications...");
  
  // Listen for ShipmentCreated events
  shipmentTracker.on("ShipmentCreated", (shipmentId, productId, productName, fromLocation, toLocation, quantity, owner) => {
    console.log("🔔 MetaMask Notification - Shipment Created:");
    console.log(`   Shipment ID: ${shipmentId}`);
    console.log(`   Product: ${productName} (${productId})`);
    console.log(`   Route: ${fromLocation} → ${toLocation}`);
    console.log(`   Quantity: ${quantity} MT`);
    console.log(`   Owner: ${owner}`);
  });
  
  // Listen for ShipmentStatusChanged events
  shipmentTracker.on("ShipmentStatusChanged", (shipmentId, productId, status, location, timestamp) => {
    const statusNames = ["Pending", "In Transit", "Delivered"];
    console.log("🔔 MetaMask Notification - Status Update:");
    console.log(`   Shipment ID: ${shipmentId}`);
    console.log(`   Product ID: ${productId}`);
    console.log(`   New Status: ${statusNames[status]}`);
    console.log(`   Location: ${location}`);
    console.log(`   Timestamp: ${new Date(timestamp * 1000).toLocaleString()}`);
  });
  
  // Listen for ShipmentInTransit events
  shipmentTracker.on("ShipmentInTransit", (shipmentId, productId, currentLocation, timestamp, owner) => {
    console.log("🔔 MetaMask Notification - In Transit:");
    console.log(`   Shipment ID: ${shipmentId}`);
    console.log(`   Product ID: ${productId}`);
    console.log(`   Current Location: ${currentLocation}`);
    console.log(`   Time: ${new Date(timestamp * 1000).toLocaleString()}`);
  });
  
  // Listen for ShipmentDelivered events
  shipmentTracker.on("ShipmentDelivered", (shipmentId, productId, deliveryLocation, deliveryTime, recipient) => {
    console.log("🔔 MetaMask Notification - Delivered:");
    console.log(`   Shipment ID: ${shipmentId}`);
    console.log(`   Product ID: ${productId}`);
    console.log(`   Delivered to: ${deliveryLocation}`);
    console.log(`   Delivery Time: ${new Date(deliveryTime * 1000).toLocaleString()}`);
    console.log(`   Recipient: ${recipient}`);
  });
  
  // Test status updates
  console.log("\n🚛 Testing status updates...");
  
  // Start transit
  console.log("Starting transit...");
  const transitTx = await shipmentTracker.startTransit("TRC-TEST-001", "Port Klang, Malaysia");
  await transitTx.wait();
  
  // Wait a bit
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Update location
  console.log("Updating location...");
  const locationTx = await shipmentTracker.updateLocation("TRC-TEST-001", "Strait of Malacca");
  await locationTx.wait();
  
  // Wait a bit
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Complete delivery
  console.log("Completing delivery...");
  const deliveryTx = await shipmentTracker.completeDelivery("TRC-TEST-001", "Singapore Distribution Center");
  await deliveryTx.wait();
  
  console.log("\n🎉 Contract deployment and testing completed!");
  console.log("\n📋 Contract Information:");
  console.log("=====================================");
  console.log(`Contract Address: ${shipmentTracker.address}`);
  console.log(`Network: ${(await ethers.provider.getNetwork()).name}`);
  console.log(`Chain ID: ${(await ethers.provider.getNetwork()).chainId}`);
  console.log(`Deployer: ${owner.address}`);
  
  console.log("\n🔧 Configuration for Flutter App:");
  console.log("=====================================");
  console.log(`static const String shipmentContractAddress = '${shipmentTracker.address}';`);
  
  console.log("\n📱 Flutter Integration Steps:");
  console.log("=====================================");
  console.log("1. Update BlockchainConfig.shipmentContractAddress with the address above");
  console.log("2. Ensure your Flutter app is connected to the same network");
  console.log("3. Initialize ShipmentNotificationService in your app");
  console.log("4. Start creating shipments to see MetaMask notifications!");
  
  console.log("\n🔔 MetaMask Setup Instructions:");
  console.log("=====================================");
  console.log("1. Add Hardhat network to MetaMask:");
  console.log("   - Network Name: Hardhat Local");
  console.log("   - RPC URL: http://localhost:8545");
  console.log("   - Chain ID: 31337");
  console.log("   - Currency Symbol: ETH");
  console.log("2. Import test account with private key:");
  console.log("   - 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
  console.log("3. Make sure to watch the contract address for events");
  
  // Keep the process alive to continue listening for events
  console.log("\n⏳ Keeping process alive to monitor events...");
  console.log("Press Ctrl+C to stop monitoring");
  
  // Prevent the script from exiting
  process.stdin.resume();
}

main()
  .then(() => {
    // Don't exit, keep listening for events
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
  });