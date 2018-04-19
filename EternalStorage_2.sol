pragma solidity ^0.4.21;

contract Owned {
    address public owner;
    address public newOwner;
    address internal admin;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event AdminChanged(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) public onlyOwner{
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function showAdmin() public view onlyOwner returns(address _admin){
        _admin = admin;
        return _admin;
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


contract EternalStorage is Owned{

    mapping(bytes32 => uint) UIntStorage;
    function getUIntValue(bytes32 record) public view onlyAdmin returns (uint){
        return UIntStorage[record];
    }
    function setUIntValue(bytes32 record, uint value) public onlyAdmin returns(bool success){
        UIntStorage[record] = value;
    }

    mapping(bytes32 => string) StringStorage;
    function getStringValue(bytes32 record) public view onlyAdmin returns (string){
        return StringStorage[record];
    }
    function setStringValue(bytes32 record, string value) public onlyAdmin returns(bool success){
        StringStorage[record] = value;
    }

    mapping(bytes32 => address) AddressStorage;
    function getAddressValue(bytes32 record) public view onlyAdmin returns (address){
        return AddressStorage[record];
    }
    function setAddressValue(bytes32 record, address value) public onlyAdmin returns(bool success){
        AddressStorage[record] = value;
    }

    mapping(bytes32 => bytes) BytesStorage;
    function getBytesValue(bytes32 record) public view onlyAdmin returns (bytes){
        return BytesStorage[record];
    }
    function setBytesValue(bytes32 record, bytes value) public onlyAdmin returns(bool success){
        BytesStorage[record] = value;
    }

    mapping(bytes32 => bool) BooleanStorage;
    function getBooleanValue(bytes32 record) public view onlyAdmin returns (bool){
        return BooleanStorage[record];
    }
    function setBooleanValue(bytes32 record, bool value) public onlyAdmin returns(bool success){
        BooleanStorage[record] = value;
    }
    
    mapping(bytes32 => int) IntStorage;
    function getIntValue(bytes32 record) public view onlyAdmin returns (int){
        return IntStorage[record];
    }
    function setIntValue(bytes32 record, int value) public onlyAdmin returns(bool success){
        IntStorage[record] = value;
    }
}