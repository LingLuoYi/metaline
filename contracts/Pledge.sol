// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Hero.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// v1  0x50cA319bED4Fc3eCBF60c0e885399a4AC7A3db49
// 质押
contract Pledge is Ownable{

    bool public isOpen; //开放质押？
    uint256 public pledgeId;

    IERC20 incomeToke; //收益token
    Hero pledgeToken; //质押token

    uint256 public maxPledgeAmount;//个人最大质押数量
    uint256 public unlockTime;//解锁时长秒
    uint256 totalPledgeNumber;

    mapping(uint256 => uint256) public dailyProduction;//各等级日产生量

    struct PledgeHero{
        uint256 level;
        address userAddress; //质押的用户地址
        uint256 income; //质押收益
        uint256 toBeUnlockedIncome; //待解锁收益
        uint256 unlockedIncome;//已解锁收益
        uint256 laseTime; //上次提取时间
        bool isExist;
    }
    mapping(uint256 => PledgeHero) public pledgeHeroMap;
    //用户质押列表
    mapping(address => uint256[]) public userPledgeHeroMap;

    struct UnlockOrder{
        address user;
        uint256 amount;//解锁数量
        uint256 time;//添加时间
        bool isUnlock;//锁定中？
    }

    //用户解锁订单
    mapping(uint256 => UnlockOrder) public unlockOrderMap;

    constructor(address _incomeToke, address _pledgeToken){
        incomeToke = IERC20(_incomeToke);
        pledgeToken = Hero(_pledgeToken);
        isOpen = true;
        maxPledgeAmount = 100;
        unlockTime = 259200;//72 小时
    }

    function open(bool _isOpen) external onlyOwner{
        isOpen = _isOpen;
    }

    function setMaxPledgeAmount(uint256 _maxPledgeAmount) external onlyOwner {

        maxPledgeAmount = _maxPledgeAmount;
    }

    function setDailyProduction(uint256[] memory _dailyProductions) external onlyOwner {
        for (uint256 i=0; i<_dailyProductions.length; i++){
            dailyProduction[i] = _dailyProductions[i];
        }
    }

    function setUnlockTime(uint256 _time) external onlyOwner{
        unlockTime = _time;
    }

    function authorize(address owner, uint256 tokenId) external onlyOwner {
        pledgeToken.approve(owner, tokenId);
    }

    //
    function pledge(uint256 tokenId) public{
        require(isOpen, "not open");
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        require(pledgeHero.isExist == false, "The nft has been pledged");
        address sender = msg.sender;
        //判断质押总数
        uint256[] storage tokenIdList = userPledgeHeroMap[sender];
        require(tokenIdList.length < maxPledgeAmount, "max stake");
        //将token转过来
        pledgeToken.transferFrom(sender, address(this) , tokenId);
        //记录token
        //获取合约等级
        (uint256 id,uint256 level,uint256 kind) = pledgeToken.heroes(tokenId);
        pledgeHero = PledgeHero(level, sender, 0, 0, 0, block.timestamp,true);
        pledgeHeroMap[tokenId] = pledgeHero;
        //记录用户
        tokenIdList.push(tokenId);
        userPledgeHeroMap[sender] = tokenIdList;
        totalPledgeNumber++;
    }

    //
    function unPledge(uint256 tokenId) public{
        require(isOpen,"not open");
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        require(pledgeHero.isExist == true, "The nft is not pledged");
        address sender = msg.sender;
        require(pledgeHero.userAddress == sender, "not your pledge");
        //转走
        pledgeToken.transferFrom(address(this), sender, tokenId);
        //先设置为没挖矿，提取完所有收益在释放
        pledgeHero.isExist = false;
        pledgeHeroMap[tokenId] = pledgeHero;
        uint256[] storage tokenIdList = userPledgeHeroMap[sender];
        //删除用户列表
        for (uint32 i=0;i<tokenIdList.length;i++){
            if (tokenIdList[i] == tokenId){
                //移动后面的元素到前面来
                for (uint32 j=i;j < tokenIdList.length - 1; j++){
                    tokenIdList[j] == tokenIdList[j + 1];
                }
                //删最后一个
                tokenIdList.pop();
                break;
            }
        }
        userPledgeHeroMap[sender] = tokenIdList;
        totalPledgeNumber = SafeMath.sub(totalPledgeNumber, 1);//这里溢出说明质押也有问题
    }

    //计算单个用户所有收益, 读
    function allIncomeByUser(address userAddress) public view returns(uint256[5] memory){
        uint256[] memory userPledgeList = userPledgeHeroMap[userAddress];
        uint256 income = 0;
        uint256 toBeUnlockedIncome = 0;
        uint256 unlockedIncome = 0;
        for(uint32 i = 0; i <  userPledgeList.length; i++){
            PledgeHero memory pledgeHero = pledgeHeroMap[userPledgeList[i]];
            UnlockOrder memory order = unlockOrderMap[userPledgeList[i]];
            if (order.isUnlock == true && (block.timestamp - order.time) > unlockTime){
                unlockedIncome = SafeMath.add(unlockedIncome, order.amount);
            }
            income = SafeMath.add(income, pledgeHero.income);//上次余额
            income = SafeMath.add(income, calculate(userPledgeList[i]));//本次挖矿
            toBeUnlockedIncome = SafeMath.add(toBeUnlockedIncome, pledgeHero.toBeUnlockedIncome);
            unlockedIncome = SafeMath.add(unlockedIncome, pledgeHero.unlockedIncome);
        }
        return [totalPledgeNumber,userPledgeList.length,income,toBeUnlockedIncome, unlockedIncome];
    }

    //单个用户所有质押
    function allPledgeByUser(address userAddress) public view returns(PledgeHero[] memory){
        uint256[] memory userPledgeList = userPledgeHeroMap[userAddress];
        PledgeHero[] memory pledgeHeroList = new PledgeHero[](userPledgeList.length);
        for(uint32 i = 0; i <  userPledgeList.length; i++){
            pledgeHeroList[i] = pledgeHeroMap[userPledgeList[i]];
        }
        return pledgeHeroList;
    }

    //变更收益
    function changePledgeHero(uint256 tokenId, int256 income, int256 toBeUnlockedIncome,int256 unlockedIncome, uint256 time)  internal{
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        pledgeHero.income = uint256(int256(pledgeHero.income) + income);
        pledgeHero.toBeUnlockedIncome = uint256(int256(pledgeHero.toBeUnlockedIncome) + toBeUnlockedIncome);
        pledgeHero.unlockedIncome = uint256(int256(pledgeHero.unlockedIncome) + unlockedIncome);
        if (time > pledgeHero.laseTime){
            pledgeHero.laseTime = time; //重置收益时间
        }
        pledgeHeroMap[tokenId] = pledgeHero;
    }

    //直接赋值收益，不做计算
    function changeIncome(uint256 tokenId,int256 income) external onlyOwner{
        changePledgeHero(tokenId, int256(income), 0, 0, 0);
    }

    //计算收益
    function calculate(uint256 tokenId) internal view returns(uint256){
        //根据时间长短计算
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        if (pledgeHero.isExist == true){ // 在挖矿
            uint256 time = block.timestamp - pledgeHero.laseTime;
            uint256 base = dailyProduction[pledgeHero.level];
            return SafeMath.mul(time, base);
        }else{
            return 0;
        }
    }

    //提取合约收益
    function extract(uint256 tokenId,uint256 amount) public {
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        require(pledgeHero.userAddress == msg.sender, "not your earnings");
        uint256 income = pledgeHero.income;
        income = SafeMath.add(income, calculate(tokenId));
        require(income >= amount, "Insufficient earnings");
        changePledgeHero(tokenId, -int256(amount), int256(amount), 0, block.timestamp);
        unlockOrderMap[tokenId] = UnlockOrder(msg.sender, amount, block.timestamp, true);
    }

    //提取所有收益
    function extract() public {
        //减掉所有收益
        uint256[] memory userPledgeList = userPledgeHeroMap[msg.sender];
        uint256 amount = 0;
        for(uint32 i = 0; i <  userPledgeList.length; i++){
            PledgeHero memory pledgeHero = pledgeHeroMap[userPledgeList[i]];
            amount = SafeMath.add(amount, pledgeHero.income);//余额
            amount = SafeMath.add(amount, calculate(userPledgeList[i]));
            unlockOrderMap[userPledgeList[i]] = UnlockOrder(msg.sender, pledgeHero.income, block.timestamp, true);
            changePledgeHero(userPledgeList[i], -int256(pledgeHero.income), int256(pledgeHero.income), 0, block.timestamp);
        }
    }

    //释放收益, 不检查时间
    function freed(uint256 tokenId, uint256 amount) external onlyOwner{
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        UnlockOrder memory order = unlockOrderMap[tokenId];
        uint256 unlockAmount = pledgeHero.toBeUnlockedIncome;
        unlockAmount =SafeMath.add(unlockAmount, order.amount);
        require(unlockAmount >= amount, "Insufficient earnings");
        changePledgeHero(tokenId, 0, -int256(amount), int256(amount), 0);
        unlockOrderMap[tokenId] = UnlockOrder(address(0x0000000000000000000000000000000000000000),0,0,false);
    }

    //转出收益
    function withdraw(uint256 tokenId,uint amount) public{
        PledgeHero memory pledgeHero = pledgeHeroMap[tokenId];
        require(pledgeHero.userAddress == msg.sender, "not your earnings");
        uint256 unlockedIncome = pledgeHero.unlockedIncome;
        UnlockOrder memory order = unlockOrderMap[tokenId];
        if (order.isUnlock == true && (block.timestamp - order.time) >= unlockTime){
            unlockedIncome = SafeMath.add(unlockedIncome, order.amount);
            changePledgeHero(tokenId, 0, 0, -int256(order.amount), 0);
            unlockOrderMap[tokenId] = UnlockOrder(address(0x0000000000000000000000000000000000000000),0,0,false);
        }
        require(unlockedIncome >= amount, "Insufficient earnings");
        changePledgeHero(tokenId, 0, 0, -int256(amount), 0);
        incomeToke.transferFrom(address(this), msg.sender, amount);
        if (pledgeHero.income == 0 && pledgeHero.isExist == false){
            //释放掉该笔质押
            pledgeHeroMap[tokenId] = PledgeHero(0,address(0x0000000000000000000000000000000000000000),0, 0, 0, 0, false);
        }
    }

    //转出所有收益
    function withdraw() public{
        uint256[] memory userPledgeList = userPledgeHeroMap[msg.sender];
        uint256 amount = 0;
        for(uint32 i = 0; i <  userPledgeList.length; i++){
            PledgeHero memory pledgeHero = pledgeHeroMap[userPledgeList[i]];
            UnlockOrder memory order = unlockOrderMap[userPledgeList[i]];
            if (order.isUnlock == true && (block.timestamp - order.time) >= unlockTime){
                amount =SafeMath.add(amount, order.amount);
                unlockOrderMap[userPledgeList[i]] = UnlockOrder(address(0x0000000000000000000000000000000000000000),0,0,false);
            }
            amount += pledgeHero.unlockedIncome;
            changePledgeHero(userPledgeList[i], 0, 0, -int256(pledgeHero.unlockedIncome), 0);
            if (pledgeHero.isExist == false){
                //释放掉该笔质押
                pledgeHeroMap[userPledgeList[i]] = PledgeHero(0,address(0x0000000000000000000000000000000000000000),0, 0, 0, 0, false);
            }
        }
        incomeToke.transferFrom(address(this), msg.sender, amount);
    }
}