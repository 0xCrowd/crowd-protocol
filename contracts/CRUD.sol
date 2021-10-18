// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CRUD{

    struct Instance{
        uint id;
        bool isActive;
    }
   
    Instance[] public sequence;

    function create(bool _isActive, uint _nextId) public {
        sequence.push(Instance(_nextId, _isActive));
    }
   
    function read(uint _id) public view returns(uint, bool){
        require(sequence[_id].id == _id);
        return(sequence[_id].id, sequence[_id].isActive);
    }
   
    function update(uint _id, bool _isActive) public {
        require(sequence[_id].id == _id);
        sequence[_id].isActive = _isActive;
    }
   
    function del(uint _id) public {
        require(sequence[_id].id == _id);
        delete sequence[_id];
    }
   
    function readAll() public view returns(Instance[] memory){
        return sequence;
    }
}