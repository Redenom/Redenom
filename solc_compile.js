var fs = require("fs");
var solc = require('solc'); //v0.4.24+commit.e67f0147




/*
var output = solc.compile({ sources: input }, 1)
for (var contractName in output.contracts)
	console.log(contractName + ': ' + output.contracts[contractName].bytecode)
*/

fs.readFile("contracts/Redenom.sol", "utf8", function(err, data) {
	if(!err){

		var input = {
			//'lib.sol': 'library L { function f() returns (uint) { return 7; } }',
			'Redenom.sol': data
		}

		//console.log(data);


		try{
			var output = solc.compile({ sources: input }, 1);

			/* // debuging metadata
			fs.writeFile("solc/"+ Date.now() +"_debug_data.txt", JSON.stringify(output), function(err) {
			    if(err) {
			        return console.log(err);
			    }
			}); */


			for (var contractName in output.contracts){
				console.log('------------------ ' + contractName + ' ------------------------');
				console.log(output.contracts[contractName].bytecode);
				console.log('------------------ /' + contractName + ' ------------------------');

				cname = contractName.replace(":","_");
				bfname = "solc/bin/" + Date.now() + "_" + cname + '_bytecode.txt';
				bytec = output.contracts[contractName].bytecode;

				fs.writeFile(bfname, bytec, function(err) {
				    if(err) {
				        return console.log(err);
				    }
				}); 

				afname = "solc/bin/" + Date.now() + "_" + cname + '_ABI.txt';
				abi = output.contracts[contractName].interface;

				fs.writeFile(afname, abi, function(err) {
				    if(err) {
				        return console.log(err);
				    }
				}); 

			}


		}catch(_err){
			console.log(_err.msg);
		}


	}else{
		console.log(err.msg);
	}
});