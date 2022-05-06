// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
    /*
     * @dev 事件通知 —— 冻结资产
     * @param {String} _address 目标地址
     * @param {Number} _amount 冻结额度
     */
    event Frozen(address indexed _address, uint256 _amount);

    /*
     * @dev 事件通知 —— 发生交易
     * @param {String} _from
     * @param {String} _to
     * @param {Number} _amount
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    /*
     * @dev 事件通知 —— 授权变更
     * @param {String} _owner
     * @param {String} _operator
     * @param {Number} _amount
     */
    event Approval(address indexed _owner, address indexed _operator, uint256 _amount);

    /*
     * @dev 事件通知 —— 增发代币
     * @param {String} _address 增发币接收地址
     * @param {String} _amount 增发数量
     */
    event Mint(address indexed _address, uint256 _amount);

    /*
     * @dev 事件通知 —— 销毁代币
     * @param {String} _address 目标地址
     * @param {Number} _amount 销毁的数量
     */
    event Burn(address indexed _address, uint256 _amount);

    /**
     * @dev 查询代币名称
     */
    function name() external view returns (string memory);

    /**
     * @dev 查询代币符号
     */
    function symbol() external view returns (string memory);

    /**
     * @dev 查询代币精度
     */
    function decimals() external view returns (uint32);

    /**
     * @dev 查询代币总发行量
     * @return {Number} 返回发行量
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev 最大手续费
     * @return {Number} 返回手续费
     */
    function feeMax() external view returns (uint256);

    /*
     * @dev 设置最大手续费
     * @param {Number} feeMax 最大手续费
     */
    function setFeeMax(uint256 _feeMax) external;

    /**
     * @dev 手续费率
     * @return {Number} 返回手续费率
     */
    function rate() external view returns (uint32);

    /*
     * @dev 设置转账手续费
     * @param {Number} _rate
     */
    function setRate(uint32 _rate) external;

    /**
     * @dev 查询手续费
     * @param {Number} _amount 额度
     * @return {Number} 返回手续费
     */
    function getFee(uint256 _amount) external view returns (uint256);

    /**
     * @dev 查询账户被冻结资产额度
     * @param {String} _address 查询的地址
     */
    function frozenOf(address _address) external view returns (uint256);

    /**
     * @dev 查询地址余额
     * @param {String} _address
     * @return {Number} 返回余额
     */
    function balanceOf(address _address) external view returns (uint256);

    /**
     * @dev 查询地址可用余额
     * @param {String} _address
     * @return {Number} 返回余额
     */
    function balanceUseOf(address _address) external view returns (uint256);

    /*
     * @dev 发起人转账
     * @param {String} _to 收款用户
     * @param {Number} _amount 金额
     */
    function transfer(address _to, uint256 _amount) external;

    /*
     * @dev 发起人转账
     * @param {String} _to 收款人
     * @param {Number} _amount 转账金额
     */
    function safeTransfer(
        address _to,
        uint256 _amount
    ) external returns(bool);

    /*
     * @dev 从某账户转账给某人（公开）
     * @param {String} _from 转出人
     * @param {String} _to 收款人
     * @param {Number} _amount 转账金额
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /*
     * @dev 从某账户转账给某人（公开）
     * @param {String} _from 转出人
     * @param {String} _to 收款人
     * @param {Number} _amount 转账金额
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns(bool);

    /*
     * 授权
     * @param {String} _operator 授权可操作人
     * @param {Number} _amount 授权单笔可操作额度
     */
    function approve(address _operator, uint256 _amount) external;

    /**
     * @dev 查询授权额度
     * @param {String} _owner 持有人地址
     * @param {String} _operator 授权人地址
     * @return {Number} 返回授权额度
     */
    function allowance(address _owner, address _operator)
    external
    view
    returns (uint256);

    /*
     * @dev (授权人)批量转账
     * @param {String} _from 转出地址
     * @param {String} _toArr 收币地址集合
     * @param {Number} _amount 每个地址所获额度
     */
    function transferFromBath(
        address _from,
        address[] memory _toArr,
        uint256 _amount
    ) external;

    /*
     * @dev 批量转账
     * @param {String} _toArr 收币地址集合
     * @param {Number} _amount 每个地址所获额度
     */
    function transferBath(address[] memory _toArr, uint256 _amount) external;

    /*
     * @dev 增发代表
     * @param {String} _address 增发给某人
     * @param {Number} _amount 增发的数量
     */
    function mint(address _address, uint256 _amount) external;

    /*
     * @dev 冻结资产
     * @param {String} _address 目标地址
     * @param {Number} _amount 冻结额度
     */
    function freeze(address _address, uint256 _amount) external;

    /*
     * @dev 销毁某人的代币
     * @param {String} _address 账户地址
     * @param {Number} _amount 销毁数量
     */
    function burnFrom(address _address, uint256 _amount) external;

    /*
     * @dev 费用统计
     * @param {String} _address 账户地址
     * @param {Number} _amount 销毁数量
     */
    function feeCount() external view returns (uint256);
}
