pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./aliana/IAliana.sol";
import "./aliana/GFAccessControl.sol";
import "./aliana/IGeneScience.sol";

contract GeneMath {
    using SafeMath for uint256;

    uint256 constant posNum = 8;

    function _newSeedWithBlock(
        uint256 blockNumber,
        uint256 id1,
        uint256 id2
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(id1, id2, blockhash(blockNumber)))
            );
    }

    function _random(uint256 g1, uint256 g2) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(g1, g2)));
    }

    function _random3(
        uint256 g1,
        uint256 g2,
        uint256 g3
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(g1, g2, g3)));
    }

    function sliceUint8(uint256 bs, uint256 startByte)
        internal
        pure
        returns (uint8)
    {
        uint8 x = 0;
        x += uint8(bs >> (startByte * 8));
        return x;
    }

    function isCollections(uint256 gene) public pure returns (bool) {
        uint8 flag = sliceUint8(gene, 2 * 8);
        return (flag & 0x01) != 0;
    }

    function getTargetQualityList(uint32 q1, uint32 q2)
        public
        pure
        returns (uint32[5] memory)
    {
        q1 += 1;
        q2 += 1;
        uint32 a = q1 * 10 + q2;
        if (q1 > q2) {
            a = q2 * 10 + q1;
        }
        if (a == 11) {
            uint32[5] memory res = [uint32(85000), 12500, 2000, 500, 0];
            return res;
        } else if (a == 12) {
            uint32[5] memory res = [uint32(47500), 43750, 7250, 1250, 250];
            return res;
        } else if (a == 22) {
            uint32[5] memory res = [uint32(10000), 75000, 12500, 2000, 500];
            return res;
        } else if (a == 13) {
            uint32[5] memory res = [uint32(42500), 11250, 38500, 6500, 1250];
            return res;
        } else if (a == 23) {
            uint32[5] memory res = [uint32(5000), 42500, 43750, 7250, 1500];
            return res;
        } else if (a == 33) {
            uint32[5] memory res = [uint32(0), 10000, 75000, 12500, 2500];
            return res;
        } else if (a == 14) {
            uint32[5] memory res = [uint32(0), 0, 55000, 40000, 5000];
            return res;
        } else if (a == 24) {
            uint32[5] memory res = [uint32(0), 0, 54000, 40000, 6000];
            return res;
        } else if (a == 34) {
            uint32[5] memory res = [uint32(0), 0, 46250, 43750, 10000];
            return res;
        } else if (a == 44) {
            uint32[5] memory res = [uint32(0), 0, 10000, 75000, 15000];
            return res;
        } else if (a == 15) {
            uint32[5] memory res = [uint32(0), 0, 0, 60000, 40000];
            return res;
        } else if (a == 25) {
            uint32[5] memory res = [uint32(0), 0, 0, 57000, 43000];
            return res;
        } else if (a == 35) {
            uint32[5] memory res = [uint32(0), 0, 0, 53750, 46250];
            return res;
        } else if (a == 45) {
            uint32[5] memory res = [uint32(0), 0, 0, 47500, 52500];
            return res;
        } else if (a == 55) {
            uint32[5] memory res = [uint32(0), 0, 0, 5000, 95000];
            return res;
        } else {
            require(false, "unknown quality");
        }
    }

    function _randQuality(
        uint256 _seed,
        uint256 pos,
        uint8 _level1,
        uint8 _level2
    ) internal pure returns (uint8) {
        uint32 r = (uint32(_random(_seed, pos)) % 100000) + 1;
        uint32[5] memory list = getTargetQualityList(_level1, _level2);
        uint8 res = 0;
        for (uint8 i = 0; i < 5; i += 1) {
            uint32 v = list[i];
            if (r > v) {
                res = i + 1;
            } else {
                res = i;
                break;
            }
            r = r - v;
        }
        require(res <= 4, "randQuality: quality must < 4");
        return res;
    }

    function _randStyle(
        uint256 _seed,
        uint256 pos,
        uint8 _st1,
        uint8 _st2
    ) internal pure returns (uint8) {
        uint8[8] memory posStyleNum = [uint8(5), 6, 9, 4, 5, 8, 9, 4];
        uint8 maxStype = posStyleNum[pos];
        uint8 targetStyle = 0;
        uint32 stypeFrom = (uint32(_random(_seed, 8769872137)) % 4) + 1;
        if (stypeFrom == 1) {
            // stypeFrom _st1
            targetStyle = _st1;
        } else if (stypeFrom == 2) {
            // stypeFrom _st2
            targetStyle = _st2;
        } else {
            targetStyle = (uint8(_random(_seed, stypeFrom)) % maxStype);
        }
        return targetStyle;
    }

    /// @dev mix two genes
    /// @param _genes1 the genes1
    /// @param _genes2 the genes2
    function mixGenesBySeed(
        uint256 _genes1,
        uint256 _genes2,
        uint256 seed
    ) public pure returns (uint256) {
        return _mixGenesBySeed(_genes1, _genes2, seed);
    }

    /// @dev mix two genes
    /// @param _genes1 the genes1
    /// @param _genes2 the genes2
    function _mixGenesBySeed(
        uint256 _genes1,
        uint256 _genes2,
        uint256 seed
    ) internal pure returns (uint256) {
        require(
            (!isCollections(_genes1)) && (!isCollections(_genes2)),
            "collections can't mix"
        );
        seed = _random3(seed, _genes1, _genes2);
        uint256 res = uint256(0);
        for (uint256 pos = 0; pos < posNum; pos += 1) {
            uint256 index = pos * 2;

            uint8 targetQuality = _randQuality(
                _random(seed, res),
                pos,
                sliceUint8(_genes1, index),
                sliceUint8(_genes2, index)
            );
            res += uint256(uint256(targetQuality) << (index * 8));

            uint8 targetStyle = _randStyle(
                _random(seed, res),
                pos,
                sliceUint8(_genes1, index + 1),
                sliceUint8(_genes2, index + 1)
            );
            res += uint256(uint256(targetStyle) << ((index + 1) * 8));
        }
        return res;
    }

    function geneLpLaborDetail(int256 _id, uint256 _genes)
        public
        pure
        returns (uint256 base_, uint256 total_)
    {
        if (isCollections(_genes)) {
            return (0, 0);
        }
        // basic labor is 0
        uint256 resOther = uint256(0);
        uint256 resL3 = uint256(0);
        uint256 resL4 = uint256(0);
        uint256 l3Num = 0;
        uint256 l4Num = 0;
        uint256[8] memory posBasicLaborNum = [uint256(4), 5, 5, 7, 6, 8, 6, 8];
        uint256[5] memory qualityBasicLaborNum = [uint256(1), 4, 25, 120, 1000];
        uint256[9] memory plusLevel3 = [
            uint256(10000),
            10000,
            11000,
            13000,
            15000,
            18000,
            22000,
            30000,
            60000
        ];
        uint256[9] memory plusLevel4 = [
            uint256(10000),
            10000,
            12000,
            15000,
            21000,
            33000,
            50000,
            100000,
            300000
        ];
        for (uint256 pos = 0; pos < posNum; pos += 1) {
            uint256 index = pos * 2;
            uint8 level = sliceUint8(_genes, index);
            uint256 baseValue = posBasicLaborNum[pos] *
                qualityBasicLaborNum[level];
            if (level == 3) {
                resL3 += baseValue;
                l3Num++;
            } else if (level == 4) {
                resL4 += baseValue;
                l4Num++;
            } else {
                resOther += baseValue;
            }
        }
        if (false) {
            // shield warning
            _id = 0;
        }
        return (
            resOther + resL3 + resL4,
            resOther +
                resL3.mul(plusLevel3[l3Num]).div(10000) +
                resL4.mul(plusLevel4[l4Num]).div(10000)
        );
    }

    function geneLpLabor(int256 _id, uint256 _genes)
        public
        pure
        returns (uint256)
    {
        (, uint256 total) = geneLpLaborDetail(_id, _genes);
        return total;
    }

    function totalQuality(int256 _id, uint256 _genes)
        public
        pure
        returns (uint256)
    {
        // basic labor is 0
        uint256 res = uint256(0);
        for (uint256 pos = 0; pos < posNum; pos += 1) {
            uint256 index = pos * 2;
            uint8 level = sliceUint8(_genes, index);
            res += level;
        }
        if (false) {
            // shield warning
            _id = 0;
        }
        return res;
    }

    function isValid(int256 _id, uint256 _genes) public pure returns (bool) {
        if (_genes < 0) {
            return false;
        }
        if (false) {
            // shield warning
            _id = 0;
        }
        return true;
    }

    // For an auction item with the same id, its genes are the same no matter when.
    function getAuctionGene(uint256 _id) public pure returns (uint256) {
        uint256 gene;
        uint256 seed = uint256(
            keccak256(abi.encodePacked(_id, uint256(20210710)))
        );
        uint8[8] memory posStyleNum = [uint8(4), 4, 6, 4, 4, 6, 6, 4];
        for (uint256 pos = 0; pos < posNum; pos += 1) {
            seed = uint256(keccak256(abi.encodePacked(seed, uint256(pos))));
            uint256 index = pos * 2;

            uint8 targetQuality = 0;
            uint32 act = (uint32(seed) % 10000) + 1;
            if (act <= 9800) {
                targetQuality = 0;
            } else if (act <= 9800 + 190) {
                targetQuality = 1;
            } else if (act <= 9800 + 190 + 10) {
                targetQuality = 2;
            }
            gene += uint256(uint256(targetQuality) << (index * 8));

            seed = uint256(
                keccak256(abi.encodePacked(seed, uint256(targetQuality)))
            );
            uint8 maxStyle = posStyleNum[pos];
            uint8 targetStyle = (uint8(seed) % maxStyle);
            gene += uint256(uint256(targetStyle) << ((index + 1) * 8));
        }
        return gene;
    }
}

