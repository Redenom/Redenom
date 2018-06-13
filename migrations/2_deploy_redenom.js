// http://truffleframework.com/docs/getting_started/migrations

var Redenom = artifacts.require("Redenom");
// The name specified should match the name of the contract definition within that source file.
// Do not pass the name of the source file, as files can contain more than one contract.

module.exports = function(deployer, network, accounts) { // , network, accounts - aditional for conv.

	console.log("main acc:" , accounts[0]);

  	if (network == "development" || network == "devex") {
      	// Do something specific to the network named "main".
      	deployer.deploy(Redenom, {from: accounts[0]});
    } 
	
};

