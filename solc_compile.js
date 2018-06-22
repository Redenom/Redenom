var fs = require("fs");
var solc = require('solc'); //v0.4.24+commit.e67f0147


fs.readFile("contracts/Redenom.sol", "utf8", function(err, data) {
	if(!err){

		var input = {
			//'lib.sol': 'library L { function f() returns (uint) { return 7; } }',
			'Redenom.sol': data
		}

		//console.log(data);

		try{
			var output = solc.compile({ sources: input }, 1);

			console.log(output)

			for (var contractName in output.contracts){
				console.log('------------------ ' + contractName + ' ------------------------');
				console.log(output.contracts[contractName].bytecode);
				console.log('------------------ /' + contractName + ' ------------------------');

				cname = contractName.replace(":","_");
				fname = "solc/bin/" + Date.now() + "_" + cname + '.txt';
				bytec = output.contracts[contractName].bytecode;

				fs.writeFile(fname, bytec, function(err) {
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