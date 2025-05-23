-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_KEY := 

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; 

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url $(ALCHEMY_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast

ifeq ($(findstring --network ethereum,$(ARGS)),--network ethereum)
	NETWORK_ARGS := --rpc-url $(ALCHEMY_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployThalerSavingsPool.s.sol:DeployThalerSavingsPool $(NETWORK_ARGS)





verify:
	@forge verify-contract --chain-id 84532 --watch --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0x5AF37fb2fff2d7D0520C80f1eA4F317024d4fc2C src/ThalerSavingsPool.sol:ThalerSavingsPool 
#@forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(address)" "$(ESCROW)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0x7627F934F4f32fd34C1eCb1ec938bf64b0149Aa9 src/YapOrderBookFactory.sol:YapOrderBookFactory
#@forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(address,address)" "$(USDC)" "$(FACTORY)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0xa55b6f0BC1Ef608393678530C179D19715B75e7c src/YapEscrow.sol:YapEscrow
#forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(address,address,address,address,uint256)" "$(STABLECOIN)" "$(FEECOLLECTOR)" "$(ESCROW)" "$(YAPORACLE)" "$(KOLID)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0xD2bB8F9cb41a03a5c93770dfe508F00Ee6FB5075 src/YapOrderBook.sol:YapOrderBook
#@forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(address)" "$(UPDATER)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0xDa1B4fFfAF462D5c39c2c06b33b1d400c0E04aB7 src/YapOracle.sol:YapOracle
#@forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(string,string,uint256,address[3],uint256[3],address)" "$(NAME)" "$(SYMBOL)" "$(MAX_SUPPLY)" "[$(ALLOCATION_ADDY1),$(ALLOCATION_ADDY2),$(ALLOCATION_ADDY3)]" "[$(ALLOCATIONAMOUNT1),$(ALLOCATIONAMOUNT2),$(ALLOCATIONAMOUNT3)]" "$(FACTORY)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.24 0xe2A1A3c40dFE8e29e00f25f50C113FF9b06ac912 
	
