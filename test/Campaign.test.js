const Campaign = artifacts.require("Campaign");
const Factory = artifacts.require("CampaignFactory");
const SToken = artifacts.require("SToken");

let factory;
let campaign;
let token;

contract("Unit tests", (accounts) => {
    it("deploys a factory and a campaign", async () => {
        factory = await Factory.new();
        await factory.createCampaign(
            1e15,
            "titolo prova",
            "sottotitolo",
            "immagine bellissima",
            "descrizione figa",
            1e10,
            "Prova",
            "PROV",
        );
        let [campaignAddress] = await factory.getDeployedCampaigns();
        campaign = await Campaign.at(campaignAddress);
        token = await SToken.at(await campaign.tokenAddress());
        assert.ok(factory.address);
        assert.ok(campaign.address);
        assert.equal(await token.balanceOf(accounts[0]), 1e10 / 4);
    });

    it("marks caller as Campaign manager", async () => {
        const manager = await campaign.manager();
        assert.equal(manager, accounts[0]);
    });

    it("allows person to contribute and mark as contributor", async () => {
        await campaign.contribute({
            from: accounts[1],
            value: web3.utils.toWei("0.01", "ether"),
        });
        const isContributor = await campaign.isContributor({
            from: accounts[1],
        });
        assert(isContributor);
        const balance = await token.balanceOf(accounts[1]);
        assert(balance, web3.utils.toWei("0.01", "ether"));
    });

    it("requires a minimum contribute", async () => {
        try {
            await campaign.contribute({
                from: accounts[0],
                value: 50,
            });
            assert(false);
        } catch (err) {
            assert(err);
        }
    });

    it("allows a manager to make a payment request", async () => {
        await campaign.createRequest(
            "Buy batteries",
            web3.utils.toWei("1", "ether"),
            accounts[1],
            {
                from: accounts[0],
            },
        );

        const request = await campaign.requests(0);

        assert.equal(accounts[1], request.recipient);
    });

    it("processes request", async () => {
        let initialBalance = await web3.eth.getBalance(accounts[1]);
        initialBalance = parseFloat(web3.utils.fromWei(initialBalance, "ether"));
        console.log("Initial balance " + initialBalance);

        await campaign.contribute({
            from: accounts[0],
            value: web3.utils.toWei("2", "ether"),
        });

        await campaign.createRequest("A", web3.utils.toWei("1", "ether"), accounts[1], {
            from: accounts[0],
        });

        await campaign.approveRequest(0, { from: accounts[0] });
        await campaign.finalizeRequest(0, { from: accounts[0] });

        let balance = await web3.eth.getBalance(accounts[1]);
        balance = parseFloat(web3.utils.fromWei(balance, "ether"));

        console.log("Final balance " + balance);
        assert(balance > initialBalance);
    });
});
