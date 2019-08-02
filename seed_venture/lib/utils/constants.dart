// ROPSTEN

const String GlobalFactoryAddress = '0xd7f7c1206cf5dd94d6a2565dc1d078cdeaefb8c8';
const String SeedTokenAddress = '0x029eb9c1810a97431200c08b827944b30f615325';
const String DexAddress = '0x523b0dff8294e09ef0763805861e64593c4a4468';
const String infuraWSS = 'wss://testnet.seedventure.io'; // websocket
const String infuraHTTP = 'https://testnet.seedventure.io';
const String EtherscanURL = 'https://ropsten.etherscan.io/';
const int DefaultGasPrice = 30;
const int DefaultGasLimit = 8000000;

// topics for eth_getLogs
// Factory events
const String newPanelCreatedTopic = "0x28e958703d566ea9825155c28c95c3d92a2da219b51404343e4653bccd47525a";

// FP events
const String newSeedMaxSupplyTopic = "0x6c0400aaf859104057a4afd47301bdc6ac1829e4fd0b02292b6287ea761862e7";
const String ownerDataHashChangedTopic = "0xb4630f894cab42818aa587f8d4fc219b8472578638e808b23df12161ad730af6";
const String tokenExchangeRateChangedTopic = "0x09384e57f5d53342da2bbb810e7f68d5b6b397b491b7ae37f0b78b49d3d43ca5";
const String memberAddedTopic = "0x94d9b0a056867efca93631b338c7fde3befc3f54db36b90b8456b069385c30be";
const String memberHashChangedTopic = "0x4ae00b988cb3b798b8bc44e759790a289c70af1275d958aafd5938e2da3592f9";
const String fundsUnlockedTopic = "0x77a5b70f4e0aa62836a5593ff0f7bea03fbd7a17df0a63cf6cd5ce0a7a25ca1c";

// AT events
const String WLThresholdChangedTopic = "0x10b2a5b108c7f1e07744f78d98a096424f89c30fca6176cb114052d552ea4650";
