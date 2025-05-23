//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title ThalerSavingsPool
 * @author Thaler Protocol
 * @notice A contract that allows users to create savings pools with regular deposit schedules
 * @dev Implements a savings mechanism with optional early withdrawal via ZK proof verification
 */
contract ThalerSavingsPool {
    // Custom errors for better gas efficiency and clarity
    error TLR__OnlyOwner();
    error TLR__CallerNotOwner();
    error TLR__INVALID_INPUTS();
    error TLR__DonationFailed();
    error TLR__InvalidDuration();
    error TLR__SavingPoolEnded();
    error TLR__NonExistentPool();
    error TLR__ExcessEthDeposit();
    error TLR__AlreadyWhitelisted();
    error TLR__InsufficientSavings();
    error TLR__InvalidTotalDuration();
    error TLR__InvalidCharityAddress();
    error TLR__CharityNotWhitelisted();
    error TLR__InvalidInitialDeposit();
    error TLR__InvalidEthDepositRatio();
    error TLR__InvalidInitialETHDeposit();
    error TLR__SavingPoolDepositIntervalNotYet();

    // Time constants for savings pool durations
    uint48 private constant THREE_MONTHS = 7776000; // 3 months in seconds
    uint48 private constant SIX_MONTHS = 15552000; // 6 months in seconds
    uint48 private constant TWELVE_MONTHS = 31536000; // 12 months in seconds
    uint48 public constant INTERVAL = 2592000; // 1 month in seconds - deposit interval

    /**
     * @notice Structure to store savings pool details
     * @dev All time-related fields are stored as Unix timestamps
     */
    struct SavingsPool {
        address user; // Owner of the savings pool
        uint64 duration; // Total duration of the savings pool in seconds
        uint32 numberOfDeposits; // Number of deposits remaining
        uint88 totalSaved; // Total amount saved so far
        address tokenToSave; // Token address (address(0) for ETH)
        uint88 amountToSave; // Total target amount to save
        uint8 totalIntervals; // Amount to deposit at each interval
        uint88 initialDeposit; // Initial deposit amount
        uint48 endDate; // Timestamp when the savings period ends
        uint48 startDate; // Timestamp when the savings pool was created
        uint48 nextDepositDate; // Timestamp for the next scheduled deposit
        uint48 lastDepositedTimestamp; // Timestamp of the last deposit
    }

    address private owner;

    // Mapping from savings pool ID to savings pool details
    mapping(bytes32 => SavingsPool) public savingsPools;

    mapping(address => bool) public isWhitelistedCharity;

    /**
     * @notice Emitted when a new savings pool is created
     * @param user Address of the user who created the pool
     * @param duration Total duration of the savings pool in seconds
     * @param numberOfDeposits Number of deposits remaining
     * @param totalSaved Initial amount saved
     * @param tokenToSave Token address (address(0) for ETH)
     * @param amountToSave Total target amount to save
     * @param totalIntervals Amount to deposit at each interval
     * @param initialDeposit Initial deposit amount
     * @param endDate Timestamp when the savings period ends
     * @param startDate Timestamp when the savings pool was created
     * @param nextDepositDate Timestamp for the next scheduled deposit
     * @param lastDepositedTimestamp Timestamp of the initial deposit
     */
    event SavingsPoolCreated(
        address user,
        bytes32 savingsPoolId,
        uint64 duration,
        uint32 numberOfDeposits,
        uint88 totalSaved,
        address tokenToSave,
        uint88 amountToSave,
        uint8 totalIntervals,
        uint88 initialDeposit,
        uint48 endDate,
        uint48 startDate,
        uint48 nextDepositDate,
        uint48 lastDepositedTimestamp
    );

    /**
     * @notice Emitted when a deposit is made to a savings pool
     * @param user Address of the user who made the deposit
     * @param depositedAmount Amount deposited
     * @param totalSaved Updated total amount saved
     * @param nextDepositDate Updated timestamp for the next scheduled deposit
     * @param numberOfDeposits Updated number of deposits remaining
     * @param lastDepositedTimestamp Updated timestamp of the last deposit
     */
    event SavingsPoolERC20Deposited(
        address user,
        bytes32 savingsPoolId,
        uint88 depositedAmount,
        uint88 totalSaved,
        uint48 nextDepositDate,
        uint32 numberOfDeposits,
        uint48 lastDepositedTimestamp
    );

    /**
     * @notice Emitted when a user deposits ETH into a savings pool
     * @param user The address of the user who made the deposit
     * @param savingsPoolId The unique identifier of the savings pool
     * @param depositedAmount The amount of ETH deposited in this transaction
     * @param totalSaved The total amount saved in the pool after this deposit
     * @param nextDepositDate The timestamp when the next deposit is due
     * @param numberOfDeposits The total number of deposits made to this pool
     * @param lastDepositedTimestamp The timestamp when this deposit was made
     */
    event SavingsPoolETHDeposited(
        address user,
        bytes32 savingsPoolId,
        uint88 depositedAmount,
        uint88 totalSaved,
        uint48 nextDepositDate,
        uint32 numberOfDeposits,
        uint48 lastDepositedTimestamp
    );

    /**
     * @notice Emitted when a user withdraws from an ERC20 savings pool
     * @param user Address of the user who withdrew
     * @param endDate Timestamp when the savings period ends
     * @param startDate Timestamp when the savings pool was created
     * @param timeStamp Timestamp of the withdrawal
     * @param totalSaved Total amount saved
     * @param tokenSaved Token address
     * @param poolDuration Duration of the savings pool
     * @param savingsPoolId ID of the savings pool
     * @param totalWithdrawn Total amount withdrawn
     */
    event WithdrawFromERC20Pool(
        address user,
        uint48 endDate,
        uint48 startDate,
        uint48 timeStamp,
        uint88 totalSaved,
        address tokenSaved,
        uint64 poolDuration,
        bytes32 savingsPoolId,
        uint88 totalWithdrawn
    );

    /**
     * @notice Emitted when a user withdraws from an ETH savings pool
     * @param user Address of the user who withdrew
     * @param endDate Timestamp when the savings period ends
     * @param startDate Timestamp when the savings pool was created
     * @param timeStamp Timestamp of the withdrawal
     * @param totalSaved Total amount saved
     * @param poolDuration Duration of the savings pool
     * @param savingsPoolId ID of the savings pool
     * @param totalWithdrawn Total amount withdrawn
     */
    event WithdrawFromEthPool(
        address user,
        uint48 endDate,
        uint48 startDate,
        uint48 timeStamp,
        uint88 totalSaved,
        uint64 poolDuration,
        bytes32 savingsPoolId,
        uint88 totalWithdrawn
    );

    /**
     * @notice Emitted when a user makes an early withdrawal and donates penalty fees to charity
     * @param user Address of the user making early withdrawal
     * @param charityAddress Address of the charity receiving the donation
     * @param amountDonated Amount donated to charity from early withdrawal penalty
     * @param tokenToSave Address of the token that was withdrawn early
     */
    event EarlyWithdrawalDonation(
        address user,
        address charityAddress,
        uint256 amountDonated,
        address tokenToSave
    );

    /**
     * @notice Emitted when a charity is whitelisted
     * @param charityAddress Address of the whitelisted charity
     */
    event CharityWhitelisted(address charityAddress);

    modifier onlyOwner() {
        if (msg.sender != owner) revert TLR__OnlyOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Creates a new ERC20 token savings pool
     * @dev Transfers the initial deposit from the user to the contract
     * @param _tokenToSave Address of the ERC20 token to save
     * @param _amountToSave Total target amount to save
     * @param _duration Duration of the savings pool (must be 3, 6, or 12 months)
     * @param _initialDeposit Initial deposit amount
     */
    function createSavingsPoolERC20(
        address _tokenToSave,
        uint88 _amountToSave,
        uint64 _duration,
        uint88 _initialDeposit,
        uint8 _totalIntervals
    ) public {
        // Validate duration is one of the allowed values
        if (
            _duration != THREE_MONTHS &&
            _duration != SIX_MONTHS &&
            _duration != TWELVE_MONTHS
        ) revert TLR__InvalidTotalDuration();

        // Validate initial deposit is a proper fraction of total amount
        if (
            _initialDeposit > _amountToSave ||
            _amountToSave % _initialDeposit != 0 ||
            (_amountToSave / _totalIntervals) != _initialDeposit
        ) revert TLR__InvalidInitialDeposit();

        // Validate none of the inputs are zero or invalid
        if (
            _duration == 0 || _initialDeposit == 0 || _tokenToSave == address(0)
        ) revert TLR__INVALID_INPUTS();

        // Validate duration is divisible by the interval
        if (_duration % INTERVAL != 0 && _duration != TWELVE_MONTHS)
            revert TLR__InvalidDuration();

        // Generate a unique ID for the savings pool
        bytes32 savingsPoolId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, _tokenToSave)
        );

        // Emit event for savings pool creation
        emit SavingsPoolCreated(
            msg.sender,
            savingsPoolId,
            _duration,
            _totalIntervals,
            _initialDeposit,
            _tokenToSave,
            _amountToSave,
            _totalIntervals,
            _initialDeposit,
            uint48(block.timestamp + _duration),
            uint48(block.timestamp),
            uint48(block.timestamp + INTERVAL),
            uint48(block.timestamp)
        );

        // Create the savings pool in storage
        savingsPools[savingsPoolId] = SavingsPool({
            user: msg.sender,
            duration: _duration,
            numberOfDeposits: _totalIntervals,
            totalSaved: _initialDeposit,
            tokenToSave: _tokenToSave,
            amountToSave: _amountToSave,
            totalIntervals: _totalIntervals,
            initialDeposit: _initialDeposit,
            endDate: uint48(block.timestamp + _duration),
            startDate: uint48(block.timestamp),
            nextDepositDate: uint48(block.timestamp) + INTERVAL,
            lastDepositedTimestamp: uint48(block.timestamp)
        });

        // Transfer initial deposit from user to contract
        IERC20(_tokenToSave).transferFrom(
            msg.sender,
            address(this),
            _initialDeposit
        );
    }

    /**
     * @notice Creates a new ETH savings pool
     * @dev Requires the initial deposit to be sent with the transaction
     * @param _amountToSave Total target amount to save in wei
     * @param _duration Duration of the savings pool (must be 3, 6, or 12 months)
     * @param _initialDeposit Initial deposit amount in wei
     */
    function createSavingsPoolEth(
        uint88 _amountToSave,
        uint64 _duration,
        uint88 _initialDeposit,
        uint8 _totalIntervals
    ) public payable {
        // Validate duration is one of the allowed values
        if (
            _duration != THREE_MONTHS &&
            _duration != SIX_MONTHS &&
            _duration != TWELVE_MONTHS
        ) revert TLR__InvalidTotalDuration();

        // Validate initial deposit is a proper fraction of total amount
        if (
            _initialDeposit > _amountToSave ||
            _amountToSave % _initialDeposit != 0 ||
            (_amountToSave / _totalIntervals) != _initialDeposit
        ) revert TLR__InvalidInitialDeposit();

        // Validate none of the inputs are zero
        if (_amountToSave == 0 || _duration == 0 || _initialDeposit == 0)
            revert TLR__INVALID_INPUTS();

        // Validate duration is divisible by the interval
        if (_duration % INTERVAL != 0 && _duration != TWELVE_MONTHS)
            revert TLR__InvalidDuration();

        // Validate sent ETH matches the initial deposit
        if (msg.value != _initialDeposit)
            revert TLR__InvalidInitialETHDeposit();

        // Generate a unique ID for the savings pool
        bytes32 savingsPoolId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );

        // Emit event for savings pool creation
        emit SavingsPoolCreated(
            msg.sender,
            savingsPoolId,
            _duration,
            _totalIntervals,
            _initialDeposit,
            address(0),
            _amountToSave,
            _totalIntervals,
            _initialDeposit,
            uint48(block.timestamp + _duration),
            uint48(block.timestamp),
            uint48(block.timestamp + INTERVAL),
            uint48(block.timestamp)
        );

        // Create the savings pool in storage
        savingsPools[savingsPoolId] = SavingsPool({
            user: msg.sender,
            duration: _duration,
            numberOfDeposits: _totalIntervals,
            totalSaved: _initialDeposit,
            tokenToSave: address(0),
            amountToSave: _amountToSave,
            totalIntervals: _totalIntervals,
            initialDeposit: _initialDeposit,
            endDate: uint48(block.timestamp + _duration),
            startDate: uint48(block.timestamp),
            nextDepositDate: uint48(block.timestamp) + INTERVAL,
            lastDepositedTimestamp: uint48(block.timestamp)
        });
    }

    /**
     * @notice Deposits ETH to an existing savings pool
     * @dev Requires ETH to be sent with the transaction
     * @param _savingsPoolId ID of the savings pool to deposit to
     */
    function depositToEthSavingPool(
        bytes32 _savingsPoolId,
        uint88 _depositAmount
    ) public payable {
        // Get the savings pool from storage
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];

        if (savingsPool.user == address(0)) revert TLR__NonExistentPool();

        // Validate caller is the pool owner
        if (savingsPool.user != msg.sender) revert TLR__CallerNotOwner();

        // Validate savings pool hasn't ended
        if (block.timestamp > savingsPool.endDate)
            revert TLR__SavingPoolEnded();

        // Validate deposit is made at or after the next deposit date
        if (block.timestamp < savingsPool.nextDepositDate)
            revert TLR__SavingPoolDepositIntervalNotYet();

        // Validate deposit amount is a proper ratio of the total amount
        if (_depositAmount != msg.value) revert TLR__InvalidEthDepositRatio();

        // Validate deposit doesn't exceed remaining amount
        if (
            (savingsPool.amountToSave / savingsPool.totalIntervals) !=
            _depositAmount
        ) revert TLR__ExcessEthDeposit();

        // Update savings pool state
        savingsPool.totalSaved += uint88(msg.value);
        savingsPool.numberOfDeposits -= 1;
        savingsPool.lastDepositedTimestamp = uint48(block.timestamp);

        // Update next deposit date if there are more deposits remaining
        if (savingsPool.numberOfDeposits > 0) {
            savingsPool.nextDepositDate += INTERVAL;
        }

        // Emit deposit event
        emit SavingsPoolETHDeposited(
            msg.sender,
            _savingsPoolId,
            uint88(msg.value),
            savingsPool.totalSaved,
            savingsPool.nextDepositDate,
            savingsPool.numberOfDeposits,
            savingsPool.lastDepositedTimestamp
        );
    }

    function depositToERC20SavingPool(
        bytes32 _savingsPoolId,
        uint88 _amountToDeposit
    ) public {
        // Get the savings pool from storage
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];

        // Calculate remaining amount to be deposited
        uint256 remainingDepositAmount = savingsPool.amountToSave -
            savingsPool.totalSaved;

        if (savingsPool.user == address(0)) revert TLR__NonExistentPool();

        if (savingsPool.user != msg.sender) revert TLR__CallerNotOwner();

        // Validate savings pool hasn't ended
        if (block.timestamp > savingsPool.endDate)
            revert TLR__SavingPoolEnded();

        // Validate deposit is made at or after the next deposit date
        if (block.timestamp < savingsPool.nextDepositDate)
            revert TLR__SavingPoolDepositIntervalNotYet();

        // Validate deposit amount is a proper ratio of the total amount
        if (savingsPool.amountToSave % _amountToDeposit != 0)
            revert TLR__InvalidEthDepositRatio();

        // Validate deposit doesn't exceed remaining amount
        if (_amountToDeposit > remainingDepositAmount)
            revert TLR__ExcessEthDeposit();

        // Update savings pool state
        savingsPool.totalSaved += _amountToDeposit;
        savingsPool.numberOfDeposits -= 1;
        savingsPool.lastDepositedTimestamp = uint48(block.timestamp);

        // Update next deposit date if there are more deposits remaining
        if (savingsPool.numberOfDeposits > 0) {
            savingsPool.nextDepositDate += INTERVAL;
        }

        // Emit deposit event
        emit SavingsPoolERC20Deposited(
            msg.sender,
            _savingsPoolId,
            _amountToDeposit,
            savingsPool.totalSaved,
            savingsPool.nextDepositDate,
            savingsPool.numberOfDeposits,
            savingsPool.lastDepositedTimestamp
        );

        IERC20(savingsPool.tokenToSave).transferFrom(
            msg.sender,
            address(this),
            _amountToDeposit
        );
    }

    /**
     * @notice Withdraws ETH from a savings pool after it has ended
     * @dev Only the pool owner can withdraw, and only after the end date
     * @param _savingsPoolId ID of the savings pool to withdraw from
     * @param _charityAddress Address of the charity to donate to when early withdrawing
     */
    function withdrawFromEthSavingPool(
        bytes32 _savingsPoolId,
        address _charityAddress
    ) public {
        // Get the savings pool from storage
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];

        // Validate caller is the pool owner
        if (msg.sender != savingsPool.user) revert TLR__CallerNotOwner();

        // Validate there are funds to withdraw
        if (savingsPool.totalSaved == 0) revert TLR__InsufficientSavings();

        uint256 donationAmount;
        // Validate savings pool has ended
        if (block.timestamp < savingsPool.endDate) {
            if (_charityAddress == address(0))
                revert TLR__InvalidCharityAddress();

            donationAmount = (savingsPool.endDate / 2) > block.timestamp
                ? ((savingsPool.totalSaved) / 4)
                : ((savingsPool.totalSaved) / 8);

            bool success = earlyWithdrawalDonation(
                donationAmount,
                _charityAddress,
                savingsPool.tokenToSave
            );
            if (success == false) revert TLR__DonationFailed();
        }

        // Emit withdrawal event
        emit WithdrawFromEthPool(
            msg.sender,
            savingsPool.endDate,
            savingsPool.startDate,
            uint48(block.timestamp),
            savingsPool.totalSaved,
            savingsPool.duration,
            _savingsPoolId,
            savingsPool.totalSaved
        );
        uint256 totalSaved = savingsPool.totalSaved - donationAmount;

        // Delete the savings pool
        delete savingsPools[_savingsPoolId];

        // Transfer ETH to the user
        (bool _success, ) = payable(msg.sender).call{value: totalSaved}("");

        require(_success, "ETH transfer failed");
    }

    /**
     * @notice Withdraws ERC20 tokens from a savings pool
     * @dev Can withdraw early if a valid ZK proof is provided
     * @param _savingsPoolId ID of the savings pool to withdraw from
     * @param _charityAddress Address of the charity to donate to when early withdrawing
     */
    function withdrawFromERC20SavingPool(
        bytes32 _savingsPoolId,
        address _charityAddress
    ) public {
        // Get the savings pool from storage
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];

        // Validate caller is the pool owner
        if (msg.sender != savingsPool.user) revert TLR__CallerNotOwner();

        // Validate there are funds to withdraw
        if (savingsPool.totalSaved == 0) revert TLR__InsufficientSavings();

        uint256 donationAmount;
        // If withdrawing early, donate
        if (block.timestamp < savingsPool.endDate) {
            if (_charityAddress == address(0))
                revert TLR__InvalidCharityAddress();

            // Extract donation amount from public inputs (4th parameter)
            donationAmount = (savingsPool.endDate / 2) > block.timestamp
                ? ((savingsPool.totalSaved) / 4)
                : ((savingsPool.totalSaved) / 8);

            bool success = earlyWithdrawalDonation(
                donationAmount,
                _charityAddress,
                savingsPool.tokenToSave
            );
            if (success == false) revert TLR__DonationFailed();
        }

        // Emit withdrawal event
        emit WithdrawFromERC20Pool(
            msg.sender,
            savingsPool.endDate,
            savingsPool.startDate,
            uint48(block.timestamp),
            savingsPool.totalSaved,
            savingsPool.tokenToSave,
            savingsPool.duration,
            _savingsPoolId,
            savingsPool.totalSaved
        );

        uint256 totalSaved = savingsPool.totalSaved - donationAmount;
        address tokenToSave = savingsPool.tokenToSave;

        // Delete the savings pool
        delete savingsPools[_savingsPoolId];

        // Transfer tokens to the user
        IERC20(tokenToSave).transferFrom(address(this), msg.sender, totalSaved);
    }

    function earlyWithdrawalDonation(
        uint256 amountToDonate,
        address charityAddress,
        address _tokenToSave
    ) internal returns (bool success) {
        if (isWhitelistedCharity[charityAddress] == false)
            revert TLR__CharityNotWhitelisted();

        emit EarlyWithdrawalDonation(
            msg.sender,
            charityAddress,
            amountToDonate,
            _tokenToSave
        );
        if (_tokenToSave != address(0)) {
            return
                success = IERC20(_tokenToSave).transferFrom(
                    address(this),
                    charityAddress,
                    amountToDonate
                );
        } else {
            (success, ) = payable(charityAddress).call{value: amountToDonate}(
                ""
            );
            return success;
        }
    }

    function whitelistCharity(address charityAddress) public onlyOwner {
        if (isWhitelistedCharity[charityAddress])
            revert TLR__AlreadyWhitelisted();
        emit CharityWhitelisted(charityAddress);
        isWhitelistedCharity[charityAddress] = true;
    }
}

/**
 * @title IERC20
 * @dev Interface for the ERC20 standard
 */
interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