contract GeneScienceTask {
    using SafeMath for uint256;
    uint256 latestTaskId = 0;

    struct MixTask {
        address from;
        uint256 matronId;
        uint256 sireId;
        uint256 beginBlockNumber;
        uint256 seed;
        bool canTake;
    }

    event ExpiredMixTask(address indexed from, uint256 indexed id);

    // Mapping from owner to list of owned task IDs
    mapping(address => uint256[]) private _addrInProgressTasks;
    // Mapping from task ID to index of the owner task list
    mapping(uint256 => uint256) private _addrInProgressTasksIndex;

    mapping(uint256 => MixTask) internal mixTasks;

    function mixTaskOf(address addr)
        public
        view
        returns (
            address[] memory from,
            uint256[] memory matronId,
            uint256[] memory sireId,
            uint256[] memory beginBlockNumber,
            bool[] memory canTake
        )
    {
        uint256[] memory list = _addrInProgressTasks[addr];

        from = new address[](list.length);
        matronId = new uint256[](list.length);
        sireId = new uint256[](list.length);
        beginBlockNumber = new uint256[](list.length);
        canTake = new bool[](list.length);

        for (uint256 i = 0; i < list.length; i++) {
            uint256 taskId = list[i];
            MixTask memory task = mixTasks[taskId];
            from[i] = task.from;
            matronId[i] = task.matronId;
            sireId[i] = task.sireId;
            beginBlockNumber[i] = task.beginBlockNumber;
            canTake[i] = task.canTake;
        }
    }

    function mixTask(uint256 taskId)
        public
        view
        returns (
            address from,
            uint256 matronId,
            uint256 sireId,
            uint256 beginBlockNumber,
            bool canTake
        )
    {
        MixTask storage task = mixTasks[taskId];
        from = task.from;
        matronId = task.matronId;
        sireId = task.sireId;
        beginBlockNumber = task.beginBlockNumber;
        canTake = task.canTake;
    }

    /**
     * @dev Clear this owner list of expired tasks
     * @param owner address owning the tasks
     */
    function cleanAddrExpiredTasks(address owner) public {
        uint256[] memory list = addrInProgressTasks(owner);
        for (uint256 i = 0; i < list.length; i++) {
            MixTask storage task = mixTasks[list[i]];
            if (task.canTake && (task.beginBlockNumber + 255 <= block.number)) {
                _removeTaskToOwnerEnumeration(owner, list[i]);
                emit ExpiredMixTask(task.from, list[i]);
            }
        }
    }

    /**
     * @dev Gets the list of task IDs of the requested owner.
     * @param owner address owning the tasks
     * @return uint256[] List of task IDs owned by the requested address
     */
    function addrInProgressTasks(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory list = _addrInProgressTasks[owner];
        uint256[] memory result = new uint256[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            result[i] = list[i];
        }
        return result;
    }

    /**
     * @dev Private function to add a task to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given task ID
     * @param taskId uint256 ID of the task to be added to the tasks list of the given address
     */
    function _addTaskToOwnerEnumeration(address to, uint256 taskId) internal {
        _addrInProgressTasksIndex[taskId] = _addrInProgressTasks[to].length;
        _addrInProgressTasks[to].push(taskId);
    }

    /**
     * @dev Private function to remove a task from this extension's ownership-tracking data structures. Note that
     * while the task is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given task ID
     * @param taskId uint256 ID of the task to be removed from the tasks list of the given address
     */
    function _removeTaskToOwnerEnumeration(address from, uint256 taskId)
        internal
    {
        // To prevent a gap in from's tasks array, we store the last task in the index of the task to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _addrInProgressTasks[from].length.sub(1);
        uint256 taskIndex = _addrInProgressTasksIndex[taskId];

        // When the task to delete is the last task, the swap operation is unnecessary
        if (taskIndex != lastTokenIndex) {
            uint256 lastTokenId = _addrInProgressTasks[from][lastTokenIndex];

            _addrInProgressTasks[from][taskIndex] = lastTokenId; // Move the last task to the slot of the to-delete task
            _addrInProgressTasksIndex[lastTokenId] = taskIndex; // Update the moved task's index
        }

        // This also deletes the contents at the last position of the array
        _addrInProgressTasks[from].length--;

        // Note that _ownedTokensIndex[taskId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the task was the last one).
    }
}

