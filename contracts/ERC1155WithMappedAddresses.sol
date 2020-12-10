//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC1155.sol";

contract ERC1155WithMappedAddresses is ERC1155 {
    mapping(address => address) public originalAddresses; // mapping from old to new account addresses

    constructor (string memory uri_) ERC1155(uri_) { }

    /// Don't forget to override also _upgradeAccounts().
    function lastAddress(address account) public virtual view returns (address) {
        return account;
    }

    // Internal functions //

    function _upgradeAccounts(address[] memory accounts, address[] memory newAccounts) internal virtual view {
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
}