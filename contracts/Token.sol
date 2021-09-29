// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes {

    address public campaignAddress;
    uint256 maxSupplyToken;

    modifier restricted(){
        assert(msg.sender == campaignAddress);
        _;
    }

    constructor( uint256 _maxSupply, string memory _name, string memory _symbol ) ERC20(_name, _symbol) ERC20Permit(_name) {
        campaignAddress = msg.sender;
        maxSupplyToken = _maxSupply;
    }

    function sendTokens(uint256 amount, address sender) public restricted{
        _mint(sender, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function getSummary() public view returns(uint, uint, string memory, string memory){
        return(
            totalSupply(),
            maxSupplyToken,
            name(),
            symbol()
        );
    }
}