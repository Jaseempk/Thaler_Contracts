// Import required Noir standard library components
use dep::std;

// Define the oracle to verify donations
#[oracle(verifyDonation)]
unconstrained fn verify_donation(_tx_hash: Field, _sender: Field, _recipient: Field, _min_amount: Field) -> Field {}

// Unconstrained function to call the oracle
unconstrained fn donation_verified(
    tx_hash: Field,
    sender: Field,
    recipient: Field,
    min_amount: Field
) -> Field {
    verify_donation(tx_hash, sender, recipient, min_amount)
}

// Main function to prove a donation was made before withdrawal
fn main(
    tx_hash: Field, // Hash of the donation transaction
    sender: Field, // Address that made the donation (should match withdrawal caller)
    recipient: Field, // Donation recipient address
    donation_amount: Field // Amount donated
) {
    // Verify the donation transaction occurred and is valid
    let is_valid = donation_verified(tx_hash, sender, recipient, donation_amount);

    // Constrain that the transaction is valid (1 means valid, 0 means invalid)
    assert(is_valid == 1);
}

// Test function
#[test]
fn test_donation_verification() {
    // For testing, you would provide real transaction data
    // These values would need to be updated with real data
    let test_tx_hash = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
    let test_sender = 0x1111111111111111111111111111111111111111;
    let test_recipient = 0x2222222222222222222222222222222222222222;
    let test_donation = 1000000000000000000; // 1 ETH in wei

    // This should pass if oracle verifies the transaction
    main(test_tx_hash, test_sender, test_recipient, test_donation);
}
