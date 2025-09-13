const { ethers } = require("hardhat");

async function main() {
  const network = hre.network.name;
  console.log(`🔍 Checking balances on ${network} network...\n`);

  // Get signers
  const signers = await ethers.getSigners();
  
  for (let i = 0; i < Math.min(signers.length, 5); i++) {
    const signer = signers[i];
    const balance = await signer.provider.getBalance(signer.address);
    const balanceEth = ethers.formatEther(balance);
    
    console.log(`📋 Account #${i}:`);
    console.log(`   Address: ${signer.address}`);
    console.log(`   Balance: ${balanceEth} ETH`);
    
    if (parseFloat(balanceEth) === 0) {
      console.log(`   ⚠️  No funds! Fund this address using faucets.`);
    } else if (parseFloat(balanceEth) < 0.01) {
      console.log(`   ⚠️  Low balance! Consider adding more funds.`);
    } else {
      console.log(`   ✅ Good balance for deployment.`);
    }
    console.log("");
  }

  // Show faucet links for testnets
  if (network === 'holesky') {
    console.log("🚰 Holesky Faucets:");
    console.log("   • https://holesky-faucet.pk910.de/");
    console.log("   • https://faucet.quicknode.com/ethereum/holesky");
    console.log("   • https://sepoliafaucet.com/");
  } else if (network === 'sepolia') {
    console.log("🚰 Sepolia Faucets:");
    console.log("   • https://sepoliafaucet.com/");
    console.log("   • https://faucet.quicknode.com/ethereum/sepolia");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });