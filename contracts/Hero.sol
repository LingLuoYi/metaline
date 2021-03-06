// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//nft
contract Hero is Ownable, ERC721Burnable {
    using SafeMath for uint256;

    uint public maxSupply;
    uint public maxSpecies; //物种数量
    mapping(address => bool) public minters;
    uint public tokenId;

    struct Hero {
        uint id;
        uint level; //nft 等级
        uint kind; // 1 = produce 2= boat  3= double   1= 货物生产英雄  2= 船只加速英雄  3 = 双栖
    }

    mapping(uint => uint[]) public speciesAttributes;
    mapping(uint => uint[]) public boatAttributes;

    struct Property {
        uint id;
        uint goods_level;
        uint sail_level;
        bool is_goods_accelerate;
        bool is_sail_accelerate;
    }

    mapping(address => bool) public operators;
    mapping(uint => Property) public properties;

    //根据token id查询对应nft的等级和类型属性
    mapping(uint => Hero) public heroes;


    //1 名字是 MetaLine Hero（MHERO）   注意大小写
    constructor() public ERC721("MetaLine Hero", "MHERO") {
        maxSupply = 1000000;
        minters[msg.sender] = true;
    }

    //mint出新英雄，通过盲盒抽
    function safeMint(address _to, uint _level, uint _kind) public onlyMinter {
        require(tokenId < maxSupply, " > max");
        tokenId++;
        _safeMint(_to, tokenId);
        heroes[tokenId] = Hero(tokenId, _level, _kind);
    }

    function setProperty(uint _id, uint _goods_level, uint _sail_level, bool _is_goods_accelerate, bool _is_sail_accelerate) external onlyMinter {
        properties[_id] = Property(_id, _goods_level, _sail_level, _is_goods_accelerate, _is_sail_accelerate);
    }

    function setBaseUri(string calldata _uri) external onlyOwner {
        _setBaseURI(_uri);
    }


    function setMinter(address _addr, bool _bool) public onlyOwner {
        minters[_addr] = _bool;
    }

    function setMaxSupply(uint _max) external onlyOwner {
        maxSupply = _max;
    }

    function setMaxSpecies(uint _max) external onlyOwner {
        maxSpecies = _max;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "!minter");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "!o");
        _;
    }

    function modifyHero(uint256 _tokenId,uint256 _level, uint256 _kind) external onlyOperator{
        heroes[_tokenId] = Hero(_tokenId, _level, _kind);
    }


    //获取某个地址所有nft属性（等级和类型）
    function getTotalHeroes(address _account, uint begin, uint end) public view returns (Hero[] memory) {
        uint _len = end - begin;
        Hero[] memory _heroes = new Hero[](_len);
        for (uint256 i = begin; i < end; i++) {
            _heroes[i - begin].id = tokenOfOwnerByIndex(_account, i);
            _heroes[i - begin].level = heroes[_heroes[i - begin].id].level;
            _heroes[i - begin].kind = heroes[_heroes[i - begin].id].kind;

        }
        return _heroes;
    }


    function getTotalProperties(address _account, uint begin, uint end) public view returns (Property[] memory){
        uint _len = end - begin;
        Property[] memory _properties = new Property[](_len);
        for (uint256 i = begin; i < end; i++) {
            _properties[i - begin].id = tokenOfOwnerByIndex(_account, i);
            _properties[i - begin].goods_level = properties[_properties[i - begin].id].goods_level;
            _properties[i - begin].sail_level = properties[_properties[i - begin].id].sail_level;
            _properties[i - begin].is_goods_accelerate = properties[_properties[i - begin].id].is_goods_accelerate;
            _properties[i - begin].is_sail_accelerate = properties[_properties[i - begin].id].is_sail_accelerate;

        }
        return _properties;
    }

    function getHeroesPart(uint begin, uint end) public view returns (Hero[] memory) {
        uint _len = end - begin;
        Hero[] memory _heroes = new Hero[](_len);
        for (uint256 i = begin; i < end; i++) {
            _heroes[i - begin].id = i;
            _heroes[i - begin].level = heroes[_heroes[i - begin].id].level;
            _heroes[i - begin].kind = heroes[_heroes[i - begin].id].kind;

        }
        return _heroes;
    }


    function getPropertiesPart(uint begin, uint end) public view returns (Property[] memory){
        uint _len = end - begin;
        Property[] memory _properties = new Property[](_len);
        for (uint256 i = begin; i < end; i++) {
            _properties[i - begin].id = i;
            _properties[i - begin].goods_level = properties[_properties[i - begin].id].goods_level;
            _properties[i - begin].sail_level = properties[_properties[i - begin].id].sail_level;
            _properties[i - begin].is_goods_accelerate = properties[_properties[i - begin].id].is_goods_accelerate;
            _properties[i - begin].is_sail_accelerate = properties[_properties[i - begin].id].is_sail_accelerate;
        }
        return _properties;
    }


}
