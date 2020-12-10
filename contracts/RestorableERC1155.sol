//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// import "hardhat/console.sol";
import "./ERC1155.sol";

contract RestorableERC1155 is ERC1155 {
    mapping(address => address) public accountMoves; // mapping from old to new account addresses

    constructor (string memory uri_) ERC1155(uri_) { }

    function restoreAccount(address oldAccount_, address newAccount_) public {
        require(allowedRestoreAccount(oldAccount_, newAccount_), "Not permitted.");
        accountMoves[newAccount_] = oldAccount_; // FIXME: or vice versa?
        emit AccountRestored(oldAccount_, newAccount_);
    }

    function restoreFunds(address oldAccount_, address newAccount_, uint256 token_) public
        checkRestoreOperator(newAccount_)
        checkMovedOwner(oldAccount_, newAccount_)
    {
        uint256 amount = _balances[token_][oldAccount_];

        _balances[token_][newAccount_] = _balances[token_][oldAccount_];
        _balances[token_][oldAccount_] = 0;

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

        emit TransferBatch(_msgSender(), oldAccount_, newAccount_, tokens_, amounts);
    }

    function allowedRestoreAccount(address /*oldAccount_*/, address /*newAccount_*/) public virtual returns (bool) {
        return false;
    }

    modifier checkRestoreOperator(address newAccount_) virtual {
        require(
            newAccount_ == _msgSender() || isApprovedForAll(newAccount_, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _;
    }

    modifier checkMovedOwner(address oldAccount_, address newAccount_) virtual {
        for (address account = oldAccount_; account != newAccount_; account = accountMoves[account]) {
            require(account != address(0), "Not a moved owner");
        }
        _;
    }

    event AccountRestored(address oldAccount, address newAccount);
}
