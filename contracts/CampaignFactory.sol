// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint tokenPrice, string memory title, string memory image, string memory description,uint256 tokenMaxSupply, string memory tokenName, string memory tokenSymbol, uint timeout) public {
        address newCampaign = address(new Campaign(tokenPrice, msg.sender, title, image, description, tokenMaxSupply, tokenName, tokenSymbol, timeout));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
}