pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/factories/BribeFactory.sol";
import "contracts/factories/GaugeFactory.sol";
import "contracts/factories/PairFactory.sol";
import "contracts/ExternalBribe.sol";
import "contracts/Gauge.sol";
import "contracts/Minter.sol";
import "contracts/OptionToken.sol";
import "contracts/OptionTokenV2.sol";
import "contracts/Pair.sol";
import "contracts/RewardsDistributor.sol";
import "contracts/Router.sol";
import "contracts/Flow.sol";
import "contracts/VelocimeterLibrary.sol";
import "contracts/Voter.sol";
import "contracts/VeArtProxy.sol";
import "contracts/VotingEscrow.sol";
import "utils/TestOwner.sol";
import "utils/TestStakingRewards.sol";
import "utils/TestToken.sol";
import "utils/TestVoter.sol";
import "utils/TestVotingEscrow.sol";
import "utils/TestWETH.sol";

abstract contract BaseTest is Test, TestOwner {
    uint256 constant USDC_1 = 1e6;
    uint256 constant USDC_100K = 1e11; // 1e5 = 100K tokens with 6 decimals
    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals
    uint256 constant TOKEN_100M = 1e26; // 1e8 = 100M tokens with 18 decimals
    uint256 constant TOKEN_10B = 1e28; // 1e10 = 10B tokens with 18 decimals
    uint256 constant PAIR_1 = 1e9;
    uint256 constant private ONE_DAY = 86400;
    uint256 constant internal ONE_WEEK = ONE_DAY * 7;
    uint256 constant internal TWENTY_SIX_WEEKS = 26 * ONE_WEEK;

    TestOwner owner;
    TestOwner owner2;
    TestOwner owner3;
    address[] owners;
    MockERC20 USDC;
    MockERC20 FRAX;
    MockERC20 DAI;
    TestWETH WETH; // Mock WETH token
    Flow FLOW;
    MockERC20 LR; // late reward
    TestToken stake;
    PairFactory factory;
    Router router;
    VelocimeterLibrary lib;
    Pair pair;
    Pair pair2;
    Pair pair3;
    Pair flowDaiPair;
    OptionToken oFlow;
    OptionTokenV2 oFlowV2;

    function deployOwners() public {
        owner = TestOwner(address(this));
        owner2 = new TestOwner();
        owner3 = new TestOwner();
        owners = new address[](3);
        owners[0] = address(owner);
        owners[1] = address(owner2);
        owners[2] = address(owner3);
    }

    function deployCoins() public {
        USDC = new MockERC20("USDC", "USDC", 6);
        FRAX = new MockERC20("FRAX", "FRAX", 18);
        DAI = new MockERC20("DAI", "DAI", 18);
        FLOW = new Flow(msg.sender, 82800140034502500000000000);
        LR = new MockERC20("LR", "LR", 18);
        WETH = new TestWETH();
        stake = new TestToken("stake", "stake", 18, address(owner));
    }

    function mintStables() public {
        for (uint256 i = 0; i < owners.length; i++) {
            USDC.mint(owners[i], 1e12 * USDC_1);
            FRAX.mint(owners[i], 1e12 * TOKEN_1);
            DAI.mint(owners[i], 1e12 * TOKEN_1);
        }
    }

    function mintFlow(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _amounts.length; i++) {
            FLOW.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintLR(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            LR.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintStake(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            stake.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintWETH(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            WETH.mint(_accounts[i], _amounts[i]);
        }
    }

    function dealETH(address [] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            vm.deal(_accounts[i], _amounts[i]);
        }
    }

    function deployPairFactoryAndRouter() public {
        factory = new PairFactory();
        assertEq(factory.allPairsLength(), 0);
        factory.setFee(true, 1); // set fee back to 0.01% for old tests
        factory.setFee(false, 1);
        factory.setTank(address(msg.sender)); // set tank

        router = new Router(address(factory), address(WETH));
        assertEq(router.factory(), address(factory));
        lib = new VelocimeterLibrary(address(router));
    }

    function deployPairWithOwner(address _owner) public {
        vm.startPrank(_owner, _owner);
        FRAX.approve(address(router), TOKEN_1);
        USDC.approve(address(router), USDC_1);
        router.addLiquidity(address(FRAX), address(USDC), true, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        FRAX.approve(address(router), TOKEN_1);
        USDC.approve(address(router), USDC_1);
        router.addLiquidity(address(FRAX), address(USDC), false, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        FRAX.approve(address(router), TOKEN_1);
        DAI.approve(address(router), TOKEN_1);
        router.addLiquidity(address(FRAX), address(DAI), true, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);
        FLOW.approve(address(router), TOKEN_1);
        DAI.approve(address(router), TOKEN_1);
        router.addLiquidity(address(FLOW), address(DAI), false, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);
        vm.stopPrank();
        assertEq(factory.allPairsLength(), 4);

        address create2address = router.pairFor(address(FRAX), address(USDC), true);
        address address1 = factory.getPair(address(FRAX), address(USDC), true);
        pair = Pair(address1);
        address address2 = factory.getPair(address(FRAX), address(USDC), false);
        pair2 = Pair(address2);
        address address3 = factory.getPair(address(FRAX), address(DAI), true);
        pair3 = Pair(address3);
        address address4 = factory.getPair(address(FLOW), address(DAI), false);
        flowDaiPair = Pair(address4);
        assertEq(address(pair), create2address);
        assertGt(lib.getAmountOut(USDC_1, address(USDC), address(FRAX), true), 0);
    }

    function mintPairFraxUsdcWithOwner(address _owner) public {
        TestOwner(_owner).transfer(address(USDC), address(pair), USDC_1);
        TestOwner(_owner).transfer(address(FRAX), address(pair), TOKEN_1);
        TestOwner(_owner).mint(address(pair), _owner);
    }

    function deployOptionTokenWithOwner(address _owner, address _gaugeFactory) public {
        oFlow = new OptionToken(
            "Option to buy FLOW",
            "oFLOW",
            _owner,
            DAI,
            ERC20(address(FLOW)),
            flowDaiPair,
            _gaugeFactory,
            _owner,
            30
        );
    }

    function deployOptionTokenV2WithOwner(
        address _owner,
        address _gaugeFactory,
        address _voter,
        address _escrow
    ) public {
        oFlowV2 = new OptionTokenV2(
            "Option to buy FLOW",
            "oFLOW",
            _owner,
            address(DAI),
            address(FLOW),
            flowDaiPair,
            _gaugeFactory,
            _owner,
            _voter,
            _escrow,
            address(router)
        );
    }

    receive() external payable {}
}
