pragma solidity ^0.4.11;


contract Certificates {

  // index of created Certificates

  address[] public certificates;
  //when the certificate is created by the issuing party
    event Created(address indexed certificate);
  // useful to know the row count in Certificates index

  function getCertificateCount() 
    public
    constant
    returns(uint)
  {
    return certificates.length;
  }

  // deploy a new Certificate

  function newCertificate()
    public
    returns(address)
  {
    Certificate c = new Certificate(msg.sender);
    certificates.push(c);
    Created(c);
    return c.getIssuerAddress();
  }
}


/** @title Certificate. */
contract Certificate {
 
 //assignee
 struct Contact {
     //name of contact
     string  name;
     //name of the company for contact
     string  company;
     //email for the conact
     string email;
     //address for the conat
    address publicAddress;
  }
 
  //certificate issuer 
  struct Issuer {
     //issuer contact details 
    Contact issuerDetail;
    //designation of the issuer
    string designation;
    //logo path fot the logo dsplayed on the certifcate
    string logo;
  }
 
  //certificate approver 
  struct Approver {
      //approver contact details
    Contact approverDetail;
    //approver deignation
    string designation;   
  }
  
  //owner of the cetificte contract
  address public  owner;

  //current state of the contract  
  enum State {
        /*Created: certificate has been created, but awaiting addition of details
        Pending: details added, awaiting signatures from issuer and approver
        Issued: all signatures received, certificate is valid.
        Expired: certificate has expired without receiving a 'completed' Event*/
        Created, Pending, Issued, Expired, Revoked
    }
   //this will hold the current state of the certifcate  
    State private state = State.Created;

    //This structure will hold the dates for the certificate
    struct Dates {
        //date the certificate is created + requested
        uint created;
       
        //date the certificate is signed by all parties and is officially issued
        uint issued;
       
        //date the certificate is certified by the approving authority
        uint completed;

        //default expiration date of the certificate, exercised only if  never verified by approving authority
        uint expired;

        //date the certificate is revoked by the issuing/revoked authority
        uint revoked;

        //certificate expiry date
        uint expiry;
    }
    
    //intialis current date
    Dates public dates = Dates(now, 0, 0, 0,0,0);
    
    //issuer who will issue the certificate
    Issuer issuer;
    
    //assignee to whom certifcate is assigned
    Contact assignee;
        
    //approver needs to approve the certifcate
    Approver approver;
    
    //Will hold the signatures
    struct Signature {
        //when was signed
        uint date;
        //who signed
        address owner;
    }

    //Who will sign the certificates
    struct Signatures {
        //need issuer signature
        Signature issuer;
        // need approver signature
        Signature approver;
    }

    Signatures private signatures;

    //Course for which this certificate is approved.
    struct Course {
      string name;
      string courseType;
      string completionCriteria;
      uint completed;
    }

    //we can add list of courses for which this certficate is generated
    Course[] public courses;
   
    //when the certificate is created by the issuing party
    event Created(address indexed certificate);

    //when the Courses have been added, and the certificate is awaiting signing by parties and authorities
    event Pending(address indexed certificate,
        address issuerAddress,
        address assigneeAddress,
        address approverAddress);

    //when all required parties and authorities have signed the certificate
    event Issued(address indexed certificate);

    //when a certificate has been signed by a party of authority's agent
    event Signed(address by);

    //when the certificate is expired
    event Expired(address indexed certificate);

    //when certificate issuer changed
    event IssuerChanged(address oldaddress, address newaddress);

    //when certificate approver changed
    event ApproverChanged(address oldaddress, address newaddress);

    //when certificate assignee changed
    event AssigneeChanged(address oldaddress, address newaddress);

    //when certificate expiry changed
    event ExpiryChanged(uint oldExpiry, uint newExpiry);

    //when a certificate is revoked 
    event Revoked(address from);

    /*
    Certificates should be created by the issuer
    params:
    - issuer - issuer address we can aslo use msg.sender
    - assignee - assignee address
    - approver- approver address    
    */
    function Certificate(address _issuerAddress) {
            owner = _issuerAddress;
            issuer.issuerDetail.publicAddress = _issuerAddress;
            //assignee.publicAddress = _assigneeAddress;
            //approver.approverDetail.publicAddress = _approverAddress;
            //intialise to 365 days
            uint expirationDateTimeFromNow = now + (60 * 60 * 24 * 365);     
            signatures = Signatures(
                    Signature(now, _issuerAddress),
                    Signature(0,0x0));
                dates = Dates(now, 0, 0, expirationDateTimeFromNow,0,0);
            Created(this);
    }

    function kill() {
        if (msg.sender == owner && state == State.Pending) {
            selfdestruct(owner);
        }
    }

   modifier onlyIssuer() { // only issuer Modifier
        require(msg.sender == issuer.issuerDetail.publicAddress);
        _;
    }
    modifier onlyApprover() { // only approver Modifier
        require(msg.sender == approver.approverDetail.publicAddress);
        _;
    }
    
    modifier onlyAssignee() { // only assigne Modifier
        require(msg.sender == assignee.publicAddress);
        _;
    }
    
    modifier onlyMembers() {//either issuer/ approver or assignee
       require(msg.sender == issuer.issuerDetail.publicAddress || msg.sender == approver.approverDetail.publicAddress || msg.sender == assignee.publicAddress);
      _;
    } 

    //add courses for the certificate with completed date time
    function addCourse(string name, string courseType, string completionCriteria, uint completed) onlyIssuer {
        if (state != State.Created) {
            revoke();
        }
        // can be multiple but only one used currently
        courses.push(Course(name, courseType, completionCriteria,completed));
    }

    //completed adding all the courses make it pending 
    function completedAddingCoursed() onlyIssuer {
        if (state != State.Created) {
            return;
        }
        state = State.Pending;
        Pending(this, issuer.issuerDetail.publicAddress, assignee.publicAddress, approver.approverDetail.publicAddress);
    }

    //get assignee address
    function getAssigneeAddress() constant returns (address) {
        return assignee.publicAddress;
    }

    //get issuer address
    function getIssuerAddress() constant returns (address) {
        return issuer.issuerDetail.publicAddress;
    }    

    //get approver address
    function getApproverAddress() constant returns (address) {
        return approver.approverDetail.publicAddress;
    }

    //get signatures from signer list
    function getSignatures() constant returns (uint[2]) {
        return [signatures.issuer.date,
            signatures.approver.date
        ];
    }

    //whether the cert can be signed 
    function canSign() constant returns (bool) {
        return(state==State.Pending);
    }

    //approve the certificate and raise issued event
    function sign() onlyApprover {
        if (state != State.Pending) {
            revert();
        }
        signatures.approver = Signature(now, msg.sender);
        dates.issued = now;
        state = State.Issued;
        Issued(this);
    }
    
    //revoke the certificate and raise revoked event
    function revoke() onlyIssuer {
      if (state == State.Issued) {
      state = State.Revoked;
      dates.revoked = now;
      Revoked(this);
      } else {
          revert();
      }
    }

    //expire the certificate if the certificate expiry has been set. Raise expired event
    function expireIfNecessary() {
        if (dates.expiry > 0 && now >= dates.expiry && state == State.Issued) {
            state = State.Expired;
            dates.expired = now;
        }
        Expired(this);
    }

    // if the certificate is expired. Either expiry = 0 means never expires
    function isExpired()  constant returns (bool) {
        return (state == State.Expired || (dates.expiry > 0 && now >= dates.expiry));
    }

    //if the certificate is valid (issue and non expired)
    function isValid()  onlyMembers constant returns (bool) {
        return (state == State.Issued && (dates.expiry==0 || now < dates.expiry));
    }

    //set issuer details only issuer can change the details 
    function setIssuer(string _name,string _designation,string _logo, string _email, string _company ) onlyIssuer {
        if (state == State.Created) {
            issuer.issuerDetail.name = _name;
            issuer.issuerDetail.email = _email;
            issuer.issuerDetail.company = _company;
            issuer.designation = _designation;
            issuer.logo = _logo;
        } else {
            revert();
        }
    }
    //set issuer details only issuer can change the details 
    function setIssuer(address _issuerAddress, string _name,string _designation,string _logo, string _email, string _company ) onlyIssuer {
        if (state == State.Created) {
            issuer.issuerDetail.publicAddress = _issuerAddress;
           setIssuer(_name,_designation,_logo,_email,_company);
        } else {
            revert();
        }
    }

    //set approver details only issuer can change the details.Raise approver changed event 
    function setApprover(string _name, string _email, string _company,string _designation, address _approverAddress ) onlyIssuer {
        if (state == State.Created || state == State.Pending) {
            address oldAddress = approver.approverDetail.publicAddress;
            approver.approverDetail.publicAddress = _approverAddress;
            approver.approverDetail.name = _name;
            approver.approverDetail.email = _email;
            approver.approverDetail.company = _company;
            approver.designation = _designation;
            ApproverChanged(oldAddress, _approverAddress);
        } else {
            revert();
        }
    }

    //set assignee details only issuer can change the details.Raise assignee changed event 
    function setAssignee(string _name, string _email, string _company, address _assigneeAddress,uint _expiry ) onlyIssuer {
        if (state == State.Created || state == State.Pending) {
            address oldAddress = assignee.publicAddress;
            assignee.publicAddress = _assigneeAddress;
            assignee.name = _name;
            assignee.email = _email;
            assignee.company = _company;
            AssigneeChanged(oldAddress, _assigneeAddress);
            dates.expiry = _expiry;
        } else {
            revert();
        }
    }

    //change certexpiry and raise expiry changed event
    function changeCertificateExpiry(uint _expiry) onlyIssuer {
        if (state == State.Created || state == State.Pending || state == State.Expired) {
            uint oldExpiry = dates.expiry;
            dates.expiry = _expiry;
            dates.expired = 0;//reset expired
            ExpiryChanged(oldExpiry,_expiry);
        }else {
            revert();
        }
    }

    //get the certificate issuer
    function getIssuer() constant returns  (string  name,string email, string company, string designation,string logo){
      name = issuer.issuerDetail.name;
      email = issuer.issuerDetail.email; 
      company = issuer.issuerDetail.company;
      designation = issuer.designation;
      logo = issuer.logo;
    }
    
    //get the approver
    function getApprover() constant returns (string  name,string email, string company, string designation) {
      name = approver.approverDetail.name;
      email = approver.approverDetail.email; 
      company = approver.approverDetail.company;
      designation = approver.designation;
    }

    //get assignee
    function getAssignee() constant returns (string  name,string email, string company) {
      name = assignee.name;
      email = assignee.email; 
      company = assignee.company;
    }

    //get the first course
    function getCourse() constant returns (string  name,string courseType, string completionCriteria, uint completed) { 
     name = courses[0].name;
     courseType = courses[0].courseType; 
     completionCriteria = courses[0].completionCriteria;
     completed = courses[0].completed;
    }

    //this is the properitory function getting the hash
    function getHashValue() onlyMembers returns (string hashvalue) {
        return "hashvaluebasedonassigneenameissuenameandapprovername" ; 
    }

    function validateCertificate(address assigneeAddress, string assigneeName, string hashValue) returns (bool isvalid) {
        //use assigne name address to generate the hashvalue and compares"
        string memory currenthashvalue = "hashvaluebasedonassigneenameissuenameandapprovername"; 
        isvalid = false;
        if (assignee.publicAddress == assigneeAddress && sha3(assignee.name) == sha3(assigneeName) && sha3(currenthashvalue) ==sha3(hashValue)) {
            if (State.Issued == state) {
                if ((dates.expiry == 0 && now < dates.expiry)) {
                    isvalid = true;
                }
            }
        }
    }
}