// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import {Campaign} from "./Campaign.sol";
import {SToken} from "./sToken.sol";


contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum, string memory title, string memory subtitle, string memory image, string memory description,uint256 tokenMaxSupply, string memory tokenName, string memory tokenSymbol) public {
        address newCampaign = address(new Campaign(minimum, msg.sender, title, subtitle, image, description, tokenMaxSupply, tokenName, tokenSymbol));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
}