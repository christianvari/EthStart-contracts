// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.0;

contract SGovernance {

    struct Request {
        address creator;
        string[2] info; // [title,description]
        uint[3] uintArray; // [value, approvalsCount, timeout]
        address payable recipient;
        bool[2] status; // [isCompleted, isApproved]
        mapping(address=>bool) approvals;
    }


    Request[] public requests;
    uint public requestsCount;
    address public campaign;

    modifier restricted(){
        assert(msg.sender == campaign);
        _;
    }

    constructor() public {

        campaign = msg.sender;
        requestsCount = 0;
    }

    function createRequest(address c, string memory t, string memory desc, uint value, address payable recipient, uint time) public restricted{
        Request memory newRequest = Request(
            {creator: c,
            info:[t,desc],
            uintArray:[value, 0 , block.timestamp + time],
            recipient:recipient,
            status:[false, false]
            }
        );

        requests.push(newRequest);
        requestsCount++;
    }

    function approveRequest(uint id, address user, uint balance) public restricted{
        Request storage req = requests[id];

        require(!req.status[0], "Request altredy completed");
        require(block.timestamp <= req.uintArray[2], "Timeout is ended");
        require(!req.approvals[user], "You can approve only one time");

        req.approvals[user] = true;
        req.uintArray[1] += balance;
    }

    function finalizeRequest(uint id, uint totalSupply) public restricted{
        Request storage req = requests[id];

        require(!req.status[0], "Request altredy completed");
        require(block.timestamp > req.uintArray[2], "Timeout is not ended");

        req.status[1] = req.uintArray[1] > (totalSupply / 2);
        req.status[0] = true;
    }

    function getRequestStatus(uint id) public view returns(bool, address payable, uint value){
        Request memory req = requests[id];
        return(req.status[1], req.recipient, req.uintArray[0]);
    }

    function getRequestsCount() public view returns(uint){
        return requests.length;
    }
}