// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SToken is ERC20Capped {

    address public campaignAddress;
    uint public minimumBuy;

    modifier restricted(){
        assert(msg.sender == campaignAddress);
        _;
    }

    constructor(address owner, uint256 maxSupply, string memory name, string memory symbol, uint minBuy ) public ERC20(name, symbol) ERC20Capped(maxSupply) {
        _mint(owner, maxSupply/4);
        campaignAddress = msg.sender;
        minimumBuy= minBuy;
    }

    function getTokenQuantity(uint256 depositedAmount, string memory symbol ) internal view returns(uint){
        // uint256 price = 400;  //openFeedOracle.price(symbol);
        return depositedAmount/minimumBuy;
    }

    function sendTokens(uint256 depositedAmount, string memory symbol, address sender) public restricted{
        require(depositedAmount > minimumBuy, "The minimum contribution is not satisfied");

        uint256 amount = getTokenQuantity(depositedAmount, symbol);
        _mint(sender, amount);
    }
    
}