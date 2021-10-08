const Campaign = artifacts.require("Campaign");
const Factory = artifacts.require("CampaignFactory");
const Token = artifacts.require("Token");
const StartGovernor = artifacts.require("StartGovernor");
const BN = require("bn.js");

let factory;
let campaign;
let token;
let governor;
let campaignAddress;
const TIMEOUT = 30;
const timeout = new BN(Date.now() / 1000 + TIMEOUT);

contract("Unit tests", (accounts) => {
    it("deploys a factory and a campaign", async () => {
        factory = await Factory.new();
        await factory.createCampaign(
            "titolo prova",
            "immagine bellissima",
            "descrizione figa",
            web3.utils.toWei("10000", "ether"),
            "Prova",
            "PROV",
            timeout,
        );

        const res = await factory.getCampaigns(0, 1, true);
        campaign = await Campaign.at(res.values[0]);

        campaignAddress = campaign.address;

        assert.equal(res.len.toNumber(), 1);
        assert.ok(factory.address);
        assert.ok(campaign.address);
    });

    it("marks caller as Campaign manager", async () => {
        const res = await campaign.manager();
        assert.equal(res, accounts[0]);
    });

    it("allows person to contribute and mark as contributor", async () => {
        const amount = web3.utils.toWei("5", "ether");
        await campaign.contribute({
            from: accounts[1],
            value: amount,
        });
        const balance = await campaign.contributerBalanceOf(accounts[1]);

        assert.equal(balance, amount);
    });

    it("check that timer is not elapsed", async () => {
        const res = await campaign.timeout();

        assert.ok(res.toNumber() * 1000 > Date.now(), "timer elapsed");
    });

    it("wait for timeout", async () => {
        await new Promise((r) => setTimeout(r, (TIMEOUT + 5) * 1000));

        const res = await campaign.timeout();
        assert.ok(res.toNumber() * 1000 < Date.now(), "timer not elapsed");
    });

    it("finalize funding", async () => {
        await factory.finalizeCrowdfunding(campaignAddress);
        const isFunded = await campaign.isCampaignFunded();
        assert(isFunded);
    });

    // it("redeem tokens", async () => {
    //     await campaign.redeem({ from: accounts[1] });
    //     await campaign.redeem({ from: accounts[2] });
    // });

    // it("make a request", async () => {
    //     await campaign.createRequest(
    //         "Buy batteries",
    //         "Descriptionnnn",
    //         web3.utils.toWei("1", "ether"),
    //         accounts[1],
    //         "5",
    //     );
    // });

    // it("vote request", async () => {
    //     await campaign.approveRequest(0, { from: accounts[2] });
    // });

    // it("finalize request", async () => {
    //     await new Promise((r) => setTimeout(r, 6000));
    //     await campaign.finalizeRequest(0, { from: accounts[2] });
    // });
});
