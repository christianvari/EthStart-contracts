// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.2 <0.9.0;
import {Token} from "./Token.sol";
import {StartGovernor} from "./StartGovernor.sol";

contract Campaign {
    address public initiator;

    string public title;
    string public description;
    string public imageURL;
    string public tokenName;
    string public tokenSymbol;

    uint256 public tokenMaxSupply;
    address public manager;
    uint256 public timeout;
    uint256 public creationTimestamp;
    bool public isCampaignFunded;

    address[] contributersAddresses;
    mapping(address => uint256) contributersDeposits;

    address public tokenAddress;
    address public governanceAddress;

    modifier restricted() {
        assert(msg.sender == initiator);
        _;
    }

    modifier beforeTimeout() {
        assert(block.timestamp <= timeout);
        _;
    }
    modifier afterTimeout() {
        assert(block.timestamp > timeout);
        _;
    }
    modifier isCampaignFundedModifier() {
        assert(isCampaignFunded);
        _;
    }

    constructor(
        address _manager,
        string memory _title,
        string memory _imageURL,
        string memory _description,
        uint256 _tokenMaxSupply,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _timeout
    ) {
        assert(block.timestamp <= _timeout && _tokenMaxSupply > 0);

        initiator = msg.sender;
        title = _title;
        imageURL = _imageURL;
        description = _description;
        tokenMaxSupply = _tokenMaxSupply;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        manager = _manager;
        timeout = _timeout;
        creationTimestamp = block.timestamp;
        isCampaignFunded = false;
    }

    function contribute() external payable beforeTimeout {
        require(msg.value > 0);
        uint256 depositedAmount = contributersDeposits[msg.sender];
        if (depositedAmount == 0) contributersAddresses.push(msg.sender);
        contributersDeposits[msg.sender] = depositedAmount + msg.value;
    }

    function contributerBalanceOf(address account)
        external
        view
        returns (uint256)
    {
        return contributersDeposits[account];
    }

    function finalizeCrowdfunding() external restricted {
        Token token = new Token(tokenMaxSupply, tokenName, tokenSymbol);
        tokenAddress = address(token);
        StartGovernor governor = new StartGovernor(token, title);
        governanceAddress = address(governor);
        isCampaignFunded = true;
        token.sendTokens(tokenMaxSupply / 4, manager);
    }

    function redeem() external afterTimeout {
        if (isCampaignFunded) {
            uint256 depositedAmount = contributersDeposits[msg.sender];
            require(depositedAmount > 0);
            contributersDeposits[msg.sender] = 0;
            Token(tokenAddress).sendTokens(
                (depositedAmount * tokenMaxSupply) / address(this).balance,
                msg.sender
            );
        } else {
            uint256 depositedAmount = contributersDeposits[msg.sender];
            contributersDeposits[msg.sender] = 0;
            (bool sent, ) = msg.sender.call{value: depositedAmount}("");
            assert(sent);
        }
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
}
