import "./AggregatorV3Interface.sol";



contract sstest {
    AggregatorV3Interface internal priceFeed;

 constructor() {   priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);}


function getLatestPrice() public view returns (int) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
}

}