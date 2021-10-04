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
    uint256 public endBlock;
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
        assert(block.number <= endBlock);
        _;
    }
    modifier afterTimeout() {
        assert(block.number > endBlock);
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
        uint256 _endBlock
    ) {
        assert(block.number <= _endBlock && _tokenMaxSupply > 0 );

        initiator = msg.sender;
        title = _title;
        imageURL = _imageURL;
        description = _description;
        tokenMaxSupply = _tokenMaxSupply;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        manager = _manager;
        endBlock = _endBlock;
        isCampaignFunded = false;
    }

    function contribute() public payable beforeTimeout {
        require(msg.value > 0);
        uint256 depositedAmount = contributersDeposits[msg.sender];
        if (depositedAmount == 0) contributersAddresses.push(msg.sender);
        contributersDeposits[msg.sender] = depositedAmount + msg.value;
    }

    function contributerBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return contributersDeposits[account];
    }

    function finalizeCrowdfunding() public afterTimeout restricted {
        Token token = new Token(tokenMaxSupply, tokenName, tokenSymbol);
        tokenAddress = address(token);
        StartGovernor governor = new StartGovernor(token, title);
        governanceAddress = address(governor);
        token.sendTokens(tokenMaxSupply / 4, manager);
        isCampaignFunded = true;
    }

    function redeem() public afterTimeout {
        if (isCampaignFunded) {
            uint256 depositedAmount = contributersDeposits[msg.sender];
            require(depositedAmount > 0);
            Token(tokenAddress).sendTokens(
                (depositedAmount / address(this).balance) * tokenMaxSupply,
                msg.sender
            );
        } else {
            uint256 depositedAmount = contributersDeposits[msg.sender];
            (bool sent, ) = msg.sender.call{value: depositedAmount}("");
            require(sent, "Failed to send Ether");
        }
        contributersDeposits[msg.sender] = 0;
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

    // function getCampaignSummary()
    //     public
    //     view
    //     returns (
    //         address,
    //         string memory,
    //         string memory,
    //         string memory,
    //         bool,
    //         uint256
    //     )
    // {
    //     return (
    //         manager,
    //         title,
    //         description,
    //         imageURL,
    //         isCampaignFunded,
    //         tokenMaxSupply
    //     );
    // }

    // function getFundingSummary()
    //     public
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         address[] memory,
    //         string memory,
    //         string memory
    //     )
    // {
    //     return (
    //         address(this).balance,
    //         endBlock,
    //         contributersAddresses,
    //         tokenName,
    //         tokenSymbol
    //     );
    // }
}
