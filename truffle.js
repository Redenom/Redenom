module.exports = {
  	networks: {
	    development: {
	      	host: "127.0.0.1",
	      	port: 7555,
	      	network_id: "*" // "*" Match any network id
	    },
	    ropsten: {
	      	host: "127.0.0.1",
	      	port: 4545,
	      	network_id: "3" 
	    },
	    main: {
			host: "127.0.0.1",
		    port: 8545,
      		network_id: "1" 
    	}

  	}
};

// truffle compile --all
// truffle migrate --reset --network development/ropsten/main