contract GeneScienceSafe is GeneScienceTask, GeneMath, GFAccessControl {
    using SafeMath for uint256;

    IAliana public aliana;
    IGeneScience public mathGene;

    constructor(IAliana _alianaAddr) public {
        require(_alianaAddr.isAliana(), "GeneScience: isAliana false");
        aliana = _alianaAddr;
    }

    /// @dev Update the address of the genetic math contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setMathGene(IGeneScience _address) public onlyCEO {
        require(_address.isGeneScience(), "GeneScience: not gene");

        // Set the new contract address
        mathGene = _address;
    }

    function isGeneScience() public pure returns (bool) {
        return true;
    }

    /// @dev deprecated
    function mixGenes(
        int256, /* _id1 */
        int256, /* _id2 */
        uint256, /* _genes1 */
        uint256, /* _genes2 */
        uint256 /* _targetBlock */
    ) public pure returns (uint256) {
        require(false, "deprecated, use newMixTask and doneMixTask");
        return 0;
    }

    event NewMixTask(address indexed from, uint256 indexed id);

    event DoneMixTask(
        address indexed from,
        uint256 indexed id,
        uint256 kittenId
    );

    // Help someone to get his seeds. This caller can be our backend service.
    function trySeedAddrMixTask() external {
        _trySeedAddrMixTask(msg.sender);
    }

    // Help someone to get his seeds. This caller can be our backend service.
    function trySeedAddrMixTask(address addr) external {
        _trySeedAddrMixTask(addr);
    }

    // Help someone to get his seeds. This caller can be our backend service.
    function trySeedAddrMixTask(uint256 taskId) external {
        _trySeedAddrMixTask(taskId);
    }

    // Help someone to get his seeds. This caller can be our backend service.
    function _trySeedAddrMixTask(address addr) internal {
        uint256[] memory list = addrInProgressTasks(addr);
        for (uint256 i = 0; i < list.length; i++) {
            _trySeedAddrMixTask(list[i]);
        }
    }

    // Try to help the last person to get his seed. But if the last person's mission has expired, then unfortunately he will lose his synthesis
    function _trySeedAddrMixTask(uint256 taskId) internal {
        MixTask storage task = mixTasks[taskId];
        if (!task.canTake) {
            return;
        }
        if (task.seed != 0) {
            return;
        }
        if (task.beginBlockNumber >= block.number) {
            return;
        }
        if (task.beginBlockNumber + 255 > block.number) {
            task.seed = _newSeedWithBlock(
                task.beginBlockNumber,
                task.matronId,
                task.sireId
            );
        } else {
            // expired
        }
    }

    // The player needs to call newMixTask to create a task, and then call doneMixTask in another block to pick up the result of the composition
    function newMixTask(uint256 _matronId, uint256 _sireId)
        external
        returns (uint256)
    {
        cleanAddrExpiredTasks(msg.sender);
        return _newMixTask(_matronId, _sireId);
    }

    // The player needs to call newMixTask to create a task, and then call doneMixTask in another block to pick up the result of the composition
    function newMixTask(
        uint256[] calldata _matronIds,
        uint256[] calldata _sireIds
    ) external returns (uint256[] memory) {
        cleanAddrExpiredTasks(msg.sender);
        require(
            _matronIds.length != 0 && _matronIds.length == _sireIds.length,
            "MixTask: only different aliana can be merged"
        );

        uint256[] memory result = new uint256[](_matronIds.length);
        for (uint256 i = 0; i < _matronIds.length; i++) {
            result[i] = _newMixTask(_matronIds[i], _sireIds[i]);
        }
        return result;
    }

    // The player needs to call newMixTask to create a task, and then call doneMixTask in another block to pick up the result of the composition
    function _newMixTask(uint256 _matronId, uint256 _sireId)
        internal
        whenNotPaused
        returns (uint256)
    {
        latestTaskId = latestTaskId + 1;
        MixTask storage task = mixTasks[latestTaskId];
        require(
            _matronId != _sireId,
            "MixTask: only different aliana can be merged"
        );
        require(
            aliana.ownerOf(_matronId) == msg.sender,
            "MixTask: must be the owner"
        );
        require(
            aliana.ownerOf(_sireId) == msg.sender,
            "MixTask: must be the owner"
        );

        (uint256 matronBirthTime, , , uint256 matronGenes, ) = aliana.getAliana(
            _matronId
        );
        (uint256 sireBirthTime, , , uint256 sireGenes, ) = aliana.getAliana(
            _sireId
        );

        require(
            (!isCollections(matronGenes)) && (!isCollections(sireGenes)),
            "MixTask: collections can't mix"
        );

        // Check that the matron is a valid cat.
        require(matronBirthTime != 0, "Aliana: matron birthTime not valid");

        // Check that the sire is a valid cat.
        require(sireBirthTime != 0, "Aliana: sire birthTime not valid");

        aliana.transferFrom(msg.sender, address(this), _matronId);
        aliana.transferFrom(msg.sender, address(this), _sireId);
        aliana.burn(_matronId);
        aliana.burn(_sireId);

        task.from = msg.sender;
        task.matronId = _matronId;
        task.sireId = _sireId;
        task.beginBlockNumber = block.number;
        task.seed = 0;
        task.canTake = true;
        _addTaskToOwnerEnumeration(msg.sender, latestTaskId);
        emit NewMixTask(msg.sender, latestTaskId);
        return latestTaskId;
    }

    // The player needs to call newMixTask to create a task, and then call doneMixTask in another block to pick up the result of the composition
    function doneMixTask() external returns (uint256[] memory) {
        cleanAddrExpiredTasks(msg.sender);
        return _doneMixTask(msg.sender);
    }

    function doneMixTask(address addr) external returns (uint256[] memory) {
        cleanAddrExpiredTasks(addr);
        return _doneMixTask(addr);
    }

    function doneMixTask(uint256 taskId) external returns (uint256) {
        return _doneMixTask(taskId);
    }

    function _doneMixTask(address addr) internal returns (uint256[] memory) {
        uint256[] memory list = addrInProgressTasks(addr);
        uint256[] memory result = new uint256[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            result[i] = _doneMixTask(list[i]);
        }
        return result;
    }

    event Mix(
        address indexed src,
        uint256 indexed matronId,
        uint256 indexed sireId,
        uint256 kittenId
    );

    function _doneMixTask(uint256 taskId) internal returns (uint256) {
        MixTask storage task = mixTasks[taskId];
        require(task.canTake, "MixTask: can't take");

        uint256 _matronId = task.matronId;
        uint256 _sireId = task.sireId;

        require(
            task.beginBlockNumber != 0 && task.beginBlockNumber < block.number,
            "MixTask: wrong timing"
        );
        uint256 seed = task.seed;
        require(
            seed != 0 || task.beginBlockNumber + 255 > block.number,
            "MixTask: unfortunately, expired"
        );
        if (seed == 0 && task.beginBlockNumber + 255 > block.number) {
            seed = _newSeedWithBlock(
                task.beginBlockNumber,
                task.matronId,
                task.sireId
            );
        }
        require(seed != 0, "MixTask: seed 0");

        (, , , uint256 matronGenes, ) = aliana.getAliana(_matronId);
        (, , , uint256 sireGenes, ) = aliana.getAliana(_sireId);

        // Call the sooper-sekret gene mixing operation.
        uint256 childGenes = 0;
        if (address(mathGene) != address(0)) {
            childGenes = mathGene.mixGenesBySeed(matronGenes, sireGenes, seed);
        } else {
            childGenes = _mixGenesBySeed(matronGenes, sireGenes, seed);
        }

        uint256 kittenId = aliana.createOfficialAliana(
            _matronId,
            _sireId,
            childGenes,
            task.from
        );

        emit Mix(task.from, _matronId, _sireId, kittenId);

        task.canTake = false;
        _removeTaskToOwnerEnumeration(task.from, taskId);
        emit DoneMixTask(task.from, taskId, kittenId);
        return kittenId;
    }
}
