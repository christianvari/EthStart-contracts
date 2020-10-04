const Campaign = artifacts.require("Campaign");
const Factory = artifacts.require("CampaignFactory");
const SToken = artifacts.require("SToken");
const SGovernance = artifacts.require("SGovernance");
const BN = require("bn.js");

let factory;
let campaign;
let token;
let governance;

contract("Unit tests", (accounts) => {
    it("deploys a factory and a campaign", async () => {
        factory = await Factory.new();
        await factory.createCampaign(
            web3.utils.toWei("0.000001", "ether"),
            "titolo prova",
            "immagine bellissima",
            "descrizione figa",
            "10000000",
            "Prova",
            "PROV",
            "10",
        );
        let [campaignAddress] = await factory.getDeployedCampaigns();
        campaign = await Campaign.at(campaignAddress);
        assert.ok(factory.address);
        assert.ok(campaign.address);
    });

    it("marks caller as Campaign manager", async () => {
        const summary = await campaign.getCampaignSummary();
        const manager = summary[2];
        assert.equal(manager, accounts[0]);
    });

    it("allows person to contribute and mark as contributor", async () => {
        const amount = web3.utils.toWei("5", "ether");
        await campaign.contribute({
            from: accounts[1],
            value: amount,
        });
        const balance = await campaign.balanceOf({
            from: accounts[1],
        });
        assert.equal(balance, amount);
    });

    it("buy all remaining tonkes", async () => {
        let summary = await campaign.getFundingSummary();
        assert(summary[1].gt(new BN(parseInt(Date.now() / 1000))), "timer elapsed");
        const availableAmount = summary[0].mul(
            new BN(web3.utils.toWei("0.000001", "ether")),
        );

        await campaign.contribute({
            from: accounts[2],
            value: availableAmount,
        });

        summary = await campaign.getFundingSummary();
        assert.equal(summary[0], 0, "tokens finished");
    });

    it("wait for timeout", async () => {
        await new Promise((r) => setTimeout(r, 15000));

        const summary = await campaign.getFundingSummary();
        assert(summary[1].lt(new BN(parseInt(Date.now() / 1000))), "timer not elapsed");
        assert.equal(summary[0], 0, "disponible tokens left");
    });

    it("finalize funding", async () => {
        await campaign.finalizeCrowdfunding();
        const summary = await campaign.getCampaignSummary();
        const isFunded = summary[6];
        assert(isFunded);
    });

    it("redeem tokens", async () => {
        await campaign.redeem({ from: accounts[1] });
        await campaign.redeem({ from: accounts[2] });
    });

    it("make a request", async () => {
        await campaign.createRequest(
            "Buy batteries",
            "Descriptionnnn",
            web3.utils.toWei("1", "ether"),
            accounts[1],
            "5",
        );
    });

    it("vote request", async () => {
        await campaign.approveRequest(0, { from: accounts[2] });
    });

    it("finalize request", async () => {
        await new Promise((r) => setTimeout(r, 6000));
        await campaign.finalizeRequest(0, { from: accounts[2] });
    });
});
