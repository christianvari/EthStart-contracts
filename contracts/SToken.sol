// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SToken is ERC20Capped {

    address public campaignAddress;
    uint public maxSupplyToken;

    modifier restricted(){
        assert(msg.sender == campaignAddress);
        _;
    }

    constructor(uint256 maxSupply, string memory name, string memory symbol ) public ERC20(name, symbol) ERC20Capped(maxSupply) {
        campaignAddress = msg.sender;
        maxSupplyToken = maxSupply;
    }

    function sendTokens(uint256 amount, address sender) public restricted{
        _mint(sender, amount);
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