const BookToken = artifacts.require("BookToken");
const BookLending = artifacts.require("BookLending");

module.exports = async function (deployer, network, accounts) {
  console.log("\n========================================");
  console.log("Starting BookLending Platform Deployment");
  console.log("========================================\n");
  console.log("Network:", network);
  console.log("Deployer:", accounts[0]);
  console.log("\n");

  // 1. Deploy BookToken contract
  console.log("📚 Step 1: Deploying BookToken...");
  await deployer.deploy(BookToken);

  const bookTokenInstance = await BookToken.deployed();
  const bookTokenAddress = bookTokenInstance.address;

  console.log("✅ BookToken deployed at:", bookTokenAddress);
  console.log("\n");

  // 2. Deploy BookLending contract
  console.log("📖 Step 2: Deploying BookLending...");
  console.log("   Using BookToken address:", bookTokenAddress);

  await deployer.deploy(BookLending, bookTokenAddress);

  const bookLendingInstance = await BookLending.deployed();
  const bookLendingAddress = bookLendingInstance.address;

  console.log("✅ BookLending deployed at:", bookLendingAddress);
  console.log("\n");

  // 3. Transfer BookToken ownership to BookLending
  console.log("🔐 Step 3: Transferring BookToken ownership to BookLending...");
  await bookTokenInstance.transferOwnership(bookLendingAddress);
  console.log("✅ Ownership transferred successfully");
  console.log("\n");

  // 4. Display deployment summary
  console.log("========================================");
  console.log("Deployment Summary");
  console.log("========================================");
  console.log("BookToken Address:    ", bookTokenAddress);
  console.log("BookLending Address:  ", bookLendingAddress);
  console.log("========================================\n");

  // Save addresses to a file for backend use
  const fs = require('fs');
  const deploymentInfo = {
    network: network,
    bookToken: bookTokenAddress,
    bookLending: bookLendingAddress,
    deployer: accounts[0],
    timestamp: new Date().toISOString()
  };

  const outputPath = __dirname + '/../deployment-info.json';
  fs.writeFileSync(
    outputPath,
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("📝 Deployment info saved to:", outputPath);
  console.log("\n✨ Deployment completed successfully!\n");
};