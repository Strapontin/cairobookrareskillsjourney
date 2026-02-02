import { RpcProvider } from "starknet";
import * as dotenv from "dotenv";

dotenv.config();

async function getTxnReceipt() {
    // Initialize RPC provider with Sepolia testnet endpoint
    const alchemyApiKey = process.env.ALCHEMY_API_KEY;

    // initialize provider for Sepolia testnet with Alchemy
    const provider = new RpcProvider({
      nodeUrl: `https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/${alchemyApiKey}`,
    });
    // Transaction hash to query (replace with actual hash)
    const transactionHash =
      "0x5df0e42012440f59eb9cdd7994a3001b72cebc781bd8527fb3a5343cdb9d6f7";

    try {
        // Fetch transaction receipt from the network
        const receipt: any = await provider.getTransactionReceipt(transactionHash);

        // Display formatted receipt data
        console.log(JSON.stringify(receipt, null, 2));
    } catch (error) {
        // Handle network or transaction errors
        console.error("Error getting transaction receipt:", error);
    }
}

// Execute the function
getTxnReceipt();