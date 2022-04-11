pragma solidity >=0.6.2 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "./Hero.sol";

contract BlindBox is Ownable {
    using SafeMath for uint256;

    Hero public hero;
    IERC20 public usdt;

    uint public random;
    uint public totalAmount = 666;
    uint public maxMint = 100;
    uint public start =1; //todo
    uint public price = 1e18;

    uint public mintedAmountTotal;

    uint[] public levelRandomCounts;
    uint[] public kindRandomCounts;


    mapping (uint=>uint) public levelMapCount; // 1,2,3,4,5
    mapping (uint=>uint) public kindMapCount;  // 1= produce 2= boat 3 = double
    mapping (uint=>uint) public levelMinted;
    mapping (uint=>uint) public kindMinted;

    uint public totalSpecies; //物种总数
    uint public totalBoatType; //船只类型总数

    //等级对应物种数量
    mapping (uint=>uint) public levelMapSpecies;

    //等级对应船只数量
    mapping (uint=>uint) public levelMapBoat;


    mapping (address=>uint) public mintedAmount;

    constructor () public   {
        totalSpecies = 30;
        totalBoatType = 4;

        levelMapCount[1] = 0;
        levelMapCount[2] = 0;
        levelMapCount[3] = 466;
        levelMapCount[4] = 133;
        levelMapCount[5] = 67;

        kindMapCount[1] = 333;
        kindMapCount[2] = 200;
        kindMapCount[3] = 133;

        levelRandomCounts=[
            totalAmount - levelMapCount[5],
            totalAmount - levelMapCount[5] - levelMapCount[4],
            totalAmount - levelMapCount[5] - levelMapCount[4] - levelMapCount[3],
            totalAmount - levelMapCount[5] - levelMapCount[4] - levelMapCount[3] - levelMapCount[2]
        ];

        kindRandomCounts = [
            totalAmount - kindMapCount[3],
            totalAmount - kindMapCount[3] - kindMapCount[2]
        ];

        levelMapSpecies[3] = 3;
        levelMapSpecies[4] = 4;
        levelMapSpecies[5] = 5;

        levelMapBoat[3] = 2;
        levelMapBoat[4] = 2;
        levelMapBoat[5] = 2;

    }

    function getLevel(uint256 _levelRandom) private view returns (uint256){
        if(_levelRandom>levelRandomCounts[0]){
            if(levelMinted[5]< levelMapCount[5] ){
                return 5;
            }else if(levelMinted[4]<levelMapCount[4]){
                return 4;
            }else if(levelMinted[3]<levelMapCount[3]){
                return 3;
            }else if(levelMinted[2]<levelMapCount[2]){
                return 2;
            }else {
                return 1;
            }

        }else if(_levelRandom>levelRandomCounts[1]){
            if(levelMinted[4]<levelMapCount[4]){
                return 4;
            }else if(levelMinted[3]<levelMapCount[3]){
                return 3;
            }else if(levelMinted[2]<levelMapCount[2]){
                return 2;
            }else if(levelMinted[1]<levelMapCount[1]){
                return 1;
            }else{
                return 5;
            }
        }else if(_levelRandom>levelRandomCounts[2]){
            if(levelMinted[3]<levelMapCount[3]){
                return 3;
            }else if(levelMinted[2]<levelMapCount[2]){
                return 2;
            }else if(levelMinted[1]<levelMapCount[1]){
                return 1;
            }else if(levelMinted[5]<levelMapCount[5]){
                return 5;
            }else {
                return 4;
            }
        }else if(_levelRandom>levelRandomCounts[3]){
            if(levelMinted[2]<levelMapCount[2]){
                return 2;
            }else if(levelMinted[1]<levelMapCount[1]){
                return 1;
            }else if(levelMinted[5]<levelMapCount[5]){
                return 5;
            }else if(levelMinted[4]<levelMapCount[4]) {
                return 4;
            }else {
                return 3;
            }
        }else{
            if(levelMinted[1]<levelMapCount[1]){
                return 1;
            }else if(levelMinted[5]<levelMapCount[5]){
                return 5;
            }else if(levelMinted[4]<levelMapCount[4]) {
                return 4;
            }else if(levelMinted[3]<levelMapCount[3]) {
                return 3;
            }else{
                return 2;
            }
        }
    }

    function getKind(uint256 _kindRandom) private view returns (uint256){
        if(_kindRandom>kindRandomCounts[0]){
            if(kindMinted[3]<kindMapCount[3]){
                return 3;
            }else if(kindMinted[2]<kindMapCount[2]){
                return 2;
            }else {
                return 1;
            }

        }else if(_kindRandom>kindRandomCounts[1]){
            if(kindMinted[2]<kindMapCount[2]){
                return 2;
            }else if(kindMinted[1]<kindMapCount[1]){
                return 1;
            }else{
                return 3;
            }

        }else{
            if(kindMinted[1]<kindMapCount[1]){
                return 1;
            }else if(kindMinted[3]<levelMapCount[3]) {
                return 3;
            }else{
                return 2;
            }
        }
    }

    //抽盲盒，
    //参数 ——amoutn: 抽取盲盒的数量
    function mint(uint256 _amount) public {
        require(mintedAmountTotal + _amount <= totalAmount,"not more");
        require(mintedAmount[msg.sender] + _amount <= maxMint,"gt max");
        require(block.timestamp >= start && start >0,"not start");
        usdt.transferFrom(msg.sender,address(this),price *_amount);
        uint _level;
        uint _kind;
        for (uint256 index = 0; index < _amount; index++) {
            random++;
            uint256  _random =uint256(keccak256(abi.encodePacked(random,block.coinbase, msg.sender,block.timestamp,uint256(blockhash(block.number -1))))) % totalAmount;
            _level =  getLevel(_random);
            _kind = getKind(_random);

            levelMinted[_level]++;
            kindMinted[_kind] ++;
            hero.safeMint(msg.sender, _level,_kind);
        }
        mintedAmount[msg.sender] = mintedAmount[msg.sender] + _amount;
        mintedAmountTotal = mintedAmountTotal + _amount;
    }

    function setInit(address _hero,address _usdt) external onlyOwner{
        hero = Hero(_hero);
        usdt = IERC20(_usdt);
    }
    function setmaxMint(uint _max) external onlyOwner {
        maxMint = _max;
    }
    function setStart(uint _s) external onlyOwner {
        start = _s;
    }
    function exit() external onlyOwner {
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
    }
}