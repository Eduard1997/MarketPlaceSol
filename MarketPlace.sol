pragma solidity ^0.5.12;

import './ERCCompToken.sol';


contract MarketPlace {
    
    // actors
    struct Manager {
        string name;
        uint reputation;
    }
    
    struct Freelancer {
        string name;
        uint reputation;
        string categoryOfExpertise;
    }
    
    struct Evaluator {
        string name;
        uint reputation;
        string categoryOfExpertise;
    }
    
    struct SWProd {
        uint SWProdID;
        string description;
        uint DEV;
        uint REV;
        string categoryOfExpertise;
        uint freelancerTime;
        uint evaluatorTime;
        address manager;
    }
    
    struct Financer {
        string name;
    }

    // All the addresses that are registered as managers, freelancers, evaluators or financers
    mapping (address => bool) public registeredAddresses;
    address[] registeredAccounts; 

    // Managers
    mapping (address => bool) public managersAddresses;
    mapping (address => Manager) public managers;
    mapping (uint => address) public SWProdsProposedByManagers;
    
    // Freelancers
    mapping (address => Freelancer) public freelancers;
    mapping (address => bool) public freelancersAddresses;
    mapping (uint => address) public SWProdsAssignedToFreelancers;

    mapping (uint => address[]) public SWProdsApplied;
    mapping (uint => mapping(address => uint)) amountForSWProdsApplied;
    
    // Evaluators
    mapping (address => Evaluator) public evaluators;
    mapping (address => bool) public evaluatorsAddresses;

    mapping (uint => address[]) public SWProdAssignedToEvaluators;
    mapping (uint => address) public acceptedSWProdByEvaluators;
    
    // Financer
    mapping (address => Financer) public financers;
    mapping (address => bool) public financersAddresses;
    
    // ERCCompToken utils - Token contract's address 
    address ERCCompTokenAddress;
    ERCCompToken erccompToken;
    address owner;
    
    // SWProd utils
    uint SWProdID = 0;
    // All SWProds existing in MarketPlace 
    mapping (uint => SWProd) public SWProds;
    // SWProd that were accepted by an evaluator 
    mapping (uint => bool) public acceptedSWProd;
    // SWProd opened in order to be chosen by freelancers 
    mapping (uint => address) public openedSWProd;
    // The solution proposed by a freelancer for a specific SWProd 
    mapping (address => string) public solutions;
    mapping (uint => address) public solutionSWProd;
    // SWProd that need to be evaluated 
    mapping (uint => address) public SWProdsToBeEvaluated;
    
    uint[] resolvedSWProd;
    mapping (uint => address) public refusedSWProdEvaluation;
    SWProd[] public completedSWProd;
    SWProd[] public rejectedSWProd;
    

    
    constructor(address _ERCCompTokenAddress) public  {
        ERCCompTokenAddress = _ERCCompTokenAddress;
        erccompToken = ERCCompToken(ERCCompTokenAddress);
        
        owner = msg.sender;
        
        initMarketPlace(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 
                        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 
                        0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,
                        0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7
                        );
    }
    
    function initMarketPlace(address _managerAddress, address _freelancerAddress, address _evaluatorAddress, address _financerAddress) public {
        managers[_managerAddress] = Manager('Managerul Marian', 5);
        registeredAddresses[_managerAddress] = true;
        managersAddresses[_managerAddress] = true;
        registeredAccounts.push(_managerAddress);
        
        freelancers[_freelancerAddress] = Freelancer("Freelancerul Frant", 5,  "C++");
        registeredAddresses[_freelancerAddress] = true;
        freelancersAddresses[_freelancerAddress] = true;
        registeredAccounts.push(_freelancerAddress);
        
        evaluators[_evaluatorAddress] = Evaluator('Evaluatorul Diana', 5, "C++");
        registeredAddresses[_evaluatorAddress] = true;
        evaluatorsAddresses[_evaluatorAddress] = true;
        registeredAccounts.push(_evaluatorAddress);
        
        // Financer
        financers[_financerAddress] = Financer('Finantatorul Fred');
        registeredAddresses[_financerAddress] = true;
        financersAddresses[_financerAddress] = true;
        registeredAccounts.push(_financerAddress);
    }

    /* Each account has an amount of tokens minted in the constructor of ERCCompToken */
    function registerAsManager(string calldata _name) external {
        require(registeredAddresses[msg.sender] != true, 'Can not assign a new role to a registered address... ');
        managers[msg.sender] = Manager(_name, 5);
        registeredAddresses[msg.sender] = true;
        managersAddresses[msg.sender] = true;
        registeredAccounts.push(msg.sender);
    }
    
    function registerAsFreelancer(string calldata _name, string calldata _categoryOfExpertise) external {
        require(registeredAddresses[msg.sender] != true, 'Can not assign a new role to a registered address... ');
        freelancers[msg.sender] = Freelancer(_name, 5, _categoryOfExpertise);
        registeredAddresses[msg.sender] = true;
        freelancersAddresses[msg.sender] = true;
        registeredAccounts.push(msg.sender);
    }
    
    function registerAsEvaluator(string calldata _name, string calldata _categoryOfExpertise) external {
        require(registeredAddresses[msg.sender] != true, 'Can not assign a new role to a registered address... ');
        evaluators[msg.sender] = Evaluator(_name, 5, _categoryOfExpertise);
        registeredAddresses[msg.sender] = true;
        evaluatorsAddresses[msg.sender] = true;
        registeredAccounts.push(msg.sender);
    }
    
    function registerAsFinancer(string calldata _name) external {
        require(registeredAddresses[msg.sender] != true, 'Error: A registered address cannot be overwritten!');
        financers[msg.sender] = Financer(_name);
        registeredAddresses[msg.sender] = true;
        financersAddresses[msg.sender] = true;
        registeredAccounts.push(msg.sender);
    }
    

    function getRegisteredAccounts() public view returns(uint) {
        return registeredAccounts.length;
    }
    
    function getAccountBalance(address _account) public view returns(uint) {
        return erccompToken.balanceOf(_account);        
    }
    
    // Warning... This method should be called before createSWProd method... It provides an allowance regarding the transfered amount of tokens...
    function approveAmountOfTokensForSWProdCreation(address _managerAddress, uint _DEV, uint _REV) external {
        require(registeredAddresses[_managerAddress] == true, 'The address is not registered... The current operation can not be executed... ');
        require(managersAddresses[_managerAddress] == true, 'The address does not correspond to a manager... The current operation can not be executed... ');
        erccompToken.approve(address(this), _DEV + _REV);
        
    }
    

    function createSWProd(string calldata _description, uint _DEV, uint _REV, string calldata _categoryOfExpertise, uint _freelanceTime, uint _evaluatorTime, address  _evaluator) external {
        require(registeredAddresses[msg.sender] == true, 'The address is not registered... The current operation can not be executed... ');
        require(managersAddresses[msg.sender] == true, 'The address does not correspond to a manager... The current operation can not be executed... ');
        require(evaluatorsAddresses[_evaluator] == true, 'The evaluator does not exist... ');
        erccompToken.transferFrom(msg.sender, address(this), _DEV + _REV);
        SWProds[SWProdID] = SWProd(SWProdID, _description, _DEV, _REV, _categoryOfExpertise, _freelanceTime, _evaluatorTime, msg.sender);
        SWProdsProposedByManagers[SWProdID] = msg.sender;
        SWProdAssignedToEvaluators[SWProdID].push(_evaluator);
        SWProdID ++;
    }
    
    // Condition from FE: if (SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV > sum(_DEV, _REV)) then "Provide a greater amount of tokens... "
    // Validation on FE: approve(difference) if exists 
    function updateSWProd(uint _SWProdID, string calldata _description, uint _DEV, uint _REV, string calldata _categoryOfExpertise, uint _freelanceTime, uint _evaluatorTime, address _managerAddress, address _evaluator) external {
        require(registeredAddresses[_managerAddress] == true, 'The address is not registered... The current operation can not be executed... ');
        require(managersAddresses[_managerAddress] == true, 'The address does not correspond to a manager... The current operation can not be executed... ');
        require(SWProdsProposedByManagers[_SWProdID] == _managerAddress, 'This SWProd is not assigned to the current manager... ');
        require(SWProdsApplied[_SWProdID].length == 0, 'Can not delete a SWProd at this stage... ');
        uint previousAmount = SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV;
        uint actualAmount = _DEV + _REV;
        if (previousAmount > actualAmount) {
            erccompToken.transfer(_managerAddress, previousAmount - actualAmount);
        }
        else {
            erccompToken.transferFrom(_managerAddress, address(this), actualAmount - previousAmount);
        }
        // delete the previously SWProd and add the updated SWProd 
        delete SWProds[_SWProdID];
        SWProds[_SWProdID] = SWProd(_SWProdID, _description, _DEV, _REV, _categoryOfExpertise, _freelanceTime, _evaluatorTime, _managerAddress);
        SWProdAssignedToEvaluators[_SWProdID].push(_evaluator);
    }
    
    // Method for assigning a new evaluator... passing arrays as argument (X)
    function addEvaluatorForSWProd(uint _SWProdID, address _evaluatorAddress) external {
        bool isAssigned = false;
        for (uint i = 0; i < SWProdAssignedToEvaluators[_SWProdID].length; i++) {
            if (_evaluatorAddress == SWProdAssignedToEvaluators[_SWProdID][i]) {
                isAssigned == true;
            } 
        }
        require(isAssigned == false, 'The evaluator is already assigned to this SWProd...');
        SWProdAssignedToEvaluators[_SWProdID].push(_evaluatorAddress);
    }
    
    // Method that checks if an evaluator was assigned to a specific SWProd
    function isAssignedEvaluator(uint _SWProdID, address _evaluatorAddress) external view returns(bool) {
        bool isAssigned = false;
        for (uint i = 0; i < SWProdAssignedToEvaluators[_SWProdID].length; i++) {
            if (_evaluatorAddress == SWProdAssignedToEvaluators[_SWProdID][i]) {
                isAssigned == true;
            } 
        }
        return isAssigned;
    }
    
    // This method is used in the case an evaluator accepts to evaluate a SWProd
    function acceptSWProdEvaluator(uint _SWProdID) external {
        acceptedSWProdByEvaluators[_SWProdID] = msg.sender;
        acceptedSWProd[_SWProdID] = true;
        delete SWProdAssignedToEvaluators[_SWProdID];
    }
    
    
    // This method should be called before  applyForSWProd method, because it contains an approve statement which is necessary in order to transfer the tokens to the MarketPlace contract...
    function applyForSWProdApproveAmont(uint _SWProdID, uint _amountForEvaluator) external {
        require(acceptedSWProd[_SWProdID] == true, 'SWProd is not accepted... ');
        // This condition should exist on FE also...
        require(_amountForEvaluator == SWProds[_SWProdID].REV, 'Set another amount of tokens for evaluator... ');
        erccompToken.approve(address(this), _amountForEvaluator);
    }
    
    // This method is used in the case a freelancer wants to work for a SWProds TO DO approve sum from Web3
    function applyForSWProd(uint _SWProdID, address _freelanceID, uint _amountForEvaluator) external {
        require(acceptedSWProd[_SWProdID] == true, 'SWProd is not accepted... ');
        // This condition should exist on FE also... 
        require(_amountForEvaluator == SWProds[_SWProdID].REV, 'Set another amount of tokens for evaluator... ');
        erccompToken.transferFrom(_freelanceID, address(this), _amountForEvaluator);
        amountForSWProdsApplied[_SWProdID][_freelanceID] = _amountForEvaluator;
        SWProdsApplied[_SWProdID].push(_freelanceID);
        
    }
    
    function cancelSWProd(uint _SWProdID, address _managerAddress) external {
        require(SWProdsApplied[_SWProdID].length == 0, 'Can not delete a SWProd at this stage... ');
        require(SWProds[_SWProdID].manager == _managerAddress, 'This manager did not created this SWProd...');
        uint amountToReturn = SWProds[_SWProdID].REV + SWProds[_SWProdID].DEV;
        erccompToken.transfer(SWProds[_SWProdID].manager, amountToReturn);
        delete SWProds[_SWProdID];
        delete SWProdsApplied[_SWProdID];
        delete SWProdsProposedByManagers[_SWProdID];
    }

    
    // This method is used when the manager choses a freelancer from the available ones. After this step the SWProd is opened 
    function openSWProd(uint _SWProdID, address _freelancerID, address _managerAddress) external {
        require(freelancersAddresses[_freelancerID] == true, 'The current freelancer is registered... ');
        require(managersAddresses[_managerAddress] == true, 'The current manager is registered... ');
        require(acceptedSWProd[_SWProdID] == true, 'The SWProd is not accepted... ');
        openedSWProd[_SWProdID] = _freelancerID;
        // From FE: transfer(address, amount) for each freelancer who was not chosen by the mananger
    }
    
    // This method is used in the case a freelancer wants to submit a solution for the SWProd he/she applied for
    function resolveSWProd(uint _SWProdID, address _freelancerID, string calldata _githubLink) external {
        require(openedSWProd[_SWProdID] == _freelancerID, 'Can not submit the response for this SWProd... It is not opened yet... ');
        solutions[_freelancerID] = _githubLink;
        solutionSWProd[_SWProdID] = _freelancerID;
    }
    
    function acceptSWProdFreelancer(uint _SWProdID, address _managerAddress, address _freelancerID) external {
        require(solutionSWProd[_SWProdID] == _freelancerID, 'The SWProd was not resolved by current freelancer... ');
        require(SWProds[_SWProdID].manager == _managerAddress, 'The SWProd was not proposed by the current manager... ');
        resolvedSWProd.push(_SWProdID); // the SWProds that are solutioned should be displayed in a separate table
        freelancers[_freelancerID].reputation ++;
        managers[_managerAddress].reputation ++;
        erccompToken.transfer(_managerAddress, SWProds[_SWProdID].REV);
    }
    
    // This method should be called after acceptSWProd method
    function sendRewardForAcceptedFreelancer(uint _SWProdID, address _freelancerID) external {
        uint amountToTransfer = SWProds[_SWProdID].DEV + amountForSWProdsApplied[_SWProdID][_freelancerID];
        erccompToken.transfer(_freelancerID, amountToTransfer);
    }
    
    // Evaluation process
    function refuseSWProd(uint _SWProdID, address _managerAddress, address _freelancerAddress) external {
        require(solutionSWProd[_SWProdID] == _freelancerAddress, 'The SWProd was not resolved by current freelancer... ');
        require(SWProds[_SWProdID].manager == _managerAddress, 'The SWProd was not proposed by the current manager... ');
        refusedSWProdEvaluation[_SWProdID] = acceptedSWProdByEvaluators[_SWProdID];
    }
    
    function evaluatePositive(uint _SWProdID) external {
        // reputation manager --
        managers[SWProds[_SWProdID].manager].reputation --;
        // reputation freelancer ++
        freelancers[solutionSWProd[_SWProdID]].reputation ++;
        // reputation evaluator ++
        evaluators[refusedSWProdEvaluation[_SWProdID]].reputation ++;
        // send to freelancer SWProds[_SWProdID].DEV + amountForSWProdsApplied[_SWProdID][_freelancerID]
        erccompToken.transfer(solutionSWProd[_SWProdID],  SWProds[_SWProdID].DEV + amountForSWProdsApplied[_SWProdID][solutionSWProd[_SWProdID]]);
        
    }
    
    function evaluatePositiveSendToEvaluator(uint _SWProdID) external {
        // send to evaluator SWProds[_SWProdID].DEV => try from web3
        erccompToken.transfer(refusedSWProdEvaluation[_SWProdID], SWProds[_SWProdID].REV);
        // delete the refused SWProd
        delete refusedSWProdEvaluation[_SWProdID];
        completedSWProd.push(SWProds[_SWProdID]);
    }
    
    function evaluateNegative(uint _SWProdID) external {
        // reputation manager ++
        managers[SWProds[_SWProdID].manager].reputation ++;
        // reputation freelancer --
        freelancers[solutionSWProd[_SWProdID]].reputation --;
        // reputation evaluator ++
        evaluators[refusedSWProdEvaluation[_SWProdID]].reputation ++;
        // send to manager SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV
        erccompToken.transfer(SWProds[_SWProdID].manager, SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV);
    }
    
    function evaluateNegativeSendToEvaluator(uint _SWProdID) external {
        // send to evaluator amountForSWProdsApplied[_SWProdID][_freelancerID]
        erccompToken.transfer(refusedSWProdEvaluation[_SWProdID], amountForSWProdsApplied[_SWProdID][solutionSWProd[_SWProdID]]);
        delete refusedSWProdEvaluation[_SWProdID];
        rejectedSWProd.push(SWProds[_SWProdID]);
    }
    
    function evaluateNeutral(uint _SWProdID) external {
        // reputation evaluator --
        evaluators[refusedSWProdEvaluation[_SWProdID]].reputation --;
        // send to freelancer amountForSWProdsApplied[_SWProdID][_freelancerID]
        erccompToken.transfer(solutionSWProd[_SWProdID], amountForSWProdsApplied[_SWProdID][solutionSWProd[_SWProdID]]);
    }
    
    function evaluateNeutralSendToManager(uint _SWProdID) external {
        // send to manager SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV
        erccompToken.transfer(SWProds[_SWProdID].manager, SWProds[_SWProdID].DEV + SWProds[_SWProdID].REV);
    }
    
    // Send the tokens from another freelancers back => multiple transfers
    function sendTokensToTheRestOfFreelancers(uint _SWProdID, address _freelancerID) external {
        for (uint i = 0; i < SWProdsApplied[_SWProdID].length; i++) {
            if (_freelancerID != SWProdsApplied[_SWProdID][i]) {
                erccompToken.transfer(SWProdsApplied[_SWProdID][i], amountForSWProdsApplied[_SWProdID][SWProdsApplied[_SWProdID][i]]);
            } 
        }
        delete refusedSWProdEvaluation[_SWProdID];
        rejectedSWProd.push(SWProds[_SWProdID]);
    }
    
}