// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MockVerifier
 * @notice A mock implementation of the IVerifier interface for testing
 * @dev Allows controlling verification results for testing different scenarios
 */
contract MockVerifier {
    // Flag to control verification result
    bool private _verificationResult = false;
    
    // Track verification calls for testing
    bool public verificationCalled = false;
    bytes public lastProof;
    bytes32[] public lastPublicInputs;

    /**
     * @notice Set the result that the verify function will return
     * @param result The boolean result to return from verify
     */
    function setVerificationResult(bool result) external {
        _verificationResult = result;
    }

    /**
     * @notice Reset the verification call tracking
     */
    function resetVerificationCalled() external {
        verificationCalled = false;
        delete lastProof;
        delete lastPublicInputs;
    }

    /**
     * @notice Mock implementation of the verify function
     * @param _proof The ZK proof data
     * @param _publicInputs The public inputs for the ZK proof
     * @return The predetermined verification result
     */
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external returns (bool) {
        // Track that verification was called and store the inputs
        verificationCalled = true;
        lastProof = _proof;
        
        // Copy the public inputs array
        delete lastPublicInputs;
        for (uint256 i = 0; i < _publicInputs.length; i++) {
            lastPublicInputs.push(_publicInputs[i]);
        }
        
        return _verificationResult;
    }
}
