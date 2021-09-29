// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.2 <0.9.0;
import {Token} from "./Token.sol";
import {StartGovernor} from "./StartGovernor.sol";

contract Campaign {

    struct Details {
        string[5] info; //[title, description, imageURL, tokenName, tokenSymbol]
        uint tokenMaxSupply;
        address manager;
    }

    struct Funding {
        address[] contributersAddresses;
        mapping(address=>uint) contributersDeposits;
        uint endBlock;
    }

    Details details;
    Funding funding;

    bool isCampaignFunded;
    address public tokenAddress;
    address public governanceAddress;

    modifier restricted(){
        assert(msg.sender == details.manager);
        _;
    }
    modifier beforeTimeout(){
        assert(block.number <= funding.endBlock);
        _;
    }
    modifier afterTimeout(){
        assert(block.number > funding.endBlock);
        _;
    }
    modifier isCampaignFundedModifier(){
        assert(isCampaignFunded);
        _;
    }

    constructor(address m, string memory title, string memory imageURL, string memory description, uint tokenMaxSupply,string memory tokenName, string memory tokenSymbol, uint _endBlock) {
        assert(tokenMaxSupply > 0);
        
        details = Details({
            info: [title, description, imageURL,tokenName,tokenSymbol],
            tokenMaxSupply:tokenMaxSupply,
            manager:m
        });

        funding.endBlock = _endBlock;
        isCampaignFunded = false;
    }

    function contribute() public payable beforeTimeout {
        require(msg.value > 0);
        uint depositedAmount = funding.contributersDeposits[msg.sender];
        if(depositedAmount == 0)
            funding.contributersAddresses.push(msg.sender);
        funding.contributersDeposits[msg.sender] = depositedAmount + msg.value;
    }

    function contributerBalanceOf(address account) public view returns(uint){
        return funding.contributersDeposits[account];
    }

    function finalizeCrowdfunding() public restricted afterTimeout {
        Token token = new Token(details.tokenMaxSupply, details.info[3], details.info[4]);
        tokenAddress = address(token);
        StartGovernor governor = new StartGovernor(token ,details.info[3]);
        governanceAddress = address(governor);
        token.sendTokens(details.tokenMaxSupply / 4, msg.sender);
        isCampaignFunded = true;
    }
    function redeem() public afterTimeout {
        if(isCampaignFunded){
            uint depositedAmount = funding.contributersDeposits[msg.sender];
            require(depositedAmount>0);
            Token(tokenAddress).sendTokens(depositedAmount / address(this).balance * details.tokenMaxSupply, msg.sender);
        } else {
            uint depositedAmount = funding.contributersDeposits[msg.sender];
            (bool sent,) = msg.sender.call{value: depositedAmount}("");
            require(sent, "Failed to send Ether");

        }
        funding.contributersDeposits[msg.sender] = 0;
    }

    // function createRequest(string memory t, string memory desc, uint value, address payable recipient, uint time) public afterTimeout isCampaignFundedModifier {
    //     require(sToken.balanceOf(msg.sender) > details.tokenMaxSupply/10);
    //     sGovernance.createRequest(msg.sender, t, desc, value, recipient, time);
    // }

    // function approveRequest(uint requestId) public afterTimeout isCampaignFundedModifier {
    //     uint balance = sToken.balanceOf(msg.sender);
    //     require( balance > 0, "You havent tokens");

    //     sGovernance.approveRequest(requestId, msg.sender, balance);
    // }

    // function finalizeRequest(uint id) public afterTimeout isCampaignFundedModifier{

    //     sGovernance.finalizeRequest(id, sToken.totalSupply());
    //     (bool isApproved, address payable recipient, uint value) = sGovernance.getRequestStatus(id);
    //     if(isApproved)
    //         recipient.transfer(value);
    // }

    function getCampaignSummary() public view returns(address, string memory, string memory, string memory, bool, uint){
        return(
            details.manager,
            details.info[0],
            details.info[1],
            details.info[2],
            isCampaignFunded,
            details.tokenMaxSupply
        );
    }

    function getFundingSummary() public view returns(uint, uint, address[] memory, string memory, string memory){
        return (
            address(this).balance, 
            funding.endBlock, 
            funding.contributersAddresses,
            details.info[3],
            details.info[4]
        );
    }
}