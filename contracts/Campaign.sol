// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;
import {SToken} from "./sToken.sol";


contract Campaign {

    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalsCount;
        mapping(address=>bool) approvals;
    }

    Request[] public requests;
    uint public requestsCount;
    address public manager;
    uint public minimumContribution;
    address public tokenAddress;
    string public title;
    string public description;
    string public image;
    SToken sToken;

    modifier restricted(){
        assert(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator, string memory t, string memory i, string memory d, uint tokenMaxSupply,string memory tokenName, string memory tokenSymbol) public {
        manager = creator;
        minimumContribution = minimum;
        title = t;
        image = i;
        description = d;
        requestsCount = 0;
        sToken = new SToken(creator, tokenMaxSupply, tokenName, tokenSymbol, minimum);
        tokenAddress = address(sToken);
    }

    function contribute() public payable {
        require(msg.value > minimumContribution, "The minimum contribution is not satisfied");
        sToken.sendTokens(msg.value,"ETH",msg.sender);
    }

    function isContributor() public view returns(bool) {
        return sToken.balanceOf(msg.sender) > 0;
    }

    function createRequest(string memory desc, uint value, address payable recipient) public restricted{
        Request memory newRequest = Request(
            {description:desc,
            value:value,
            recipient:recipient,
            complete:false,
            approvalsCount:0}
        );

        requests.push(newRequest);
        requestsCount++;
    }

    function approveRequest(uint id) public {
        require(sToken.balanceOf(msg.sender) > 0, "You have to contribute");

        Request storage req = requests[id];

        require(! req.approvals[msg.sender], "You can approve only one time");

        req.approvals[msg.sender] = true;
        req.approvalsCount += sToken.balanceOf(msg.sender);
    }

    function finalizeRequest(uint id) public restricted{

        Request storage req = requests[id];

        require(! req.complete, "Request altredy completed");
        require(req.approvalsCount > (sToken.totalSupply() / 2), "Not enough approvers");

        req.recipient.transfer(req.value);
        req.complete = true;

    }

    function getSummary() public view returns(uint, uint, uint, address, string memory, string memory, string memory){
        return(
            minimumContribution,
            address(this).balance,
            requests.length,
            manager,
            title,
            description,
            image
        );
    }

    function getRequestsCount() public view returns(uint){
        return requests.length;
    }
}