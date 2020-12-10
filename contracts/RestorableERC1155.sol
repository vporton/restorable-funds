//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RestorableERC1155 is ERC1155 {
    constructor (string memory uri_) ERC1155(uri_) { }
}
