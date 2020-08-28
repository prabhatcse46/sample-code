
import "../stylesheets/app.css";


import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'


import metacoin_artifacts from '../../build/contracts/MetaCoin.json'
import certificate_artifacts from '../../build/contracts/Certificate.json'
import certificatesCollection_artifacts from '../../build/contracts/Certificates.json'


var MetaCoin = contract(metacoin_artifacts);
var CertificatesCollection = contract(certificatesCollection_artifacts);
var Certificate = contract(certificate_artifacts);
var certificatesCollectionContractAddress ='0x57e223ccb8fb7273f92e7bb83b7a6d5b78b55f48';

var accounts;
var account;

window.App = {
  start: function() {
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    MetaCoin.setProvider(web3.currentProvider);
    CertificatesCollection.setProvider(web3.currentProvider);
    Certificate.setProvider(web3.currentProvider);
    
    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;

      }

      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }

      accounts = accs;
      account = accounts[0];
     
      CertificatesCollection.defaults({from: account});
    });
    

    self.getIssuerAddress('0x95ae2b3b692d3ddd0d2d56d3b82738cc0937573c');
    self.getApproverAddress('0x95ae2b3b692d3ddd0d2d56d3b82738cc0937573c');
    $("#certificateAddress").html('0x95ae2b3b692d3ddd0d2d56d3b82738cc0937573c');
    self.isExpired();
 
  },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

   
  getApproverAddress: function(certificateContractAddress) {
    var cert;
    Certificate.at(certificateContractAddress).then(function(instance) {
      cert=instance;
      return cert.getApproverAddress();
    }).then(function(value) {
      $('#approverAddress').html(value.valueOf());
    }).then(function() {
      
      var getHashValue = cert.isExpired(function(error, res) {
        console.log('res: ' + res + 'error: ' + error ); 
      });

    console.log('getHashValue: ' + getHashValue); 

    });
  },
  getIssuerAddress: function(certificateContractAddress) {
      Certificate.at(certificateContractAddress).then(function(instance) {
      return instance.getIssuerAddress();
    }).then(function(value) {
      $('#certificateAddress').html(certificateContractAddress);
      $('#issuersAddress').html(value.valueOf());
     });
  },
  isExpired: function() {
    var certificateContractAddress = $("#certificateAddress").html();
    Certificate.at(certificateContractAddress).then(function(instance) {
    return instance.isExpired();
  }).then(function(value) {
    $('#certificatIsExpired').html(value.valueOf().toString());
    console.log('isExpired  '+ value);
   });
},
getSignatures: function() {
  var certificateContractAddress = $("#certificateAddress").html();
  Certificate.at(certificateContractAddress).then(function(instance) {
  return instance.getSignatures();
}).then(function(value) {
  $('#createDate').html(Date(value[0]));
  $('#approveDate').html(value[1]);
  console.log('getSignatures  '+ value);
 });
},
sign: function() {
  var self = this;
  var ownerAddress = $("#issuersAddress").html();
  var approverAddress = $("#approverAddress").html();
  var certificateContractAddress = $("#certificateAddress").html();
 // Certificate.defaults({from: approverAddress});
  Certificate.at(certificateContractAddress).then(function(instance) {
  return instance.sign({from:approverAddress});
}).then(function(err,value) {
  
  console.log('sign  '+ value + 'error  '+ err);
 });
},

  getIssuer: function() {
    var certificateContractAddress = $("#certificateAddress").html();
    Certificate.at(certificateContractAddress).then(function(instance) {
      return instance.getIssuer();
    }).then(function(value) {
      console.log(value);
      $('#issuerName').html(value[0]);
      $('#issuerEmail').html(value[1]);
      $('#issuerDesignation').html(value[2]);
      $('#issuerCompany').html(value[3]);
     
    }).catch(function(e) {
      console.log(e);
      this.setStatus("Error getting balance; see log.");
    });
  },
    DeployContract: function() {
    var self = this;

    var certsCol;
    CertificatesCollection.at(certificatesCollectionContractAddress).then(function(instance) {
    
      certsCol = instance;
      console.log(instance);
      //certsCol.newCertificate();
       return certsCol.newCertificate();
      }).then(function(value) {
        var newCertificateAddress = value.receipt.logs["0"].address; 
        console.log(value.receipt.logs["0"].address);
       
        $('#certificateAddress').html(newCertificateAddress);
        self.setStatus("Contract Deployed.");
       
        
      }).catch(function(e) {
        console.log(e);
        self.setStatus("Error getting balance; see log.");
    });
  },
   setIssuer: function() {
      var self = this;
      var ownerAddress = $("#issuersAddress").html();
      var certificateContractAddress = $("#certificateAddress").html();
      Certificate.defaults({from: ownerAddress});
      
      Certificate.at(certificateContractAddress).then(function(instance) {
      
      var issuerAddress = $("#_issuerAddress").val();
      var name = $("#_name").val();
      var designation =$("#_designation").val();
      var logo = $("#_logo").val();
      var email = $("#_email").val();
      var company = $("#_company").val();

     //setIssuer(address _issuerAddress, string _name,string _designation,string _logo, string _email, string _company ) 
      return instance.setIssuer(name,designation,logo,email,company);
    }).then(function(value) {console.log('function called');
      self.getIssuer();
      self.setStatus("Complete.");
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting balance; see log.");
    });
  },
  setApprover: function() {
    var self = this;
    var ownerAddress = $("#issuersAddress").html();
    var certificateContractAddress = $("#certificateAddress").html();

    Certificate.defaults({from: ownerAddress});
    Certificate.at(certificateContractAddress).then(function(instance) {

    var issuerAddress = $("#_issuerAddress").val();
    var name = $("#_name").val();
    var designation =$("#_designation").val();
    var logo = $("#_logo").val();
    var email = $("#_email").val();
    var company = $("#_company").val();

    
    return instance.setApprover(name,email,company,designation,issuerAddress);
  }).then(function(value) {
    console.log('Approver set');
    self.getApprover();
    self.setStatus("Approver set Complete.");
  }).catch(function(e) {
    console.log(e);
    self.setStatus("Error getting balance; see log.");
  });
},
getApprover: function() {
  var self = this; 
  var certificateContractAddress = $("#certificateAddress").html();
    Certificate.at(certificateContractAddress).then(function(instance) {
    return instance.getApprover();
  }).then(function(value) {
    console.log(value);

    $('#approverName').html(value[0]);
    $('#approverEmail').html(value[1]);
    $('#approverDesignation').html(value[2]);
    $('#approverCompany').html(value[3]);
    self.getSignatures();
   });
},
 transferOwner: function() {
    var self = this;

    var amount = parseInt(document.getElementById("amount").value);
    var receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    var cert;
    CertificateIssuer.deployed().then(function(instance) {
      cert = instance;
    
      console.log(cert.getOwner());
      return cert.transferOwner(receiver, {from: account});
    }).then(function() {
      
      self.setStatus("Transaction complete! ");
      
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error sending coin; see log.");
    });
  }
};

window.addEventListener('load', function() {
 
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source")
   
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545.");
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }

  App.start();
});
