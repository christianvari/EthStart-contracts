// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.2 <0.9.0;
import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    address[] public runningCampaigns;
    address[] public fundedCampaigns;

    function createCampaign(
        string memory title,
        string memory image,
        string memory description,
        uint256 tokenMaxSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 timeout
    ) public {
        address newCampaign = address(
            new Campaign(
                msg.sender,
                title,
                image,
                description,
                tokenMaxSupply,
                tokenName,
                tokenSymbol,
                timeout
            )
        );
        runningCampaigns.push(newCampaign);
    }

    function finalizeCrowdfunding(address campaignAddress, uint256 index)
        public
    {
        assert(
            runningCampaigns.length + 1 <= index &&
                runningCampaigns[index] == campaignAddress
        );
        Campaign c = Campaign(campaignAddress);
        assert(c.manager() == msg.sender && block.number > c.endBlock());
        c.finalizeCrowdfunding();
        fundedCampaigns.push(runningCampaigns[index]);
        runningCampaigns[index] = runningCampaigns[runningCampaigns.length - 1];
        runningCampaigns.pop();
    }

    function getCampaigns(uint256 cursor, uint256 howMany, bool isRunning)
        public
        view
        returns (address[] memory values, uint256 len)
    {
        uint256 length = howMany;
        address[] memory arr = isRunning ? runningCampaigns : fundedCampaigns;
        if (length > arr.length - cursor) {
            length = arr.length - cursor;
        }
        values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = arr[cursor + i];
        }

        return (values, arr.length );
    }
}
