import {
  CharityWhitelisted as CharityWhitelistedEvent,
  EarlyWithdrawalDonation as EarlyWithdrawalDonationEvent,
  SavingsPoolCreated as SavingsPoolCreatedEvent,
  SavingsPoolERC20Deposited as SavingsPoolERC20DepositedEvent,
  SavingsPoolETHDeposited as SavingsPoolETHDepositedEvent,
  WithdrawFromERC20Pool as WithdrawFromERC20PoolEvent,
  WithdrawFromEthPool as WithdrawFromEthPoolEvent,
} from "../generated/ThalerSavingsPool/ThalerSavingsPool";
import {
  CharityWhitelisted,
  EarlyWithdrawalDonation,
  SavingsPoolCreated,
  SavingsPoolERC20Deposited,
  SavingsPoolETHDeposited,
  WithdrawFromERC20Pool,
  WithdrawFromEthPool,
} from "../generated/schema";

export function handleCharityWhitelisted(event: CharityWhitelistedEvent): void {
  let entity = new CharityWhitelisted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.charityAddress = event.params.charityAddress;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleEarlyWithdrawalDonation(
  event: EarlyWithdrawalDonationEvent
): void {
  let entity = new EarlyWithdrawalDonation(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.charityAddress = event.params.charityAddress;
  entity.amountDonated = event.params.amountDonated;
  entity.tokenToSave = event.params.tokenToSave;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleSavingsPoolCreated(event: SavingsPoolCreatedEvent): void {
  let entity = new SavingsPoolCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.savingsPoolId = event.params.savingsPoolId;
  entity.duration = event.params.duration;
  entity.numberOfDeposits = event.params.numberOfDeposits;
  entity.totalSaved = event.params.totalSaved;
  entity.tokenToSave = event.params.tokenToSave;
  entity.amountToSave = event.params.amountToSave;
  entity.totalIntervals = event.params.totalIntervals;
  entity.initialDeposit = event.params.initialDeposit;
  entity.endDate = event.params.endDate;
  entity.startDate = event.params.startDate;
  entity.nextDepositDate = event.params.nextDepositDate;
  entity.lastDepositedTimestamp = event.params.lastDepositedTimestamp;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleSavingsPoolERC20Deposited(
  event: SavingsPoolERC20DepositedEvent
): void {
  let entity = new SavingsPoolERC20Deposited(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.savingsPoolId = event.params.savingsPoolId;
  entity.depositedAmount = event.params.depositedAmount;
  entity.totalSaved = event.params.totalSaved;
  entity.nextDepositDate = event.params.nextDepositDate;
  entity.numberOfDeposits = event.params.numberOfDeposits;
  entity.lastDepositedTimestamp = event.params.lastDepositedTimestamp;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleSavingsPoolETHDeposited(
  event: SavingsPoolETHDepositedEvent
): void {
  let entity = new SavingsPoolETHDeposited(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.savingsPoolId = event.params.savingsPoolId;
  entity.depositedAmount = event.params.depositedAmount;
  entity.totalSaved = event.params.totalSaved;
  entity.nextDepositDate = event.params.nextDepositDate;
  entity.numberOfDeposits = event.params.numberOfDeposits;
  entity.lastDepositedTimestamp = event.params.lastDepositedTimestamp;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleWithdrawFromERC20Pool(
  event: WithdrawFromERC20PoolEvent
): void {
  let entity = new WithdrawFromERC20Pool(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.endDate = event.params.endDate;
  entity.startDate = event.params.startDate;
  entity.timeStamp = event.params.timeStamp;
  entity.totalSaved = event.params.totalSaved;
  entity.tokenSaved = event.params.tokenSaved;
  entity.poolDuration = event.params.poolDuration;
  entity.savingsPoolId = event.params.savingsPoolId;
  entity.totalWithdrawn = event.params.totalWithdrawn;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleWithdrawFromEthPool(
  event: WithdrawFromEthPoolEvent
): void {
  let entity = new WithdrawFromEthPool(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.user = event.params.user;
  entity.endDate = event.params.endDate;
  entity.startDate = event.params.startDate;
  entity.timeStamp = event.params.timeStamp;
  entity.totalSaved = event.params.totalSaved;
  entity.poolDuration = event.params.poolDuration;
  entity.savingsPoolId = event.params.savingsPoolId;
  entity.totalWithdrawn = event.params.totalWithdrawn;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
