echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener

echo "" >  ./deployments/LuckyLandCard.full.sol
cat  ./scripts/head.sol >  ./deployments/LuckyLandCard.full.sol
$TF_CMD ./contracts/LuckyLandCard.sol >>  ./deployments/LuckyLandCard.full.sol 

echo "" >  ./deployments/LuckyLandFactory.full.sol
cat  ./scripts/head.sol >  ./deployments/LuckyLandFactory.full.sol
$TF_CMD ./contracts/LuckyLandFactory.sol >>  ./deployments/LuckyLandFactory.full.sol 

echo "" >  ./deployments/LuckyLandLottery.full.sol
cat  ./scripts/head.sol >  ./deployments/LuckyLandLottery.full.sol
$TF_CMD ./contracts/LuckyLandLottery.sol >>  ./deployments/LuckyLandLottery.full.sol 

echo "deploy end....."