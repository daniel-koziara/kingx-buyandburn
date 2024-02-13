// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract BuyAndBurnKingX {
    address private owner;
    IERC20 private titanX;
    IERC20 private kingX;
    ISwapRouter private uniswapRouter;

    uint256 private amountToSwap;
    uint256 private rewardPerCall;
    uint256 private slippage;
    uint256 private minInterval;
    uint256 private lastCallTimestamp;

    bool private paused = true;

    uint256 private totalTitanXBoughtAndBurned;
    uint256 private totalKingXBoughtAndBurned;

    event BuyAndBurn(
        address indexed caller,
        uint256 titanXSpent,
        uint256 kingXReceived
    );

    constructor(address _titanX, address _kingX, address _uniswapRouter) {
        owner = msg.sender;
        titanX = IERC20(_titanX);
        kingX = IERC20(_kingX);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        slippage = 5;
        minInterval = 60;
        amountToSwap = 1000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function setKingXAddress(address _kingX) external onlyOwner {
        kingX = IERC20(_kingX);
    }

    function setTitanXAddress(address _titanX) external onlyOwner {
        titanX = IERC20(_titanX);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setRewardPerCall(uint256 _reward) external onlyOwner {
        rewardPerCall = _reward;
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 100, "Slippage too high");
        slippage = _slippage;
    }

    function setAmountToSwap(uint256 _amountToSwap) external onlyOwner {
        amountToSwap = _amountToSwap;
    }

    function setMinInterval(uint256 _interval) external onlyOwner {
        minInterval = _interval;
    }

    function buyAndBurn() external whenNotPaused {
        require(
            block.timestamp - lastCallTimestamp > minInterval,
            "Wait for the next call interval"
        );
        lastCallTimestamp = block.timestamp;

        require(titanX.transfer(msg.sender, rewardPerCall), "Transfer failed");

        uint256 kingXBalanceBefore = kingX.balanceOf(address(this));

        swapTitanXForKingX(amountToSwap);
        uint256 kingXBalanceAfter = kingX.balanceOf(address(this));

        uint256 kingXReceived = kingXBalanceAfter - kingXBalanceBefore;

        totalTitanXBoughtAndBurned += amountToSwap + rewardPerCall;
        totalKingXBoughtAndBurned += kingXReceived;

        emit BuyAndBurn(msg.sender, amountToSwap, kingXReceived);
    }

    function swapTitanXForKingX(uint256 titanXAmount) private whenNotPaused {
        titanX.approve(address(uniswapRouter), titanXAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(titanX),
                tokenOut: address(kingX),
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: titanXAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uniswapRouter.exactInputSingle(params);
    }

    function getRewardPerCall() public view returns (uint256) {
        return rewardPerCall;
    }

    function getSlippage() public view returns (uint256) {
        return slippage;
    }

    function getAmountToSwap() public view returns (uint256) {
        return amountToSwap;
    }

    function getMinInterval() public view returns (uint256) {
        return minInterval;
    }

    function getKingxBalance() public view returns (uint256) {
        return kingX.balanceOf(address(this));
    }

    function getTitanxBalance() public view returns (uint256) {
        return titanX.balanceOf(address(this));
    }

    function getTotalTitanXBoughtAndBurned() public view returns (uint256) {
        return totalTitanXBoughtAndBurned;
    }

    function getTotalKingXBoughtAndBurned() public view returns (uint256) {
        return totalKingXBoughtAndBurned;
    }
}
