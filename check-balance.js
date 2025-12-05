// Script to check wallet balance on Arbitrum Sepolia
require('dotenv').config();
const Web3 = require('web3');

const ARBITRUM_SEPOLIA_RPC = 'https://sepolia-rollup.arbitrum.io/rpc';

async function checkBalance() {
  console.log('\n🔍 Checking Arbitrum Sepolia Wallet Balance...\n');

  try {
    const web3 = new Web3(ARBITRUM_SEPOLIA_RPC);

    // Get account from private key
    const account = web3.eth.accounts.privateKeyToAccount('0x' + process.env.PRIVATE_KEY);
    const address = account.address;

    console.log('Wallet Address:', address);

    // Get balance
    const balanceWei = await web3.eth.getBalance(address);
    const balanceEth = web3.utils.fromWei(balanceWei, 'ether');

    console.log('Balance:', balanceEth, 'ETH');
    console.log('Balance (Wei):', balanceWei);

    // Check network
    const networkId = await web3.eth.net.getId();
    console.log('Network ID:', networkId);
    console.log('Expected Network ID: 421614 (Arbitrum Sepolia)');

    if (networkId !== 421614n) {
      console.log('⚠️  Warning: Connected to wrong network!');
    }

    // Estimate deployment cost
    const gasPrice = await web3.eth.getGasPrice();
    const gasPriceGwei = web3.utils.fromWei(gasPrice, 'gwei');
    console.log('\nGas Price:', gasPriceGwei, 'Gwei');

    const estimatedGas = 8000000; // From truffle-config
    const estimatedCost = web3.utils.fromWei((BigInt(gasPrice) * BigInt(estimatedGas)).toString(), 'ether');
    console.log('Estimated Max Deployment Cost:', estimatedCost, 'ETH');

    if (parseFloat(balanceEth) > parseFloat(estimatedCost)) {
      console.log('\n✅ You have enough ETH to deploy!');
    } else {
      console.log('\n❌ Insufficient balance for deployment!');
      console.log('Please fund your wallet at:', address);
      console.log('Get testnet ETH from: https://faucet.triangleplatform.com/arbitrum/sepolia');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkBalance();
