//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC1155.sol";

contract RestorableERC1155 is ERC1155 {
    mapping(address => address) public originalAddresses; // mapping from old to new account addresses

    mapping(address => address) public newToOldAccount; // mapping from old to new account addresses

    constructor (string memory uri_) ERC1155(uri_) { }

    function restoreAccount(address oldAccount_, address newAccount_) public {
        require(allowedRestoreAccount(oldAccount_, newAccount_), "Not permitted.");
        newToOldAccount[newAccount_] = oldAccount_;
        emit AccountRestored(oldAccount_, newAccount_);
    }

    // TODO: restoreFunds and restoreFundsBatch does a bad thing with originalAddresses
    // if an operator calls this function several times in a row to restore an account.

    function restoreFunds(address oldAccount_, address newAccount_, uint256 token_) public
        checkRestoreOperator(newAccount_)
        checkMovedOwner(oldAccount_, newAccount_)
    {
        uint256 amount = _balances[token_][oldAccount_];

        _balances[token_][newAccount_] = _balances[token_][oldAccount_];
        _balances[token_][oldAccount_] = 0;

        originalAddresses[newAccount_] = originalAddresses[oldAccount_];

        emit TransferSingle(_msgSender(), oldAccount_, newAccount_, token_, amount);
    }

    function restoreFundsBatch(address oldAccount_, address newAccount_, uint256[] calldata tokens_) public
        checkRestoreOperator(newAccount_)
        checkMovedOwner(oldAccount_, newAccount_)
    {
        uint256[] memory amounts = new uint256[](tokens_.length);
        for (uint i = 0; i < tokens_.length; ++i) {
            uint256 token = tokens_[i];
            uint256 amount = _balances[token][oldAccount_];
            amounts[i] = amount;

            _balances[token][newAccount_] = _balances[token][oldAccount_];
            _balances[token][oldAccount_] = 0;
        }

        originalAddresses[newAccount_] = originalAddresses[oldAccount_];

        emit TransferBatch(_msgSender(), oldAccount_, newAccount_, tokens_, amounts);
    }

    function allowedRestoreAccount(address /*oldAccount_*/, address /*newAccount_*/) public virtual returns (bool) {
        return false;
    }

    function lastAddress(address account) public view returns (address) {
        address newAddress = originalAddresses[account];
        return newAddress != address(0) ? newAddress : account;
    }

    // Overrides //

    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        return super.balanceOf(lastAddress(account), id);
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        address[] memory newAccounts = new address[](accounts.length);
        _upgradeAccounts(accounts, newAccounts);
        return super.balanceOfBatch(newAccounts, ids);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        return super.setApprovalForAll(lastAddress(operator), approved);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return super.isApprovedForAll(lastAddress(account), operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        return super.safeTransferFrom(lastAddress(from), lastAddress(to), id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        return super.safeBatchTransferFrom(lastAddress(from), lastAddress(to), ids, amounts, data);
    }
    
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        return super._mint(lastAddress(account), id, amount, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        return super._mintBatch(lastAddress(to), ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        return super._burn(lastAddress(account), id, amount);
    }

    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        return super._burnBatch(lastAddress(account), ids, amounts);
    }

    // Internal functions //

    function _upgradeAccounts(address[] memory accounts, address[] memory newAccounts) view internal {
        // assert(accounts.length == newAccounts.length);
        for (uint i = 0; i < accounts.length; ++i) {
            newAccounts[i] = lastAddress(accounts[i]);
        }
    }

    // Modifiers //

    modifier checkRestoreOperator(address newAccount_) virtual {
        require(
            newAccount_ == _msgSender() || isApprovedForAll(newAccount_, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _;
    }

    modifier checkMovedOwner(address oldAccount_, address newAccount_) virtual {
        for (address account = oldAccount_; account != newAccount_; account = newToOldAccount[account]) {
            require(account != address(0), "Not a moved owner");
        }
        _;
    }

    // Events //

    event AccountRestored(address oldAccount, address newAccount);
}
