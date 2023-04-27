pragma solidity ^0.6.10;

import "./LibBytesMap.sol";
import "./UtilsContract.sol";
import "./openzeppelin/contracts-upgradeable/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/OwnableUpgradeable.sol";
import "./openzeppelin/contracts/ProxyAdmin.sol";
import "./openzeppelin/contracts/TransparentUpgradeableProxy.sol";
pragma experimental ABIEncoderV2;

/**
 * @title IssuerContract
 */
contract IssuerContract is Initializable, OwnableUpgradeable{

    using LibBytesMap for LibBytesMap.Map;
    LibBytesMap.Map private issuerMap;

    /**
     * @dev Error code
     */
    string constant private SUCCESS = "0000";
    string constant private ISSUER_NOT_EXIST = "2021";
    string constant private ISSUER_ALREADY_EXIST = "2022";

    event createIssuerRetLog(
        string msgcode,
        string msg
    );

    event getInitializeDataLog(
        string msgcode,
        bytes msg
    );

    /**
    * @dev initialize
    */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
    * @dev getInitializeData
    * @return "initialize()" func signature data
    */
    function getInitializeData() public returns(bytes memory){
        bytes memory data = abi.encodeWithSignature("initialize()");
        emit getInitializeDataLog(SUCCESS, data);
        return data;
    }

    /**
     * @dev Create issuer
     *
     * @param did the did
     * @param issuerInfo the issuer info
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function createIssuer(
        string memory did,
        string memory issuerInfo
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {
        bool bools = isIssuerExist(did);
        if (bools){
            emit createIssuerRetLog(ISSUER_ALREADY_EXIST, "issuer already exist");
            return (ISSUER_ALREADY_EXIST, "issuer already exist");
        }
        bytes memory didBytes = bytes(did);
        bytes memory issuerInfoBytes = bytes(issuerInfo);
        issuerMap.put(didBytes, issuerInfoBytes);
        emit createIssuerRetLog(SUCCESS, "success");
        return (SUCCESS, "success");
    }

    /**
     * @dev Get issuer by did
     *
     * @param did the did
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return issuerInfo the issuer info for result
     */
    function getIssuerByDid(
        string memory did
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        string memory issuerInfo
    )
    {
        bool bools = isIssuerExist(did);
        if (!bools){
            return (ISSUER_NOT_EXIST, "issuer not exist", "");
        }
        bytes memory didBytes = bytes(did);
        bytes memory issuerInfoBytes = issuerMap.getValue(didBytes);
        return (SUCCESS, "success", string(issuerInfoBytes));
    }

    /**
     * @dev Get all issuer info
     *
     * @param page the page
     * @param size the size
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return total the total for result
     * @return totalPage the totalPage for result
     * @return issuerLists the all issuer info list for result
     */
    function getAllIssuerInfo(
        uint32 page,
        uint32 size
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        uint256 total,
        uint256 totalPage,
        string[] memory issuerLists
    )
    {
        bytes[] memory issuerMapValues = issuerMap.values;
        if(issuerMapValues.length == 0){
            return (ISSUER_NOT_EXIST, "issuer not exist", 0, 0, new string[](0));
        }
        (uint256 totals, uint256 totalPages, string[] memory issuerList) = UtilsContract.pageIndex(page, size, issuerMapValues);
        return (SUCCESS, "success", totals, totalPages, issuerList);
    }

    /**
     * @dev Judge whether issuer exists, return true if it exist
     *
     * @param did the did
     * @return bool the bool for result
     */
    function isIssuerExist(
        string memory did
    )
    public
    view
    returns (
        bool
    )
    {
        bytes memory key = bytes(did);
        uint256 idx = issuerMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }
}

