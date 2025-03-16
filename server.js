require('dotenv').config();
const { JSONRPCServer } = require('json-rpc-2.0');
const express = require('express');
const bodyParser = require('body-parser');
const { ethers } = require('ethers');
const cors = require('cors');

// Initialize express app
const app = express();
app.use(cors());
app.use(bodyParser.json());

// Initialize JSON-RPC server
const server = new JSONRPCServer();

// Transaction inclusion check function
async function checkTransactionInclusion(txHash, rpcUrl, maxAttempts = 10, initialDelay = 1000) {
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    let attempts = 0;
    let delay = initialDelay;

    console.log(`Checking inclusion for transaction: ${txHash}`);

    while (attempts < maxAttempts) {
        attempts++;
        try {
            // Call eth_getTransactionReceipt RPC method
            const receipt = await provider.getTransactionReceipt(txHash);

            if (receipt) {
                // Transaction is included in a block
                const confirmations = receipt.confirmations;
                console.log(`✅ Transaction included in block #${receipt.blockNumber}`);
                console.log(`Confirmations: ${confirmations}`);
                console.log(`Status: ${receipt.status === 1 ? 'Success' : 'Failed'}`);
                console.log(`Gas used: ${receipt.gasUsed.toString()}`);

                // Check for minimum confirmations
                if (confirmations < parseInt(process.env.MIN_CONFIRMATIONS || "3")) {
                    console.log(`⚠️ Only ${confirmations} confirmations, waiting for ${process.env.MIN_CONFIRMATIONS}...`);

                    // Continue polling for more confirmations
                    delay = Math.min(delay * 1.5, 15000);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    continue;
                }

                return receipt;
            }

            console.log(`⏳ Attempt ${attempts}/${maxAttempts}: Transaction not yet included...`);

            // Implement exponential backoff
            delay = Math.min(delay * 1.5, 15000); // Cap at 15 seconds
            await new Promise(resolve => setTimeout(resolve, delay));

        } catch (error) {
            console.error(`❌ Error checking transaction: ${error.message}`);
            // Continue polling despite errors
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    throw new Error(`Transaction not included after ${maxAttempts} attempts`);
}

// Function to verify donation transaction
async function verifyDonationTransaction(txHash, expectedSender, expectedRecipient, expectedMinAmount) {
    try {
        const rpcUrl = process.env.RPC_URL;
        if (!rpcUrl) {
            throw new Error("RPC_URL not configured in environment");
        }

        const receipt = await checkTransactionInclusion(txHash, rpcUrl);
        if (!receipt || receipt.status !== 1) {
            console.log("❌ Transaction failed or doesn't exist");
            return false;
        }

        // Get full transaction details
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
        const tx = await provider.getTransaction(txHash);

        // Verify sender (case insensitive comparison)
        const normalizedSender = expectedSender.toLowerCase();
        const normalizedTxSender = tx.from.toLowerCase();
        if (normalizedTxSender !== normalizedSender) {
            console.log(`❌ Sender mismatch: expected ${normalizedSender}, got ${normalizedTxSender}`);
            return false;
        }

        // Verify recipient (case insensitive comparison)
        const normalizedRecipient = expectedRecipient.toLowerCase();
        const normalizedTxRecipient = tx.to.toLowerCase();
        if (normalizedTxRecipient !== normalizedRecipient) {
            console.log(`❌ Recipient mismatch: expected ${normalizedRecipient}, got ${normalizedTxRecipient}`);
            return false;
        }

        // Verify amount
        const txValue = tx.value;
        if (txValue.lt(ethers.BigNumber.from(expectedMinAmount))) {
            console.log(`❌ Amount too low: expected at least ${expectedMinAmount}, got ${txValue.toString()}`);
            return false;
        }

        console.log(`✅ Transaction verified successfully`);
        return true;
    } catch (error) {
        console.error(`❌ Error verifying donation: ${error.message}`);
        return false;
    }
}

// Helper function to extract field values from Noir format
function extractFieldValue(field) {
    if (field && field.Single && field.Single.inner) {
        return field.Single.inner;
    }
    // Handle cases where it might be a direct string
    return typeof field === 'string' ? field : '';
}

// Add direct verifyDonation method to handle the format you're receiving
server.addMethod("verifyDonation", async (params) => {
    console.log("Direct verifyDonation call received:", JSON.stringify(params, null, 2));

    try {
        // Parse parameters from the direct call
        const [txHashObj, senderObj, recipientObj, minAmountObj] = params;

        // Extract the inner values
        const txHashHex = extractFieldValue(txHashObj);
        const senderHex = extractFieldValue(senderObj);
        const recipientHex = extractFieldValue(recipientObj);
        const minAmountHex = extractFieldValue(minAmountObj);

        // Convert to proper format for verification
        const txHash = `0x${txHashHex}`;
        const sender = `0x${senderHex.slice(24)}`; // Remove padding to get standard Ethereum address
        const recipient = `0x${recipientHex.slice(24)}`; // Remove padding to get standard Ethereum address
        const minAmount = ethers.BigNumber.from(`0x${minAmountHex}`).toString();

        console.log(`Verifying donation transaction:`);
        console.log(`- TX Hash: ${txHash}`);
        console.log(`- Sender: ${sender}`);
        console.log(`- Recipient: ${recipient}`);
        console.log(`- Min Amount: ${minAmount}`);

        // Verify the donation transaction
        const isValid = await verifyDonationTransaction(
            txHash,
            sender,
            recipient,
            minAmount
        );

        console.log(`Verification result: ${isValid ? "VALID" : "INVALID"}`);
        
        // Format the response in the way Noir expects with the Single variant
        const response = {
            values: [
                {
                    Single: {
                        inner: isValid ? "1" : "0"
                    }
                }
            ]
        };
        
        console.log(`Returning response: ${JSON.stringify(response, null, 2)}`);

        // Return in the format expected by Noir
        return response;

    } catch (error) {
        console.error("Error in verifyDonation:", error);
        
        // Format error response in the way Noir expects
        const errorResponse = {
            values: [
                {
                    Single: {
                        inner: "0"
                    }
                }
            ]
        };
        
        console.log(`Returning error response: ${JSON.stringify(errorResponse, null, 2)}`);
        return errorResponse; // Return invalid on error
    }
});

// Also keep the resolve_foreign_call method for standard Noir oracle integration
server.addMethod("resolve_foreign_call", async (params) => {
    console.log("Oracle call received:", JSON.stringify(params, null, 2));

    if (params[0].function !== "verifyDonation") {
        throw Error(`Unexpected foreign call: ${params[0].function}`);
    }

    try {
        // Parse parameters from the call
        const inputs = params[0].inputs;

        if (!Array.isArray(inputs) || inputs.length !== 1 || !Array.isArray(inputs[0]) || inputs[0].length !== 4) {
            console.log(`Invalid inputs format: ${JSON.stringify(inputs)}`);
            throw new Error(`Invalid inputs format. Expected array with nested array of 4 elements.`);
        }

        const [txHashHex, senderHex, recipientHex, minAmountHex] = inputs[0];

        // Convert hex strings to proper format if needed
        const txHash = txHashHex.startsWith('0x') ? txHashHex : `0x${txHashHex}`;
        const sender = senderHex.startsWith('0x') ? senderHex : `0x${senderHex}`;
        const recipient = recipientHex.startsWith('0x') ? recipientHex : `0x${recipientHex}`;
        const minAmount = minAmountHex; // Already a numeric string

        console.log(`Verifying donation transaction:`);
        console.log(`- TX Hash: ${txHash}`);
        console.log(`- Sender: ${sender}`);
        console.log(`- Recipient: ${recipient}`);
        console.log(`- Min Amount: ${minAmount}`);

        // Verify the donation transaction
        const isValid = await verifyDonationTransaction(
            txHash,
            sender,
            recipient,
            minAmount
        );

        console.log(`Verification result: ${isValid ? "VALID" : "INVALID"}`);
        
        // Format the response in the way Noir expects with the Single variant
        const response = {
            values: [
                {
                    Single: {
                        inner: isValid ? "1" : "0"
                    }
                }
            ]
        };
        
        console.log(`Returning response: ${JSON.stringify(response, null, 2)}`);

        // Return in the format expected by Noir
        return response;

    } catch (error) {
        console.error("Error in resolve_foreign_call:", error);
        
        // Format error response in the way Noir expects
        const errorResponse = {
            values: [
                {
                    Single: {
                        inner: "0"
                    }
                }
            ]
        };
        
        console.log(`Returning error response: ${JSON.stringify(errorResponse, null, 2)}`);
        return errorResponse; // Return invalid on error
    }
});

// Set up express routes
app.post("/", (req, res) => {
    const jsonRPCRequest = req.body;

    console.log(`Received request: ${JSON.stringify(jsonRPCRequest, null, 2)}`);

    server.receive(jsonRPCRequest).then((jsonRPCResponse) => {
        if (jsonRPCResponse) {
            console.log(`Sending response: ${JSON.stringify(jsonRPCResponse, null, 2)}`);
            res.json(jsonRPCResponse);
        } else {
            console.log("No response to send, sending 204");
            res.sendStatus(204);
        }
    }).catch(error => {
        console.error("Error processing request:", error);
        res.status(500).json({
            jsonrpc: "2.0",
            error: {
                code: -32603,
                message: "Internal error",
                data: { message: error.message }
            },
            id: jsonRPCRequest.id
        });
    });
});

// Add a health check endpoint
app.get("/health", (req, res) => {
    res.json({ status: "ok" });
});

// Start the server
const PORT = process.env.PORT || 5555;
app.listen(PORT, () => {
    console.log(`Oracle server running on port ${PORT}`);
    console.log(`RPC URL: ${process.env.RPC_URL}`);
    console.log(`Minimum confirmations: ${process.env.MIN_CONFIRMATIONS || "3"}`);
});