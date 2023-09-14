var AuctionCreator = artifacts.require("AuctionCreator");

module.exports = function(deployer) {
    deployer.deploy(AuctionCreator);
}