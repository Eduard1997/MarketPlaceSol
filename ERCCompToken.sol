pragma solidity ^0.5.12;


/* SafeMath */
contract SafeMath {
    
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Owned {
    
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ERCCompToken is ERC20Interface, Owned, SafeMath {
    
    string public symbol;
    string public  name;
    uint public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "FRL";
        name = "ERCCompToken";
        decimals = 18;
        
        // managers
        mint(500, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        mint(500, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        mint(500, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        
        // freelancers
        mint(500, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        mint(500, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2);
        mint(500, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372);
        
        // evaluators
        mint(500, 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678);
        
        // financers
        mint(500, 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function mint(uint _amount, address _spender) internal {
        _totalSupply = safeAdd(_totalSupply, _amount);
        balances[_spender] = safeAdd(balances[_spender], _amount);
        emit Transfer(address(0), _spender, _amount);
}

}