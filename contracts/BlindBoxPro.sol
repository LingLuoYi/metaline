pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/IBEP20.sol";


import "./Hero.sol";

contract BlindBoxPro is Ownable{

    Hero public hero; //抽出的
    IBEP20 public usdt;//支付的

    bool public isOpen;
    uint8 public mintedOneTotal;//单次最高
    address collection; //收款地址

    mapping(uint8 => uint256) public levelPrice;//价格等级
    mapping(uint8 => uint8[]) public levelProbability;//等级概率
    mapping(uint8 => uint8[]) public kindProbability;//英雄类型概率
    mapping(uint8 => uint256[]) public mintedAmountTotal;//总数mt
    mapping(uint8 => uint256[]) public alreadyCardTotal;//已开总数at


    constructor (address _heroToken, address _usdtToken) public{
        levelPrice[0] = 99e18; //普通版
        levelPrice[1] = 299e18; //创世版
        levelPrice[2] = 499e18; //牛逼创世版
        isOpen = true;
        mintedOneTotal = 99;
        hero = Hero(_heroToken);
        usdt = IBEP20(_usdtToken);
        collection = address(0xe27d47410Ea9268D766B67eC68Bd856746B12bda);

        levelProbability[0] = [36,65,90,98,100];
        levelProbability[1] = [0,0,65,95,100];
        levelProbability[2] = [0,0,38,88,100];
        uint8[3] memory k = [50,80,100];
        kindProbability[0] = k;
        kindProbability[1] = k;
        kindProbability[2] = k;
        mintedAmountTotal[0] = [720,580,500,160,40];
        mintedAmountTotal[1] = [0,0,130,60,9];
        mintedAmountTotal[2] = [0,0,338,453,97];
        alreadyCardTotal[0] = [0,0,0,0,0];
        alreadyCardTotal[1] = [0,0,0,0,0];
        alreadyCardTotal[2] = [0,0,0,0,0];
    }

    function setCollection(address _collection) external onlyOwner{
        collection = _collection;
    }

//    function setHeroToken(address _address) external onlyOwner{
//        hero = Hero(_address);
//    }
//
//    function setUsdtToken(address _address) external onlyOwner{
//        usdt = IERC20(_address);
//    }
//
//    function setMintedOneTotal(uint8 _mintedOneTotal) external onlyOwner{
//        mintedOneTotal = _mintedOneTotal;
//    }
//
//    function setTotal(uint8 level, uint256[] memory _total) external onlyOwner{
//        mintedAmountTotal[level] = _total;
//        alreadyCardTotal[level] = new uint256[](_total.length);
//    }
//
//    function setLevelPrice(uint256[] memory price) external onlyOwner{
//        for (uint8 i = 0; i < price.length; i++){
//            levelPrice[i] = price[i];
//        }
//    }
//
//    function setLevelProbability(uint8 _level,uint8[] memory _levelProbability) external onlyOwner{
//        levelProbability[_level] = _levelProbability;
//    }
//
//    function setKindProbability(uint8 _level, uint8[] memory _kindProbability) external onlyOwner{
//        kindProbability[_level] = _kindProbability;
//    }


    function countCardTotal(uint8 level) public view returns(uint256){
        uint256[] memory totals = mintedAmountTotal[level];
        uint256 total = 0;
        for (uint i = 0; i<totals.length; i++){
            total += totals[i];
        }
        return total;
    }

    function countAlreadyTotal(uint8 level) public view returns(uint256){
        uint256[] memory totals = alreadyCardTotal[level];
        uint256 total = 0;
        for (uint i = 0; i < totals.length; i++){
            total += totals[i];
        }
        return total;
    }

    function isMax(uint8 _boxLevel, uint8 _heroLevel, uint8 _amount) internal view returns(bool){
        uint256[] memory at = alreadyCardTotal[_boxLevel];
        uint256[] memory mt = mintedAmountTotal[_boxLevel];
        return at[_heroLevel-1] + _amount > mt[_heroLevel-1];
    }

    function getSecurityLevel(uint8 _boxLevel, uint8 _heroLevel) internal view returns(uint8){
        uint256[] memory at = alreadyCardTotal[_boxLevel];
        _heroLevel = _heroLevel + 1;
        if (isMax(_boxLevel, _heroLevel, 1)){
            //如果当前等级已经满了, 查找按顺序查找一个没满的等级
            for (uint8 i = 0; i<at.length; i++){
                if (i != _heroLevel - 1 && !isMax(_boxLevel, i + 1, 1)){
                    return i + 1;
                }
            }
        }
        return _heroLevel;
    }

    function setAt(uint8 _boxLevel, uint8 _heroLevel, uint8 _amount) internal{
        uint256[] memory at = alreadyCardTotal[_boxLevel];
        at[_heroLevel-1] += _amount;
        alreadyCardTotal[_boxLevel] = at;
    }


    function mint(uint8 _amount, uint8 _level) public{
        require(isOpen, "not open");
        require(countCardTotal(_level) >= (countAlreadyTotal(_level) + _amount), "max amount");
        require(_amount <= mintedOneTotal, "max one amount");
        uint256 price = levelPrice[_level] * uint256(_amount);
        //把币转过来
        usdt.transferFrom(msg.sender, collection, price);
        for (uint8 i = 0; i < _amount; i++){
            uint8 random = rand(100);
            uint8 level = getLevel(random, _level);
            uint8 kind = getKind(random, _level);
            //检查一下
            level = getSecurityLevel(_level, level - 1);
            //生产
            hero.safeMint(msg.sender, uint256(level), uint256(kind));
            //查询
            Hero.Hero[] memory heroList = hero.getTotalHeroes(msg.sender, 0, hero.balanceOf(msg.sender));
            if (heroList.length > 0){
                Hero.Hero memory hero1 = heroList[heroList.length - 1];
                emit Mint(msg.sender, _level + 1, hero1.id, hero1.level, hero1.kind);
            }
            // +1
            setAt(_level, level, 1);
        }
    }

    function getKind(uint8 _random, uint8 _level)internal view returns(uint8){
        uint8[] memory pro = kindProbability[_level];
        //如果第一个概率就满足
        if (0 < _random && _random <= pro[0]){
            return 1;
        }else{
            for (uint8 i = 0; i < pro.length; i++){
                if (i + 1 < pro.length){
                    if (pro[i] < _random && _random <= pro[i+1]){
                        //中间概率
                        return i + 2;
                    }
                }
            }
            //最后一个依然没有匹配到
            return uint8(pro.length);
        }
    }

    function getLevel(uint8 _random, uint8 _level) internal view returns(uint8){
        uint8[] memory pro = levelProbability[_level];
        //如果第一个概率就满足
        if (0 < _random && _random <= pro[0]){
            return 1;
        }else{
            for (uint8 i = 0; i < pro.length; i++){
                if (i + 1 < pro.length){
                    if (pro[i] < _random && _random <= pro[i+1]){
                        //中间概率
                        return i + 2;
                    }
                }
            }
            //最后一个依然没有匹配到
            return uint8(pro.length);
        }
    }

    function rand(uint256 _length) public view returns(uint8) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty,block.coinbase, msg.sender, block.timestamp, uint256(blockhash(block.number -1)))));
        return uint8(random%_length);
    }

//    function change() external onlyOwner{
//        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
//    }

    event Mint(address indexed owner, uint8 indexed box_type, uint256 indexed token_id, uint256 level, uint256 kind);

}
