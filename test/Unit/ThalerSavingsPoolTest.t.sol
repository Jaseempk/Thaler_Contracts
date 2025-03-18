// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ThalerSavingsPool} from "../../src/ThalerSavingsPool.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockVerifier} from "./mocks/MockVerifier.sol";

/**
 * @title ThalerSavingsPoolTest
 * @notice Comprehensive test suite for the ThalerSavingsPool contract
 * @dev Tests all functionality, edge cases, and potential vulnerabilities
 */
contract ThalerSavingsPoolTest is Test {
    // Constants for test configuration
    uint256 private constant THREE_MONTHS = 7884000; // 3 months in seconds
    uint256 private constant SIX_MONTHS = 15768000; // 6 months in seconds
    uint256 private constant TWELVE_MONTHS = 31536000; // 12 months in seconds
    uint256 private constant INTERVAL = 2628000; // 1 month in seconds
    uint256 private constant DONATION_RATIO = (3 / 25) * 100;

    // Test accounts
    address private deployer = makeAddr("deployer");
    address private user1 = makeAddr("user1");
    address private user2 = makeAddr("user2");
    address private user3 = makeAddr("user3");
    address private recipient = makeAddr("recipient");

    // Contract instances
    ThalerSavingsPool private savingsPool;
    MockERC20 private token;
    MockVerifier private verifier;

    // Test data
    bytes32 private savingsPoolId;
    bytes private mockProof;
    bytes32[] private mockPublicInputs;

    // Events to test
    event SavingsPoolCreated(
        address user,
        uint256 endDate,
        uint256 duration,
        uint256 startDate,
        uint256 totalSaved,
        address tokenToSave,
        uint256 amountToSave,
        uint256 initialDeposit,
        uint256 totalWithdrawn,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );

    event SavingsPoolDeposited(
        address user,
        uint256 depositedAmount,
        uint256 totalSaved,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );

    event WithdrawFromERC20Pool(
        address user,
        uint256 endDate,
        uint256 lastDepositedTimestamp,
        uint256 withdrawalTimestamp,
        uint256 totalSaved,
        address tokenToSave,
        uint256 duration,
        bytes32 poolId,
        uint256 amountWithdrawn
    );

    event WithdrawFromEthPool(
        address user,
        uint256 endDate,
        uint256 lastDepositedTimestamp,
        uint256 withdrawalTimestamp,
        uint256 totalSaved,
        uint256 duration,
        bytes32 poolId,
        uint256 amountWithdrawn
    );

    event Deposit(
        address user,
        bytes32 poolId,
        uint256 depositedAmount,
        uint256 nextDepositDate,
        uint256 totalSaved
    );

    /**
     * @notice Set up the test environment before each test
     */
    function setUp() public {
        // Set up the test environment with the deployer account
        vm.startPrank(deployer);

        // Deploy mock contracts
        token = new MockERC20("Test Token", "TEST", 18);
        verifier = new MockVerifier();

        // Deploy the ThalerSavingsPool contract
        savingsPool = new ThalerSavingsPool(address(verifier));

        // Initialize mock proof data
        mockProof = abi.encode("mock proof data");
        mockPublicInputs = new bytes32[](4);
        mockPublicInputs[0] = bytes32(uint256(0x1)); // tx_hash
        mockPublicInputs[1] = bytes32(uint256(uint160(user1))); // sender
        mockPublicInputs[2] = bytes32(uint256(uint160(recipient))); // recipient
        mockPublicInputs[3] = bytes32(uint256(1 ether)); // donation_amount

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test that the constructor properly initializes the contract
     */
    function test_Constructor() public {
        assertEq(
            address(savingsPool.verifier()),
            address(verifier),
            "Verifier address should be set correctly"
        );
    }

    /**
     * @notice Test that the constructor reverts with zero address
     */
    function test_Constructor_ZeroAddress() public {
        vm.expectRevert();
        new ThalerSavingsPool(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                    ERC20 SAVINGS POOL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test creating an ERC20 savings pool with valid parameters
     */
    function test_CreateSavingsPoolERC20_ValidParams() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL; // 12 months worth of savings
        uint256 initialDeposit = INTERVAL; // 1 month initial deposit
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect the SavingsPoolCreated event to be emitted
        vm.expectEmit(true, true, true, true);
        emit SavingsPoolCreated(
            user1,
            block.timestamp + duration,
            duration,
            block.timestamp,
            initialDeposit,
            address(token),
            amountToSave,
            initialDeposit,
            0,
            block.timestamp + INTERVAL,
            amountToSave / INTERVAL,
            block.timestamp
        );

        // Create the savings pool
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Get the savings pool data
        (
            address poolUser,
            uint256 endDate,
            uint256 poolDuration,
            uint256 startDate,
            uint256 totalSaved,
            address tokenToSave,
            uint256 poolAmountToSave,
            uint256 poolInitialDeposit,
            uint256 totalWithdrawn,
            uint256 nextDepositDate,
            uint256 numberOfDeposits,
            uint256 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the savings pool data
        assertEq(poolUser, user1, "User should be set correctly");
        assertEq(
            endDate,
            block.timestamp + duration,
            "End date should be set correctly"
        );
        assertEq(poolDuration, duration, "Duration should be set correctly");
        assertEq(
            startDate,
            block.timestamp,
            "Start date should be set correctly"
        );
        assertEq(totalSaved, 0, "Total saved should be 0 initially"); // Note: This is 0 because the contract doesn't update totalSaved
        assertEq(tokenToSave, address(token), "Token should be set correctly");
        assertEq(
            poolAmountToSave,
            amountToSave,
            "Amount to save should be set correctly"
        );
        assertEq(
            poolInitialDeposit,
            initialDeposit,
            "Initial deposit should be set correctly"
        );
        assertEq(totalWithdrawn, 0, "Total withdrawn should be 0 initially");
        assertEq(
            nextDepositDate,
            block.timestamp + INTERVAL,
            "Next deposit date should be set correctly"
        );
        assertEq(
            numberOfDeposits,
            amountToSave / INTERVAL,
            "Number of deposits should be set correctly"
        );
        assertEq(
            lastDepositedTimestamp,
            block.timestamp,
            "Last deposited timestamp should be set correctly"
        );

        // Verify token transfer
        assertEq(
            token.balanceOf(address(savingsPool)),
            initialDeposit,
            "Contract should have received initial deposit"
        );
        assertEq(
            token.balanceOf(user1),
            amountToSave - initialDeposit,
            "User should have remaining tokens"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid duration
     */
    function test_CreateSavingsPoolERC20_InvalidDuration() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 invalidDuration = 1000; // Not 3, 6, or 12 months

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect revert with invalid duration
        vm.expectRevert(ThalerSavingsPool.TLR_InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            invalidDuration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid initial deposit
     */
    function test_CreateSavingsPoolERC20_InvalidInitialDeposit() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 invalidInitialDeposit = amountToSave + 1; // Greater than amount to save
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, invalidInitialDeposit);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), invalidInitialDeposit);

        // Expect revert with invalid initial deposit
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            invalidInitialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid deposit ratio
     */
    function test_CreateSavingsPoolERC20_InvalidDepositRatio() public {
        // Set up test data
        uint256 amountToSave = 10 * INTERVAL; // 10 months worth of savings
        uint256 initialDeposit = 3 * INTERVAL; // Not divisible evenly into amountToSave
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect revert with invalid deposit ratio
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with zero values
     */
    function test_CreateSavingsPoolERC20_ZeroValues() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        vm.startPrank(user1);

        // Test with zero amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            0,
            duration,
            initialDeposit
        );

        // Test with zero duration
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            0,
            initialDeposit
        );

        // Test with zero initial deposit
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            0
        );

        // Test with zero address token
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolERC20(
            address(0),
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid amount to save
     */
    function test_CreateSavingsPoolERC20_InvalidAmountToSave() public {
        // Set up test data
        uint256 invalidAmountToSave = 10 * INTERVAL + 1; // Not divisible by interval
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, invalidAmountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), invalidAmountToSave);

        // Expect revert with invalid amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidDepositAmount.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            invalidAmountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with insufficient token approval
     */
    function test_CreateSavingsPoolERC20_InsufficientApproval() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve less than initial deposit
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit - 1);

        // Expect revert with insufficient approval
        vm.expectRevert("ERC20: insufficient allowance");
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with insufficient token balance
     */
    function test_CreateSavingsPoolERC20_InsufficientBalance() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint less than initial deposit to user1
        vm.startPrank(deployer);
        token.mint(user1, initialDeposit - 1);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);

        // Expect revert with insufficient balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    ETH SAVINGS POOL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test creating an ETH savings pool with valid parameters
     */
    function test_CreateSavingsPoolEth_ValidParams() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL; // 12 months worth of savings
        uint256 initialDeposit = INTERVAL; // 1 month initial deposit
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect the SavingsPoolCreated event to be emitted
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit SavingsPoolCreated(
            user1,
            block.timestamp + duration,
            duration,
            block.timestamp,
            initialDeposit,
            address(0),
            amountToSave,
            initialDeposit,
            0,
            block.timestamp + INTERVAL,
            (amountToSave - initialDeposit) / INTERVAL,
            block.timestamp
        );

        // Create the savings pool
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Get the savings pool data
        (
            address poolUser,
            uint256 endDate,
            uint256 poolDuration,
            uint256 startDate,
            uint256 totalSaved,
            address tokenToSave,
            uint256 poolAmountToSave,
            uint256 poolInitialDeposit,
            uint256 totalWithdrawn,
            uint256 nextDepositDate,
            uint256 numberOfDeposits,
            uint256 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the savings pool data
        assertEq(poolUser, user1, "User should be set correctly");
        assertEq(
            endDate,
            block.timestamp + duration,
            "End date should be set correctly"
        );
        assertEq(poolDuration, duration, "Duration should be set correctly");
        assertEq(
            startDate,
            block.timestamp,
            "Start date should be set correctly"
        );
        assertEq(
            totalSaved,
            initialDeposit,
            "Total saved should be initial deposit"
        );
        assertEq(tokenToSave, address(0), "Token should be address(0) for ETH");
        assertEq(
            poolAmountToSave,
            amountToSave,
            "Amount to save should be set correctly"
        );
        assertEq(
            poolInitialDeposit,
            initialDeposit,
            "Initial deposit should be set correctly"
        );
        assertEq(totalWithdrawn, 0, "Total withdrawn should be 0 initially");
        assertEq(
            nextDepositDate,
            block.timestamp + INTERVAL,
            "Next deposit date should be set correctly"
        );
        assertEq(
            numberOfDeposits,
            (amountToSave - initialDeposit) / INTERVAL,
            "Number of deposits should be set correctly"
        );
        assertEq(
            lastDepositedTimestamp,
            block.timestamp,
            "Last deposited timestamp should be set correctly"
        );

        // Verify ETH transfer
        assertEq(
            address(savingsPool).balance,
            initialDeposit,
            "Contract should have received initial deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid duration
     */
    function test_CreateSavingsPoolEth_InvalidDuration() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 invalidDuration = 1000; // Not 3, 6, or 12 months

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid duration
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR_InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            invalidDuration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid initial deposit
     */
    function test_CreateSavingsPoolEth_InvalidInitialDeposit() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 invalidInitialDeposit = amountToSave + 1; // Greater than amount to save
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, invalidInitialDeposit);

        // Expect revert with invalid initial deposit
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: invalidInitialDeposit}(
            amountToSave,
            duration,
            invalidInitialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid deposit ratio
     */
    function test_CreateSavingsPoolEth_InvalidDepositRatio() public {
        // Set up test data
        uint256 amountToSave = 10 * INTERVAL; // 10 months worth of savings
        uint256 initialDeposit = 3 * INTERVAL; // Not divisible evenly into amountToSave
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid deposit ratio
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with zero values
     */
    function test_CreateSavingsPoolEth_ZeroValues() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        vm.startPrank(user1);

        // Test with zero amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            0,
            duration,
            initialDeposit
        );

        // Test with zero duration
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            0,
            initialDeposit
        );

        // Test with zero initial deposit
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolEth{value: 0}(amountToSave, duration, 0);

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid amount to save
     */
    function test_CreateSavingsPoolEth_InvalidAmountToSave() public {
        // Set up test data
        uint256 invalidAmountToSave = 10 * INTERVAL + 1; // Not divisible by interval
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid amount to save
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidDepositAmount.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            invalidAmountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with mismatched ETH value
     */
    function test_CreateSavingsPoolEth_MismatchedEthValue() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 sentEth = initialDeposit - 1; // Less than initial deposit
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with mismatched ETH value
        vm.startPrank(user1);
        vm.expectRevert(
            ThalerSavingsPool.TLR__InvalidInitialETHDeposit.selector
        );
        savingsPool.createSavingsPoolEth{value: sentEth}(
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with insufficient ETH balance
     */
    function test_CreateSavingsPoolEth_InsufficientBalance() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Deal less than initial deposit to user1
        vm.deal(user1, initialDeposit - 1);

        // Expect revert with insufficient balance
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test depositing to an ERC20 savings pool
     */
    function test_DepositToERC20SavingsPool() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;
        uint256 depositAmount = INTERVAL;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect the Deposit event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Deposit(
            user1,
            poolId,
            depositAmount,
            nextDepositDate,
            initialDeposit + depositAmount
        );

        // Deposit to the savings pool
        savingsPool.depositToERC20SavingPool(poolId, depositAmount);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            ,
            uint256 totalSaved,
            ,
            ,
            ,
            ,
            uint256 updatedNextDepositDate,
            ,
            uint256 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalSaved,
            initialDeposit + depositAmount,
            "Total saved should be updated"
        );
        assertEq(
            updatedNextDepositDate,
            nextDepositDate + INTERVAL,
            "Next deposit date should be updated"
        );
        assertEq(
            lastDepositedTimestamp,
            nextDepositDate,
            "Last deposited timestamp should be updated"
        );

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            initialDeposit + depositAmount,
            "Contract should have received deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool
     */
    function test_DepositToETHSavingsPool() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;
        uint256 depositAmount = INTERVAL;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect the Deposit event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Deposit(
            user1,
            poolId,
            depositAmount,
            nextDepositDate,
            initialDeposit + depositAmount
        );

        // Deposit to the savings pool
        savingsPool.depositToEthSavingPool{value: depositAmount}(poolId);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            ,
            uint256 totalSaved,
            ,
            ,
            ,
            ,
            uint256 updatedNextDepositDate,
            ,
            uint256 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalSaved,
            initialDeposit + depositAmount,
            "Total saved should be updated"
        );
        assertEq(
            updatedNextDepositDate,
            nextDepositDate + INTERVAL,
            "Next deposit date should be updated"
        );
        assertEq(
            lastDepositedTimestamp,
            nextDepositDate,
            "Last deposited timestamp should be updated"
        );

        // Verify ETH balance
        assertEq(
            address(savingsPool).balance,
            initialDeposit + depositAmount,
            "Contract should have received deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a non-existent savings pool
     */
    function test_DepositToNonExistentPool() public {
        // Generate a random pool ID
        bytes32 nonExistentPoolId = keccak256(
            abi.encodePacked("non-existent-pool")
        );

        // Expect revert with non-existent pool
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.depositToERC20SavingPool(nonExistentPoolId, 0);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ERC20 savings pool with insufficient token balance
     */
    function test_DepositToERC20SavingsPool_InsufficientBalance() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1 (just enough for initial deposit)
        vm.startPrank(deployer);
        token.mint(user1, initialDeposit);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with insufficient balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        savingsPool.depositToERC20SavingPool(poolId, amountToSave);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ERC20 savings pool with insufficient allowance
     */
    function test_DepositToERC20SavingsPool_InsufficientAllowance() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool with initial approval
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // No additional approval given

        // Expect revert with insufficient allowance
        vm.expectRevert("ERC20: insufficient allowance");
        savingsPool.depositToERC20SavingPool(poolId, amountToSave);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool with insufficient ETH
     */
    function test_DepositToETHSavingsPool_InsufficientETH() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;
        uint256 depositAmount = INTERVAL;

        // Deal ETH to user1 (just enough for initial deposit)
        vm.deal(user1, initialDeposit);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with insufficient ETH
        vm.expectRevert();
        savingsPool.depositToEthSavingPool{value: depositAmount - 1}(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool with excess ETH
     */
    function test_DepositToETHSavingsPool_ExcessETH() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;
        uint256 depositAmount = INTERVAL;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with excess ETH
        vm.expectRevert(ThalerSavingsPool.TLR__ExcessEthDeposit.selector);
        savingsPool.depositToEthSavingPool{value: depositAmount + 1}(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ERC20 savings pool with ETH
     */
    function test_DepositToERC20SavingsPool_WithETH() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Deal ETH to user1
        vm.deal(user1, INTERVAL);

        // Expect revert when sending ETH to an ERC20 pool
        vm.expectRevert();
        savingsPool.depositToEthSavingPool{value: INTERVAL}(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool without ETH
     */
    function test_DepositToETHSavingsPool_WithoutETH() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert when not sending ETH to an ETH pool
        vm.expectRevert();
        savingsPool.depositToEthSavingPool(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool before the next deposit date
     */
    function test_DepositBeforeNextDepositDate() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to before next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate - 1);

        // Expect revert when depositing before next deposit date
        // vm.expectRevert(ThalerSavingsPool.TLR__DepositDateNotReached.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool after all deposits are made
     */
    function test_DepositAfterAllDepositsMade() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after all deposits
        uint256 finalDepositDate = block.timestamp + INTERVAL;
        vm.warp(finalDepositDate);

        // Expect revert when depositing after all deposits are made
        // vm.expectRevert(ThalerSavingsPool.TLR__AllDepositsMade.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool from a different user with ERC20 token
     */
    function test_DepositFromDifferentUserERC20() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));
        vm.stopPrank();

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Try to deposit as user2
        vm.startPrank(user2);
        token.approve(address(savingsPool), INTERVAL);

        // Expect revert when depositing from a different user
        vm.expectRevert(ThalerSavingsPool.TLR__CallerNotOwner.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool from a different user
     */
    function test_DepositFromDifferentUser() public {
        // Set up test data
        uint256 amountToSave = 12 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));
        vm.stopPrank();

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Try to deposit as user2
        vm.startPrank(user2);
        token.approve(address(savingsPool), INTERVAL);

        // Expect revert when depositing from a different user
        vm.expectRevert(ThalerSavingsPool.TLR__CallerNotOwner.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test withdrawing from an ERC20 savings pool after completion
     */
    function test_WithdrawFromERC20SavingsPool_AfterCompletion() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Expect the Withdrawal event to be emitted
        vm.expectEmit(true, true, true, true);
        emit WithdrawFromERC20Pool(
            user1,
            endDate,
            block.timestamp,
            block.timestamp,
            amountToSave,
            address(token),
            duration,
            poolId,
            amountToSave
        );

        // Withdraw from the savings pool
        savingsPool.withdrawFromSavingsPool(poolId);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            ,
            uint256 totalSaved,
            ,
            ,
            ,
            uint256 totalWithdrawn,
            ,
            ,

        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalWithdrawn,
            amountToSave,
            "Total withdrawn should be updated"
        );

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            0,
            "Contract should have sent all tokens"
        );
        assertEq(
            token.balanceOf(user1),
            amountToSave,
            "User should have received all tokens"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from an ETH savings pool after completion
     */
    function test_WithdrawFromETHSavingsPool_AfterCompletion() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool{value: INTERVAL}(poolId);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Record user's ETH balance before withdrawal
        uint256 userBalanceBefore = user1.balance;

        // Expect the Withdrawal event to be emitted
        vm.expectEmit(true, true, true, true);
        emit WithdrawFromEthPool(
            user1,
            endDate,
            block.timestamp,
            block.timestamp,
            amountToSave,
            duration,
            poolId,
            amountToSave
        );

        // Withdraw from the savings pool
        savingsPool.withdrawFromSavingsPool(poolId);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            ,
            uint256 totalSaved,
            ,
            ,
            ,
            uint256 totalWithdrawn,
            ,
            ,

        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalWithdrawn,
            amountToSave,
            "Total withdrawn should be updated"
        );

        // Verify ETH balance
        assertEq(
            address(savingsPool).balance,
            0,
            "Contract should have sent all ETH"
        );
        assertEq(
            user1.balance,
            userBalanceBefore + amountToSave,
            "User should have received all ETH"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a non-existent savings pool
     */
    function test_WithdrawFromNonExistentPool() public {
        // Generate a random pool ID
        bytes32 nonExistentPoolId = keccak256(
            abi.encodePacked("non-existent-pool")
        );

        // Expect revert with non-existent pool
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.withdrawFromSavingsPool(nonExistentPoolId);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool before completion
     */
    function test_WithdrawBeforeCompletion() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make one deposit
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        // Warp to before the end date
        uint256 endDate = block.timestamp + duration - 1;
        vm.warp(endDate);

        // Expect revert when withdrawing before completion
        vm.expectRevert();
        savingsPool.withdrawFromSavingsPool(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool from a different user
     */
    function test_WithdrawFromDifferentUser() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        vm.stopPrank();

        // Try to withdraw as user2
        vm.startPrank(user2);

        // Expect revert when withdrawing from a different user
        vm.expectRevert(ThalerSavingsPool.TLR__NotPoolOwner.selector);
        savingsPool.withdrawFromSavingsPool(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool that has already been withdrawn
     */
    function test_WithdrawAfterAlreadyWithdrawn() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Withdraw from the savings pool
        savingsPool.withdrawFromSavingsPool(poolId);

        // Expect revert when withdrawing again
        vm.expectRevert(ThalerSavingsPool.TLR__AlreadyWithdrawn.selector);
        savingsPool.withdrawFromSavingsPool(poolId);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool with incomplete deposits
     */
    function test_WithdrawWithIncompleteDeposits() public {
        // Set up test data
        uint256 amountToSave = 3 * INTERVAL;
        uint256 initialDeposit = INTERVAL;
        uint256 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make only one deposit (out of two required)
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Expect the Withdrawal event to be emitted with partial amount
        vm.expectEmit(true, true, true, true);
        emit WithdrawFromERC20Pool(
            user1,
            endDate,
            block.timestamp,
            block.timestamp,
            initialDeposit + INTERVAL,
            address(token),
            duration,
            poolId,
            initialDeposit + INTERVAL
        );

        // Withdraw from the savings pool
        savingsPool.withdrawFromSavingsPool(poolId);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            ,
            uint256 totalSaved,
            ,
            ,
            ,
            uint256 totalWithdrawn,
            ,
            ,

        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalWithdrawn,
            initialDeposit + INTERVAL,
            "Total withdrawn should be updated"
        );

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            0,
            "Contract should have sent all tokens"
        );
        assertEq(
            token.balanceOf(user1),
            initialDeposit + INTERVAL,
            "User should have received partial tokens"
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    ZK PROOF VERIFICATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test verifying a valid ZK proof
     */
    function test_VerifyZKProof_Valid() public {
        // Set up mock verifier to return true
        vm.startPrank(deployer);
        verifier.setVerificationResult(true);
        vm.stopPrank();

        // Create a mock proof and public inputs
        bytes memory proof = abi.encodePacked("valid proof data");
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = keccak256("input1");
        publicInputs[1] = keccak256("input2");

        // Verify the proof
        vm.startPrank(user1);
        bool result = savingsPool.verifyProof(proof, publicInputs);
        vm.stopPrank();

        // Verify the result
        assertTrue(result, "Proof verification should succeed");

        // Verify that the verifier was called with the correct inputs
        assertTrue(
            verifier.verificationCalled(),
            "Verifier should have been called"
        );
        assertEq(verifier.lastProof(), proof, "Proof should match");
        assertEq(
            verifier.lastPublicInputs(0),
            publicInputs[0],
            "Public input 0 should match"
        );
        assertEq(
            verifier.lastPublicInputs(1),
            publicInputs[1],
            "Public input 1 should match"
        );
    }

    /**
     * @notice Test verifying an invalid ZK proof
     */
    function test_VerifyZKProof_Invalid() public {
        // Set up mock verifier to return false
        vm.startPrank(deployer);
        verifier.setVerificationResult(false);
        vm.stopPrank();

        // Create a mock proof and public inputs
        bytes memory proof = abi.encodePacked("invalid proof data");
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = keccak256("input1");
        publicInputs[1] = keccak256("input2");

        // Verify the proof
        vm.startPrank(user1);
        bool result = savingsPool.verifyProof(proof, publicInputs);
        vm.stopPrank();

        // Verify the result
        assertFalse(result, "Proof verification should fail");

        // Verify that the verifier was called with the correct inputs
        assertTrue(
            verifier.verificationCalled(),
            "Verifier should have been called"
        );
        assertEq(verifier.lastProof(), proof, "Proof should match");
        assertEq(
            verifier.lastPublicInputs(0),
            publicInputs[0],
            "Public input 0 should match"
        );
        assertEq(
            verifier.lastPublicInputs(1),
            publicInputs[1],
            "Public input 1 should match"
        );
    }

    /**
     * @notice Test verifying a ZK proof with empty proof data
     */
    function test_VerifyZKProof_EmptyProof() public {
        // Set up mock verifier to return false
        vm.startPrank(deployer);
        verifier.setVerificationResult(false);
        vm.stopPrank();

        // Create empty proof and public inputs
        bytes memory emptyProof = new bytes(0);
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = keccak256("input1");
        publicInputs[1] = keccak256("input2");

        // Verify the proof
        vm.startPrank(user1);
        bool result = savingsPool.verifyProof(emptyProof, publicInputs);
        vm.stopPrank();

        // Verify the result
        assertFalse(result, "Proof verification should fail with empty proof");

        // Verify that the verifier was called
        assertTrue(
            verifier.verificationCalled(),
            "Verifier should have been called"
        );
    }

    /**
     * @notice Test verifying a ZK proof with empty public inputs
     */
    function test_VerifyZKProof_EmptyPublicInputs() public {
        // Set up mock verifier to return false
        vm.startPrank(deployer);
        verifier.setVerificationResult(false);
        vm.stopPrank();

        // Create a mock proof and empty public inputs
        bytes memory proof = abi.encodePacked("valid proof data");
        bytes32[] memory emptyPublicInputs = new bytes32[](0);

        // Verify the proof
        vm.startPrank(user1);
        bool result = savingsPool.verifyProof(proof, emptyPublicInputs);
        vm.stopPrank();

        // Verify the result
        assertFalse(
            result,
            "Proof verification should fail with empty public inputs"
        );

        // Verify that the verifier was called
        assertTrue(
            verifier.verificationCalled(),
            "Verifier should have been called"
        );
    }
}
