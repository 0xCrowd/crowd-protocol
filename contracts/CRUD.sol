// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CRUD{

    struct Instance{
        uint id;
        address addr;
    }
   
    Instance[] public sequence;

    function create(uint _id, address addr) public {
        sequence.push(Instance(_id, addr));
    }
   
    function read(uint _id) public view returns(address){
        require(sequence[_id].id == _id, "The vault with this index does not exist");
        return sequence[_id].addr;
    }
   
    function update(uint _id, address _addr) public {
        require(sequence[_id].id == _id);
        sequence[_id].addr = _addr;
    }
   
    function del(uint _id) public {
        require(sequence[_id].id == _id);
        delete sequence[_id];
    }
   
    function readAll() public view returns(Instance[] memory){
        return sequence;
    }
}