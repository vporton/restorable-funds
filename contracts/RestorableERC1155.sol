//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// import "hardhat/console.sol";
import "./ERC1155.sol";

contract RestorableERC1155 is ERC1155 {
    mapping(address => address) accountMoves;

    constructor (string memory uri_) ERC1155(uri_) { }

    function restoreAccount(address oldAccount_, address newAccount_) public {
        require(allowedRestoreAccount(oldAccount_, newAccount_), "Not permitted.");
        accountMoves[newAccount_] = oldAccount_; // FIXME: or vice versa?
        emit AccountRestored(oldAccount_, newAccount_);
    }

    // TODO: chain
    function restoreFunds(address oldAccount_, address newAccount_, uint256 token_) public {
        checkAllowedRestoreFunds(oldAccount_, newAccount_, token_);

        uint256 amount = _balances[token_][oldAccount_];

        address operator = _msgSender();

        _balances[token_][newAccount_] = _balances[token_][oldAccount_];
        _balances[token_][oldAccount_] = 0;

        emit TransferSingle(operator, oldAccount_, newAccount_, token_, amount);
    }

    // TODO: restoreFundsBatch()

    function allowedRestoreAccount(address /*oldAccount_*/, address /*newAccount_*/) public virtual returns (bool) {
        return false;
    }

    function checkAllowedRestoreFunds(address oldAccount_, address newAccount_, uint256 token_) public virtual {
        
    }

    event AccountRestored(address oldAccount, address newAccount);
}
