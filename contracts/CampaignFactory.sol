// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.2 <0.9.0;
import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(string memory title, string memory image, string memory description,uint256 tokenMaxSupply, string memory tokenName, string memory tokenSymbol, uint timeout) public {
        address newCampaign = address(new Campaign( msg.sender, title, image, description, tokenMaxSupply, tokenName, tokenSymbol, timeout));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
}