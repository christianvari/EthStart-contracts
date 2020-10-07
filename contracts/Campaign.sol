// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import {SToken} from "./SToken.sol";
import {SGovernance} from "./SGovernance.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';

contract Campaign {

    using SafeMath for uint;

    struct Details {
        string[5] info; //[title, description, imageURL, tokenName, tokenSymbol]
        uint tokenPrice;
        uint tokenMaxSupply;
        address manager;
    }

    struct Funding {
        address[] contributersAddresses;
        mapping(address=>uint) contributersFunds;
        uint tokensAvailibility;
        uint timeout;
        bool isCampaignFunded;
    }

    Details public details;
    Funding public funding;

    address public tokenAddress;
    SToken sToken;

    address public governanceAddress;
    SGovernance sGovernance;

    modifier restricted(){
        assert(msg.sender == details.manager);
        _;
    }
    modifier beforeTimeout(){
        assert(block.timestamp <= funding.timeout);
        _;
    }
    modifier afterTimeout(){
        assert(block.timestamp > funding.timeout);
        _;
    }
    modifier isCampaignFundedModifier(){
        assert(funding.isCampaignFunded);
        _;
    }

    constructor(uint tokenPrice, address m, string memory title, string memory imageURL, string memory description, uint tokenMaxSupply,string memory tokenName, string memory tokenSymbol, uint t) public {
        details = Details({
            info: [title, description, imageURL,tokenName,tokenSymbol],
            tokenPrice:tokenPrice,
            tokenMaxSupply:tokenMaxSupply,
            manager:m
        });

        funding.timeout = block.timestamp.add(t);
        funding.isCampaignFunded = false;
        funding.tokensAvailibility = tokenMaxSupply.sub(tokenMaxSupply.div(4));
    }

    function contribute() public payable beforeTimeout {
        require(msg.value > 0);
        require(funding.tokensAvailibility.mul(details.tokenPrice) >= msg.value, "Not enough tokens disponible");
        uint depositedAmount = funding.contributersFunds[msg.sender];
        if(depositedAmount == 0)
            funding.contributersAddresses.push(msg.sender);
        funding.contributersFunds[msg.sender] = funding.contributersFunds[msg.sender].add(msg.value);
        funding.tokensAvailibility = funding.tokensAvailibility.sub(msg.value.div(details.tokenPrice));
    }

    function allocationBalanceOf() public view returns(uint){
        return funding.contributersFunds[msg.sender];
    }
    function tokensBalanceOf() public view afterTimeout isCampaignFundedModifier returns(uint){
        return sToken.balanceOf(msg.sender);
    }

    function finalizeCrowdfunding() public restricted afterTimeout {
        require(funding.tokensAvailibility == 0);
        sToken = new SToken(details.tokenMaxSupply, details.info[3], details.info[4]);
        tokenAddress = address(sToken);
        sGovernance = new SGovernance();
        governanceAddress = address(sGovernance);
        sToken.sendTokens(details.tokenMaxSupply.div(4), msg.sender);
        funding.isCampaignFunded = true;

    }
    function redeem() public afterTimeout {
        if(funding.isCampaignFunded){
            uint depositedAmount = funding.contributersFunds[msg.sender];
            require(depositedAmount>0);
            sToken.sendTokens(depositedAmount.div(details.tokenPrice), msg.sender);
        } else {
            uint depositedAmount = funding.contributersFunds[msg.sender];
            msg.sender.transfer(depositedAmount);
        }
        funding.contributersFunds[msg.sender] = 0;

    }

    function createRequest(string memory t, string memory desc, uint value, address payable recipient, uint time) public afterTimeout isCampaignFundedModifier {
        require(sToken.balanceOf(msg.sender) > details.tokenMaxSupply.div(10));
        sGovernance.createRequest(msg.sender, t, desc, value, recipient, time);
    }

    function approveRequest(uint requestId) public afterTimeout isCampaignFundedModifier {
        uint balance = sToken.balanceOf(msg.sender);
        require( balance > 0, "You havent tokens");

        sGovernance.approveRequest(requestId, msg.sender, balance);
    }

    function finalizeRequest(uint id) public afterTimeout isCampaignFundedModifier{

        sGovernance.finalizeRequest(id, sToken.totalSupply());
        (bool isApproved, address payable recipient, uint value) = sGovernance.getRequestStatus(id);
        if(isApproved)
            recipient.transfer(value);
    }

    function getCampaignSummary() public view returns(uint, uint, address, string memory, string memory, string memory, bool){
        return(
            details.tokenPrice,
            address(this).balance,
            details.manager,
            details.info[0],
            details.info[1],
            details.info[2],
            funding.isCampaignFunded
        );
    }

    function getFundingSummary() public view returns(uint, uint, address[] memory, string memory, string memory){
        return (
            funding.tokensAvailibility, 
            funding.timeout, 
            funding.contributersAddresses,
            details.info[1],
            details.info[2]
        );
    }
}