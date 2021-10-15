SHELL := /bin/bash
MAKEFLAGS += --no-print-directory

SOL_PATH=contract
SOL_GEN_PATH=bin
SOL_FILES=$(wildcard $(SOL_PATH)/*.sol)
CONTRACT_LIST=$(basename $(notdir $(SOL_FILES)))
SOL_GEN_FILES_BASE:=$(join $(addsuffix /, $(basename $(patsubst $(SOL_PATH)%, $(SOL_GEN_PATH)%, $(SOL_FILES)))), $(CONTRACT_LIST))
SOL_ABI_GEN_FILES:=$(patsubst %, %.abi, $(SOL_GEN_FILES_BASE))
SOL_BIN_GEN_FILES:=$(patsubst %, %.bin, $(SOL_GEN_FILES_BASE))
SOL_GAS_CHECK_GEN_FILES:=$(patsubst %, %.gasCheck, $(SOL_GEN_FILES_BASE))

FAKE_SOL_GEN_FILES_BASE:=$(basename $(patsubst $(SOL_PATH)%, $(SOL_GEN_PATH)%, $(SOL_FILES)))
FAKE_SOL_ABI_GEN_FILES:=$(patsubst %, %.abi, $(FAKE_SOL_GEN_FILES_BASE))
FAKE_SOL_BIN_GEN_FILES:=$(patsubst %, %.bin, $(FAKE_SOL_GEN_FILES_BASE))
FAKE_SOL_GAS_CHECK_GEN_FILES:=$(patsubst %, %.gasCheck, $(FAKE_SOL_GEN_FILES_BASE))

SOLC_DIR_PATH:=tools/solc
SOLC_PATH:=$(SOLC_DIR_PATH)/solc

ifeq ($(OS),Windows_NT)
else
	ifeq ($(shell uname),Darwin)
		SOLC_PATH=$(SOLC_DIR_PATH)/solc-macos
	else
	endif
endif

ADDR_DIR:=address

ALIANA_CONTRACT_NAME:=Aliana
ALIANA_MINT_CONTRACT_NAME:=AlianaMinting
ALIANA_SALE_CONTRACT_NAME:=AlianaSale
ACTION_CONTRACT_NAME:=Auction
FLASH_SALE_CONTRACT_NAME:=FlashSale
LP_MINT_CONTRACT_NAME:=LPMint
GFS_BONUS_CONTRACT_NAME:=GFSBonus
GFS_MINT_CONTRACT_NAME:=GFSMint
VIEW_CONTRACT_NAME:=GFView
FAKE_ALIANA_CONTRACT_NAME:=FakeAliana
WGFT_CONTRACT_NAME:=WGFT

GENE_ADDR_FILE_BASE:=$(ADDR_DIR)/gene
TOKEN_ADDR_FILE_BASE:=$(ADDR_DIR)/token
GFS_TOKEN_ADDR_FILE_BASE:=$(ADDR_DIR)/gfsToken
ALIANA_ADDR_FILE_BASE:=$(ADDR_DIR)/aliana
ALIANA_SALE_ADDR_FILE_BASE:=$(ADDR_DIR)/alianaSale
ALIANA_MINT_ADDR_FILE_BASE:=$(ADDR_DIR)/alianaMint
AUCTION_ADDR_FILE_BASE:=$(ADDR_DIR)/auction
FLASH_SALE_ADDR_FILE_BASE:=$(ADDR_DIR)/flashSale
VIEW_ADDR_FILE_BASE:=$(ADDR_DIR)/view
FAKE_ALIANA_ADDR_FILE_BASE:=$(ADDR_DIR)/fakeAliana
MIMO_LP_TOKEN_ADDR_FILE_BASE:=$(ADDR_DIR)/lpToken
LP_MINT_ADDR_FILE_BASE:=$(ADDR_DIR)/lpMint
GFS_BONUS_ADDR_FILE_BASE:=$(ADDR_DIR)/gfsBonus
GFS_MINT_ADDR_FILE_BASE:=$(ADDR_DIR)/gfsMint
WGFT_ADDR_FILE_BASE:=$(ADDR_DIR)/WGFT

$(SOL_GEN_PATH)/%.abi: $(SOL_PATH)/%.sol
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --overwrite --optimize --abi $?
	@cp $(SOL_GEN_PATH)/$(basename $(?))/$(notdir $(basename $(?))).abi $(SOL_GEN_PATH)/abi/$(notdir $(basename $(?))).abi

$(SOL_GEN_PATH)/%.bin: $(SOL_PATH)/%.sol
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --overwrite --optimize --bin $?

$(SOL_GEN_PATH)/%.gasCheck: $(SOL_PATH)/%.sol
	@echo gas check: $(?)
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --overwrite --optimize --gas $?

.PHONY: build-sol
build-sol: pre-build-sol ## build sol files
	@"$(MAKE)" -j4 build-sol-worker

.PHONY: build-sol-worker
build-sol-worker: build-sol-bin build-sol-abi ## build sol files

.PHONY: build-sol-bin
build-sol-bin: $(FAKE_SOL_BIN_GEN_FILES) ## build sol files bin

.PHONY: gas-check-sol
gas-check-sol: $(FAKE_SOL_GAS_CHECK_GEN_FILES) ## check sol files gas

.PHONY: build-sol-abi
build-sol-abi: $(FAKE_SOL_ABI_GEN_FILES) ## build sol files abi

.PHONY: clean-build-sol
clean-build-sol: ## clean build sol files 
	@rm -rf $(SOL_GEN_PATH)

.PHONY: pre-build-sol
pre-build-sol: ## pre build sol files 
	@mkdir -p $(SOL_GEN_PATH)
	@mkdir -p $(SOL_GEN_PATH)/abi
