pragma solidity >=0.6.2 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Attribute is Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public operators;
    mapping(uint => uint[]) public speciesAttributes;
    mapping(uint => uint[]) public boatAttributes;

    constructor(){
        operators[msg.sender] = true;
    }


    function setSpecie(uint _id, uint[] calldata _species) external onlyOperator {
        speciesAttributes[_id] = _species;
    }

    function setBoat(uint _id, uint[] calldata _boats) external onlyOperator {
        boatAttributes[_id] = _boats;
    }

    //设置token id的货物和船只属性
    function setAttributes(uint _id, uint[] calldata _species, uint[] calldata _boat) external onlyOperator {
        speciesAttributes[_id] = _species;
        boatAttributes[_id] = _boat;
    }


    function setOperator(address _addr, bool _bool) public onlyOwner {
        operators[_addr] = _bool;
    }


    modifier onlyOperator() {
        require(operators[msg.sender], "!o");
        _;
    }

    function getSpeciesAttributes(uint _id) public view returns (uint[] memory) {
        uint _len = speciesAttributes[_id].length;
        uint[] memory _attrs = new uint[](_len);
        for (uint i = 0; i < _len; i++) {
            _attrs[i] = speciesAttributes[_id][i];
        }
        return _attrs;
    }

    function getBoatAttributes(uint _id) public view returns (uint[] memory) {
        uint _len = boatAttributes[_id].length;
        uint[] memory _attrs = new uint[](_len);
        for (uint i = 0; i < _len; i++) {
            _attrs[i] = boatAttributes[_id][i];
        }
        return _attrs;
    }

    //获取货物和船只属性
    function getBoth(uint _id) public view returns (uint[] memory, uint[] memory) {
        return (getSpeciesAttributes(_id), getBoatAttributes(_id));
    }

}
